import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'parser_cam.dart';
import 'siyi_service.dart';

class MavlinkBridgeService {
  static final MavlinkBridgeService instance = MavlinkBridgeService._internal();
  factory MavlinkBridgeService() => instance;
  MavlinkBridgeService._internal();

  WebSocketChannel? _channel;
  bool _isConnecting =
      false;

  double vesselLat = 0.0;
  double vesselLon = 0.0;
  double vesselHeading = 0.0;

  // Status koneksi ke app MAVLink
  ValueNotifier<bool> isConnectedToMavlink = ValueNotifier(false);

  // 1. Hubungkan ke Server MAVLink Lokal dengan pengaman TCP check
  Future<void> connectToMavlinkServer() async {
    if (_isConnecting || isConnectedToMavlink.value) return;
    _isConnecting = true;

    try {
      // Uji koneksi TCP terlebih dahulu secara aman & non-blocking (Timeout 1 detik)
      // Ini mencegah WebSocketChannel.connect memblokir UI thread saat server mati
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

        // SETELAH DATA KAPAL DITERIMA, JALANKAN PERHITUNGAN TARGET (KODE ASLI)
        _calculateAndSendTarget();
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

    final payload = jsonEncode({
      'type': 'TARGET_COORDINATE',
      'isValid': isValid,
      'lat': targetLat,
      'lon': targetLon,
    });

    SiyiCamParser.objectPos.value = {
      'valid': isValid ? 1 : 0,
      'lat': targetLat,
      'lng': targetLon,
    };

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
