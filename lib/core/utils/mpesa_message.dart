/// What a coach's M-Pesa confirmation SMS says about a payment.
class MpesaMessage {
  const MpesaMessage({this.code, this.amount, this.sender});

  /// The transaction code, e.g. SKL4ABC123.
  final String? code;
  final double? amount;

  /// Who sent it, as M-Pesa printed the name (usually in capitals).
  final String? sender;

  bool get isEmpty => code == null && amount == null;

  /// Reads a pasted confirmation. Handles send money, till and paybill
  /// wording; anything it can't find stays null for the coach to fill in.
  static MpesaMessage parse(String text) {
    final t = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    final code = RegExp(r'\b([A-Z0-9]{10})\b').firstMatch(t)?.group(1);
    final amt = RegExp(r'(?:Ksh|KES)\s?([\d,]+(?:\.\d{1,2})?)', caseSensitive: false).firstMatch(t)?.group(1);
    final amount = amt == null ? null : double.tryParse(amt.replaceAll(',', ''));

    String? sender;
    final from = RegExp(r'received from (.+?)(?: for account| on \d|\. New|$)', caseSensitive: false).firstMatch(t)?.group(1);
    if (from != null) {
      // Drop the phone number, masked or not, wherever it sits.
      final name = from.replaceAll(RegExp(r'\+?\d[\d*]{6,}'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
      if (name.isNotEmpty) sender = name;
    }
    return MpesaMessage(code: code, amount: amount, sender: sender);
  }
}
