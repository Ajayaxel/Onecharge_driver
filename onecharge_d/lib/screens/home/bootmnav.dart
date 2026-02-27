import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onecharge_d/logic/blocs/vehicle/vehicle_bloc.dart';
import 'package:onecharge_d/logic/blocs/vehicle/vehicle_event.dart';
import 'package:onecharge_d/screens/home/tabs/home_screen.dart';
import 'package:onecharge_d/screens/vehicles/vehicles_screen.dart';
import 'package:onecharge_d/screens/history/history_screen.dart';
import 'package:onecharge_d/screens/profile/profile_screen.dart';

class Bootmnav extends StatefulWidget {
  const Bootmnav({super.key});

  @override
  State<Bootmnav> createState() => _BootmnavState();
}

class _BootmnavState extends State<Bootmnav> {
  int _currentIndex = 0;
  bool _isBottomNavVisible = true;

  void setBottomNavVisible(bool visible) {
    setState(() {
      _isBottomNavVisible = visible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: [
              HomeTab(onSheetToggle: setBottomNavVisible),
              const VehiclesScreen(),
              const HistoryScreen(),
              const ProfileScreen(),
            ],
          ),
          AnimatedPositioned(
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
            bottom: _isBottomNavVisible ? 0 : -250,
            left: 0,
            right: 0,
            child: CustomBottomNavBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                if (index == 1) {
                  // Only fetch if not already loaded — prevents duplicate calls
                  // on every tab switch. Pull-to-refresh handles explicit reload.
                  final vehicleState = context.read<VehicleBloc>().state;
                  final gridNotLoaded = !vehicleState.grid.isLoaded;
                  final bannerNotLoaded = !vehicleState.banner.isLoaded;
                  if (gridNotLoaded) {
                    context.read<VehicleBloc>().add(const FetchVehicles());
                  }
                  if (bannerNotLoaded) {
                    context.read<VehicleBloc>().add(
                      const FetchCurrentVehicle(),
                    );
                  }
                }
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xffF5F5F5)),
      child: SafeArea(
        top: false,
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              _buildNavItem(0, 'Home', Icons.home_outlined),
              _buildNavItem(1, 'Vehicles', CupertinoIcons.car),
              _buildNavItem(2, 'History', Icons.history),
              _buildNavItem(3, 'Profile', Icons.person_outline),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon) {
    final bool isSelected = currentIndex == index;
    final Color color = isSelected ? Colors.black : const Color(0xFF999999);

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Top Indicator
            Positioned(
              top: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isSelected ? 1.0 : 0.0,
                child: Container(
                  height: 4,
                  width: 45,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
            // Icon and Text
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10), // Space for indicator
                Icon(icon, color: color, size: 26),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
