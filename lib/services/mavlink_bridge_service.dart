import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../enums/camera_id.dart';
import '../enums/camera_state.dart';
import '../models/camera_status.dart';
import 'camera_manager.dart';
import 'parser_cam.dart';
import 'siyi_service.dart';

class MavlinkBridgeService {
  static final MavlinkBridgeService instance = MavlinkBridgeService._internal();
  factory MavlinkBridgeService() => instance;
  MavlinkBridgeService._internal();

  WebSocketChannel? _channel;
  bool _isConnecting = false;

  double vesselLat = 0.0;
  double vesselLon = 0.0;
  double vesselHeading = 0.0;

  double? _previousTargetLat;
  double? _previousTargetLon;
  DateTime? _previousTargetTime;

  ValueNotifier<bool> isConnectedToMavlink = ValueNotifier(false);

  Future<void> connectToMavlinkServer() async {
    if (_isConnecting || isConnectedToMavlink.value) return;
    _isConnecting = true;

    try {
      final socket = await Socket.connect(
        '127.0.0.1',
        8080,
        timeout: const Duration(seconds: 1),
      );
      await socket.close();

      debugPrint("🔌 Menghubungkan ke MAVLink Server (ws://127.0.0.1:8080)...");
      _channel = WebSocketChannel.connect(Uri.parse('ws://127.0.0.1:8080'));

      isConnectedToMavlink.value = true;
      _isConnecting = false;

      _channel!.stream.listen(
        (message) {
          _handleIncomingData(message);
        },
        onError: (error) {
          debugPrint("⚠️ Koneksi WebSocket MAVLink error: $error");
          _handleDisconnect();
        },
        onDone: () {
          debugPrint("➖ Koneksi WebSocket MAVLink ditutup server.");
          _handleDisconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      // Server mati / port ditolak ditangkap di sini dengan aman tanpa freeze/crash
      _isConnecting = false;
      _handleDisconnect();
    }
  }

  // 2. Tangani data yang masuk dari MAVLink Server
  void _handleIncomingData(String message) {
    try {
      final data = jsonDecode(message);
      if (data['type'] == 'VESSEL_STATE') {
        vesselLat = data['lat'];
        vesselLon = data['lon'];
        vesselHeading = data['heading'];

        _calculateAndSendTarget();
      } else if (data['type'] == 'REQ_CAM_STATUS') {
        debugPrint("Got cam state req");
        _sendCamState();
      }
    } catch (e) {
      debugPrint("⚠️ Gagal parsing data dari MAVLink: $e");
    }
  }

  // KODE KALKULASI TARGET ASLIMU (TIDAK DIUBAH SAMA SEKALI)
  void _calculateAndSendTarget() {
    final gimbalAtt = SiyiCamParser.gimbalAttitude.value;
    double gimbalYaw = gimbalAtt['yaw'] ?? 0.0;
    double gimbalPitch = gimbalAtt['pitch'] ?? 0.0;
    double lrfDist = SiyiCamParser.lrfDistance.value;
    bool lrfIsOn = SiyiCamParser.isLrfOn.value;
    bool isValid = false;

    if (lrfDist > 0 && lrfIsOn) {
      isValid = true;
    }

    double absoluteHeading = (vesselHeading + gimbalYaw) % 360;

    double pitchRad = gimbalPitch * (pi / 180.0);
    double horizontalDistance = lrfDist * cos(pitchRad);

    double earthRadius = 6378137.0;

    double headingRad = absoluteHeading * (pi / 180.0);

    double dLat = horizontalDistance * cos(headingRad); // pergeseran ke utara
    double dLon = horizontalDistance * sin(headingRad); // pergeseran ke timur

    double targetLat = vesselLat + (dLat / earthRadius) * (180.0 / pi);
    double targetLon =
        vesselLon +
        (dLon / (earthRadius * cos(vesselLat * (pi / 180.0)))) * (180.0 / pi);

    final now = DateTime.now();
    double? speedMps;

    if (isValid) {
      final prevLat = _previousTargetLat;
      final prevLon = _previousTargetLon;
      final prevTime = _previousTargetTime;

      if (prevLat != null && prevLon != null && prevTime != null) {
        speedMps = _calculateTargetSpeed(
          previousLat: prevLat,
          previousLon: prevLon,
          currentLat: targetLat,
          currentLon: targetLon,
          elapsed: now.difference(prevTime),
        );
      }

      _previousTargetLat = targetLat;
      _previousTargetLon = targetLon;
      _previousTargetTime = now;
    } else {
      _previousTargetLat = null;
      _previousTargetLon = null;
      _previousTargetTime = null;
    }

    if (speedMps != null) {
      debugPrint('Target speed: ${speedMps.toStringAsFixed(1)} m/s');
    }

    final payload = jsonEncode({
      'type': 'TARGET_COORDINATE',
      'isValid': isValid,
      'lat': targetLat,
      'lon': targetLon,
      'spd': speedMps,
    });

    SiyiCamParser.objectPos.value = {
      'valid': isValid ? 1 : 0,
      'lat': targetLat,
      'lng': targetLon,
      'spd': speedMps ?? 0,
    };

    _channel?.sink.add(payload);
  }

  double _calculateTargetSpeed({
    required double previousLat,
    required double previousLon,
    required double currentLat,
    required double currentLon,
    required Duration elapsed,
  }) {
    if (elapsed.inMicroseconds <= 0) return 0;

    const double earthRadius =
        6378137; // (m) r di garis khatulistiwa @2026, asline si embuh

    final lat1 = previousLat * pi / 180;
    final lat2 = currentLat * pi / 180;
    final deltaLat = (currentLat - previousLat) * pi / 180;
    final deltaLon = (currentLon = previousLon) * pi / 180;

    final a =
        (pow(sin(deltaLat / 2), 2) +
                cos(lat1) * cos(lat2) * pow(sin(deltaLon / 2), 2))
            .clamp(0.0, 1.0)
            .toDouble();

    final angularDistance = 2 * atan2(sqrt(a), sqrt(1 - a));
    final distance = earthRadius * angularDistance;
    final elapsedSeconds = elapsed.inMicroseconds / 1000000;

    return distance / elapsedSeconds;
  }

  void _sendCamState() {
    final manager = CameraManager.instance;
    bool cam1Connected =
        manager.get(CameraId.front).status.value.state == CameraState.playing;
    bool cam2Connected =
        manager.get(CameraId.left).status.value.state == CameraState.playing;
    bool cam3Connected =
        manager.get(CameraId.rear).status.value.state == CameraState.playing;
    bool cam4Connected =
        manager.get(CameraId.right).status.value.state == CameraState.playing;

    final payload = jsonEncode({
      'type': 'CAM_STATUS',
      'cam1': cam1Connected,
      'cam2': cam2Connected,
      'cam3': cam3Connected,
      'cam4': cam4Connected,
    });

    _channel?.sink.add(payload);
  }

  double getNormalizedPitch(double rawPitch) {
    if (rawPitch > 0) {
      return 180.0 - rawPitch;
    } else {
      return -180.0 - rawPitch;
    }
  }

  void _handleDisconnect() {
    isConnectedToMavlink.value = false;
    _isConnecting = false;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;

    // Coba hubungkan ulang setelah 3 detik
    Future.delayed(const Duration(seconds: 3), () {
      if (!isConnectedToMavlink.value && !_isConnecting) {
        connectToMavlinkServer();
      }
    });
  }

  void dispose() {
    _channel?.sink.close();
    isConnectedToMavlink.dispose();
  }
}
