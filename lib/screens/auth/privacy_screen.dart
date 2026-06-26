import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Privacy Policy', style: TextStyle(color: AppColors.grey900, fontWeight: FontWeight.w900)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.grey900),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Your Privacy Matters',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.grey900),
            ),
            SizedBox(height: 16),
            Text(
              'Last Updated: April 2026',
              style: TextStyle(color: AppColors.grey500, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 32),
            _Section(
              title: '1. Information We Collect',
              content: 'We collect information you provide directly to us when you create an account, such as your name, email, and golf stats.',
            ),
            _Section(
              title: '2. How We Use Information',
              content: 'We use the information we collect to provide, maintain, and improve our services, including personalization of your golf analytics.',
            ),
            _Section(
              title: '3. Data Storage',
              content: 'ScoreCaddie uses a local-first architecture where your data is stored on your device and synced to our secure cloud servers.',
            ),
            _Section(
              title: '4. Information Sharing',
              content: 'We do not share your personal information with third parties except as described in this policy or with your consent.',
            ),
            _Section(
              title: '5. Security',
              content: 'We take reasonable measures to help protect information about you from loss, theft, misuse, and unauthorized access.',
            ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.grey900),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(fontSize: 15, color: AppColors.grey600, height: 1.6),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
