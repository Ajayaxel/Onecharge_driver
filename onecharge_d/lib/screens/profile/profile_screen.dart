import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onecharge_d/logic/blocs/auth/auth_bloc.dart';
import 'package:onecharge_d/logic/blocs/auth/auth_event.dart';
import 'package:onecharge_d/logic/blocs/auth/auth_state.dart';
import 'package:onecharge_d/logic/blocs/driver/driver_bloc.dart';
import 'package:onecharge_d/logic/blocs/driver/driver_state.dart';
import 'package:onecharge_d/screens/profile/edit_profile_screen.dart';
import 'package:onecharge_d/screens/chat/chat_screen.dart';

import 'package:onecharge_d/widgets/platform_loading.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w400,
            fontFamily: 'Lufga',
          ),
        ),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          return Stack(
            children: [
              BlocBuilder<DriverBloc, DriverState>(
                builder: (context, state) {
                  String userName = 'Driver';
                  String profileImageUrl =
                      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=200&auto=format&fit=crop';

                  if (state is DriverLoaded) {
                    userName = state.driverData['name'] ?? 'Driver';
                    profileImageUrl =
                        state.driverData['profile_image'] ?? profileImageUrl;
                  }

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        // Profile Image
                        Center(
                          child: ClipOval(
                            child: Image.network(
                              profileImageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                  ),
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey[200],
                                    );
                                  },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Name
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Lufga',
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Subtitle
                        const Text(
                          'Individual',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF999999),
                            fontFamily: 'Lufga',
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Menu Items
                        _buildMenuItem(
                          icon: Icons.person,
                          title: 'Profile',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfileScreen(),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.notifications,
                          title: 'Notification',
                          trailing: Transform.scale(
                            scale: 0.8,
                            child: Switch(
                              value: true,
                              onChanged: (val) {},
                              activeColor: const Color(0xFF4CAF50),
                            ),
                          ),
                        ),
                        _buildMenuItem(
                          icon: Icons.info,
                          title: 'Terms & Conditions',
                          onTap: () {},
                        ),
                        _buildMenuItem(
                          icon: Icons.chat_bubble,
                          title: 'Chat Support',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ChatScreen(),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.logout,
                          title: 'Log out',
                          onTap: () {
                            _showLogoutDialog(context);
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.delete,
                          title: 'Delete Account',
                          titleColor: const Color(0xFFFF5252),
                          iconColor: const Color(0xFFFF5252),
                          showTrailing: false,
                          onTap: () {},
                        ),
                        const SizedBox(height: 100), // Spacing for bottom nav
                      ],
                    ),
                  );
                },
              ),
              if (authState is AuthLogoutLoading)
                Container(
                  color: Colors.white.withOpacity(0.5),
                  child: const Center(child: PlatformLoading()),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                const Text(
                  'Log out',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lufga',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Are you sure you want to log out of your account?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF999999),
                    fontFamily: 'Lufga',
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: Color(0xFFEEEEEE)),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Lufga',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<AuthBloc>().add(LogoutRequested());
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Log out',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Lufga',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
    Color? titleColor,
    Color? iconColor,
    bool showTrailing = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: iconColor ?? const Color(0xFF666666),
          size: 26,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: titleColor ?? Colors.black,
            fontFamily: 'Lufga',
          ),
        ),
        trailing:
            trailing ??
            (showTrailing
                ? const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Color(0xFF999999),
                  )
                : null),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      ),
    );
  }
}
