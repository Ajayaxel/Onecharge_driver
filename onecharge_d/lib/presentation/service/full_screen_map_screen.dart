import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:onecharge_d/core/models/ticket.dart';

class FullScreenMapScreen extends StatefulWidget {
  final String? latitude;
  final String? longitude;
  final String location;
  final Ticket? ticket;

  const FullScreenMapScreen({
    super.key,
    this.latitude,
    this.longitude,
    required this.location,
    this.ticket,
  });

  @override
  State<FullScreenMapScreen> createState() => _FullScreenMapScreenState();
}

class _FullScreenMapScreenState extends State<FullScreenMapScreen> {
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
      return Scaffold(
        appBar: AppBar(
          title: const Text('Map'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: const Center(
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

    return Scaffold(
      body: Stack(
        children: [
          // Full screen Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _location!,
              zoom: 15.0,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('customer_location'),
                position: _location!,
                infoWindow: InfoWindow(
                  title: 'Customer Location',
                  snippet: widget.location,
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed,
                ),
              ),
            },
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            mapType: MapType.normal,
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            zoomControlsEnabled: true,
            compassEnabled: true,
            mapToolbarEnabled: false,
          ),
          // Top navigation bar overlay
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Navigation',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Location info card at the bottom
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Customer Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.location,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (widget.latitude != null && widget.longitude != null) {
                          _showNavigationOptions(
                            widget.latitude!,
                            widget.longitude!,
                            widget.location,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Location coordinates not available'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.directions,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: const Text(
                        'See Routes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNavigationOptions(String latitude, String longitude, String location) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Select Navigation App',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Google Maps
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.map,
                      color: Colors.blue,
                      size: 24,
                    ),
                  ),
                  title: const Text(
                    'Google Maps',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _openGoogleMaps(latitude, longitude, location);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 8),
                // Apple Maps
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.map_outlined,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                  title: const Text(
                    'Apple Maps',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _openAppleMaps(latitude, longitude, location);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 8),
                // Waze
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.navigation,
                      color: Color(0xFF5C9EFF),
                      size: 24,
                    ),
                  ),
                  title: const Text(
                    'Waze',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _openWaze(latitude, longitude, location);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openGoogleMaps(String latitude, String longitude, String location) async {
    try {
      final lat = double.parse(latitude);
      final lng = double.parse(longitude);
      
      final googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=${Uri.encodeComponent(location)}',
      );
      
      if (await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication)) {
        return;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open Google Maps'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening Google Maps: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openAppleMaps(String latitude, String longitude, String location) async {
    try {
      final lat = double.parse(latitude);
      final lng = double.parse(longitude);
      
      final appleMapsUrl = Uri.parse(
        Platform.isIOS
            ? 'http://maps.apple.com/?daddr=$lat,$lng'
            : 'http://maps.apple.com/?daddr=$lat,$lng',
      );
      
      if (await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication)) {
        return;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open Apple Maps'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening Apple Maps: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openWaze(String latitude, String longitude, String location) async {
    try {
      final lat = double.parse(latitude);
      final lng = double.parse(longitude);
      
      // Waze URL format: waze://?ll=latitude,longitude&navigate=yes
      final wazeUrl = Uri.parse(
        'waze://?ll=$lat,$lng&navigate=yes',
      );
      
      // Try Waze app first
      if (await launchUrl(wazeUrl, mode: LaunchMode.externalApplication)) {
        return;
      }
      
      // Fallback to Waze web if app is not installed
      final wazeWebUrl = Uri.parse(
        'https://waze.com/ul?ll=$lat,$lng&navigate=yes',
      );
      
      if (await launchUrl(wazeWebUrl, mode: LaunchMode.externalApplication)) {
        return;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open Waze'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening Waze: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

