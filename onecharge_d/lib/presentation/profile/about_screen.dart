import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:onecharge_d/presentation/login/login_screen.dart';
import 'package:onecharge_d/presentation/profile/bloc/profile_bloc.dart';
import 'package:onecharge_d/presentation/profile/bloc/profile_event.dart';
import 'package:onecharge_d/presentation/profile/bloc/profile_state.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Delete Account',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.black),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      // Call logout API
      context.read<ProfileBloc>().add(const LogoutDriver());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is LogoutSuccess) {
          // Show success SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate to login screen after successful logout
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        } else if (state is LogoutError) {
          // Show error SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'About',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Info Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        size: 40,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Onecharge Driver',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Privacy Policy Section
              _buildSection(
                title: 'Privacy Policy',
                icon: Icons.privacy_tip_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrivacyPolicyScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // Account Deletion Section
              _buildSection(
                title: 'Delete Account',
                icon: Icons.delete_outline,
                onTap: () => _handleDeleteAccount(context),
                isDestructive: true,
              ),

              const SizedBox(height: 24),

              // Additional Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Support',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'If you have any questions or need assistance, please contact our support team.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? Colors.red.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isDestructive ? Colors.red : Colors.black,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? Colors.red : Colors.black,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.black.withOpacity(0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Future<void> _launchEmail(String email) async {
    try {
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: email,
        query: 'subject=Privacy Policy Inquiry - 1Charge',
      );
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _launchPhone(String phone) async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phone);
      await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Introduction
              _buildSection(
                title: 'Welcome to 1Charge',
                content:
                    'Welcome to 1Charge ("we," "our," or "us"). We are committed to protecting your privacy and ensuring the security of your personal information. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and services.',
              ),
              const SizedBox(height: 16),

              // 1. Information We Collect
              _buildSection(
                title: '1. Information We Collect',
                content: '',
                children: [
                  _buildSubSection(
                    title: '1.1 Personal Information',
                    content:
                        'When you register and use our services, we may collect the following personal information:\n\n'
                        '• Account Information: Name, mobile number, email address, and profile image\n'
                        '• Authentication Data: Login credentials (when using email/password), OTP verification codes, and third-party authentication tokens (Google, Apple Sign-In)\n'
                        '• Vehicle Information: Vehicle type (Car/Scooter/Bike), brand name, model name, license plate number, vehicle color, and year\n'
                        '• Location Data: GPS coordinates (latitude/longitude), address information, and location history when you request services\n'
                        '• Service Requests: Issue categories, descriptions, photos, videos, and service ticket information',
                  ),
                  const SizedBox(height: 12),
                  _buildSubSection(
                    title: '1.2 Automatically Collected Information',
                    content:
                        '• Device information (device type, operating system, unique device identifiers)\n'
                        '• App usage data and analytics\n'
                        '• IP address and network information\n'
                        '• Crash reports and error logs',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. How We Use Your Information
              _buildSection(
                title: '2. How We Use Your Information',
                content:
                    'We use the collected information for the following purposes:\n\n'
                    '• To provide, maintain, and improve our services\n'
                    '• To process and fulfill your service requests\n'
                    '• To connect you with service partners, mechanics, or towing services\n'
                    '• To send you service updates, notifications, and important information\n'
                    '• To verify your identity and prevent fraud\n'
                    '• To personalize your experience\n'
                    '• To analyze usage patterns and improve app functionality\n'
                    '• To comply with legal obligations\n'
                    '• To respond to your inquiries and provide customer support',
              ),
              const SizedBox(height: 16),

              // 3. Location Information
              _buildSection(
                title: '3. Location Information',
                content:
                    'We collect and use location information to:\n\n'
                    '• Auto-detect your location for service dispatch\n'
                    '• Allow you to manually select your location on a map\n'
                    '• Share your location with service providers to enable them to reach you\n'
                    '• Improve location-based services\n\n'
                    'You can control location permissions through your device settings. However, disabling location services may limit our ability to provide certain features.',
              ),
              const SizedBox(height: 16),

              // 4. Third-Party Services
              _buildSection(
                title: '4. Third-Party Services',
                content:
                    'We use third-party services that may collect information:\n\n'
                    '• Google Maps API: For location services and mapping functionality\n'
                    '• Authentication Providers: Google Sign-In and Apple Sign-In for authentication\n'
                    '• Cloud Storage: For storing photos and videos you upload\n'
                    '• Analytics Services: To understand app usage and improve our services\n\n'
                    'These third-party services have their own privacy policies. We encourage you to review them.',
              ),
              const SizedBox(height: 16),

              // 5. Information Sharing and Disclosure
              _buildSection(
                title: '5. Information Sharing and Disclosure',
                content:
                    'We may share your information in the following circumstances:\n\n'
                    '• Service Providers: We share necessary information (location, vehicle details, issue description) with service partners, mechanics, and towing services to fulfill your requests\n'
                    '• Legal Requirements: When required by law, court order, or government regulation\n'
                    '• Business Transfers: In connection with a merger, acquisition, or sale of assets\n'
                    '• With Your Consent: When you explicitly authorize us to share information\n\n'
                    'We do not sell your personal information to third parties.',
              ),
              const SizedBox(height: 16),

              // 6. Data Security
              _buildSection(
                title: '6. Data Security',
                content:
                    'We implement appropriate technical and organizational measures to protect your personal information, including:\n\n'
                    '• Encryption of data in transit and at rest\n'
                    '• Secure authentication mechanisms\n'
                    '• Regular security assessments\n'
                    '• Access controls and employee training\n\n'
                    'However, no method of transmission over the internet or electronic storage is 100% secure. While we strive to protect your data, we cannot guarantee absolute security.',
              ),
              const SizedBox(height: 16),

              // 7. Data Retention
              _buildSection(
                title: '7. Data Retention',
                content:
                    'We retain your personal information for as long as necessary to:\n\n'
                    '• Provide our services to you\n'
                    '• Comply with legal obligations\n'
                    '• Resolve disputes and enforce agreements\n\n'
                    'You may request deletion of your account and associated data at any time, subject to legal retention requirements.',
              ),
              const SizedBox(height: 16),

              // 8. Your Rights and Choices
              _buildSection(
                title: '8. Your Rights and Choices',
                content:
                    'Depending on your location, you may have the following rights:\n\n'
                    '• Access: Request access to your personal information\n'
                    '• Correction: Request correction of inaccurate information\n'
                    '• Deletion: Request deletion of your personal information\n'
                    '• Portability: Request a copy of your data in a portable format\n'
                    '• Opt-out: Opt-out of certain data processing activities\n'
                    '• Withdraw Consent: Withdraw consent for data processing where applicable\n\n'
                    'To exercise these rights, please contact us using the information provided below.',
              ),
              const SizedBox(height: 16),

              // 9. Children's Privacy
              _buildSection(
                title: '9. Children\'s Privacy',
                content:
                    'Our services are not intended for individuals under the age of 18. We do not knowingly collect personal information from children. If you believe we have collected information from a child, please contact us immediately.',
              ),
              const SizedBox(height: 16),

              // 10. International Data Transfers
              _buildSection(
                title: '10. International Data Transfers',
                content:
                    'Your information may be transferred to and processed in countries other than your country of residence. These countries may have different data protection laws. We take appropriate measures to ensure your data is protected in accordance with this Privacy Policy.',
              ),
              const SizedBox(height: 16),

              // 11. Changes to This Privacy Policy
              _buildSection(
                title: '11. Changes to This Privacy Policy',
                content:
                    'We may update this Privacy Policy from time to time. We will notify you of any material changes by:\n\n'
                    '• Posting the new Privacy Policy in the app\n'
                    '• Updating the "Last Updated" date\n'
                    '• Sending you a notification (for significant changes)\n\n'
                    'Your continued use of our services after changes become effective constitutes acceptance of the updated Privacy Policy.',
              ),
              const SizedBox(height: 16),

              // 12. California Privacy Rights (CCPA)
              _buildSection(
                title: '12. California Privacy Rights (CCPA)',
                content:
                    'If you are a California resident, you have additional rights under the California Consumer Privacy Act (CCPA), including:\n\n'
                    '• The right to know what personal information is collected, used, shared, or sold\n'
                    '• The right to delete personal information\n'
                    '• The right to opt-out of the sale of personal information (we do not sell your information)\n'
                    '• The right to non-discrimination for exercising your privacy rights',
              ),
              const SizedBox(height: 16),

              // 13. GDPR Rights (EU Users)
              _buildSection(
                title: '13. GDPR Rights (EU Users)',
                content:
                    'If you are located in the European Economic Area (EEA), you have rights under the General Data Protection Regulation (GDPR), including:\n\n'
                    '• Right of access, rectification, and erasure\n'
                    '• Right to restrict processing\n'
                    '• Right to data portability\n'
                    '• Right to object to processing\n'
                    '• Right to lodge a complaint with a supervisory authority',
              ),
              const SizedBox(height: 16),

              // 14. Contact Us
              _buildContactSection(),

              const SizedBox(height: 24),

              // Last Updated
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.black.withOpacity(0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Last Updated: 06-12-2025',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withOpacity(0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Agreement Text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'By using 1Charge, you acknowledge that you have read and understood this Privacy Policy and agree to the collection and use of your information as described herein.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.7),
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    List<Widget>? children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              content,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black.withOpacity(0.7),
                height: 1.5,
              ),
            ),
          ],
          if (children != null) ...[
            const SizedBox(height: 12),
            ...children,
          ],
        ],
      ),
    );
  }

  Widget _buildSubSection({
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: TextStyle(
            fontSize: 12,
            color: Colors.black.withOpacity(0.7),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '14. Contact Us',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'If you have any questions, concerns, or requests regarding this Privacy Policy or our data practices, please contact us:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildContactItem(
            icon: Icons.email_outlined,
            label: 'Email',
            value: 'Askme@onecharge.io',
            onTap: () => _launchEmail('Askme@onecharge.io'),
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: '+971 52 7462872',
            onTap: () => _launchPhone('+971527462872'),
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            icon: Icons.location_on_outlined,
            label: 'Address',
            value: 'Dubai, United Arab Emirates',
            onTap: null,
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    final widget = Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        if (onTap != null)
          Icon(
            Icons.chevron_right,
            size: 20,
            color: Colors.black.withOpacity(0.4),
          ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: widget,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: widget,
    );
  }
}


