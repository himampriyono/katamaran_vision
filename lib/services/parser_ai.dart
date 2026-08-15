import 'dart:typed_data';

import 'package:flutter/material.dart';

class SiyiAiParser {
  static final ValueNotifier<String> fwVersion = ValueNotifier<String>("");
  static final ValueNotifier<bool> isAiMode = ValueNotifier<bool>(false);
  static final ValueNotifier<String> trackStatus = ValueNotifier<String>(
    "Idle",
  );
  static final ValueNotifier<int> flowState = ValueNotifier<int>(0);
  static final ValueNotifier<AiTargetData> targetData =
      ValueNotifier<AiTargetData>(const AiTargetData());

  static SiyiAiResponse? parse(Uint8List packet) {
    if (packet.length < 10) return null;
    if (packet[0] != 0x55 || packet[1] != 0x66) return null;

    int dataLen = packet[3] | (packet[4] << 8);

    if (packet.length < 7 + dataLen + 2) return null;

    int cmdId = packet[7];
    Uint8List payload = packet.sublist(8, 8 + dataLen);

    return _decodeAiPayload(cmdId, payload);
  }

  static SiyiAiResponse _decodeAiPayload(int cmdId, Uint8List payload) {
    switch (cmdId) {
      case 0x01: // Request AI Firmware Version Number
        if (payload.length >= 4) {
          int verInt =
              payload[0] |
              (payload[1] << 8) |
              (payload[2] << 16) |
              (payload[3] << 24);
          int patch = verInt & 0xFF;
          int minor = (verInt >> 8) & 0xFF;
          int major = (verInt >> 16) & 0xFF;

          String versionStr = 'v$major.$minor.$patch';
          fwVersion.value = versionStr;

          return SiyiAiResponse(
            cmdId: cmdId,
            data: {'fw_version': 'v$major.$minor.$patch'},
          );
        }
        break;

      case 0x03: // Request AI Module Identification Status
      case 0x04: // Set/Ack AI Module Identification Status
        if (payload.isNotEmpty) {
          int aiMode = payload[0];
          bool modeBool = aiMode == 1;

          isAiMode.value = modeBool;
          return SiyiAiResponse(
            cmdId: cmdId,
            data: {'ai_mode': aiMode == 1, 'status_raw': aiMode},
          );
        }
        break;

      case 0x06: // Set AI Module to Track Target (ACK Status)
        if (payload.isNotEmpty) {
          int sta = payload[0];
          // 0: setting error, 1: success, 2: not in AI mode, 3: stream not support
          String statusDesc = switch (sta) {
            0 => 'Setting Error',
            1 => 'Success (Tracking)',
            2 => 'Not in AI Mode',
            3 => 'Stream Not Support',
            _ => 'Unknown',
          };

          trackStatus.value = statusDesc;

          return SiyiAiResponse(
            cmdId: cmdId,
            data: {'status_code': sta, 'status_desc': statusDesc},
          );
        }
        break;

      case 0x08: // Obtain Coordinate Info Flow State
      case 0x09: // Set Coordinate Info Flow State
        if (payload.isNotEmpty) {
          int sta = payload[0];

          flowState.value = sta;

          return SiyiAiResponse(cmdId: cmdId, data: {'flow_state': sta});
        }

        break;

      case 0x0A: // AI Module Tracking Target Coordinate Info Stream
        debugPrint("📦 RAW 0x0A Payload (Len: ${payload.length}): $payload");
        if (payload.length >= 10) {
          int posX = payload[0] | (payload[1] << 8);
          int posY = payload[2] | (payload[3] << 8);
          int posWidth = payload[4] | (payload[5] << 8);
          int posHeight = payload[6] | (payload[7] << 8);
          int targetId = payload[8];
          int trackSta = payload[9];

          // Terjemahkan Target ID sesuai SDK
          String targetType = switch (targetId) {
            0 => 'People (Orang)',
            1 => 'Car (Mobil)',
            2 => 'Bus',
            3 => 'Truck (Truk)',
            255 => 'Arbitrary Object (Bebas)',
            _ => 'Unknown ($targetId)',
          };

          targetData.value = AiTargetData(
            targetType: targetType,
            posX: posX,
            posY: posY,
            width: posWidth,
            height: posHeight,
            trackStatus: trackSta,
          );

          return SiyiAiResponse(
            cmdId: cmdId,
            data: {
              'target_type': targetType,
              'pos_x': posX,
              'pos_y': posY,
              'width': posWidth,
              'height': posHeight,
              'track_status': trackSta,
            },
          );
        }
        break;

      default:
        // Jika ada cmdId asing yang belum terdaftar, akan masuk ke sini
        print(
          "⚠️ [IN-AI] Unknown CmdID ditemukan: 0x${cmdId.toRadixString(16).padLeft(2, '0')}",
        );
        break;
    }
    return SiyiAiResponse(cmdId: cmdId, data: {'raw_payload': payload});
  }
}

class SiyiAiResponse {
  final int cmdId;
  final Map<String, dynamic> data;

  SiyiAiResponse({required this.cmdId, required this.data});
}

class AiTargetData {
  final String targetType;
  final int posX;
  final int posY;
  final int width;
  final int height;
  final int trackStatus;

  const AiTargetData({
    this.targetType = "NONE",
    this.posX = 0,
    this.posY = 0,
    this.width = 0,
    this.height = 0,
    this.trackStatus = 0,
  });

  bool get isTracking => trackStatus == 1;
}
