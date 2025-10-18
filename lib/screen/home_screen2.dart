import 'dart:async';
import 'dart:convert';
import 'dart:math' show cos, sqrt, asin;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:system_alert_window/system_alert_window.dart';

/// Navigation + Maps screen
/// - Shows live user location on Google Map
/// - Search bar (Google Places Autocomplete via HTTP)
/// - Route drawing (Google Directions API)
/// - Navigation panel when destination set
/// - Sample traffic light countdown at one intersection
/// - When app backgrounded during navigation, show floating overlay window
/// - If stopped at red and it turns green while app backgrounded, ring a notification
class HomeScreenTwo extends StatefulWidget {
  const HomeScreenTwo({
    super.key,
    this.name,
    this.vehicle,
  });

  final String? name;
  final String? vehicle;

  @override
  State<HomeScreenTwo> createState() => _HomeScreenTwoState();
}

class _HomeScreenTwoState extends State<HomeScreenTwo>
    with WidgetsBindingObserver {
  // --- Configuration ---
  // IMPORTANT: Replace with your Google Maps/Places/Directions API key
  static const String googleApiKey = 'YOUR_GOOGLE_API_KEY';

  // Sample traffic light coordinates: 42°20'39.3"N 83°10'01.4"W
  // Decimal: 42.34425, -83.16706 (approx)
  static const LatLng sampleTrafficLight = LatLng(42.34425, -83.16706);

  // Traffic light cycle (sample data): total 59s
  static const int redSeconds = 30;
  static const int greenSeconds = 25;
  static const int yellowSeconds = 4;

  // --- Map/Location ---
  GoogleMapController? _mapController;
  final Location _location = Location();
  LocationData? _currentLocation;
  StreamSubscription<LocationData>? _locationSubscription;

  MapType _currentMapType = MapType.normal;
  final Set<Marker> _markers = <Marker>{};
  final Set<Polyline> _polylines = <Polyline>{};

  // --- Search ---
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<_PlaceSuggestion> _predictions = <_PlaceSuggestion>[];
  bool _showPredictions = false;

  // --- Routing ---
  LatLng? _destination;
  bool _hasRoute = false;
  bool _isNavigating = false;
  String? _routeDistanceText;
  String? _routeDurationText;

  // --- Traffic light simulation ---
  Timer? _trafficLightTicker;
  _TrafficPhase _currentPhase = _TrafficPhase.red;
  int _phaseSecondsRemaining = redSeconds;
  bool _nearSampleLight = false;
  _TrafficPhase? _previousPhase;

  // --- Background / notifications / overlay ---
  bool _appInBackground = false;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _initializeNotifications();
    _initLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _locationSubscription?.cancel();
    _mapController?.dispose();

    _trafficLightTicker?.cancel();

    _searchController.dispose();
    _searchFocusNode.dispose();

    super.dispose();
  }

  // --- Lifecycle ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _appInBackground = state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached;

    if (_appInBackground) {
      if (_isNavigating) {
        _showMiniOverlay();
      }
    } else {
      // Foreground - hide overlay if any
      _hideMiniOverlay();
    }
  }

  // --- Setup: notifications ---
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _notifications.initialize(initSettings);

    // Create a channel with sound for Android 8+
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'traffic_light_channel',
      'Traffic Light Alerts',
      description: 'Alerts when traffic lights change',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
      sound: RawResourceAndroidNotificationSound(''), // default sound
    );

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);
  }

  Future<void> _notifyGreenLight() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'traffic_light_channel',
      'Traffic Light Alerts',
      channelDescription: 'Alerts when traffic lights change',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      1001,
      'Light is GREEN',
      'Go now',
      details,
    );

    // Also play a short system click as immediate feedback (best-effort)
    await SystemSound.play(SystemSoundType.alert);
  }

  // --- Setup: location & live updates ---
  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          setState(() {});
          return;
        }
      }

      PermissionStatus permission = await _location.hasPermission();
      if (permission == PermissionStatus.denied) {
        permission = await _location.requestPermission();
        if (permission != PermissionStatus.granted) {
          setState(() {});
          return;
        }
      }

      // Initial get
      _currentLocation = await _location.getLocation();
      setState(() {});

      // Listen to updates
      _locationSubscription = _location.onLocationChanged.listen((loc) {
        setState(() {
          _currentLocation = loc;
        });
        _refreshMarkers();
        _checkProximityToSampleLight();
      });
    } catch (e) {
      // ignore
    }
  }

  void _refreshMarkers() {
    if (_currentLocation == null) return;

    final Set<Marker> newMarkers = <Marker>{
      Marker(
        markerId: const MarkerId('me'),
        position: LatLng(
          _currentLocation!.latitude ?? 0,
          _currentLocation!.longitude ?? 0,
        ),
        infoWindow: InfoWindow(
          title: widget.name ?? 'You',
          snippet: 'Current location',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    };

    if (_destination != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _destination!,
          infoWindow: const InfoWindow(title: 'Destination'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    // Optional: show a marker for the sample traffic light when navigating
    if (_isNavigating) {
      newMarkers.add(
        const Marker(
          markerId: MarkerId('traffic_light_sample'),
          position: sampleTrafficLight,
          infoWindow: InfoWindow(title: 'Traffic Light (sample)'),
        ),
      );
    }

    setState(() {
      _markers
        ..clear()
        ..addAll(newMarkers);
    });
  }

  // --- Search (Places Autocomplete) ---
  Future<void> _searchPlaces(String text) async {
    if (text.trim().isEmpty) {
      setState(() {
        _predictions = <_PlaceSuggestion>[];
        _showPredictions = false;
      });
      return;
    }

    try {
      final locationBias = _currentLocation != null
          ? '&location=${_currentLocation!.latitude},${_currentLocation!.longitude}&radius=20000'
          : '';
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeQueryComponent(text)}$locationBias&key=$googleApiKey',
      );
      final resp = await http.get(url).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final preds = (data['predictions'] as List<dynamic>?) ?? <dynamic>[];
        final suggestions = preds
            .map((e) => _PlaceSuggestion(
                  description: e['description'] as String? ?? '',
                  placeId: e['place_id'] as String? ?? '',
                ))
            .where((s) => s.placeId.isNotEmpty)
            .toList();
        setState(() {
          _predictions = suggestions;
          _showPredictions = suggestions.isNotEmpty;
        });
      }
    } catch (_) {
      // ignore transient errors
    }
  }

  Future<void> _selectPrediction(_PlaceSuggestion suggestion) async {
    try {
      // Get place details for coordinates
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=${Uri.encodeQueryComponent(suggestion.placeId)}&key=$googleApiKey',
      );
      final resp = await http.get(url).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final result = data['result'] as Map<String, dynamic>?;
        final geometry = result?['geometry'] as Map<String, dynamic>?;
        final loc = geometry?['location'] as Map<String, dynamic>?;
        if (loc != null) {
          final dest = LatLng((loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble());
          setState(() {
            _destination = dest;
            _searchController.text = suggestion.description;
            _showPredictions = false;
            _predictions = <_PlaceSuggestion>[];
            _hasRoute = false;
            _isNavigating = false;
          });
          _refreshMarkers();
          await _getRoute();
          await _fitToRoute();
        }
      }
    } catch (_) {
      // ignore
    }
  }

  // --- Directions & route polyline ---
  Future<void> _getRoute() async {
    if (_currentLocation == null || _destination == null) return;

    final origin = '${_currentLocation!.latitude},${_currentLocation!.longitude}';
    final dest = '${_destination!.latitude},${_destination!.longitude}';

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$dest&key=$googleApiKey',
      );
      final resp = await http.get(url).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final routes = (data['routes'] as List<dynamic>?) ?? <dynamic>[];
        if (routes.isNotEmpty) {
          final route = routes.first as Map<String, dynamic>;
          final overview = route['overview_polyline'] as Map<String, dynamic>?;
          final points = overview?['points'] as String?;

          final legs = (route['legs'] as List<dynamic>?) ?? <dynamic>[];
          if (legs.isNotEmpty) {
            final leg = legs.first as Map<String, dynamic>;
            _routeDistanceText = (leg['distance'] as Map<String, dynamic>?)?['text'] as String?;
            _routeDurationText = (leg['duration'] as Map<String, dynamic>?)?['text'] as String?;
          }

          if (points != null) {
            final coords = _decodePolyline(points);
            setState(() {
              _polylines
                ..clear()
                ..add(Polyline(
                  polylineId: const PolylineId('route'),
                  points: coords,
                  color: const Color(0xFF4285F4),
                  width: 5,
                  geodesic: true,
                ));
              _hasRoute = true;
            });
          }
        }
      }
    } catch (_) {
      // ignore
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  Future<void> _fitToRoute() async {
    if (_mapController == null || _currentLocation == null || _destination == null) return;

    double minLat = _currentLocation!.latitude ?? 0;
    double maxLat = _currentLocation!.latitude ?? 0;
    double minLng = _currentLocation!.longitude ?? 0;
    double maxLng = _currentLocation!.longitude ?? 0;

    void include(LatLng p) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    include(_destination!);

    final double latPadding = (maxLat - minLat).abs() * 0.2;
    final double lngPadding = (maxLng - minLng).abs() * 0.2;

    final bounds = LatLngBounds(
      southwest: LatLng(minLat - latPadding, minLng - lngPadding),
      northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
    );

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  // --- Traffic light simulation and proximity ---
  void _checkProximityToSampleLight() {
    if (_currentLocation == null || !_isNavigating) {
      _nearSampleLight = false;
      _stopTrafficLightTicker();
      return;
    }

    final me = LatLng(
      _currentLocation!.latitude ?? 0,
      _currentLocation!.longitude ?? 0,
    );
    final distanceMeters = _haversineMeters(me, sampleTrafficLight);
    final bool near = distanceMeters < 60; // ~60m proximity

    if (near && !_nearSampleLight) {
      _nearSampleLight = true;
      _startTrafficLightTicker();
    } else if (!near && _nearSampleLight) {
      _nearSampleLight = false;
      _stopTrafficLightTicker();
    }
  }

  void _startTrafficLightTicker() {
    _trafficLightTicker?.cancel();
    _updateTrafficPhase();
    _trafficLightTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTrafficPhase();
    });
  }

  void _stopTrafficLightTicker() {
    _trafficLightTicker?.cancel();
    _trafficLightTicker = null;
  }

  void _updateTrafficPhase() {
    // Deterministic phase based on current time modulo full cycle
    final int cycle = redSeconds + greenSeconds + yellowSeconds; // 59s
    final int t = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final int mod = t % cycle;

    _TrafficPhase newPhase;
    int remaining;
    if (mod < redSeconds) {
      newPhase = _TrafficPhase.red;
      remaining = redSeconds - mod;
    } else if (mod < redSeconds + greenSeconds) {
      newPhase = _TrafficPhase.green;
      remaining = redSeconds + greenSeconds - mod;
    } else {
      newPhase = _TrafficPhase.yellow;
      remaining = cycle - mod;
    }

    // Detect red -> green transition while app is backgrounded
    if (_appInBackground && _previousPhase == _TrafficPhase.red && newPhase == _TrafficPhase.green) {
      _notifyGreenLight();
    }

    _previousPhase = _currentPhase;

    setState(() {
      _currentPhase = newPhase;
      _phaseSecondsRemaining = remaining;
    });
  }

  // --- Overlay window when backgrounded ---
  Future<void> _showMiniOverlay() async {
    try {
      bool hasPermission = await SystemAlertWindow.checkPermissions() ?? false;
      if (!hasPermission) {
        await SystemAlertWindow.requestPermissions();
        hasPermission = await SystemAlertWindow.checkPermissions() ?? false;
      }
      if (!hasPermission) return;

      final String title = 'Navigation Active';
      final String line1 = _routeDurationText != null
          ? 'ETA: $_routeDurationText'
          : 'ETA: --';
      final String line2 = _routeDistanceText != null
          ? 'Distance: $_routeDistanceText'
          : 'Distance: --';

      await SystemAlertWindow.showSystemWindow(
        height: 180,
        width: 320,
        gravity: SystemWindowGravity.TOP,
        notificationTitle: 'Navigation',
        notificationBody: 'Running in background',
        header: SystemWindowHeader(
          title: SystemWindowText(text: title, fontSize: 16, textColor: Colors.white),
          padding: SystemWindowPadding.setSymmetricPadding(12, 12),
          decoration: SystemWindowDecoration(startColor: Colors.deepPurple),
        ),
        body: SystemWindowBody(
          rows: [
            EachRow(
              columns: [
                EachColumn(
                  text: SystemWindowText(text: line1, fontSize: 14, textColor: Colors.black87),
                ),
              ],
            ),
            EachRow(
              columns: [
                EachColumn(
                  text: SystemWindowText(text: line2, fontSize: 14, textColor: Colors.black87),
                ),
              ],
            ),
            if (_destination != null)
              EachRow(
                columns: [
                  EachColumn(
                    text: SystemWindowText(
                      text: 'Dest: ${_destination!.latitude.toStringAsFixed(4)}, ${_destination!.longitude.toStringAsFixed(4)}',
                      fontSize: 12,
                      textColor: Colors.black54,
                    ),
                  ),
                ],
              ),
          ],
          padding: SystemWindowPadding.setSymmetricPadding(12, 12),
          decoration: const SystemWindowDecoration(startColor: Colors.white),
        ),
      );
    } catch (_) {
      // ignore overlay errors
    }
  }

  Future<void> _hideMiniOverlay() async {
    try {
      await SystemAlertWindow.closeSystemWindow();
    } catch (_) {
      // ignore
    }
  }

  // --- Helpers ---
  double _haversineMeters(LatLng a, LatLng b) {
    const double p = 0.017453292519943295; // pi/180
    final double c = 0.5 -
        cos((b.latitude - a.latitude) * p) / 2 +
        cos(a.latitude * p) *
            cos(b.latitude * p) *
            (1 - cos((b.longitude - a.longitude) * p)) /
            2;
    return 12742000 * asin(sqrt(c)); // 2*R*asin, R=6371e3 m
  }

  void _centerOnMe() {
    if (_mapController == null || _currentLocation == null) return;
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            _currentLocation!.latitude ?? 0,
            _currentLocation!.longitude ?? 0,
          ),
          zoom: 17.5,
          tilt: 0,
          bearing: 0,
        ),
      ),
    );
  }

  void _cycleMapType() {
    setState(() {
      if (_currentMapType == MapType.normal) {
        _currentMapType = MapType.satellite;
      } else if (_currentMapType == MapType.satellite) {
        _currentMapType = MapType.hybrid;
      } else {
        _currentMapType = MapType.normal;
      }
    });
  }

  void _startNavigation() {
    if (_hasRoute) {
      setState(() {
        _isNavigating = true;
      });
      _refreshMarkers();
      _checkProximityToSampleLight();
    }
  }

  void _stopNavigation() {
    setState(() {
      _isNavigating = false;
      _nearSampleLight = false;
    });
    _stopTrafficLightTicker();
    _hideMiniOverlay();
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    final bool isLoading = _currentLocation == null;

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading Map'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.name ?? 'Navigation'}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.layers),
            onPressed: _cycleMapType,
            tooltip: 'Map type',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
              _refreshMarkers();
            },
            initialCameraPosition: CameraPosition(
              target: LatLng(
                _currentLocation!.latitude ?? 0,
                _currentLocation!.longitude ?? 0,
              ),
              zoom: 16,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: _currentMapType,
            markers: _markers,
            polylines: _polylines,
            trafficEnabled: true,
            buildingsEnabled: true,
            indoorViewEnabled: true,
            zoomControlsEnabled: false,
            minMaxZoomPreference: const MinMaxZoomPreference(3, 20),
          ),

          // Search bar
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              children: [
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Search destination',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _predictions = <_PlaceSuggestion>[];
                                  _showPredictions = false;
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    onChanged: _searchPlaces,
                    onSubmitted: _searchPlaces,
                    textInputAction: TextInputAction.search,
                  ),
                ),
                if (_showPredictions)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _predictions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final s = _predictions[index];
                        return ListTile(
                          leading: const Icon(Icons.place_outlined),
                          title: Text(
                            s.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _selectPrediction(s),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Top info card (similar to prior UI)
          Positioned(
            top: 84,
            left: 16,
            right: 16,
            child: Card(
              elevation: 8,
              color: Colors.white.withOpacity(0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.directions_car, color: Colors.deepPurple, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.vehicle ?? 'Vehicle',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.navigation, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                _routeDistanceText ?? '--',
                                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                              ),
                              if (_hasRoute) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Route ${_isNavigating ? 'active' : 'ready'}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.green[800],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Traffic light countdown when near the sample intersection and navigating
          if (_isNavigating && _nearSampleLight)
            Positioned(
              top: 170,
              left: 16,
              right: 16,
              child: _TrafficLightBanner(
                phase: _currentPhase,
                secondsRemaining: _phaseSecondsRemaining,
              ),
            ),

          // Bottom navigation panel
          if (_destination != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _NavigationPanel(
                distanceText: _routeDistanceText,
                durationText: _routeDurationText,
                isNavigating: _isNavigating,
                onStart: _startNavigation,
                onStop: _stopNavigation,
                onFit: _fitToRoute,
                onCenter: _centerOnMe,
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'center',
            onPressed: _centerOnMe,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'fit',
            onPressed: _fitToRoute,
            child: const Icon(Icons.route),
          ),
        ],
      ),
    );
  }
}

