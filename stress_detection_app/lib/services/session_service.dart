import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

class SessionUploadResult {
  SessionUploadResult({
    required this.savedLocally,
    required this.uploadedToCloud,
    this.localPath,
    this.errorMessage,
    this.sessionRow,
  });

  final bool savedLocally;
  final bool uploadedToCloud;
  final String? localPath;
  final String? errorMessage;
  final Map<String, dynamic>? sessionRow;
}

class SessionService {
  final _client = Supabase.instance.client;

  static const String videoBucket = 'session-videos';
  static const String audioBucket = 'session-audio';

  Future<SessionUploadResult> saveSession({
    required File mediaFile,
    required bool audioOnly,
    required int detectedStressPeak,
    required int detectedStressEnd,
    required int durationSeconds,
    required int introductionSeconds,
    required int pressureSeconds,
    required int pressureTier,
    required String languageCode,
    required Map<String, dynamic> phaseMetadata,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Not authenticated. Please log in again.');
    }

    if (!await mediaFile.exists()) {
      throw Exception('Recording file not found on device.');
    }

    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    final videoPath = '$userId/$sessionId.mp4';
    final audioPath = '$userId/$sessionId.m4a';

    var uploadError =
        'Cloud upload failed. Check Supabase storage buckets and policies.';

    try {
      if (audioOnly) {
        await _uploadWithTimeout(
          bucket: audioBucket,
          path: audioPath,
          file: mediaFile,
          contentType: 'audio/m4a',
        );
      } else {
        await _uploadWithTimeout(
          bucket: videoBucket,
          path: videoPath,
          file: mediaFile,
          contentType: 'video/mp4',
        );
        await _uploadWithTimeout(
          bucket: audioBucket,
          path: audioPath,
          file: mediaFile,
          contentType: 'audio/mp4',
        );
      }

      final row = await _client
          .from('stress_sessions')
          .insert({
            'user_id': userId,
            'self_reported_stress': detectedStressEnd,
            'video_storage_path': audioOnly ? audioPath : videoPath,
            'audio_storage_path': audioPath,
            'duration_seconds': durationSeconds,
            'introduction_seconds': introductionSeconds,
            'pressure_seconds': pressureSeconds,
            'pressure_tier': pressureTier,
            'phase_metadata': {
              ...phaseMetadata,
              'language': languageCode,
              'audio_only': audioOnly,
              'detected_stress_peak': detectedStressPeak,
              'detected_stress_end': detectedStressEnd,
            },
          })
          .select()
          .single();

      return SessionUploadResult(
        savedLocally: true,
        uploadedToCloud: true,
        localPath: mediaFile.path,
        sessionRow: row,
      );
    } catch (e, st) {
      debugPrint('Session upload error: $e\n$st');
      uploadError = e.toString();
    }

    return SessionUploadResult(
      savedLocally: true,
      uploadedToCloud: false,
      localPath: mediaFile.path,
      errorMessage: uploadError,
    );
  }

  Future<void> _uploadWithTimeout({
    required String bucket,
    required String path,
    required File file,
    required String contentType,
  }) async {
    await _client.storage.from(bucket).upload(
          path,
          file,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        ).timeout(
          const Duration(minutes: 3),
          onTimeout: () => throw Exception(
            'Upload timed out. Check your internet connection.',
          ),
        );
  }

  Future<List<Map<String, dynamic>>> getMySessions() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('stress_sessions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<String> getSignedPlaybackUrl(Map<String, dynamic> session) async {
    final meta = session['phase_metadata'];
    final audioOnly = meta is Map && meta['audio_only'] == true;
    final path = audioOnly
        ? session['audio_storage_path'] as String?
        : session['video_storage_path'] as String?;
    if (path == null || path.isEmpty) {
      throw Exception('No recording path found.');
    }
    final bucket = audioOnly ? audioBucket : videoBucket;
    return _client.storage.from(bucket).createSignedUrl(path, 3600);
  }

  String fileNameFromPath(String storagePath) => p.basename(storagePath);
}
