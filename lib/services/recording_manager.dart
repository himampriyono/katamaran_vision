import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/camera_config.dart';
import '../utils/utils.dart';
import '../enums/camera_id.dart';
import 'camera_manager.dart';

class RecordingManager {
  static final RecordingManager instance = RecordingManager._internal();
  RecordingManager._internal();

  final ValueNotifier<Map<CameraId, bool>> isRecording =
      ValueNotifier<Map<CameraId, bool>>({});
  final ValueNotifier<Map<CameraId, DateTime>> startTimes =
      ValueNotifier<Map<CameraId, DateTime>>({});
  final Map<CameraId, Process?> processes = {};
  final Map<CameraId, bool> _userWantsRecording = {};

  DateTime? getStartTime(CameraId id) => startTimes.value[id];
  bool? getUserWants(CameraId id) => _userWantsRecording[id];
  final Set<CameraId> _startingCameras = {};
  final Map<CameraId, int> _fileIndexes = {};

  void startCamera(CameraConfig config, {bool byUser = true}) async {
    if (processes.containsKey(config.id) ||
        _startingCameras.contains(config.id)) {
      debugPrint("Camera ${config.id} is already recording/processing.");
      return;
    }

    if (byUser && (isRecording.value[config.id] ?? false)) return;
    if (!byUser && (_userWantsRecording[config.id] != true)) return;
    if (config.rtspUrl.trim().isEmpty) return;

    _startingCameras.add(config.id);

    if (byUser) {
      _userWantsRecording[config.id] = true;
      _fileIndexes[config.id] = 1;
    } else {
      _fileIndexes[config.id] = (_fileIndexes[config.id] ?? 0) + 1;
    }

    final cameraNameStr = _getNameForCameraId(config.id);
    final outputPath = await Utils.generateVideoPath(
      (_fileIndexes[config.id] ?? 1) < 2
          ? cameraNameStr
          : "$cameraNameStr${_fileIndexes[config.id]}",
    );

    try {
      if (_userWantsRecording[config.id] == false && !byUser) {
        _startingCameras.remove(config.id);
        return;
      }
      debugPrint("Start record $cameraNameStr -> $outputPath");

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

      processes[config.id] = process;
      _startingCameras.remove(config.id);

      final newRecordingMap = Map<CameraId, bool>.from(isRecording.value);
      newRecordingMap[config.id] = true;
      isRecording.value = newRecordingMap;

      final newTimesMap = Map<CameraId, DateTime>.from(startTimes.value);
      newTimesMap[config.id] = DateTime.now();
      startTimes.value = newTimesMap;

      process.stderr.transform(systemEncoding.decoder).listen((data) {
        // debugPrint("FFmpeg [$cameraNameStr]: $data");
      });

      process.exitCode.then((code) {
        debugPrint(
          "FFmpeg recorder exited for $cameraNameStr with code: $code",
        );
        processes.remove(config.id);
        startTimes.value.remove(config.id);
        _startingCameras.remove(config.id);

        isRecording.value[config.id] = false;
      });
    } catch (e) {
      debugPrint("Failed to start FFmpeg recorder for $cameraNameStr: $e");
      isRecording.value[config.id] = false;
      _startingCameras.remove(config.id);
      processes[config.id] = null;
    }
  }

  void stopCamera(CameraConfig config, {bool byUser = true}) {
    if (byUser) {
      _userWantsRecording[config.id] = false;
    }

    final process = processes.remove(config.id);
    if (process == null) return;

    // processes.remove(config.id);

    final newRecordingMap = Map<CameraId, bool>.from(isRecording.value);
    newRecordingMap[config.id] = false;
    isRecording.value = newRecordingMap;

    final newTimesMap = Map<CameraId, DateTime>.from(startTimes.value);
    newTimesMap.remove(config.id);
    startTimes.value = newTimesMap;

    try {
      process.stdin.writeln('q');
      Future.delayed(const Duration(seconds: 2), () {
        try {
          process.kill(ProcessSignal.sigterm);
          debugPrint(
            "FFmpeg for ${_getNameForCameraId(config.id)} closed gracefully.",
          );
        } catch (_) {}
      });
    } catch (e) {
      process.kill();
    }
  }

  void startAllCamera() async {
    for (final id in CameraId.values) {
      final session = CameraManager.instance.get(id);
      startCamera(session.config);
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  void stopAllCamera() async {
    for (final id in CameraId.values) {
      final session = CameraManager.instance.get(id);
      stopCamera(session.config);
      await Future.delayed(const Duration(milliseconds: 300));
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
