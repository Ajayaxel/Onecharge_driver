import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:onecharge_d/core/models/vehicle.dart';
import 'package:onecharge_d/core/services/background_location_service.dart';
import 'package:onecharge_d/core/utils/location_service.dart';
import 'package:onecharge_d/presentation/home/bloc/vehicle_bloc.dart';
import 'package:onecharge_d/presentation/home/bloc/vehicle_state.dart';
import 'package:onecharge_d/presentation/home/vehicle_drop_off_full_screen_map.dart';
import 'package:onecharge_d/presentation/home/vehicle_image_upload_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class VehicleDropOffBottomSheet extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleDropOffBottomSheet({
    super.key,
    required this.vehicle,
  });

  @override
  State<VehicleDropOffBottomSheet> createState() =>
      _VehicleDropOffBottomSheetState();
}

class _VehicleDropOffBottomSheetState
    extends State<VehicleDropOffBottomSheet> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  LatLng? _currentLocation;
  bool _isLoadingLocation = true;
  final LocationService _locationService = LocationService();
  final BackgroundLocationService _backgroundLocationService =
      BackgroundLocationService();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Try to get location from background service first
      Position? position = _backgroundLocationService.currentPosition;

      // If not available, get current location
      if (position == null) {
        position = await _locationService.getCurrentLocation();
      }

      if (position != null) {
        final latLng = LatLng(position.latitude, position.longitude);
        setState(() {
          _currentLocation = latLng;
          _selectedLocation = latLng; // Default to current location
          _isLoadingLocation = false;
        });

        // Move camera to current location
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(latLng, 15.0),
        );
      } else {
        setState(() {
          _isLoadingLocation = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to get current location'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onMapTap(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
  }

  void _openFullScreenMap() async {
    if (_selectedLocation == null) return;

    final selectedLocation = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleDropOffFullScreenMap(
          initialLocation: _selectedLocation!,
          currentLocation: _currentLocation,
          onLocationSelected: (location) {
            Navigator.of(context).pop(location);
          },
        ),
      ),
    );

    if (selectedLocation != null && mounted) {
      setState(() {
        _selectedLocation = selectedLocation;
      });
      // Update map camera to new location
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(selectedLocation, 15.0),
      );
    }
  }

  Future<void> _openGoogleMaps() async {
    if (_selectedLocation == null) return;

    try {
      final googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${_selectedLocation!.latitude},${_selectedLocation!.longitude}',
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

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _navigateToImageUpload() {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleImageUploadScreen(
          vehicle: widget.vehicle,
          selectedLocation: _selectedLocation!,
          hasIssue: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VehicleBloc, VehicleState>(
      listener: (context, state) {
        // Note: Drop-off success/error handling is now in VehicleImageUploadScreen
        // This listener is kept for any other vehicle state changes
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text(
                    'Return Vehicle',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Map
            Expanded(
              child: _isLoadingLocation
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.black),
                    )
                  : _selectedLocation == null
                      ? const Center(
                          child: Text('Unable to load map'),
                        )
                      : Stack(
                          children: [
                            GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: _selectedLocation!,
                                zoom: 15.0,
                              ),
                              onMapCreated: (GoogleMapController controller) {
                                _mapController = controller;
                              },
                              onTap: _onMapTap,
                              markers: {
                                Marker(
                                  markerId: const MarkerId('drop_off_location'),
                                  position: _selectedLocation!,
                                  infoWindow: const InfoWindow(
                                    title: 'Drop-off Location',
                                  ),
                                  icon: BitmapDescriptor.defaultMarkerWithHue(
                                    BitmapDescriptor.hueRed,
                                  ),
                                ),
                                if (_currentLocation != null &&
                                    _currentLocation != _selectedLocation)
                                  Marker(
                                    markerId: const MarkerId('current_location'),
                                    position: _currentLocation!,
                                    infoWindow: const InfoWindow(
                                      title: 'Current Location',
                                    ),
                                    icon: BitmapDescriptor.defaultMarkerWithHue(
                                      BitmapDescriptor.hueBlue,
                                    ),
                                  ),
                              },
                              myLocationButtonEnabled: true,
                              myLocationEnabled: true,
                              zoomControlsEnabled: true,
                              compassEnabled: true,
                              mapToolbarEnabled: false,
                            ),
                            // Full screen map button
                            Positioned(
                              top: 16,
                              right: 16,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FloatingActionButton(
                                    mini: true,
                                    backgroundColor: Colors.white,
                                    onPressed: _openFullScreenMap,
                                    heroTag: 'fullscreen',
                                    child: const Icon(
                                      Icons.fullscreen,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  FloatingActionButton(
                                    mini: true,
                                    backgroundColor: Colors.white,
                                    onPressed: _openGoogleMaps,
                                    heroTag: 'external',
                                    child: const Icon(
                                      Icons.open_in_new,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
            ),

            // Location info and button
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedLocation != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                              'Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedLocation == null
                          ? null
                          : _navigateToImageUpload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: const Text(
                        'Confirm Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

