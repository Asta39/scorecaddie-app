import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/ai_analyzer_service.dart';

class SwingCoachBot extends StatefulWidget {
  final AIShotAnalysis analysis;
  const SwingCoachBot({super.key, required this.analysis});

  @override
  State<SwingCoachBot> createState() => _SwingCoachBotState();
}

class _SwingCoachBotState extends State<SwingCoachBot> {
  final List<Map<String, String>> _messages = [];
  final _controller = TextEditingController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _startConversation();
  }

  void _startConversation() {
    setState(() {
      _messages.add({
        'role': 'bot',
        'text': 'Great swing! Your launch angle was ${widget.analysis.launchAngle.toStringAsFixed(1)} degrees. Based on my analysis, you have a solid tempo. Any questions about this shot or your technique?',
      });
    });
  }

  void _handleSend(String text) {
    if (text.isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isTyping = true;
    });
    _controller.clear();

    // Simulated "Professional Golf Knowledge" response
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add({
            'role': 'bot',
            'text': _generateGolfAdvice(text),
          });
        });
      }
    });
  }

  String _generateGolfAdvice(String query) {
    query = query.toLowerCase();
    final metrics = widget.analysis.poseMetrics;

    if (query.contains('head')) {
      if (metrics != null && metrics['headStability'] != null) {
        final stability = metrics['headStability'] as double;
        if (stability > 0.85) {
          return "Your head stability was excellent on that shot (${(stability * 100).round()}% stability). You stayed remarkably level through impact, which is a hallmark of a professional-grade swing.";
        } else {
          return "I detected some movement in your head position. Your stability was around ${(stability * 100).round()}%. Focus on keeping your lead ear 'pinned' to an imaginary point until after the ball is gone.";
        }
      }
      return 'Maintaining a steady head is key to consistent ball striking. Try to feel your spine rotating around a fixed axis.';
    }

    if (query.contains('shoulder') || query.contains('turn') || query.contains('backswing')) {
      if (metrics != null && metrics['shoulderTurn'] != null) {
        final turn = metrics['shoulderTurn'] as double;
        if (turn < 85) {
          return "Your shoulder turn was ${turn.round()}°. A bit more rotation (aiming for 90°+) will help you create more speed and a better path. Try to feel your lead shoulder move under your chin.";
        } else {
          return "Outstanding rotation! You achieved a ${turn.round()}° shoulder turn. This creates massive potential for power. Just ensure your transition starts from the ground up.";
        }
      }
    }

    if (query.contains('position') || query.contains('posture') || query.contains('spine')) {
      if (metrics != null && metrics['spineAngle'] != null) {
        final angle = metrics['spineAngle'] as double;
        return "Your spine angle was maintained at ${angle.round()}° throughout the swing. Consistency here is why your launch angle was so stable at ${widget.analysis.launchAngle.toStringAsFixed(1)}°.";
      }
    }

    if (query.contains('distance') || query.contains('power')) {
      return 'To increase distance, focus on your smash factor. Your current ball speed of ${widget.analysis.ballSpeed.round()} mph is solid, but hitting the sweet spot consistently will yield more yards.';
    }

    if (query.contains('slice') || query.contains('right')) {
      return 'A slice is often caused by an outside-in swing path. Ensure your lead shoulder stays closed during the transition and feel the club head swinging more towards "one o\'clock".';
    }

    return 'That is a great technical question. Based on your ${widget.analysis.swingQuality} quality rating, your fundamentals are strong. Focus on maintaining that rhythm for your next shot!';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildChatList(),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey900,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.golfLime,
            radius: 12,
            child: Icon(LucideIcons.bot, size: 14, color: AppColors.grey900),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AI SWING COACH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
              Text('Online • Professional Advice', style: TextStyle(color: Colors.white70, fontSize: 8)),
            ],
          ),
          const Spacer(),
          Icon(LucideIcons.moreHorizontal, color: Colors.white, size: 16),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final m = _messages[index];
          final isBot = m['role'] == 'bot';
          return Align(
            alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isBot ? Colors.white : AppColors.emerald700,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomLeft: isBot ? const Radius.circular(0) : null,
                  bottomRight: !isBot ? const Radius.circular(0) : null,
                ),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)],
              ),
              child: Text(m['text']!, 
                style: TextStyle(
                  color: isBot ? AppColors.grey800 : Colors.white, 
                  fontSize: 13, height: 1.4)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Ask about your swing...',
                hintStyle: TextStyle(color: AppColors.grey400),
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              onSubmitted: _handleSend,
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.send, color: AppColors.emerald700, size: 20),
            onPressed: () => _handleSend(_controller.text),
          ),
        ],
      ),
    );
  }
}
