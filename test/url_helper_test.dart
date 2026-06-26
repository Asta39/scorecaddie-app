import 'package:flutter_test/flutter_test.dart';
import 'package:score_caddie/core/utils/url_helper.dart';

void main() {
  group('UrlHelper - normalizeWhatsAppNumber', () {
    test('removes leading 0 and adds 254', () {
      expect(UrlHelper.normalizeWhatsAppNumber('0712345678'), '254712345678');
    });

    test('adds 254 to 9-digit Kenyan number starting with 7', () {
      expect(UrlHelper.normalizeWhatsAppNumber('712345678'), '254712345678');
    });

    test('adds 254 to 9-digit Kenyan number starting with 1', () {
      expect(UrlHelper.normalizeWhatsAppNumber('123456789'), '254123456789');
    });

    test('keeps already normalized number', () {
      expect(UrlHelper.normalizeWhatsAppNumber('254712345678'), '254712345678');
    });

    test('removes all non-digits', () {
      expect(UrlHelper.normalizeWhatsAppNumber('+254-712-345-678'), '254712345678');
    });
  });
}