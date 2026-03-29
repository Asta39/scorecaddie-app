import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

class UrlHelper {
  /// Normalizes a phone number for WhatsApp.
  /// Replaces a leading '0' with '254' (Kenya country code).
  /// Removes any non-numeric characters first.
  static String normalizeWhatsAppNumber(String phone) {
    // Remove all non-digit characters
    String clean = phone.replaceAll(RegExp(r'\D'), '');
    
    // If it starts with '0', replace it with '254'
    if (clean.startsWith('0')) {
      return '254${clean.substring(1)}';
    }
    
    // If it starts with '7' or '1' but only has 9 digits, add '254'
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
      } else {
        debugPrint('Could not launch WhatsApp or web link for $normalized');
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
      } else {
        debugPrint('Could not launch caller for $clean');
      }
    } catch (e) {
      debugPrint('Error launching caller: $e');
    }
  }
}
