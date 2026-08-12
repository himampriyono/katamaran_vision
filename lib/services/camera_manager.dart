import 'package:flutter/material.dart';
import '../enums/camera_id.dart';
import '../models/camera_config.dart';
import 'camera_session.dart';
import 'settings_manager.dart';

class CameraManager {
  CameraManager._();

  static final CameraManager instance = CameraManager._();
  final Map<CameraId, CameraSession> _sessions = {};
  Iterable<CameraSession> get sessions => _sessions.values;
  bool get isInitialized => _sessions.isNotEmpty;
  final ValueNotifier<CameraId?> fullscreenCamera = ValueNotifier(null);
  CameraId? get fullscreen => fullscreenCamera.value;

  Future<void> initialize() async {
    if (_sessions.isNotEmpty) {
      await dispose();
    }

    for (final CameraConfig config in SettingsManager.instance.cameras.value) {
      _sessions[config.id] = CameraSession(config: config);
    }
  }

  CameraSession get(CameraId id) {
    final session = _sessions[id];

    if (session == null) {
      throw StateError(
        'CameraSession for ${id.name} has not been initialized.',
      );
    }

    return session;
  }

  Future<void> connectAll() async {
    await Future.wait(
      _sessions.values
          .where((session) => session.config.autoConnect)
          .map((session) => session.connect()),
    );
  }

  Future<void> disconnectAll() async {
    for (final session in _sessions.values) {
      await session.disconnect();
    }
  }

  Future<void> updateCamera(CameraConfig config) async {
    await SettingsManager.instance.saveCamera(config);

    final session = _sessions[config.id];

    if (session != null) {
      await session.updateConfig(config);
    }
  }

  Future<void> dispose() async {
    fullscreenCamera.value = null;
    
    for (final session in _sessions.values) {
      await session.dispose();
    }

    _sessions.clear();
  }

  bool isFullscreen(CameraId id) {
    return fullscreen == id;
  }

  void toggleFullscreen(CameraId id) {
    if (fullscreenCamera.value == id) {
      fullscreenCamera.value = null;
    } else {
      fullscreenCamera.value = id;
    }
  }
}
