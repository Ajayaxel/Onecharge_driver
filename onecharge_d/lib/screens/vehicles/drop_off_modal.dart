import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:onecharge_d/data/models/vehicle_model.dart';
import 'package:onecharge_d/logic/blocs/vehicle/vehicle_bloc.dart';
import 'package:onecharge_d/logic/blocs/vehicle/vehicle_event.dart';
import 'package:onecharge_d/logic/blocs/vehicle/vehicle_state.dart';
import 'package:onecharge_d/widgets/custom_toast.dart';

// ─── Side labels for display ──────────────────────────────────────────────────
const _sides = ['Front', 'Back', 'Left', 'Right', 'Top', 'Bottom'];
const _sideIcons = [
  Icons.arrow_upward,
  Icons.arrow_downward,
  Icons.arrow_back,
  Icons.arrow_forward,
  Icons.expand_less,
  Icons.expand_more,
];

/// Call this to open the drop-off flow for [vehicle].
Future<void> showDropOffModal(BuildContext context, VehicleModel vehicle) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<VehicleBloc>(),
      child: _DropOffModal(vehicle: vehicle),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _DropOffModal extends StatefulWidget {
  final VehicleModel vehicle;
  const _DropOffModal({required this.vehicle});

  @override
  State<_DropOffModal> createState() => _DropOffModalState();
}

class _DropOffModalState extends State<_DropOffModal> {
  // Stepper: 0 = map, 1 = images
  int _step = 0;

  // Map state
  GoogleMapController? _mapController;
  LatLng? _pickedLocation;
  bool _loadingLocation = true;

  // Image state — exactly 6 slots
  final List<String?> _imagePaths = List.filled(6, null);

