import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:onecharge_d/presentation/service/full_screen_map_screen.dart';

class GoogleMapWidget extends StatefulWidget {
  final String? latitude;
  final String? longitude;
  final String location;

  const GoogleMapWidget({
    super.key,
    this.latitude,
    this.longitude,
    required this.location,
  });

  @override
  State<GoogleMapWidget> createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  GoogleMapController? _mapController;
  LatLng? _location;

  @override
  void initState() {
    super.initState();
    _parseLocation();
  }

  void _parseLocation() {
    try {
      if (widget.latitude != null && widget.longitude != null) {
        final lat = double.parse(widget.latitude!);
        final lng = double.parse(widget.longitude!);
        _location = LatLng(lat, lng);
      } else {
        // Default to Dubai if coordinates are null
        _location = const LatLng(25.13348087, 55.39013391);
      }
    } catch (e) {
      // Default to Dubai if parsing fails
      _location = const LatLng(25.13348087, 55.39013391);
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_location == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: Text(
            "Unable to load map",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Colors.black,
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _location!,
              zoom: 15.0,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('service_location'),
                position: _location!,
                infoWindow: InfoWindow(
                  title: 'Service Location',
                  snippet: widget.location,
                ),
              ),
            },
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            mapType: MapType.normal,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            onTap: (LatLng position) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullScreenMapScreen(
                    latitude: widget.latitude ?? '',
                    longitude: widget.longitude ?? '',
                    location: widget.location,
                  ),
                ),
              );
            },
          ),
        ),
        // Full screen icon overlay
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullScreenMapScreen(
                    latitude: widget.latitude ?? '',
                    longitude: widget.longitude ?? '',
                    location: widget.location,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.fullscreen,
                color: Colors.black,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

