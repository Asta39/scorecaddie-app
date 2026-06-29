import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/theme/app_theme.dart';
import 'loading_spinner.dart';

enum STKPushStatus {
  sending,
  waitingForPIN,
  verifying,
  success,
  failure,
}

class STKPushConfirmationDialog extends StatefulWidget {
  final String mpesaPhone;
  final num amount;
  final String currency;
  final Future<bool> Function() onConfirm;

  const STKPushConfirmationDialog({
    super.key,
    required this.mpesaPhone,
    required this.amount,
    this.currency = 'KES',
    required this.onConfirm,
  });

  @override
  State<STKPushConfirmationDialog> createState() => _STKPushConfirmationDialogState();
}

class _STKPushConfirmationDialogState extends State<STKPushConfirmationDialog> {
  STKPushStatus _status = STKPushStatus.sending;
  int _secondsRemaining = 30;
  Timer? _countdownTimer;
  bool? _actionResult;

  @override
  void initState() {
    super.initState();
    _startFlow();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startFlow() async {
    // Stage 1: Sending STK Push (simulated 2 seconds delay)
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    setState(() {
      _status = STKPushStatus.waitingForPIN;
    });

    // Start background action verification
    _runConfirmAction();

    // Start countdown
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _countdownTimer?.cancel();
        _handleTimeout();
      }
    });
  }

  void _runConfirmAction() async {
    try {
      final success = await widget.onConfirm();
      _actionResult = success;
      
      // If we got a response, simulate a short verification stage
      await Future.delayed(const Duration(seconds: 4)); // Let user see the PIN prompt for a few seconds
      if (!mounted) return;

      _countdownTimer?.cancel();
      setState(() {
        _status = STKPushStatus.verifying;
      });

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      setState(() {
        if (_actionResult == true) {
          _status = STKPushStatus.success;
        } else {
          _status = STKPushStatus.failure;
        }
      });
    } catch (_) {
      _countdownTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _status = STKPushStatus.failure;
      });
    }
  }

  void _handleTimeout() {
    setState(() {
      _status = STKPushStatus.failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.white,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusIcon(),
            const SizedBox(height: 24),
            _buildStatusText(),
            const SizedBox(height: 16),
            _buildDetails(),
            const SizedBox(height: 32),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (_status) {
      case STKPushStatus.sending:
      case STKPushStatus.verifying:
        return const SizedBox(
          width: 72,
          height: 72,
          child: LoadingSpinner(size: 48),
        );
      case STKPushStatus.waitingForPIN:
        return Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.golfLime.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            LucideIcons.smartphone,
            color: AppColors.grey900,
            size: 36,
          ),
        );
      case STKPushStatus.success:
        return Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: AppColors.golfLime,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            LucideIcons.check,
            color: AppColors.grey900,
            size: 36,
          ),
        );
      case STKPushStatus.failure:
        return Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            LucideIcons.x,
            color: Colors.red,
            size: 36,
          ),
        );
    }
  }

  Widget _buildStatusText() {
    String title = '';
    String subtitle = '';

    switch (_status) {
      case STKPushStatus.sending:
        title = 'Sending STK Push';
        subtitle = 'Initiating payment request to Safaricom M-Pesa...';
        break;
      case STKPushStatus.waitingForPIN:
        title = 'Enter M-Pesa PIN';
        subtitle = 'We have sent an STK Push to your phone. Please check your screen, enter your M-Pesa PIN, and authorize the charge.';
        break;
      case STKPushStatus.verifying:
        title = 'Verifying Payment';
        subtitle = 'Confirming transaction details with M-Pesa backend...';
        break;
      case STKPushStatus.success:
        title = 'Entry Confirmed!';
        subtitle = 'M-Pesa payment successfully verified. You have registered for this competition.';
        break;
      case STKPushStatus.failure:
        title = 'Payment Failed';
        subtitle = 'We could not verify your payment. Ensure your phone is nearby, has sufficient balance, and try again.';
        break;
    }

    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.grey900,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.grey500,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDetails() {
    if (_status == STKPushStatus.success || _status == STKPushStatus.failure) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Phone Number', style: TextStyle(color: AppColors.grey500, fontSize: 13)),
              Text(widget.mpesaPhone, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.grey900, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Amount Due', style: TextStyle(color: AppColors.grey500, fontSize: 13)),
              Text('${widget.currency} ${widget.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.grey900, fontSize: 13)),
            ],
          ),
          if (_status == STKPushStatus.waitingForPIN) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.grey200),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.clock, size: 14, color: AppColors.grey500),
                const SizedBox(width: 6),
                Text(
                  'Waiting: $_secondsRemaining seconds remaining',
                  style: const TextStyle(color: AppColors.grey600, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions() {
    switch (_status) {
      case STKPushStatus.sending:
      case STKPushStatus.verifying:
        return const SizedBox.shrink();
      case STKPushStatus.waitingForPIN:
        return SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () {
              _countdownTimer?.cancel();
              Navigator.pop(context, false);
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.grey300),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Cancel Request', style: TextStyle(color: AppColors.grey700, fontWeight: FontWeight.bold)),
          ),
        );
      case STKPushStatus.success:
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.golfLime,
              foregroundColor: AppColors.grey900,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        );
      case STKPushStatus.failure:
        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.grey300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Close', style: TextStyle(color: AppColors.grey700, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _status = STKPushStatus.sending;
                      _secondsRemaining = 30;
                      _actionResult = null;
                    });
                    _startFlow();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.golfLime,
                    foregroundColor: AppColors.grey900,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        );
    }
  }
}
