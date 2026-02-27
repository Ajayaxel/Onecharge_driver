import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onecharge_d/logic/blocs/driver/driver_bloc.dart';
import 'package:onecharge_d/logic/blocs/driver/driver_state.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:onecharge_d/core/network/reverb_service.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';

class HomeHeader extends StatefulWidget {
  final String? location;
  final VoidCallback? onNotificationTap;

  const HomeHeader({super.key, this.location, this.onNotificationTap});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  String _currentLocation = 'Fetching location...';

  @override
  void initState() {
    super.initState();
    if (widget.location != null) {
      _currentLocation = widget.location!;
    } else {
      _fetchCurrentLocation();
    }
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted)
          setState(() => _currentLocation = 'Location services disabled');
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _currentLocation = 'Permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted)
          setState(() => _currentLocation = 'Permission permanently denied');
        return;
      }

      // Try to get last known position first for faster responsiveness
      Position? position = await Geolocator.getLastKnownPosition();

      // If no last known position, fetch current position with a timeout
      if (position == null) {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 5),
        );
      }

      // Add timeout to geocoding as well - sometimes it hangs
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 3));

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        if (mounted) {
          setState(() {
            _currentLocation =
                '${place.name ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}'
                    .replaceAll(RegExp(r'^, |, , '), '')
                    .trim();
            if (_currentLocation.isEmpty ||
                _currentLocation == ', , ' ||
                _currentLocation == ',') {
              _currentLocation = 'Unknown Location';
            }
          });
        }
      } else {
        if (mounted) setState(() => _currentLocation = 'Unknown Location');
      }
    } catch (e) {
      print('Error fetching location: $e');
      if (mounted) {
        setState(() => _currentLocation = 'Vandipetta, Vellayil, Kozhikode');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DriverBloc, DriverState>(
      builder: (context, state) {
        String userName = 'Driver';
        String profileImageUrl =
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=200&auto=format&fit=crop';

        if (state is DriverLoaded) {
          userName = state.driverData['name'] ?? 'Driver';
          profileImageUrl =
              state.driverData['profile_image'] ?? profileImageUrl;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              ClipOval(
                child: Image.network(
                  profileImageUrl,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 44,
                      height: 44,
                      color: Colors.grey[200],
                      child: const Icon(Icons.person, color: Colors.grey),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
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
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                          valueListenable: ReverbService().ticketsChannelState,
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
                                    color: dotColor.withOpacity(0.5),
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
                    Row(
                      children: [
                        const Icon(
                          Icons.circle,
                          color: Color(0xFF4CAF50),
                          size: 10,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _currentLocation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF999999),
                              fontFamily: 'Lufga',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: widget.onNotificationTap,
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5F5F5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.black,
                        size: 28,
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        height: 8,
                        width: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class HomeSearchBar extends StatelessWidget {
  final String hintText;
  final Function(String)? onChanged;

  const HomeSearchBar({
    super.key,
    this.hintText = 'Search for any Vehicles',
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.search, color: Color(0xFFCCCCCC), size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                onChanged: onChanged,
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: const TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 16,
                    fontFamily: 'Lufga',
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
