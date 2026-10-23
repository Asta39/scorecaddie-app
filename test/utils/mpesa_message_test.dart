import 'package:flutter_test/flutter_test.dart';
import 'package:score_caddie/core/utils/mpesa_message.dart';

void main() {
  test('send money', () {
    final m = MpesaMessage.parse('SKL4ABC123 Confirmed. Ksh2,000.00 received from JOHN DOE 0712345678 on 23/10/26 at 4:05 PM. New M-PESA balance is Ksh5,000.00.');
    expect(m.code, 'SKL4ABC123');
    expect(m.amount, 2000);
    expect(m.sender, 'JOHN DOE');
  });

  test('till, masked number before the name', () {
    final m = MpesaMessage.parse('SKL4XYZ789 Confirmed. on 23/10/26 at 4:05 PM Ksh1,500.00 received from 254712***678 JANE WANJIRU. New Account balance is Ksh9,000.00.');
    expect(m.code, 'SKL4XYZ789');
    expect(m.amount, 1500);
    expect(m.sender, 'JANE WANJIRU');
  });

  test('paybill with account', () {
    final m = MpesaMessage.parse('SKM1QWE456 Confirmed. Ksh3,000.00 received from PETER OTIENO 0722000111 for account COACH1 on 23/10/26 at 9:00 AM.');
    expect(m.amount, 3000);
    expect(m.sender, 'PETER OTIENO');
  });

  test('not a payment', () {
    expect(MpesaMessage.parse('hello there').isEmpty, isTrue);
  });
}
