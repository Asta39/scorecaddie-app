import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.grey900),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppColors.grey900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Effective Date: July 2026',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.grey500,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Your privacy is critically important to us at ScoreCaddie. This policy outlines how we collect, use, and protect your personal data when you use our mobile application and marketplace.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.grey700,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            _Section(
              title: '1. Information We Collect',
              content: 'We collect information you provide directly to us (such as name, email, and golf handicap) and data generated from your use of the app (such as location data, match history, and performance metrics). We also collect payment information, which is processed securely by our third-party payment gateways.',
            ),
            _Section(
              title: '2. How We Use Your Data',
              content: 'Your data is primarily used to provide and improve the ScoreCaddie service. This includes autonomous matching algorithms that use your location and handicap to connect you with nearby caddies and coaches. We also use your data for customer support, safety monitoring, and processing transactions.',
            ),
            _Section(
              title: '3. Data Synchronization & Offline Storage',
              content: 'ScoreCaddie utilizes local databases (Drift) to store your profile and round data locally on your device for offline access. This local data is automatically synchronized with our secure cloud servers (Supabase) in the background whenever your device connects to the internet. By using the app, you consent to this continuous background synchronization process.',
            ),
            _Section(
              title: '4. Information Sharing',
              content: 'We do not sell your personal data. We only share your data with third parties in the following circumstances: (a) with golf professionals when you book their services; (b) with service providers (like payment processors and cloud hosting); and (c) when required by law or to protect our legal rights.',
            ),
            _Section(
              title: '5. Data Security',
              content: 'We implement robust security measures to protect your personal data, including secure authentication systems and encrypted database connections. However, no electronic transmission or storage is 100% secure, and we cannot guarantee absolute security.',
            ),
            _Section(
              title: '6. Your Rights',
              content: 'You have the right to access, update, or delete your personal data at any time through your account settings. You may also request a full export of your data or permanently delete your account by contacting our privacy team.',
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String content;

  const _Section({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.grey900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.grey600,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
