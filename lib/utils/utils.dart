import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class Utils {
  Utils._();

  static Future<Directory> getVideoDirectory() async {
    final documents = await getApplicationDocumentsDirectory();

    final directory = Directory(path.join(documents.path, "Videos"));

    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }

    return directory;
  }

  static String generatetimeStamp() {
    final now = DateTime.now();

    return "${now.year.toString().padLeft(2, '0')}"
        "${now.month.toString().padLeft(2, '0')}"
        "${now.day.toString().padLeft(2, '0')}"
        "${now.hour.toString().padLeft(2, '0')}"
        "${now.minute.toString().padLeft(2, '0')}";
  }

  static String generateVideoFilename(String prefix) {
    return "${generatetimeStamp()}_$prefix.ts";
  }

  static String get ffmpegPath {
    return path.join(
      Directory.current.path,
      "tools",
      "ffmpeg",
      Platform.isWindows ? "ffmpeg.exe" : "ffmpeg",
    );
  }

  static String get ffprobePath {
    return path.join(
      Directory.current.path,
      "tools",
      "ffmpeg",
      Platform.isWindows ? "ffprobe.exe" : "ffprobe",
    );
  }

  static bool get hasFFmpeg {
    return File(ffmpegPath).existsSync();
  }

  static String get mediamtxPath {
    return path.join(
      Directory.current.path,
      "tools",
      "mediamtx",
      Platform.isWindows ? "mediamtx.exe" : "mediamtx",
    );
  }

  static bool get hasMediaMtx {
    return File(mediamtxPath).existsSync();
  }

  static Future<Directory> getConfigDirectory() async {
    final support = await getApplicationSupportDirectory();
    final directory = Directory(path.join(support.path, "config"));

    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }

    return directory;
  }

  static Future<String> generateVideoPath(String prefix) async {
    final directory = await getVideoDirectory();

    return path.join(directory.path, generateVideoFilename(prefix));
  }
}