  final ImagePicker _picker = ImagePicker();

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // ── Location ───────────────────────────────────────────────────────────────

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _loadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _loadingLocation = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _loadingLocation = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _pickedLocation = LatLng(pos.latitude, pos.longitude);
          _loadingLocation = false;
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_pickedLocation!, 16),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  // ── Image picking ──────────────────────────────────────────────────────────

  Future<void> _pickImage(int index) async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final file = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (file != null && mounted) {
      setState(() => _imagePaths[index] = file.path);
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text(
                'Camera',
                style: TextStyle(fontFamily: 'Lufga'),
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text(
                'Gallery',
                style: TextStyle(fontFamily: 'Lufga'),
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  void _submit() {
    final loc = _pickedLocation;
    if (loc == null) {
      CustomToast.show(
        context,
        'Please select a drop-off location',
        isError: true,
        alignRight: true,
      );
      return;
    }

    final missing = <String>[];
    for (int i = 0; i < _imagePaths.length; i++) {
      if (_imagePaths[i] == null) missing.add(_sides[i]);
    }
    if (missing.isNotEmpty) {
      CustomToast.show(
        context,
        'Missing images: ${missing.join(', ')}',
        isError: true,
        alignRight: true,
      );
      return;
    }

    context.read<VehicleBloc>().add(
      DropOffVehicle(
        vehicleId: widget.vehicle.id,
        latitude: loc.latitude,
        longitude: loc.longitude,
        imagePaths: List<String>.from(_imagePaths.map((p) => p!)),
      ),
    );

    Navigator.of(context).pop();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      height: screenH * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // ── Handle bar ──────────────────────────────────────────────────
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                if (_step == 1)
                  GestureDetector(
                    onTap: () => setState(() => _step = 0),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                    ),
                  ),
                if (_step == 1) const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _step == 0
                            ? 'Select Drop-off Location'
                            : 'Vehicle Photos',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Lufga',
                        ),
                      ),
                      Text(
                        _step == 0
                            ? 'Tap the map to set your drop-off point'
                            : 'Capture all 6 sides of the vehicle',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontFamily: 'Lufga',
                        ),
                      ),
                    ],
                  ),
                ),
                // Step indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Step ${_step + 1}/2',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Lufga',
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Step divider ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: _step >= 1 ? Colors.black : Colors.grey[200],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Content ─────────────────────────────────────────────────────
          Expanded(child: _step == 0 ? _buildMapStep() : _buildImagesStep()),

          // ── Bottom button ────────────────────────────────────────────────
          _buildBottomButton(),
        ],
      ),
    );
  }

  // ── Step 1: Map ────────────────────────────────────────────────────────────

  Widget _buildMapStep() {
    return Column(
      children: [
        // Map
        Expanded(
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _pickedLocation ?? const LatLng(0, 0),
                      zoom: 15,
                    ),
                    onMapCreated: (c) {
                      _mapController = c;
                      if (_pickedLocation != null) {
                        c.animateCamera(
                          CameraUpdate.newLatLngZoom(_pickedLocation!, 16),
                        );
                      }
                    },
                    onTap: (latLng) {
                      setState(() => _pickedLocation = latLng);
                    },
                    markers: _pickedLocation == null
                        ? {}
                        : {
                            Marker(
                              markerId: const MarkerId('dropoff'),
                              position: _pickedLocation!,
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueGreen,
                              ),
                              infoWindow: const InfoWindow(
                                title: 'Drop-off Location',
                              ),
                            ),
                          },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: false,
                  ),
                ),
              ),

              // Loading overlay
              if (_loadingLocation)
                Container(
                  color: Colors.white.withValues(alpha: 0.7),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.black),
                        SizedBox(height: 12),
                        Text(
                          'Getting your location…',
                          style: TextStyle(fontFamily: 'Lufga'),
                        ),
                      ],
                    ),
                  ),
                ),

              // Hint chip
              if (!_loadingLocation && _pickedLocation == null)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Tap on the map to set location',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontFamily: 'Lufga',
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Location info chip
        if (_pickedLocation != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8F1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF4CAF50), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Color(0xFF4CAF50),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Lat: ${_pickedLocation!.latitude.toStringAsFixed(6)}\n'
                      'Lng: ${_pickedLocation!.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Lufga',
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _determinePosition,
                    icon: const Icon(
                      Icons.my_location,
                      size: 16,
                      color: Colors.black,
                    ),
                    label: const Text(
                      'My Location',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black,
                        fontFamily: 'Lufga',
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ── Step 2: Images ─────────────────────────────────────────────────────────

  Widget _buildImagesStep() {
    final captured = _imagePaths.where((p) => p != null).length;
    return Column(
      children: [
        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                '$captured / 6 photos captured',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontFamily: 'Lufga',
                ),
              ),
              const Spacer(),
              if (captured == 6)
                const Text(
                  '✓ All photos captured',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Lufga',
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Grid of image slots
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              itemCount: 6,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (_, index) => _ImageSlot(
                index: index,
                path: _imagePaths[index],
                onTap: () => _pickImage(index),
                onRemove: () => setState(() => _imagePaths[index] = null),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Bottom button ──────────────────────────────────────────────────────────

  Widget _buildBottomButton() {
    return BlocBuilder<VehicleBloc, VehicleState>(
      buildWhen: (p, c) => p.dropOff.status != c.dropOff.status,
      builder: (context, state) {
        final submitting = state.dropOff.status == DropOffStatus.droppingOff;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: submitting
                    ? null
                    : () {
                        if (_step == 0) {
                          if (_pickedLocation == null) {
                            CustomToast.show(
                              context,
                              'Please pick a location on the map first',
                              isError: true,
                              alignRight: true,
                            );
                            return;
                          }
                          setState(() => _step = 1);
                        } else {
                          _submit();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _step == 0
                            ? 'Continue to Photos →'
                            : 'Confirm Drop-Off',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Lufga',
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────── Image Slot widget ────────────────────────────────

class _ImageSlot extends StatelessWidget {
  final int index;
  final String? path;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _ImageSlot({
    required this.index,
    required this.path,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasPic = path != null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: hasPic ? Colors.black : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasPic ? Colors.black : Colors.grey.shade300,
            width: hasPic ? 2 : 1,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Photo or placeholder
            if (hasPic)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(path!), fit: BoxFit.cover),
              )
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _sideIcons[index],
                    size: 28,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _sides[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                      fontFamily: 'Lufga',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to add',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade400,
                      fontFamily: 'Lufga',
                    ),
                  ),
                ],
              ),

            // Label overlay on captured image
            if (hasPic)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    _sides[index],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Lufga',
                    ),
                  ),
                ),
              ),

            // Remove button
            if (hasPic)
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),

            // Check badge
            if (hasPic)
              const Positioned(
                top: 6,
                left: 6,
                child: Icon(
                  Icons.check_circle,
                  color: Color(0xFF4CAF50),
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
