import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class CustomMap extends StatefulWidget {
  final List<MapListing> listings;
  final LatLng? initialLocation;
  final double? initialZoom;
  final bool showCurrentLocationButton;
  final bool showSearchBar;
  final ValueChanged<LatLng>? onLocationSelected;
  final ValueChanged<MapListing>? onListingSelected;
  final MapType mapType;
  final Set<Marker>? customMarkers;
  final Set<Polygon>? polygons;
  final Set<Polyline>? polylines;
  final Set<Circle>? circles;
  
  const CustomMap({
    super.key,
    required this.listings,
    this.initialLocation,
    this.initialZoom = 12.0,
    this.showCurrentLocationButton = true,
    this.showSearchBar = true,
    this.onLocationSelected,
    this.onListingSelected,
    this.mapType = MapType.normal,
    this.customMarkers,
    this.polygons,
    this.polylines,
    this.circles,
  });
  
  @override
  State<CustomMap> createState() => _CustomMapState();
}

class _CustomMapState extends State<CustomMap> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  LatLng? _currentLocation;
  bool _isLoading = true;
  String? _searchQuery;
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _initializeMap();
  }
  
  Future<void> _initializeMap() async {
    try {
      // Get current location if no initial location provided
      if (widget.initialLocation == null) {
        await _getCurrentLocation();
      }
      
      // Create markers from listings
      _createMarkers();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Failed to initialize map: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _getCurrentLocation() async {
    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied');
      }
      
      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      
      // Move camera to current location
      if (_mapController != null) {
        await _mapController.animateCamera(
          CameraUpdate.newLatLngZoom(
            _currentLocation!,
            widget.initialZoom!,
          ),
        );
      }
    } catch (e) {
      print('Failed to get current location: $e');
      // Fallback to default location
      _currentLocation = const LatLng(40.7128, -74.0060);
    }
  }
  
  void _createMarkers() {
    _markers.clear();
    
    // Add custom markers if provided
    if (widget.customMarkers != null) {
      _markers.addAll(widget.customMarkers!);
    }
    
    // Add listing markers
    for (final listing in widget.listings) {
      final marker = Marker(
        markerId: MarkerId(listing.id),
        position: listing.location,
        infoWindow: InfoWindow(
          title: listing.title,
          snippet: listing.priceFormatted,
          onTap: () {
            widget.onListingSelected?.call(listing);
          },
        ),
        icon: _getMarkerIcon(listing.category),
        onTap: () {
          widget.onListingSelected?.call(listing);
        },
      );
      
      _markers.add(marker);
    }
  }
  
  BitmapDescriptor _getMarkerIcon(String category) {
    // Customize marker icons based on category
    switch (category.toLowerCase()) {
      case 'real_estate':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case 'vehicle':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case 'electronics':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }
  
  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final locations = await locationFromAddress(query);
      
      if (locations.isNotEmpty) {
        final location = locations.first;
        final latLng = LatLng(location.latitude, location.longitude);
        
        await _mapController.animateCamera(
          CameraUpdate.newLatLngZoom(latLng, 14.0),
        );
        
        // Add marker for searched location
        final marker = Marker(
          markerId: const MarkerId('searched_location'),
          position: latLng,
          infoWindow: const InfoWindow(title: 'Searched Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        );
        
        setState(() {
          _markers.removeWhere((m) => m.markerId.value == 'searched_location');
          _markers.add(marker);
        });
        
        widget.onLocationSelected?.call(latLng);
      }
    } catch (e) {
      print('Failed to search location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location not found: $query'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _pickLocationFromMap() async {
    // Show dialog to confirm location pick
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Location'),
        content: const Text('Tap on the map to select a location.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Select'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && _currentLocation != null) {
      widget.onLocationSelected?.call(_currentLocation!);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final initialCameraPosition = CameraPosition(
      target: widget.initialLocation ?? _currentLocation ?? const LatLng(40.7128, -74.0060),
      zoom: widget.initialZoom!,
    );
    
    return Stack(
      children: [
        // Google Map
        GoogleMap(
          onMapCreated: (controller) {
            _mapController = controller;
          },
          initialCameraPosition: initialCameraPosition,
          markers: _markers,
          polygons: widget.polygons ?? {},
          polylines: widget.polylines ?? {},
          circles: widget.circles ?? {},
          mapType: widget.mapType,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          onTap: (latLng) {
            _pickLocationFromMap();
          },
          compassEnabled: true,
          rotateGesturesEnabled: true,
          scrollGesturesEnabled: true,
          zoomGesturesEnabled: true,
          tiltGesturesEnabled: true,
        ),
        
        // Search Bar
        if (widget.showSearchBar)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _buildSearchBar(),
          ),
        
        // Current Location Button
        if (widget.showCurrentLocationButton)
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton(
              onPressed: _getCurrentLocation,
              mini: true,
              child: const Icon(Icons.my_location),
            ),
          ),
        
        // Loading Indicator
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
  
  Widget _buildSearchBar() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search location...',
                  border: InputBorder.none,
                ),
                onSubmitted: _searchLocation,
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _markers.removeWhere((m) => m.markerId.value == 'searched_location');
                  });
                },
              ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class MapListing {
  final String id;
  final String title;
  final String description;
  final double price;
  final LatLng location;
  final String category;
  final String imageUrl;
  final bool isFeatured;
  
  const MapListing({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.location,
    required this.category,
    required this.imageUrl,
    this.isFeatured = false,
  });
  
  String get priceFormatted {
    return '\$${price.toStringAsFixed(2)}';
  }
}
