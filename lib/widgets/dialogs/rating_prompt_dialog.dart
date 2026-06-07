import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';

class RatingPromptDialog extends ConsumerStatefulWidget {
  final String providerId;
  final String providerName;
  final String bookingId;

  const RatingPromptDialog({
    super.key,
    required this.providerId,
    required this.providerName,
    required this.bookingId,
  });

  @override
  ConsumerState<RatingPromptDialog> createState() => _RatingPromptDialogState();
}

class _RatingPromptDialogState extends ConsumerState<RatingPromptDialog> {
  int _rating = 5;
  bool _submitting = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text('How was your round with ${widget.providerName}?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starValue = index + 1;
              return GestureDetector(
                onTap: () => setState(() => _rating = starValue),
                child: Icon(
                  starValue <= _rating ? CupertinoIcons.star_fill : CupertinoIcons.star,
                  color: starValue <= _rating ? Colors.orangeAccent : AppColors.grey300,
                  size: 32,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          CupertinoTextField(
            controller: _commentController,
            placeholder: 'Leave a note...',
            maxLines: 3,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.grey200),
            ),
          ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Later', style: TextStyle(color: AppColors.grey600)),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: _submitting
              ? null
              : () async {
                  final profile = ref.read(userProfileProvider).valueOrNull;
                  if (profile == null) return;
                  setState(() => _submitting = true);
                  try {
                    final supabase = ref.read(supabaseClientProvider);
                    await supabase.from('provider_reviews').insert({
                      'provider_id': widget.providerId,
                      'player_id': profile.uid,
                      'player_name': profile.name,
                      'booking_id': widget.bookingId,
                      'rating': _rating.toDouble(),
                      'comment': _commentController.text.trim(),
                    });
                  } catch (_) {
                    // Silently fail — review is non-critical
                  }
                  if (context.mounted) Navigator.pop(context);
                },
          child: const Text(
            'Submit',
            style: TextStyle(color: AppColors.emerald700, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
