import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class HelpScreen extends StatelessWidget {
  final String? role;
  const HelpScreen({super.key, this.role});

  @override
  Widget build(BuildContext context) {
    final String currentRole = role ?? 'player';
    final faqs = _getFAQsForRole(currentRole);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.pop(),
          child: const Icon(CupertinoIcons.back, color: AppColors.grey900),
        ),
        title: const Text(
          'Help & FAQs',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.grey900, fontSize: 17),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          _buildHeader(currentRole),
          const SizedBox(height: 32),
          const Text(
            'FREQUENTLY ASKED QUESTIONS',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.grey400, letterSpacing: 1.2),
          ),
          const SizedBox(height: 16),
          ...faqs.map((faq) => _buildFAQTile(faq)),
          const SizedBox(height: 40),
          _buildSupportCard(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHeader(String role) {
    String title = 'How can we help?';
    String subtitle = 'Everything you need to know about ScoreCaddie.';
    IconData icon = LucideIcons.helpCircle;

    if (role == 'coach') {
      title = 'Coach Support';
      subtitle = 'Manage your students and grow your coaching business.';
      icon = LucideIcons.graduationCap;
    } else if (role == 'caddie') {
      title = 'Caddie Guide';
      subtitle = 'Tips for providing the best experience for your players.';
      icon = LucideIcons.briefcase;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.emerald700, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 20),
        Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.grey900, letterSpacing: -0.5)),
        const SizedBox(height: 8),
        Text(subtitle, style: const TextStyle(fontSize: 16, color: AppColors.grey500, fontWeight: FontWeight.w500, height: 1.4)),
      ],
    );
  }

  Widget _buildFAQTile(_FAQItem faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(faq.question, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.grey900)),
          iconColor: AppColors.emerald700,
          collapsedIconColor: AppColors.grey300,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          expandedAlignment: Alignment.centerLeft,
          children: [
            Text(
              faq.answer,
              style: const TextStyle(fontSize: 14, color: AppColors.grey600, height: 1.5, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.grey900,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text('Still have questions?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text(
            'Our team is available 24/7 to help you with any issues.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: AppColors.emerald700,
              onPressed: () {}, // Handled in settings launchWhatsApp
              child: const Text('Chat with Us', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  List<_FAQItem> _getFAQsForRole(String role) {
    if (role == 'coach') {
      return [
        _FAQItem(
          question: 'How do students find me?',
          answer: 'Ensure your profile is set to "Public" and your availability is toggled on in the dashboard. Complete your bio and specializations to appear higher in searches.',
        ),
        _FAQItem(
          question: 'How are payments handled?',
          answer: 'Currently, ScoreCaddie facilitates the connection. Payments are handled directly between you and the student as per your set hourly rate.',
        ),
        _FAQItem(
          question: 'Can I share drills with students?',
          answer: 'Yes! Use the "New Drill" action on your dashboard to create custom training routines that your students can access.',
        ),
      ];
    } else if (role == 'caddie') {
      return [
        _FAQItem(
          question: 'How do I start a round for a player?',
          answer: 'Once a player connects with you, you can tap "Start Round" on your dashboard, select the course, and begin live tracking for them.',
        ),
        _FAQItem(
          question: 'What is Caddie Status?',
          answer: 'Availability toggles whether you appear in the marketplace. "Available" means you are ready for on-course bookings.',
        ),
        _FAQItem(
          question: 'How do I get more reviews?',
          answer: 'Providing accurate distance tracking and green reading will encourage players to leave 5-star ratings on your profile.',
        ),
      ];
    } else {
      return [
        _FAQItem(
          question: 'How is my handicap calculated?',
          answer: 'ScoreCaddie uses the World Handicap System (WHS) formula. We take your best 8 scores from your last 20 rounds to calculate your index.',
        ),
        _FAQItem(
          question: 'How do I add friends?',
          answer: 'Go to your Profile, tap the QR code icon to show your UID, or go to the Friends section to search for a friend\'s unique ID.',
        ),
        _FAQItem(
          question: 'What is AI Swing Analysis?',
          answer: 'Our AI uses pose detection to track your swing path, shoulder turn, and tempo. Ensure your full body is visible in the frame for the best results.',
        ),
      ];
    }
  }
}

class _FAQItem {
  final String question;
  final String answer;
  _FAQItem({required this.question, required this.answer});
}
