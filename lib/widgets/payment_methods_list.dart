import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/models/coaching_model.dart';
import '../screens/onboarding/ob_app.dart';
import '../screens/onboarding/ob_style.dart';
import 'top_notification.dart';

/// How to pay a coach: each way they accept, with the numbers a player
/// copies straight into M-Pesa.
class PaymentMethodsList extends StatelessWidget {
  const PaymentMethodsList({super.key, required this.methods, this.amount});
  final List<PaymentMethod> methods;

  /// What to pay, shown in the footer when known.
  final String? amount;

  @override
  Widget build(BuildContext context) {
    if (methods.isEmpty) {
      return const ObGroup(header: 'How to pay', children: [ObRow('Ask your coach how to pay', subtitle: 'They haven’t added payment details yet')]);
    }
    void copy(String what, String value) {
      Clipboard.setData(ClipboardData(text: value));
      HapticFeedback.selectionClick();
      TopNotification.showSuccess(context, '$what copied');
    }

    Widget copyButton(String what, String value) => Semantics(
          button: true,
          label: 'Copy $what',
          child: InkResponse(
            onTap: () => copy(what, value),
            radius: 24,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(LucideIcons.copy, size: 20, color: Ob.lime),
            ),
          ),
        );

    return ObGroup(
      header: 'How to pay',
      footer: [if (amount != null) 'Pay $amount.', 'Your coach records it once the money arrives.'].join(' '),
      children: [
        for (final m in methods) ...[
          if (m.type == 'cash')
            ObRow('Cash', subtitle: 'Pay your coach in person', leading: const ObRowIcon(LucideIcons.banknote, Color(0xFFB7791F)))
          else ...[
            ObRow(
              m.type == 'paybill' ? 'Paybill ${m.number}' : m.type == 'till' ? 'Till ${m.number}' : m.number,
              subtitle: [m.label, if (m.name.isNotEmpty) m.name].join(' · '),
              leading: const ObRowIcon(LucideIcons.smartphone, Ob.lime),
              trailing: copyButton(m.type == 'send_money' ? 'number' : m.type == 'till' ? 'till number' : 'business number', m.number),
            ),
            if (m.type == 'paybill')
              ObRow('Account ${m.account}', subtitle: 'Paybill account number', trailing: copyButton('account number', m.account)),
          ],
        ],
      ],
    );
  }
}
