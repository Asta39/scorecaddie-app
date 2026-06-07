import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

class UrlHelper {
  static const String appScheme = 'scorecaddie';

  /// Normalizes a phone number for WhatsApp.
  static String normalizeWhatsAppNumber(String phone) {
    String clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.startsWith('0')) {
      return '254${clean.substring(1)}';
    }
    if (clean.length == 9 && (clean.startsWith('7') || clean.startsWith('1'))) {
      return '254$clean';
    }
    return clean;
  }

  /// Launches a WhatsApp message to the given number.
  static Future<void> launchWhatsApp(String phone) async {
    final normalized = normalizeWhatsAppNumber(phone);
    final url = Uri.parse('whatsapp://send?phone=$normalized');
    final webUrl = Uri.parse('https://wa.me/$normalized');
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
    }
  }

  /// Launches the phone caller for the given number.
  static Future<void> launchCaller(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final url = Uri.parse('tel:$clean');
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    } catch (e) {
      debugPrint('Error launching caller: $e');
    }
  }

  /// Generates and shares a professional profile deep link.
  static Future<void> shareProfile({
    required String userId,
    required String name,
    required String role,
  }) async {
    final String deepLink = '$appScheme://marketplace/provider/$userId';
    final String message = 'Check out $name, a professional $role on ScoreCaddie! View their profile here: $deepLink';
    
    await Share.share(message, subject: 'ScoreCaddie Professional Profile');
  }
}
