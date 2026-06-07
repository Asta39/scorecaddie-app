import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseStorageService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Uploads a file to a specific bucket and returns the public URL.
  Future<String?> uploadFile({
    required String bucket,
    required String path,
    required File file,
  }) async {
    try {
      final storage = _client.storage.from(bucket);
      
      // Upload the file
      await storage.upload(
        path,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      // Get public URL
      final String publicUrl = storage.getPublicUrl(path);
      debugPrint('SUPABASE_STORAGE: File uploaded successfully -> $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('SUPABASE_STORAGE_ERROR: $e');
      return null;
    }
  }

  /// Specialized upload for profile photos
  Future<String?> uploadProfilePhoto(String userId, File file) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'profiles/$userId/pfp_$timestamp.jpg';
    return await uploadFile(bucket: 'user_assets', path: path, file: file);
  }

  /// Specialized upload for certifications
  Future<String?> uploadCertification(String userId, File file, String fileName) async {
    final path = 'providers/$userId/certs/$fileName.jpg';
    return await uploadFile(bucket: 'user_assets', path: path, file: file);
  }

  /// Specialized upload for scorecard scanner images
  Future<String?> uploadScorecardImage(String userId, String roundId, File file) async {
    final path = 'scorecards/$userId/$roundId.jpg';
    return await uploadFile(bucket: 'scorecard-images', path: path, file: file);
  }
}
