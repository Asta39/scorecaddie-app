import 'dart:io';
import 'package:flutter/material.dart';
import '../../widgets/offline/offline_bottom_sheet.dart';

class ConnectionGuard {
  static Future<void> run(BuildContext context, Future<void> Function() action) async {
    try {
      await action();
    } on SocketException {
      if (context.mounted) {
        OfflineBottomSheet.show(context, onRetry: () => run(context, action));
      }
    } catch (e) {
      if (e.toString().contains('Failed host lookup') || e.toString().contains('network_error')) {
        if (context.mounted) {
          OfflineBottomSheet.show(context, onRetry: () => run(context, action));
        }
      } else {
        rethrow;
      }
    }
  }
}
