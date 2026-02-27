import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:onecharge_d/widgets/success_bottom_sheet.dart';
import 'dart:ui' as ui;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onecharge_d/logic/blocs/driver/driver_bloc.dart';
import 'package:onecharge_d/logic/blocs/driver/driver_state.dart';
import 'package:onecharge_d/logic/blocs/driver/driver_event.dart';
import 'package:onecharge_d/logic/blocs/ticket/ticket_bloc.dart';
import 'package:onecharge_d/logic/blocs/ticket/ticket_state.dart';
import 'package:onecharge_d/logic/blocs/ticket/ticket_event.dart';
import 'package:onecharge_d/data/models/ticket_model.dart';
import 'package:onecharge_d/widgets/custom_toast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:onecharge_d/widgets/platform_loading.dart';
import 'package:geocoding/geocoding.dart';
import 'package:onecharge_d/core/network/reverb_service.dart';
import 'package:onecharge_d/logic/blocs/vehicle/vehicle_bloc.dart';
import 'package:onecharge_d/logic/blocs/vehicle/vehicle_event.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';

class HomeTab extends StatefulWidget {
  final Function(bool) onSheetToggle;

  const HomeTab({super.key, required this.onSheetToggle});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _isSheetOpen = false;
  double _dragPosition = 0.0;
  bool _isAccepted = false;
  bool _isAccepting = false;
  bool _isWorkStarted = false;
  List<XFile> _beforeImages = [];
  List<XFile> _afterImages = [];
  final ImagePicker _picker = ImagePicker();

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  BitmapDescriptor? _customIcon;
  Position? _currentPosition;
  GoogleMapController? _mapController;
  String _locationAddress = 'Fetching location...';
  StreamSubscription<Position>? _positionStream;
  Map<String, Marker> _otherDriversMarkers = {};
  bool _hasCenteredOnDriver = false; // ensures we snap to driver on first fix
  bool _mapTouched = false; // freezes outer scroll while user touches the map

  // Only these statuses are considered "active" and shown on the home screen
  static const List<String> _activeStatuses = [
    'offered', // New ticket offered to driver — show Swipe to Accept
    'assigned',
    'accepted',
    'on_the_way',
    'in_progress',
    'working',
  ];

  bool _isActiveTicket(String status) =>
      _activeStatuses.contains(status.toLowerCase());

