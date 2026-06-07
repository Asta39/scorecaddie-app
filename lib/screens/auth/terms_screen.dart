import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Terms of Service', style: TextStyle(color: AppColors.grey900, fontWeight: FontWeight.w900)),
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
              'Welcome to ScoreCaddie',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.grey900),
            ),
            SizedBox(height: 16),
            Text(
              'Last Updated: April 2026',
              style: TextStyle(color: AppColors.grey500, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 32),
            _Section(
              title: '1. Acceptance of Terms',
              content: 'By accessing and using ScoreCaddie, you agree to be bound by these Terms of Service and all applicable laws and regulations.',
            ),
            _Section(
              title: '2. User Accounts',
              content: 'You are responsible for maintaining the confidentiality of your account and password. You agree to accept responsibility for all activities that occur under your account.',
            ),
            _Section(
              title: '3. Use License',
              content: 'Permission is granted to temporarily download one copy of the materials (information or software) on ScoreCaddie for personal, non-commercial transitory viewing only.',
            ),
            _Section(
              title: '4. Professional Services',
              content: 'ScoreCaddie provides a marketplace for golf coaches and caddies. We do not employ these professionals and are not responsible for the quality of services provided by them.',
            ),
            _Section(
              title: '5. Disclaimer',
              content: 'The materials on ScoreCaddie are provided on an \'as is\' basis. ScoreCaddie makes no warranties, expressed or implied, and hereby disclaims and negates all other warranties including, without limitation, implied warranties or conditions of merchantability.',
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
