import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/camera_config.dart';
import '../utils/utils.dart';
import '../enums/camera_id.dart';

class RecordingManager {
  static final RecordingManager instance = RecordingManager._internal();
  RecordingManager._internal();

  final ValueNotifier<bool> isRecording = ValueNotifier<bool>(false);
  final ValueNotifier<Map<CameraId, DateTime?>> startTimesNotifier =
      ValueNotifier<Map<CameraId, DateTime?>>({});
  DateTime? getStartTime(CameraId id) => startTimesNotifier.value[id];
  final Map<CameraId, Process?> _processes = {};
  // final ValueNotifier<bool> isRecording = ValueNotifier(false);
  final Map<CameraId, bool> _isStarting = {};
  final Map<CameraId, DateTime> _startTimes = {};
  // DateTime? getStartTime(CameraId id) => _startTimes[id];

  bool isProcessing(CameraId id) =>
      _processes.containsKey(id) || (_isStarting[id] ?? false);

  Future<void> startAll() async {
    if (isRecording.value) return;
    isRecording.value = true;
  }

  Future<void> stopAll() async {
    if (!isRecording.value) return;
    isRecording.value = false;
    _startTimes.clear();

    for (var entry in _processes.entries) {
      _stopProcess(entry.value);
    }
    _processes.clear();
    startTimesNotifier.value = {};
  }

  void startCamera(CameraConfig config) async {
    if (!isRecording.value ||
        _processes.containsKey(config.id) ||
        (_isStarting[config.id] ?? false)) {
      return;
    }

    if (config.rtspUrl.trim().isEmpty) return;

    _isStarting[config.id] = true;

    final cameraNameStr = _getNameForCameraId(config.id);
    final outputPath = await Utils.generateVideoPath(cameraNameStr);

    try {
      debugPrint("Starting record $cameraNameStr -> $outputPath");

      final process = await Process.start(Utils.ffmpegPath, [
        "-y",
        "-fflags",
        "nobuffer",
        "-flags",
        "low_delay",
        "-rtsp_transport",
        "tcp",
        "-i",
        config.rtspUrl,
        "-c",
        "copy",
        "-an",
        "-threads",
        "1",
        outputPath,
      ]);

      _processes[config.id] = process;

      process.stderr.transform(systemEncoding.decoder).listen((data) {
        // debugPrint("FFmpeg [$cameraNameStr]: $data");
      });

      _startTimes[config.id] = DateTime.now();

      process.exitCode.then((code) {
        debugPrint(
          "FFmpeg recorder exited for $cameraNameStr with code: $code",
        );
        _processes.remove(config.id);
        _isStarting[config.id] = false;
        _startTimes.remove(config.id);

        final newMap = Map<CameraId, DateTime?>.from(startTimesNotifier.value);
        newMap[config.id] = DateTime.now();
        startTimesNotifier.value = newMap;
        isRecording.value = true;
      });
    } catch (e) {
      debugPrint("Failed to start FFmpeg recorder for $cameraNameStr: $e");
      _isStarting[config.id] = false;
      _processes[config.id] = null;
    }
  }

  void stopCamera(CameraId id) {
    _isStarting[id] = false;
    final process = _processes.remove(id);
    _startTimes.remove(id);
    _stopProcessGracefully(process, _getNameForCameraId(id));
    final newMap = Map<CameraId, DateTime?>.from(startTimesNotifier.value);
    newMap.remove(id);
    startTimesNotifier.value = newMap;
    if (newMap.isEmpty) isRecording.value = false;
  }

  void _stopProcessGracefully(Process? process, String cameraName) {
    if (process == null) return;

    debugPrint("Cleaning up FFmpeg for $cameraName...");

    try {
      process.stdin.writeln('q');

      Future.delayed(const Duration(seconds: 2), () {
        try {
          process.kill(ProcessSignal.sigterm);
          debugPrint("FFmpeg for $cameraName closed gracefully.");
        } catch (_) {}
      });
    } catch (_) {
      process.kill();
    }
  }

  void _stopProcess(Process? process) {
    if (process == null) return;
    try {
      process.stdin.write('q');
      process.stdin.flush();
      Future.delayed(const Duration(seconds: 1), () {
        process.kill();
      });
    } catch (_) {
      process.kill();
    }
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