  @override
  void initState() {
    super.initState();
    _loadCustomIcon();
    _getCurrentLocation();
    // Only fetch tickets if not already loaded.
    // main.dart fires FetchTickets on auth — this guard prevents a
    // duplicate call every time the home tab rebuilds.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // final ticketState = context.read<TicketBloc>().state;
      // if (ticketState is! TicketLoaded) {
      //   context.read<TicketBloc>().add(FetchTickets());
      // }
    });
    _initRealTimeListeners();
  }

  void _initRealTimeListeners() {
    final reverb = ReverbService();

    // Other drivers' locations
    reverb.bindLocationUpdated((data) {
      if (!mounted) return;
      final driverId = data['driver_id'].toString();
      final lat = double.tryParse(data['latitude'].toString());
      final lng = double.tryParse(data['longitude'].toString());
      final name = data['name'] ?? 'Driver';

      if (lat != null && lng != null) {
        setState(() {
          _otherDriversMarkers[driverId] = Marker(
            markerId: MarkerId('driver_$driverId'),
            position: LatLng(lat, lng),
            icon: _customIcon ?? BitmapDescriptor.defaultMarker,
            infoWindow: InfoWindow(title: name),
          );
        });
        _updateMarkers(); // Refresh combined markers
      }
    });

    // Vehicle dropped off
    reverb.bindVehicleDroppedOff((data) {
      if (!mounted) return;
      // Refresh available vehicles in the BLoC
      context.read<VehicleBloc>().add(FetchVehicles());
    });
  }

  // Throttle location updates to at most once per 5 seconds.
  // Using HTTP POST (not raw socket) so the backend updates
  // `last_location_updated_at` and broadcasts to the correct customer channel.
  DateTime? _lastLocationUpdateTime;

  void _sendLocationUpdateToSocket(Position position) {
    final now = DateTime.now();
    if (_lastLocationUpdateTime == null ||
        now.difference(_lastLocationUpdateTime!) > const Duration(seconds: 5)) {
      _lastLocationUpdateTime = now;
      // Fire-and-forget — errors are logged inside sendLocationUpdate.
      ReverbService().sendLocationUpdate(position.latitude, position.longitude);
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController = null;
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    // Listen for location updates
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((Position position) async {
          if (mounted) {
            setState(() {
              _currentPosition = position;
            });

            // Fetch address
            try {
              List<Placemark> placemarks = await placemarkFromCoordinates(
                position.latitude,
                position.longitude,
              ).timeout(const Duration(seconds: 3));
              if (placemarks.isNotEmpty) {
                final place = placemarks.first;
                setState(() {
                  _locationAddress =
                      '${place.name}, ${place.subLocality}, ${place.locality}';
                });
              }
            } catch (e) {
              print('Error fetching address: $e');
            }

            if (_mapController != null && !_hasCenteredOnDriver) {
              _hasCenteredOnDriver = true;
              _mapController!.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: LatLng(position.latitude, position.longitude),
                    zoom: 15,
                  ),
                ),
              );
            }
            _updateMarkers();
            _sendLocationUpdateToSocket(position);
          }
        });

    // Try to get last known position first
    Position? position = await Geolocator.getLastKnownPosition();

    if (position == null) {
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 5),
        );
      } catch (e) {
        print('Error getting current position: $e');
      }
    }

    if (position != null) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });

        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          ).timeout(const Duration(seconds: 3));

          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            setState(() {
              _locationAddress =
                  '${place.name ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}'
                      .replaceAll(RegExp(r'^, |, , '), '')
                      .trim();
            });
          }
        } catch (e) {
          print('Error fetching initial address: $e');
        }

        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(position.latitude, position.longitude),
            ),
          );
        }
        _updateMarkers();
      }
    } else {
      if (mounted) {
        setState(() {
          _locationAddress = 'Location unavailable';
        });
      }
    }
  }

  Future<Uint8List> _getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
  }

  void _loadCustomIcon() async {
    final Uint8List markerIcon = await _getBytesFromAsset(
      'images/home/mapdrivercar.png',
      160, // Reduced width for smaller car icon
    );
    if (!mounted) return;
    _customIcon = BitmapDescriptor.fromBytes(markerIcon);
    _updateMarkers();
  }

  void _updateMarkers({LatLng? destination}) {
    if (!mounted) return;
    Set<Marker> newMarkers = {};

    // Driver's current position
    if (_currentPosition != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          icon: _customIcon ?? BitmapDescriptor.defaultMarker,
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }

    // If we have a destination (accepted ticket)
    if (destination != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('customer'),
          position: destination,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'Customer Location'),
        ),
      );
    }

    setState(() {
      _markers = {...newMarkers, ..._otherDriversMarkers.values};
    });
  }

  void _drawRoute(LatLng destination) {
    if (!mounted || _currentPosition == null) return;

    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: [
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            destination,
          ],
          color: Colors.black,
          width: 5,
        ),
      };
    });

    // Fit both markers on screen
    if (_mapController != null) {
      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
          _currentPosition!.latitude < destination.latitude
              ? _currentPosition!.latitude
              : destination.latitude,
          _currentPosition!.longitude < destination.longitude
              ? _currentPosition!.longitude
              : destination.longitude,
        ),
        northeast: LatLng(
          _currentPosition!.latitude > destination.latitude
              ? _currentPosition!.latitude
              : destination.latitude,
          _currentPosition!.longitude > destination.longitude
              ? _currentPosition!.longitude
              : destination.longitude,
        ),
      );
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
    }
  }

  Future<void> _openMapsOption(LatLng destination) async {
    final lat = destination.latitude;
    final lng = destination.longitude;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              'Select Navigation',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lufga',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Choose your preferred maps application',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
                fontFamily: 'Lufga',
              ),
            ),
            const SizedBox(height: 30),
            if (Platform.isIOS)
              _buildNavOption(
                title: 'Apple Maps',
                icon: Icons.map_rounded,
                color: const Color(0xFF007AFF),
                onTap: () async {
                  await launchUrl(
                    Uri.parse('http://maps.apple.com/?daddr=$lat,$lng'),
                  );
                  if (context.mounted) Navigator.pop(context);
                },
              )
            else
              _buildNavOption(
                title: 'Google Maps',
                icon: Icons.location_on_rounded,
                color: const Color(0xFF34A853),
                onTap: () async {
                  final googleUrl = 'google.navigation:q=$lat,$lng';
                  if (await canLaunchUrl(Uri.parse(googleUrl))) {
                    await launchUrl(Uri.parse(googleUrl));
                  } else {
                    await launchUrl(
                      Uri.parse(
                        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
                      ),
                    );
                  }
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            const SizedBox(height: 16),
            _buildNavOption(
              title: 'Waze',
              icon: Icons.directions_car_rounded,
              color: const Color(0xFF33CCFF),
              onTap: () async {
                final wazeUrl = 'waze://?ll=$lat,$lng&navigate=yes';
                final wazeWebUrl =
                    'https://www.waze.com/ul?ll=$lat,$lng&navigate=yes';

                if (await canLaunchUrl(Uri.parse(wazeUrl))) {
                  await launchUrl(Uri.parse(wazeUrl));
                } else {
                  // Fallback to Waze Web
                  await launchUrl(
                    Uri.parse(wazeWebUrl),
                    mode: LaunchMode.externalApplication,
                  );
                }
                if (context.mounted) Navigator.pop(context);
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildNavOption({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'Lufga',
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocListener<TicketBloc, TicketState>(
        listener: (context, state) {
          // ─── IMPORTANT: check subclasses BEFORE the base TicketLoaded ───
          // All states below extend TicketLoaded, so they MUST come first in
          // an if/else chain, otherwise TicketLoaded would swallow them all.

          if (state is TicketAccepted) {
            // Swipe accepted — mark accepted, draw route
            CustomToast.show(context, state.message);
            setState(() {
              _isAccepted = true;
              _isAccepting = false;
            });
            if (state.tickets.isNotEmpty) {
              final ticket = state.tickets.first;
              final dest = LatLng(
                double.parse(ticket.latitude),
                double.parse(ticket.longitude),
              );
              _updateMarkers(destination: dest);
              _drawRoute(dest);
            }
          } else if (state is TicketAcceptError) {
            CustomToast.show(context, state.message, isError: true);
            setState(() {
              _dragPosition = 0;
              _isAccepted = false;
              _isAccepting = false;
            });
          } else if (state is TicketWorkStarted) {
            // ✅ StartWork API confirmed — NOW show Work in Progress
            setState(() => _isWorkStarted = true);
            CustomToast.show(context, state.message, alignRight: true);
          } else if (state is TicketWorkStartError) {
            // StartWork failed — show API error, keep showing Reached
            CustomToast.show(
              context,
              state.message,
              isError: true,
              alignRight: true,
            );
          } else if (state is TicketWorkCompleted) {
            CustomToast.show(context, state.message, alignRight: true);
          } else if (state is TicketWorkCompleteError) {
            CustomToast.show(
              context,
              state.message,
              isError: true,
              alignRight: true,
            );
          } else if (state is TicketAttachmentUploaded) {
            CustomToast.show(context, state.message, alignRight: true);
            // If the sheet is still open (i.e. we were uploading), close it
            if (Navigator.of(context).canPop()) {
              Navigator.pop(context); // Close the Upload Sheet
            }

            // Immediately update the Work in Progress status if was before_work
            if (state.type == 'before_work') {
              setState(() {
                _isWorkStarted = true;
              });
            }

            // If it was after_work (which completes the ticket usually),
            // close the task sheet and show success
            final activeTickets = state.tickets
                .where((t) => _isActiveTicket(t.status))
                .toList();

            if (activeTickets.isEmpty || state.type == 'after_work') {
              setState(() {
                _isSheetOpen = false;
                _isAccepted = false;
                _isWorkStarted = false;
              });
              widget.onSheetToggle(true);
              SuccessBottomSheet.show(context);
            }
          } else if (state is TicketAttachmentUploadError) {
            CustomToast.show(
              context,
              state.message,
              isError: true,
              alignRight: true,
            );
          } else if (state is TicketLoaded) {
            // If we are currently in the middle of an Accept API call,
            // ignore the background polling results so the UI doesn't flicker/reset.
            if (_isAccepting) return;

            // Base class — only reached for plain FetchTickets responses
            final activeTickets = state.tickets
                .where((t) => _isActiveTicket(t.status))
                .toList();

            if (activeTickets.isNotEmpty) {
              final ticket = activeTickets.first;
              final dest = LatLng(
                double.parse(ticket.latitude),
                double.parse(ticket.longitude),
              );
              final status = ticket.status.toLowerCase();

              setState(() {
                _isSheetOpen = true;
                _updateMarkers(destination: dest);
                _drawRoute(dest);

                // 'offered' = driver must swipe to accept
                _isAccepted = (status != 'offered');

                // Work started ONLY when the backend confirms in_progress/working
                // Do NOT use beforeWorkAttachments.isNotEmpty here — that caused
                // _isWorkStarted to flip true before StartWork API completed.
                _isWorkStarted = ['in_progress', 'working'].contains(status);
              });
              widget.onSheetToggle(false);
            } else {
              setState(() {
                _isSheetOpen = false;
                _isAccepted = false;
                _isWorkStarted = false;
                _markers.clear();
                _polylines.clear();
              });
              widget.onSheetToggle(true);
            }
          } else if (state is TicketRejecting) {
            // Loading spinner is shown inside the sheet button
          } else if (state is TicketRejected) {
            // Sheet is auto-closed by the BlocListener inside the sheet.
            // Show a right-aligned success toast in the main screen.
            CustomToast.show(context, state.message, alignRight: true);
            setState(() {
              _isSheetOpen = false;
              _isAccepted = false;
              _isWorkStarted = false;
              _markers.clear();
              _polylines.clear();
            });
            widget.onSheetToggle(true);
          } else if (state is TicketRejectError) {
            CustomToast.show(
              context,
              state.message,
              isError: true,
              alignRight: true,
            );
          } else if (state is TicketError) {
            CustomToast.show(context, state.message, isError: true);
          }
        },
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<TicketBloc>().add(FetchTickets());
            context.read<DriverBloc>().add(FetchDriverProfile());
            await Future.delayed(const Duration(seconds: 1));
          },
          child: CustomScrollView(
            physics: _mapTouched
                ? const NeverScrollableScrollPhysics()
                : const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Stack(
                  children: [
                    // 1. Google Map
                    Listener(
                      onPointerDown: (_) {
                        if (!_mapTouched) setState(() => _mapTouched = true);
                      },
                      onPointerUp: (_) {
                        if (_mapTouched) setState(() => _mapTouched = false);
                      },
                      onPointerCancel: (_) {
                        if (_mapTouched) setState(() => _mapTouched = false);
                      },
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.width,
                        child: GoogleMap(
                          scrollGesturesEnabled: true,
                          zoomGesturesEnabled: true,
                          rotateGesturesEnabled: true,
                          tiltGesturesEnabled: true,
                          initialCameraPosition: CameraPosition(
                            target: _currentPosition != null
                                ? LatLng(
                                    _currentPosition!.latitude,
                                    _currentPosition!.longitude,
                                  )
                                : const LatLng(0, 0),
                            zoom: _currentPosition != null ? 14 : 2,
                          ),
                          markers: _markers,
                          polylines: _polylines,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          mapType: MapType.normal,
                          onMapCreated: (controller) {
                            _mapController = controller;
                            // If GPS already responded before the map was ready,
                            // immediately jump to the driver's real location.
                            if (_currentPosition != null) {
                              Future.delayed(
                                const Duration(milliseconds: 300),
                                () {
                                  if (mounted && _mapController != null) {
                                    _mapController!.animateCamera(
                                      CameraUpdate.newCameraPosition(
                                        CameraPosition(
                                          target: LatLng(
                                            _currentPosition!.latitude,
                                            _currentPosition!.longitude,
                                          ),
                                          zoom: 15,
                                        ),
                                      ),
                                    );
                                  }
                                },
                              );
                            }
                          },
                        ),
                      ),
                    ),

                    // 2. Header (Full width, no top padding, rounded bottom)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: BlocBuilder<DriverBloc, DriverState>(
                        builder: (context, state) {
                          String userName = 'Driver';
                          String profileImageUrl = '';

                          if (state is DriverLoaded) {
                            userName = state.driverData['name'] ?? 'Driver';
                            profileImageUrl =
                                state.driverData['profile_image'] ?? '';
                          }

                          return Container(
                            padding: const EdgeInsets.only(
                              top: 50,
                              left: 24,
                              right: 24,
                              bottom: 20,
                            ),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(30),
                                bottomRight: Radius.circular(30),
                              ),
                            ),
                            child: Row(
                              children: [
                                ClipOval(
                                  child: Image.network(
                                    profileImageUrl,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              width: 44,
                                              height: 44,
                                              color: Colors.grey[200],
                                              child: const Icon(
                                                Icons.person,
                                                color: Colors.grey,
                                              ),
                                            ),
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Container(
                                            width: 44,
                                            height: 44,
                                            color: Colors.grey[200],
                                          );
                                        },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Hi $userName',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                              fontFamily: 'Lufga',
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ValueListenableBuilder<ChannelState>(
                                            valueListenable: ReverbService()
                                                .ticketsChannelState,
                                            builder: (context, state, child) {
                                              Color dotColor;
                                              switch (state) {
                                                case ChannelState.subscribed:
                                                  dotColor = Colors.green;
                                                  break;
                                                case ChannelState.subscribing:
                                                  dotColor = Colors.orange;
                                                  break;
                                                default:
                                                  dotColor = Colors.red;
                                              }
                                              return Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color: dotColor,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: dotColor
                                                          .withOpacity(0.5),
                                                      blurRadius: 4,
                                                      spreadRadius: 2,
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                      Text(
                                        _locationAddress,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF999999),
                                          fontFamily: 'Lufga',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.notifications_none,
                                  color: Colors.black,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // 3. Close Button (Animated)
                    AnimatedPositioned(
                      duration: const Duration(seconds: 2),
                      curve: Curves.easeInOut,
                      bottom: _isSheetOpen ? 390 : -80,
                      left: 0,
                      right: 0,

                      child: AnimatedOpacity(
                        duration: const Duration(seconds: 2),
                        curve: Curves.easeInOut,
                        opacity: _isSheetOpen ? 1.0 : 0.0,
                        child: Center(
                          child: BlocBuilder<TicketBloc, TicketState>(
                            builder: (context, state) {
                              return GestureDetector(
                                onTap: () {
                                  if (state is TicketLoaded &&
                                      state.tickets.isNotEmpty) {
                                    final activeTickets = state.tickets
                                        .where((t) => _isActiveTicket(t.status))
                                        .toList();
                                    if (activeTickets.isNotEmpty) {
                                      _showRejectSheet(
                                        activeTickets.first.id.toString(),
                                      );
                                      return;
                                    }
                                  }
                                  setState(() {
                                    _isSheetOpen = false;
                                  });
                                  widget.onSheetToggle(true);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.black,
                                    size: 28,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    AnimatedPositioned(
                      duration: const Duration(seconds: 2),
                      curve: Curves.easeInOut,
                      bottom: _isSheetOpen ? 15 : -800,
                      left: 15,
                      right: 15,
                      child: _buildTaskSheet(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskSheet() {
    return BlocBuilder<TicketBloc, TicketState>(
      builder: (context, state) {
        // Only show task sheet for active tickets
        if (state is TicketLoaded && state.tickets.isNotEmpty) {
          final activeTickets = state.tickets
              .where((t) => _isActiveTicket(t.status))
              .toList();
          if (activeTickets.isEmpty) return const SizedBox.shrink();
          final TicketModel ticket = activeTickets.first;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Profile Section
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 2),
                      ),
                      child: const CircleAvatar(
                        radius: 22,
                        backgroundImage: NetworkImage(
                          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=200&auto=format&fit=crop',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.customer.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Lufga',
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_filled,
                                size: 14,
                                color: Color(0xFF999999),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${DateTime.now().difference(ticket.createdAt).inMinutes} Min ago',
                                style: const TextStyle(
                                  color: Color(0xFF999999),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(ticket.status).withOpacity(0.1),
                        border: Border.all(
                          color: _statusColor(ticket.status).withOpacity(0.5),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Text(
                        ticket.status.toUpperCase(),
                        style: TextStyle(
                          color: _statusColor(ticket.status),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(color: Colors.white, thickness: 1),
                const SizedBox(height: 10),

                // Details Section
                Row(
                  children: [
                    _detailItem(
                      Icons.settings_outlined,
                      'Issue',
                      ticket.issueCategory.name,
                    ),
                    _detailItem(
                      Icons.directions_car_filled_outlined,
                      'Vehicle',
                      '${ticket.brand.name} ${ticket.model.name}',
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    _detailItem(Icons.credit_card, 'Plate', ticket.numberPlate),
                    _detailItem(
                      Icons.confirmation_number_outlined,
                      'Ticket ID',
                      ticket.ticketId,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // See Routes button is now always visible when a ticket is loaded
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: InkWell(
                    onTap: () {
                      final dest = LatLng(
                        double.parse(ticket.latitude),
                        double.parse(ticket.longitude),
                      );
                      _openMapsOption(dest);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'See Routes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Lufga',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Swipe To Accept Action
                LayoutBuilder(
                  builder: (context, constraints) {
                    double maxDrag = constraints.maxWidth - 55 - 4;
                    return GestureDetector(
                      onTap: () {
                        if (_isAccepted) {
                          // Double-check: if before work attachments already exist
                          // on the ticket, always show the After sheet
                          final bool beforeUploaded =
                              ticket.beforeWorkAttachments.isNotEmpty;
                          if (!_isWorkStarted && !beforeUploaded) {
                            _showBeforeWorkSheet(ticket.id.toString());
                          } else {
                            _showAfterWorkSheet(ticket.id.toString());
                          }
                        }
                      },
                      onHorizontalDragUpdate: (details) {
                        if (_isAccepted) return;
                        setState(() {
                          _dragPosition += details.delta.dx;
                          if (_dragPosition < 0) _dragPosition = 0;
                          if (_dragPosition > maxDrag) _dragPosition = maxDrag;
                        });
                      },
                      onHorizontalDragEnd: (details) {
                        if (_isAccepted) return;
                        if (_dragPosition > maxDrag * 0.8) {
                          setState(() {
                            _dragPosition = maxDrag;
                            _isAccepted = true;
                            _isAccepting = true;
                          });
                          context.read<TicketBloc>().add(
                            AcceptTicket(ticket.id.toString()),
                          );
                        } else {
                          setState(() {
                            _dragPosition = 0;
                          });
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 55,
                        width: constraints.maxWidth,
                        decoration: BoxDecoration(
                          color: _isAccepted
                              ? const Color(0xFFA7FF8B)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (state is TicketAccepting || _isAccepting)
                              const PlatformLoading(
                                color: Colors.black,
                                radius: 12,
                              )
                            else
                              Text(
                                _isAccepted
                                    ? (_isWorkStarted
                                          ? 'Work in Progress'
                                          : 'Reached')
                                    : 'Swipe to accept',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            // Slider Button (Animated)
                            if (!_isAccepted && state is! TicketAccepting)
                              AnimatedPositioned(
                                duration: Duration(
                                  milliseconds:
                                      _dragPosition == 0 ||
                                          _dragPosition == maxDrag
                                      ? 400
                                      : 0,
                                ),
                                curve: Curves.elasticOut,
                                left: _dragPosition + 2,
                                top: 2,
                                bottom: 2,
                                child: Container(
                                  width: 51,
                                  decoration: const BoxDecoration(
                                    color: Colors.black,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.keyboard_double_arrow_right_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _showBeforeWorkSheet(String ticketId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Servicing',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lufga',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Before Section
                  _buildUploadSection(
                    title: 'Before',
                    images: _beforeImages,
                    onAdd: () async {
                      final List<XFile> images = await _picker.pickMultiImage();
                      if (images.isNotEmpty) {
                        setSheetState(() => _beforeImages.addAll(images));
                      }
                    },
                  ),

                  const SizedBox(height: 30),

                  // Start Work Button
                  BlocBuilder<TicketBloc, TicketState>(
                    builder: (context, state) {
                      final bool isLoading = state is TicketAttachmentUploading;
                      return GestureDetector(
                        onTap: isLoading
                            ? null
                            : () {
                                context.read<TicketBloc>().add(
                                  UploadAttachments(
                                    ticketId: ticketId,
                                    type: 'before_work',
                                    filePaths: _beforeImages
                                        .map((e) => e.path)
                                        .toList(),
                                  ),
                                );
                                // Pop is now handled in BlocListener
                              },
                        child: Container(
                          width: double.infinity,
                          height: 47,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: isLoading
                                ? const PlatformLoading(
                                    color: Colors.white,
                                    radius: 10,
                                  )
                                : const Text(
                                    'Start Work',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAfterWorkSheet(String ticketId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Servicing',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lufga',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // After Section
                  _buildUploadSection(
                    title: 'After',
                    images: _afterImages,
                    onAdd: () async {
                      final List<XFile> images = await _picker.pickMultiImage();
                      if (images.isNotEmpty) {
                        setSheetState(() => _afterImages.addAll(images));
                      }
                    },
                  ),

                  const SizedBox(height: 30),

                  // Service Done Button
                  BlocBuilder<TicketBloc, TicketState>(
                    builder: (context, state) {
                      final bool isLoading = state is TicketAttachmentUploading;
                      return GestureDetector(
                        onTap: isLoading
                            ? null
                            : () {
                                context.read<TicketBloc>().add(
                                  UploadAttachments(
                                    ticketId: ticketId,
                                    type: 'after_work',
                                    filePaths: _afterImages
                                        .map((e) => e.path)
                                        .toList(),
                                  ),
                                );
                                // Pop and Success Sheet now handled in BlocListener
                              },
                        child: Container(
                          width: double.infinity,
                          height: 47,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: isLoading
                                ? const PlatformLoading(
                                    color: Colors.white,
                                    radius: 10,
                                  )
                                : const Text(
                                    'Service Done',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUploadSection({
    required String title,
    required List<XFile> images,
    required VoidCallback onAdd,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            GestureDetector(
              onTap: onAdd,
              child: const Text(
                '+Add Image',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        images.isEmpty
            ? GestureDetector(
                onTap: onAdd,
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_outlined, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'Upload Image or video',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            : SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length + 1,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    if (index == images.length) {
                      return GestureDetector(
                        onTap: onAdd,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.add_a_photo_outlined,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(
                        File(images[index].path),
                        fit: BoxFit.cover,
                        width: 120,
                        height: 120,
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }

  Widget _detailItem(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Badge colour per ticket status
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'offered':
      case 'assigned':
        return Colors.orange;
      case 'on_the_way':
        return Colors.amber;
      case 'accepted':
      case 'in_progress':
      case 'working':
        return const Color(0xFFA7FF8B);
      default:
        return Colors.white70;
    }
  }

  void _showRejectSheet(String ticketId) {
    final TextEditingController reasonController = TextEditingController(
      text: "Too far from my current location",
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return BlocListener<TicketBloc, TicketState>(
          listener: (listenerContext, state) {
            if (state is TicketRejected) {
              // Auto-close the sheet from its own context
              if (Navigator.of(sheetContext).canPop()) {
                Navigator.of(sheetContext).pop();
              }
            }
          },
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 25),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    'Reject Ticket',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lufga',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Are you sure you want to reject this ticket? Please provide a reason.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                      fontFamily: 'Lufga',
                    ),
                  ),
                  const SizedBox(height: 25),
                  TextField(
                    controller: reasonController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Enter reason here...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Colors.redAccent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(sheetContext),
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Center(
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: BlocBuilder<TicketBloc, TicketState>(
                          builder: (context, state) {
                            final bool isLoading = state is TicketRejecting;
                            return GestureDetector(
                              onTap: isLoading
                                  ? null
                                  : () {
                                      if (reasonController.text
                                          .trim()
                                          .isEmpty) {
                                        CustomToast.show(
                                          sheetContext,
                                          "Please enter a reason",
                                          isError: true,
                                        );
                                        return;
                                      }
                                      context.read<TicketBloc>().add(
                                        RejectTicket(
                                          ticketId: ticketId,
                                          reason: reasonController.text.trim(),
                                        ),
                                      );
                                    },
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Center(
                                  child: isLoading
                                      ? const PlatformLoading(
                                          color: Colors.white,
                                          radius: 10,
                                        )
                                      : const Text(
                                          'Confirm Reject',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
