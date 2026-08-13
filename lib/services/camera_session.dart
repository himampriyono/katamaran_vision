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

  DateTime _lastPacketTime = DateTime.now();
  DateTime _lastReconnectAttempt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _reconnecting = false;
  bool _autoReconnectEnabled = false;

  final ValueNotifier<CameraStatus> status = ValueNotifier(
    const CameraStatus(state: CameraState.disconnected),
  );

  final ValueNotifier<CameraMode> mode = ValueNotifier(CameraMode.live);

  StreamSubscription<bool>? _completedSubscription;
  StreamSubscription<String>? _errorSubscription;
  StreamSubscription<Duration>? _positionSubscription;

  CameraStatus? _lastState;
  bool _isCooldown = false;

  void _initialize() {
    _player = Player();
    _configurePlayer(_player!);
    _videoController = VideoController(_player!);
    _registerListeners();

    _reconnectTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _checkConnection(),
    );

    _recordingManager = RecordingManager.instance;
    status.addListener(_onStateChanged);
  }

  void _configurePlayer(Player player) {
    if (player.platform is! NativePlayer) return;

    final native = player.platform as NativePlayer;

    native.setProperty('profile', 'low-latency');
    native.setProperty('cache', 'no');
    native.setProperty('video-sync', 'desync');
    native.setProperty('framedrop', 'yes');
    native.setProperty('hwdec', 'auto');
    native.setProperty('network-timeout', '2');
    native.setProperty('rtsp-transport', 'tcp');
    native.setProperty('speed', '1.05');
    // native.setProperty('cache-pause', 'no');
    // native.setProperty('demuxer-max-bytes', '1000000');
    // native.setProperty('demuxer-max-back-bytes', '1000000');
  }

  void _registerListeners() {
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
      _lastPacketTime = DateTime.now();

      if (status.value.state != CameraState.playing) {
        status.value = status.value.copyWith(
          state: CameraState.playing,
          message: '',
        );

        // _recordingManager.startCamera(config, byUser: false);
        // _onStateChanged();
      }
    });
  }

  void _onStateChanged() async {
    if (status.value == _lastState || _isCooldown) return;

    _isCooldown = true;
    _lastState = status.value;

    final recordingMgr = RecordingManager.instance;
    final isRecording = recordingMgr.getUserWants(config.id);

    if (isRecording == true) {
      if (status.value.state == CameraState.playing) {
        recordingMgr.startCamera(config, byUser: false);
        await Future.delayed(const Duration(seconds: 2));
      } else {
        recordingMgr.stopCamera(config, byUser: false);
        await Future.delayed(const Duration(seconds: 3));
      }
    }

    _isCooldown = false;
    if(status.value != _lastState){
      _onStateChanged();
    }
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
      _lastPacketTime = DateTime.now();
      _configurePlayer(_player!);
      await _player!.open(Media(_config.rtspUrl));
    } catch (e) {
      status.value = status.value.copyWith(
        state: CameraState.error,
        message: e.toString(),
      );
    }

    _autoReconnectEnabled = true;
  }

  Future<void> disconnect({bool disableAutoReconnect = true}) async {
    // _recordingManager.stopCamera(_config.id);

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
    if (_reconnecting) return;
    _reconnecting = true;

    try {
      await disconnect(disableAutoReconnect: false);
      await Future.delayed(const Duration(milliseconds: 500));
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

    if (needRestart && isConnected) {
      await restart();
    }
  }

  Future<void> dispose() async {
    _reconnectTimer?.cancel();
    await _completedSubscription?.cancel();
    await _errorSubscription?.cancel();
    await _positionSubscription?.cancel();
    status.removeListener(_onStateChanged);
    await _player?.dispose();
    _player = null;
    _videoController = null;
  }

  Future<void> _checkConnection() async {
    if (_player == null || _reconnecting || !_autoReconnectEnabled) return;

    final diff = DateTime.now().difference(_lastPacketTime);
    if (diff.inSeconds < 3) return;

    // _recordingManager.stopCamera(_config.id);
    // _onStateChanged();
    final now = DateTime.now();
    if (now.difference(_lastReconnectAttempt).inSeconds < 10) return;
    _lastReconnectAttempt = now;

    status.value = status.value.copyWith(
      state: CameraState.reconnecting,
      message: 'Reconnecting...',
    );

    await restart();
  }
}
