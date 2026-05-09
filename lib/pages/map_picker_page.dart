import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'; // For LatLng class
import 'package:geolocator/geolocator.dart';// For accessing device location
import 'package:easy_localization/easy_localization.dart';

// A page that allows users to pick a location on the map
//content changes dynamically based on user interaction
class MapPickerPage extends StatefulWidget {
  const MapPickerPage({Key? key}) : super(key: key);

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  LatLng selectedPoint = LatLng(21.4858, 39.1925); // Default Jeddah
  final MapController _mapController = MapController(); // Map controller
  final TextEditingController _searchController = TextEditingController(); // For search input

// Function to get current location
  Future<void> _goToMyLocation() async {
    
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();// Check if location services are enabled
    if (!serviceEnabled) return; // Location services are not enabled
// Request permission if not granted
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||// If permission is denied
        permission == LocationPermission.deniedForever) {// If permission is denied forever
      permission = await Geolocator.requestPermission();// Request permission
      if (permission != LocationPermission.always && // If permission is not granted
          permission != LocationPermission.whileInUse) { //If permission is not granted
        return; // Permission not granted
      }
    }
// Get current position
    Position pos = await Geolocator.getCurrentPosition();
    setState(() {// Update selected point
      selectedPoint = LatLng(pos.latitude, pos.longitude);
    });
    _mapController.move(selectedPoint, 15);// Move map to current location
  }

  void _searchLocation() { // Search location by coordinates
    try {
      final parts = _searchController.text.split(",");// Split input by comma
      double lat = double.parse(parts[0].trim()); // Parse latitude
      double lng = double.parse(parts[1].trim()); // Parse longitude
      setState(() { // Update selected point
        selectedPoint = LatLng(lat, lng); // Create LatLng from parsed values
      });
      _mapController.move(selectedPoint, 14); // Move map to searched location
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar( 
         SnackBar(content: Text("Enter valid coordinates".tr())), // Show error message
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build the UI
    return Scaffold(
      appBar: AppBar(title: Text("Pick Location".tr())),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController, // Controller for search input
                    decoration: const InputDecoration(
                      hintText: "21.48, 39.19", // Hint text for input
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchLocation, // Search location on button press
                )
              ],
            ),
          ),

          Expanded(
            child: FlutterMap(
              mapController: _mapController, // Set map controller
              options: MapOptions( // Map options
                initialCenter: selectedPoint, // Initial center point
                initialZoom: 12, // Initial zoom level
                onTap: (tap, point) {
                  setState(() {
                    selectedPoint = point;
                  });
                },
              ),
              children: [
                TileLayer( // Tile layer for map
                // OpenStreetMap tiles
                  urlTemplate: 
                  "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: "com.example.artspace1",
                ),
                MarkerLayer(// Marker layer for selected point
                  markers: [
                    Marker(
                      point: selectedPoint,// Marker position
                      width: 60,// Marker width
                      height: 60,// Marker height
                      child: const Icon(
                        Icons.location_on,
                        size: 45,
                        color: Colors.red,
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
// Floating action buttons for map controls
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(// Zoom in button
            heroTag: "zoom_in",// Unique hero tag
            onPressed: () => _mapController.move(
              _mapController.camera.center, // Current center
              _mapController.camera.zoom + 1,// Zoom in
            ),
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "zoom_out",
            onPressed: () => _mapController.move(
              _mapController.camera.center,
              _mapController.camera.zoom - 1,
            ),
            child: const Icon(Icons.remove), // Zoom out button
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "my_location",
            onPressed: _goToMyLocation, // Go to current location
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "done",
            backgroundColor: Color(0xFF895735),
            onPressed: () => Navigator.pop(context, selectedPoint), // Return selected point
            child: const Icon(Icons.check, color: Colors.white),
          ),
        ],
      ),
    );
  }
}