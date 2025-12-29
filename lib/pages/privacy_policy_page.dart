import 'package:flutter/material.dart';
import 'package:hikenity_app/theme/app_colors.dart'; // Assuming consistent theming

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.privacy_tip,
                      color: AppColors.primary,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Privacy Policy',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Effective Date: January 1, 2025',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              // Introduction Section
              _buildSectionTitle('Introduction', context),
              _buildSectionContent(
                'This privacy policy explains how we collect, use, and protect your personal information when you use the Hikenity app. By using this app, you agree to the terms outlined in this policy.',
              ),

              // Data Collection Section
              _buildSectionTitle('Data Collection', context),
              _buildSectionContent(
                'We collect the following information to enhance your experience and ensure the proper functioning of the app:\n\n'
                '• Full Name\n'
                '• Email Address\n'
                '• Phone Number\n'
                '• Emergency Contact Number\n'
                '• Location Data (for trip tracking)\n'
                '• Profile Picture',
              ),

              // Data Usage Section
              _buildSectionTitle('Data Usage', context),
              _buildSectionContent(
                'The data collected is used for the following purposes:\n\n'
                '• Managing and tracking trips\n'
                '• Ensuring participant safety during trips\n'
                '• Providing notifications and updates\n'
                '• Enhancing user experience',
              ),

              // Data Sharing Section
              _buildSectionTitle('Data Sharing', context),
              _buildSectionContent(
                'Your data will not be shared with third parties, except as required by law or for essential app functionality (e.g., Firebase services for authentication and database storage).',
              ),

              // Data Security Section
              _buildSectionTitle('Data Security', context),
              _buildSectionContent(
                'We use secure technologies and encryption to protect your data. However, no method of electronic transmission or storage is 100% secure. We cannot guarantee absolute security.',
              ),

              // User Rights Section
              _buildSectionTitle('User Rights', context),
              _buildSectionContent(
                'You have the right to access, update, or delete your personal information at any time. Please contact support if you have any concerns regarding your data.',
              ),

              // Changes to Policy Section
              _buildSectionTitle('Changes to This Policy', context),
              _buildSectionContent(
                'We may update this privacy policy periodically to reflect changes in our practices or legal requirements. Please review this policy regularly for updates.',
              ),

              // Contact Us Section
              _buildSectionTitle('Contact Us', context),
              _buildSectionContent(
                'If you have any questions or concerns about this privacy policy, please contact us at support@hikenity.com.',
              ),

              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Thank you for trusting Hikenity.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppColors.textLight,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widget: Section Title
  Widget _buildSectionTitle(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Helper Widget: Section Content
  Widget _buildSectionContent(String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        content,
        style: const TextStyle(
          fontSize: 16,
          height: 1.5,
          color: AppColors.text,
        ),
      ),
    );
  }
}
