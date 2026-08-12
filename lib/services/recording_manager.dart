import 'dart:io';
import 'package:flutter/material.dart';
import '../models/camera_config.dart';
import '../utils/utils.dart';
import '../enums/camera_id.dart';
import 'package:media_kit/media_kit.dart';
import 'settings_manager.dart';

class RecordingManager {
  RecordingManager({required CameraConfig config, required NativePlayer player})
    : _config = config,
      _player = player;

  CameraConfig _config;
  // ignore: unused_field
  final NativePlayer _player;

  Process? _process;
  final Map<CameraId, Process?> _processes = {};

  // Melacak apakah proses stop dilakukan secara manual oleh user
  bool _isManualStopping = false;

  final ValueNotifier<bool> isRecording = ValueNotifier(false);

  void updateConfig(CameraConfig config) {
    _config = config;
  }

  // --- MODE SINGLE (Opsional jika masih dipakai) ---
  Future<void> start() async {
    if (isRecording.value) return;
    // (Gunakan logika start single yang sudah ada sebelumnya jika diperlukan)
  }

  Future<void> stop() async {
    // (Gunakan logika stop single yang sudah ada sebelumnya jika diperlukan)
  }

  // --- MODE ALL DENGAN AUTO-RECONNECT ---
  Future<void> startAll() async {
    if (isRecording.value) return;

    _isManualStopping = false;
    isRecording.value = true;

    final cameras = SettingsManager.instance.cameras.value;
    for (var cam in cameras) {
      if (cam.rtspUrl.trim().isEmpty) continue;
      _startCameraRecording(cam);
    }
  }

  // Fungsi privat untuk menjalankan rekam per kamera sekaligus memasang pengawas (watchdog)
  void _startCameraRecording(CameraConfig cam) async {
    // Jika user sudah menekan stop secara manual, batalkan
    if (!isRecording.value || _isManualStopping) return;

    final cameraNameStr = _getNameForCameraId(cam.id);
    // Tambahkan timestamp atau indeks unik agar nama file tidak bentrok jika re-connect berkali-kali
    final outputPath = await Utils.generateVideoPath("${cameraNameStr}_rec");

    try {
      debugPrint("Starting recording for $cameraNameStr...");
      final process = await Process.start(Utils.ffmpegPath, [
        "-y",
        "-nostats",
        "-loglevel",
        "error",
        "-rtsp_transport",
        "tcp",
        "-i",
        cam.rtspUrl,
        "-c",
        "copy",
        "-tag:v",
        "hvc1",
        outputPath,
      ]);

      _processes[cam.id] = process;

      // Pantau kapan proses ini berhenti
      process.exitCode.then((code) {
        debugPrint("FFmpeg exited for $cameraNameStr with code: $code");

        // Hapus dari map aktif
        if (_processes[cam.id] == process) {
          _processes.remove(cam.id);
        }

        // JIKA MATI BUKAN KARENA MANUAL STOP DAN STATUS RECORDING MASIH AKTIF -> AUTO RECONNECT
        if (!_isManualStopping && isRecording.value) {
          debugPrint(
            "Camera $cameraNameStr disconnected! Attempting to reconnect recording in 3 seconds...",
          );

          Future.delayed(const Duration(seconds: 3), () {
            // Cek sekali lagi apakah status masih merekam sebelum mencoba ulang
            if (isRecording.value && !_isManualStopping) {
              _startCameraRecording(cam);
            }
          });
        }
      });
    } catch (e) {
      debugPrint("Failed to start recording for $cameraNameStr: $e");
      _processes[cam.id] = null;

      // Coba lagi jika gagal di awal dan belum di-stop manual
      if (!_isManualStopping && isRecording.value) {
        Future.delayed(const Duration(seconds: 3), () {
          if (isRecording.value && !_isManualStopping) {
            _startCameraRecording(cam);
          }
        });
      }
    }
  }

  Future<void> stopAll() async {
    if (!isRecording.value) return;

    // Tandai bahwa ini adalah penghentian manual oleh user
    _isManualStopping = true;
    isRecording.value = false;

    try {
      debugPrint("Stopping all individual camera recordings manually...");
      final keys = _processes.keys.toList();
      for (var key in keys) {
        final process = _processes[key];
        if (process != null) {
          try {
            process.stdin.write('q');
            await process.stdin.flush();
            await process.exitCode.timeout(
              const Duration(seconds: 4),
              onTimeout: () {
                process.kill();
                return -1;
              },
            );
          } catch (_) {}
        }
      }
    } finally {
      _processes.clear();
      debugPrint("All recordings successfully stopped.");
    }
  }

  Future<void> dispose() async {
    await stopAll();
    isRecording.dispose();
  }

  String _getNameForCameraId(CameraId id) {
    switch (id) {
      case CameraId.front:
        return "Front";
      case CameraId.left:
        return "Left";
      case CameraId.rear:
        return "Rear";
      case CameraId.right:
        return "Right";
    }
  }
}