// --- Models/UI helpers ---
class _PlaceSuggestion {
  _PlaceSuggestion({required this.description, required this.placeId});
  final String description;
  final String placeId;
}

enum _TrafficPhase { red, yellow, green }

class _TrafficLightBanner extends StatelessWidget {
  const _TrafficLightBanner({
    required this.phase,
    required this.secondsRemaining,
  });

  final _TrafficPhase phase;
  final int secondsRemaining;

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String label;
    switch (phase) {
      case _TrafficPhase.red:
        color = Colors.red;
        icon = Icons.stop_circle_outlined;
        label = 'Stop';
        break;
      case _TrafficPhase.yellow:
        color = Colors.amber;
        icon = Icons.warning_amber_outlined;
        label = 'Prepare';
        break;
      case _TrafficPhase.green:
        color = Colors.green;
        icon = Icons.directions_car_filled_outlined;
        label = 'Go';
        break;
    }

    return Card(
      elevation: 8,
      color: Colors.white.withOpacity(0.98),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Traffic light ahead',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$label • $secondsRemaining s',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationPanel extends StatelessWidget {
  const _NavigationPanel({
    required this.distanceText,
    required this.durationText,
    required this.isNavigating,
    required this.onStart,
    required this.onStop,
    required this.onFit,
    required this.onCenter,
  });

  final String? distanceText;
  final String? durationText;
  final bool isNavigating;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final Future<void> Function() onFit;
  final VoidCallback onCenter;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    durationText ?? '--',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    distanceText ?? '--',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (!isNavigating)
              ElevatedButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start'),
              )
            else ...[
              OutlinedButton.icon(
                onPressed: onFit,
                icon: const Icon(Icons.fullscreen),
                label: const Text('Fit'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onCenter,
                icon: const Icon(Icons.my_location),
                label: const Text('Me'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onStop,
                icon: const Icon(Icons.stop),
                label: const Text('Stop'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
