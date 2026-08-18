import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:async';

class SiyiAiParser {
  // ValueNotifiers untuk State Management UI
  static final ValueNotifier<String> fwVersion = ValueNotifier<String>("");
  static final ValueNotifier<bool> isAiMode = ValueNotifier<bool>(false);
  static final ValueNotifier<int> trackStatus = ValueNotifier<int>(0);
  static final ValueNotifier<int> flowState = ValueNotifier<int>(0);
  static final ValueNotifier<AiTargetData> targetData =
      ValueNotifier<AiTargetData>(const AiTargetData());

  static String _lastTargetType = "NONE";
  static int _lastTrackStatus = 0;
  static DateTime _lastParseTime = DateTime.now();
  static Timer? _targetTimeoutTimer;

  static const int _payloadOffset = 8;

  static void parse(Uint8List packet) {
    try {
      if (packet.length < 10) return;
      if (packet[0] != 0x55 || packet[1] != 0x66) return;

      final int dataLen = packet[3] | (packet[4] << 8);
      if (packet.length < _payloadOffset + dataLen) return;

      final int cmdId = packet[7];

      switch (cmdId) {
        case 0x01: // Firmware Version (Butuh 4 bytes)
          if (dataLen >= 4 && packet.length >= _payloadOffset + 4) {
            int verInt =
                packet[8] |
                (packet[9] << 8) |
                (packet[10] << 16) |
                (packet[11] << 24);
            int patch = verInt & 0xFF;
            int minor = (verInt >> 8) & 0xFF;
            int major = (verInt >> 16) & 0xFF;

            fwVersion.value = 'v$major.$minor.$patch';
          }
          break;

        case 0x03: // Req AI Status
        case 0x04:
          if (dataLen >= 1 && packet.length >= _payloadOffset + 1) {
            isAiMode.value = packet[8] == 1;
          }
          break;

        case 0x05:
          if (dataLen >= 1 && packet.length >= _payloadOffset + 1) {
            int sta = packet[8];
            if (sta != 1) {
              targetData.value = const AiTargetData();
              _lastTargetType = "NONE";
              _lastTrackStatus = 0;
            }
            trackStatus.value = sta;
          }
          break;

        case 0x08:
        case 0x09:
          if (dataLen >= 1 && packet.length >= _payloadOffset + 1) {
            flowState.value = packet[8];
          }
          break;

        case 0x0A:
          // debugPrint("got 0x0A");
          _targetTimeoutTimer?.cancel();

          _targetTimeoutTimer = Timer(const Duration(seconds: 2), () {
            targetData.value = const AiTargetData();
          });

          if (dataLen >= 10 && packet.length >= _payloadOffset + 10) {
            final now = DateTime.now();
            if (now.difference(_lastParseTime).inMilliseconds < 100) {
              return;
            }
            _lastParseTime = now;
            int targetId = packet[16];
            int sta = packet[17];

            String tType = switch (targetId) {
              0 => 'People',
              1 => 'Car',
              2 => 'Bus',
              3 => 'Truck',
              255 => 'Custom Object',
              _ => 'Unknown ($targetId)',
            };

            targetData.value = AiTargetData(
              targetType: tType,
              trackStatus: sta,
            );
          }
          break;
        // return;

        default:
          break;
      }
    } catch (_) {
      // Abaikan jika ada paket rusak/korup di jaringan
    }
  }
}

class AiTargetData {
  final String targetType;
  final int trackStatus;

  const AiTargetData({this.targetType = "NONE", this.trackStatus = 3});

  bool get isTracking => trackStatus == 0 || trackStatus == 4;
}
