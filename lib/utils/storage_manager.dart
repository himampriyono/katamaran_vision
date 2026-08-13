// lib/utils/storage_manager.dart
import 'utils.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class StorageManager {
  static const int testRetentionHours = 3; // Untuk pengujian
  static const int testRetentionMinutes = 3; // Untuk pengujian
  static const int productionRetentionDays = 30;

  static Future<void> cleanupOldVideos() async {
    try {
      final dir = await Utils.getVideoDirectory();
      if (!await dir.exists()) return;

      final now = DateTime.now();

      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.ts')) {
          final stat = await entity.stat();
          final age = now.difference(stat.modified);

          if (age.inHours >= testRetentionHours) {
            debugPrint("StorageManager: Menghapus video lama: ${entity.path}");
            await entity.delete();
          }
        }
      }
    } catch (e) {
      debugPrint("StorageManager: Error saat pembersihan: $e");
    }
  }
}
