import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import '../screens/resturent_details/restaurant_detail_screen.dart';

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
      if (!_tabController.indexIsChanging) {
        setState(() {}); // 🔥 Rebuild UI with smooth animation
      }
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
          preferredSize: const Size.fromHeight(215),
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
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.black87, Colors.black],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(26),
                      topLeft: Radius.circular(26),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurpleAccent.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
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
        physics: const BouncingScrollPhysics(), // ✅ Enable smooth swiping
        children: [
          _buildRestaurantsTabAnimated(),
          _buildMapTabAnimated(),
        ],
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
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic, // ✅ Smooth curve
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
                colors: [Colors.black87, Colors.black],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : null,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.deepPurpleAccent.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, -3),
                ),
              ]
            : [],
      ),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ✅ Animated Icon/Image with scale effect
          AnimatedScale(
            scale: isSelected ? 1.0 : 0.85,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            child: imagePath != null
                ? Image.asset(
                    imagePath,
                    height: 36,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.restaurant,
                        size: 36,
                        color: isSelected ? Colors.white : Colors.white70,
                      );
                    },
                  )
                : Icon(
                    icon,
                    size: 28,
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
          ),
          const SizedBox(height: 6),
          // ✅ Animated Text with fade
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white60,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: isSelected ? 14.5 : 13.5,
            ),
            child: Text(text ?? ""),
          ),
        ],
      ),
    );
  }

  // ✅ Animated version of restaurants tab
  Widget _buildRestaurantsTabAnimated() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      child: _tabController.index == 0
          ? _buildRestaurantsTab()
          : const SizedBox.shrink(),
    );
  }

  // 🥘 Restaurants Tab (scrollable list)
  Widget _buildRestaurantsTab() {
    final restaurants = [
      {
        "name": "Al Baik",
        "image":
            "https://www.albaik.com/assets/hero/home_hero_new_1400-d5bb20bf4a5a8eaa19d22379497bd57b11272c75d0efab0f86dd34248072a596.jpg",
        "discount": "20% OFF on all meals",
      },
      {
        "name": "Herfy",
        "image":
            "https://cdn.pixabay.com/photo/2015/04/08/13/13/food-712665_960_720.jpg",
        "discount": "Buy 1 Get 1 Free Burgers",
      },
      {
        "name": "Shawarma House",
        "image":
            "https://lh3.googleusercontent.com/gps-cs-s/AC9h4noBcwB4V7rKrfnWjkqlGBnfolDiaBZitleFEUCiMvnimG3MO8gaxOW-GpqY00D0wWjBcv48jIH9sDuXFon1V69FyrApFAbB0O0aKJwwiKn2Fe1JAPg8pEaMfQvN8MtWrmCeq2Go_CUvE8bZ=s1360-w1360-h1020-rw",
        "discount": "15% OFF on Shawarma Platters",
      },
      {
        "name": "Najd Village Restaurant",
        "image":
            "https://lh3.googleusercontent.com/p/AF1QipMIK5dVMTnbpwm8ju9RvnEvdzj3J0duQprSviy4=w141-h101-n-k-no-nu",
        "discount": "10% OFF on Family Meals",
      },
      {
        "name": "Kudu",
        "image":
            "https://www.kuducompany.com/@fs/var/www/kudu/attached_assets/k2.jpeg",
        "discount": "25% OFF Breakfast Menu",
      },
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: restaurants.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final r = restaurants[index];
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.12),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.deepPurpleAccent.withOpacity(0.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurpleAccent.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(10),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  r["image"]!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(
                r["name"]!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                r["discount"]!,
                style: const TextStyle(
                  color: Colors.deepPurpleAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white70,
                size: 16,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RestaurantDetailScreen(
                      name: r['name']!,
                      image: r['image']!,
                      discount: r['discount']!,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ✅ Animated version of map tab
  Widget _buildMapTabAnimated() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      child: _tabController.index == 1
          ? _buildMapTab()
          : const SizedBox.shrink(),
    );
  }

  // 🗺️ Map Tab (Google Map view)
  Widget _buildMapTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(color: Colors.deepPurpleAccent),
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
