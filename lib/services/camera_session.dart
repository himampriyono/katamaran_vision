import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../enums/camera_id.dart';
import '../enums/camera_mode.dart';
import '../enums/camera_state.dart';
import '../models/camera_config.dart';
import '../models/camera_status.dart';
import 'recording_manager.dart';
import 'mediamtx_service.dart';

class CameraSession {
  CameraSession({required CameraConfig config}) : _config = config {
    _initialize();
  }

  late final RecordingManager _recordingManager;

  CameraConfig _config;
  CameraConfig get config => _config;

  Player? _player;
  VideoController? _videoController;
  Timer? _reconnectTimer;

  Player? get player => _player;
  VideoController? get videoController => _videoController;
  RecordingManager get recording => _recordingManager;

  DateTime _lastPositionUpdate = DateTime.now();
  Duration _lastPosition = Duration.zero;
  DateTime _lastReconnectAttempt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _reconnecting = false;
  bool _autoReconnectEnabled = false;

  final ValueNotifier<CameraStatus> status = ValueNotifier(
    const CameraStatus(state: CameraState.disconnected),
  );

  final ValueNotifier<CameraMode> mode = ValueNotifier(CameraMode.live);

  final ValueNotifier<bool> isRecording = ValueNotifier(false);

  StreamSubscription<bool>? _bufferingSubscription;
  StreamSubscription<bool>? _completedSubscription;
  StreamSubscription<String>? _errorSubscription;
  StreamSubscription<Duration>? _positionSubscription;

  String get _localRtspUrl {
    switch (_config.id) {
      case CameraId.front:
        return 'rtsp://127.0.0.1:8554/front';

      case CameraId.left:
        return 'rtsp://127.0.0.1:8554/left';

      case CameraId.rear:
        return 'rtsp://127.0.0.1:8554/rear';

      case CameraId.right:
        return 'rtsp://127.0.0.1:8554/right';
    }
  }

  void _initialize() {
    _player = Player();
    _configurePlayer(_player!);
    _videoController = VideoController(_player!);
    _registerListeners();
    _reconnectTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _checkConnection(),
    );
    final native = _player!.platform as NativePlayer;
    _recordingManager = RecordingManager(config: _config, player: native);
  }

  void _configurePlayer(Player player) {
    if (player.platform is! NativePlayer) {
      return;
    }

    final native = player.platform as NativePlayer;

    native.setProperty('profile', 'low-latency');
    native.setProperty('cache', 'no');
    native.setProperty('video-sync', 'desync');
    native.setProperty('framedrop', 'vo');
    native.setProperty('hwdec', 'auto');
    native.setProperty('speed', '1.01');
    // native.setProperty('demuxer-lavf-o', 'fflags=nobuffer');
    // native.setProperty('demuxer-max-bytes', '256KiB');
    // native.setProperty('demuxer-max-back-bytes', '0');
    // native.setProperty('rtsp-transport', 'tcp');
    // native.setProperty('network-timeout', '1000000');
  }

  void _registerListeners() {
    _bufferingSubscription = _player!.stream.buffering.listen((buffering) {
      // debugPrint('[${_config.name}] Buffering : $buffering');
    });

    _player!.stream.log.listen((event) {
      // debugPrint(
      //   "[MPV/${_config.name}] ${event.prefix}/${event.level}: ${event.text}",
      // );
    });

    _completedSubscription = _player!.stream.completed.listen((completed) {
      if (completed) {
        status.value = status.value.copyWith(
          state: CameraState.disconnected,
          message: 'Stream ended.',
        );
      }
    });

    _errorSubscription = _player!.stream.error.listen((error) {
      status.value = status.value.copyWith(
        state: CameraState.error,
        message: error,
      );
    });

    _positionSubscription = _player!.stream.position.listen((position) {
      if (position != _lastPosition) {
        _lastPosition = position;
        _lastPositionUpdate = DateTime.now();

        if (status.value.state != CameraState.playing) {
          status.value = status.value.copyWith(
            state: CameraState.playing,
            message: '',
          );
        }
      }
    });
  }

  Future<void> connect() async {
    if (_config.rtspUrl.trim().isEmpty) {
      status.value = status.value.copyWith(
        state: CameraState.error,
        message: 'RTSP URL is empty.',
      );
      return;
    }

    status.value = status.value.copyWith(
      state: CameraState.connecting,
      message: 'Connecting...',
    );

    try {
      _lastPosition = Duration.zero;
      _lastPositionUpdate = DateTime.now();
      _player!.open(Media(_config.rtspUrl));
      // _player!.open(Media(_localRtspUrl));
    } catch (e) {
      status.value = status.value.copyWith(
        state: CameraState.error,
        message: e.toString(),
      );
    }

    _autoReconnectEnabled = true;
  }

  Future<void> disconnect({bool disableAutoReconnect = true}) async {
    await _player?.stop();

    status.value = status.value.copyWith(
      state: CameraState.disconnected,
      message: '',
    );

    if (disableAutoReconnect) {
      _autoReconnectEnabled = false;
    }
  }

  Future<void> restart() async {
    if (_reconnecting) {
      // debugPrint(
      //   "[${_config.name}] RESTART TRIGGERED - recording: ${_recordingManager.isRecording.value}",
      // );
      return;
    }

    _reconnecting = true;

    try {
      await disconnect(disableAutoReconnect: false);

      await Future.delayed(const Duration(seconds: 1));

      await connect();
    } finally {
      _reconnecting = false;
    }
  }

  Future<void> updateConfig(CameraConfig config) async {
    final needRestart = _config.rtspUrl != config.rtspUrl;

    final isConnected =
        status.value.state == CameraState.playing ||
        status.value.state == CameraState.connecting;

    _config = config;
    // _recordingManager.updateConfig(config);

    if (needRestart && isConnected) {
      await restart();
    }
  }

  Future<void> dispose() async {
    _reconnectTimer?.cancel();

    await _bufferingSubscription?.cancel();
    await _completedSubscription?.cancel();
    await _errorSubscription?.cancel();
    await _positionSubscription?.cancel();

    _bufferingSubscription = null;
    _completedSubscription = null;
    _errorSubscription = null;
    _positionSubscription = null;

    await _player?.dispose();
    await _recordingManager.dispose();

    _player = null;
    _videoController = null;
  }

  Future<void> _checkConnection() async {
    if (_player == null || _reconnecting) {
      return;
    }

    if (!_autoReconnectEnabled) {
      return;
    }

    final diff = DateTime.now().difference(_lastPositionUpdate);

    if (diff.inSeconds < 3) {
      return;
    }

    final now = DateTime.now();

    if (now.difference(_lastReconnectAttempt).inSeconds < 10) {
      return;
    }

    _lastReconnectAttempt = now;

    status.value = status.value.copyWith(
      state: CameraState.reconnecting,
      message: 'Reconnecting...',
    );

    await restart();
  }

  Future<void> startRecording() async {
    await _recordingManager.start();
  }

  Future<void> stopRecording() async {
    await _recordingManager.stop();
  }

  Future<void> startRecordingAll() async {
    await _recordingManager.startAll();
  }

  Future<void> stopRecordingAll() async {
    await _recordingManager.stopAll();
  }
}
