import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
              'Terms of Service',
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
              'Welcome to ScoreCaddie. Please read these terms carefully before using our platform, as they govern your relationship with us regarding the app, the marketplace, and your data.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.grey700,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            _Section(
              title: '1. Autonomous Matching & Profiles',
              content: 'ScoreCaddie utilizes autonomous matching algorithms to connect players with golf coaches and caddies based on location, skill level, and availability. By creating a profile, you agree that your basic golf profile data (handicap, home club, preferences) may be processed to facilitate these matches.',
            ),
            _Section(
              title: '2. Professional Services (Caddies & Coaches)',
              content: 'ScoreCaddie acts strictly as a marketplace connecting players with independent golf professionals. We do not employ the caddies or coaches listed on our platform. The quality, safety, and legality of the services provided are solely the responsibility of the independent professional. We disclaim any liability arising from interactions or services booked through the platform.',
            ),
            _Section(
              title: '3. Bookings, Payments & Cancellations',
              content: 'All payments for bookings are securely processed through our third-party payment providers. By booking a session, you agree to the specific cancellation policy set by the respective professional or club. ScoreCaddie reserves the right to charge cancellation fees or suspend accounts for repeated no-shows.',
            ),
            _Section(
              title: '4. Offline Syncing & Data Integrity',
              content: 'ScoreCaddie provides an offline mode that allows you to record scores and rounds without an internet connection. While we strive to ensure seamless synchronization to our cloud servers once connectivity is restored, ScoreCaddie is not responsible for any data loss that may occur due to device failure, local storage corruption, or app deletion before a successful sync.',
            ),
            _Section(
              title: '5. User Conduct & Fair Play',
              content: 'You agree to use ScoreCaddie respectfully and honestly. Falsifying handicaps, submitting fraudulent scores, or harassing professionals or other players will result in immediate account termination and a permanent ban from the platform.',
            ),
            _Section(
              title: '6. Limitation of Liability',
              content: 'To the maximum extent permitted by law, ScoreCaddie shall not be liable for any indirect, incidental, special, consequential or punitive damages, or any loss of profits or revenues, whether incurred directly or indirectly, or any loss of data, use, good-will, or other intangible losses resulting from your use of the platform.',
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
