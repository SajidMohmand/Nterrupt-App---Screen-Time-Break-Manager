import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geocoding/geocoding.dart';

class HomeMainScreen extends StatefulWidget {
  const HomeMainScreen({super.key});

  @override
  State<HomeMainScreen> createState() => _HomeMainScreenState();
}

class _HomeMainScreenState extends State<HomeMainScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  GoogleMapController? _mapController;
  String _currentAddress = "Fetching location...";

  Position? _currentPosition;

  final List<Map<String, dynamic>> _hotels = [
    {
      "name": "Purple Sky Hotel",
      "lat": 37.42796133580664,
      "lng": -122.085749655962,
    },
    {
      "name": "Royal Orchid",
      "lat": 37.42496133180663,
      "lng": -122.081749655962,
    },
    {
      "name": "Moonlight Inn",
      "lat": 37.42196133580664,
      "lng": -122.088749655962,
    },
  ];

  final Set<Marker> _markers = {};

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // 🔥 Rebuild UI when tab changes
    });
    _initializeLocation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepPurpleAccent,
        automaticallyImplyLeading: false,
        toolbarHeight: 0, // Hide default toolbar
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(250),
          child: Column(
            children: [
              // Location Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _currentAddress,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.left,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Search TextField - Always Visible
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 12),
                    hintText: 'Select multiple restaurants...',
                    hintStyle:
                        const TextStyle(color: Colors.white70, fontSize: 14),
                    prefixIcon: const Icon(Icons.search,
                        color: Colors.white70, size: 20),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onChanged: (value) {},
                ),
              ),

              // Tabs Section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.only(top: 0),
                decoration: const BoxDecoration(
                  color: Colors.deepPurpleAccent,
                ),
                child: TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  indicator: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(26),
                      topLeft: Radius.circular(26),
                    ),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white,
                  labelPadding: EdgeInsets.zero,
                  tabs: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 2.2,
                      child: _buildCustomTab(
                        index: 0,
                        text: "Restaurants",
                        imagePath: 'assets/images/tab_image.png',
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 2.2,
                      child: _buildCustomTab(
                        index: 1,
                        text: "Map",
                        icon: Icons.map,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [_buildRestaurantsTab(), _buildMapTab()],
      ),
    );
  }

  Widget _buildCustomTab({
    required int index,
    String? text,
    String? imagePath,
    IconData? icon,
  }) {
    final isSelected = _tabController.index == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isSelected ? Colors.black : Colors.transparent,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (imagePath != null)
            Image.asset(
              imagePath,
              height: isSelected ? 36 : 30,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.restaurant,
                  size: isSelected ? 36 : 30,
                  color: isSelected ? Colors.white : Colors.white70,
                );
              },
            ),
          if (icon != null)
            Icon(
              icon,
              size: 26,
              color: isSelected ? Colors.white : Colors.white70,
            ),
          const SizedBox(height: 4),
          Text(
            text ?? "",
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // 🥘 Restaurants Tab (scrollable list)
  Widget _buildRestaurantsTab() {
    final restaurants = [
      "Purple Orchid Cafe",
      "White Lotus Grill",
      "Urban Bites",
      "Lavender Sky Lounge",
      "Midnight Dine",
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: restaurants.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final name = restaurants[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.2)),
          ),
          child: ListTile(
            leading: const Icon(
              Icons.restaurant_menu,
              color: Colors.deepPurpleAccent,
            ),
            title: Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            subtitle: const Text(
              "Tap for details",
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.deepPurpleAccent,
              size: 16,
            ),
            onTap: () {},
          ),
        );
      },
    );
  }

  // 🗺️ Map Tab (Google Map view)
  Widget _buildMapTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
            )
          : _currentPosition == null
              ? Center(
                  child: ElevatedButton.icon(
                    onPressed: _initializeLocation,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Retry"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GoogleMap(
                    onMapCreated: (controller) => _mapController = controller,
                    myLocationEnabled: true,
                    zoomControlsEnabled: false,
                    markers: _markers,
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      zoom: 14,
                    ),
                  ),
                ),
    );
  }

  Future<void> _initializeLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError("Please enable location services.");
        setState(() => _isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showError("Location permission denied.");
        setState(() => _isLoading = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _addHotelMarkers();
        _isLoading = false;
      });
      await _fetchNearbyHotels();
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _currentAddress = "${place.locality}, ${place.country}";
        });
      }
    } catch (e) {
      _showError("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _addHotelMarkers() {
    for (var hotel in _hotels) {
      _markers.add(
        Marker(
          markerId: MarkerId(hotel['name']),
          position: LatLng(hotel['lat'], hotel['lng']),
          infoWindow: InfoWindow(title: hotel['name']),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet,
          ),
        ),
      );
    }
  }

  Future<void> _fetchNearbyHotels() async {
    // ⚠️ Replace with your actual API key
    final apiKey = "AIzaSyBICWoox0z603tc9i81_e7yL8tf7YUtYtA";

    final lat = _currentPosition!.latitude;
    final lng = _currentPosition!.longitude;
    final radius = 2000; // meters

    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
      "?location=$lat,$lng"
      "&radius=$radius"
      "&type=lodging"
      "&key=$apiKey",
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        print(data);
        if (data["status"] == "OK") {
          List results = data["results"];
          _markers.clear();

          for (var place in results) {
            final name = place["name"];
            final geometry = place["geometry"];
            final lat = geometry["location"]["lat"];
            final lng = geometry["location"]["lng"];

            _markers.add(
              Marker(
                markerId: MarkerId(name),
                position: LatLng(lat, lng),
                infoWindow: InfoWindow(title: name),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueViolet,
                ),
              ),
            );
          }

          setState(() {});
        } else {
          _showError("Google Places error: ${data["status"]}");
        }
      } else {
        _showError("HTTP error: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Error fetching hotels: $e");
    }
  }
}
