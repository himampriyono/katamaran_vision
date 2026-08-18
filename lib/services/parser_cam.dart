import 'dart:typed_data';
import 'package:flutter/material.dart';

class SiyiCamParser {
  static final ValueNotifier<double> currentZoom = ValueNotifier<double>(1.0);

  static SiyiCamResponse? parse(Uint8List packet) {
    if (packet.length < 10) return null;
    if (packet[0] != 0x55 || packet[1] != 0x66) return null; //Validasi Header

    int dataLen = packet[3] | (packet[4] << 8);

    if (packet.length < 7 + dataLen + 2) return null;

    int cmdId = packet[7];
    Uint8List payload = packet.sublist(8, 8 + dataLen);

    return _decodePayload(cmdId, payload);
  }

  static SiyiCamResponse _decodePayload(int cmdId, Uint8List payload) {
    switch (cmdId) {
      case 0x01:
        if (payload.length >= 12) {
          int codeBoardVer = _toUint32(payload, 0);
          int gimbalVer = _toUint32(payload, 4);
          int zoomVer = _toUint32(payload, 8);

          return SiyiCamResponse(
            cmdId: cmdId,
            data: {
              'code_board': _formatVersion(codeBoardVer),
              'gimbal_fw': _formatVersion(gimbalVer),
              'zoom_fw': _formatVersion(zoomVer),
            },
          );
        }
        break;

      case 0x0D:
        if (payload.length >= 12) {
          int yaw = _toSigned16(payload[0], payload[1]);
          int pitch = _toSigned16(payload[2], payload[3]);
          int roll = _toSigned16(payload[4], payload[5]);

          int yawVel = _toSigned16(payload[6], payload[7]);
          int pitchVel = _toSigned16(payload[8], payload[9]);
          int rollVel = _toSigned16(payload[10], payload[11]);
          return SiyiCamResponse(
            cmdId: cmdId,
            data: {
              'yaw': yaw / 10.0,
              'pitch': pitch / 10.0,
              'roll': roll / 10.0,
              'yaw_velocity': yawVel / 10.0,
              'pitch_velocity': pitchVel / 10.0,
              'roll_velocity': rollVel / 10.0,
            },
          );
        }
        break;

      case 0x19:
        if (payload.isNotEmpty) {
          int mode = payload[0];
          return SiyiCamResponse(cmdId: cmdId, data: {'workMode': mode});
        }
        break;

      case 0x05: // Respon dari Manual Zoom (Format uint16_t)
        if (payload.length >= 2) {
          int rawVal = payload[0] | (payload[1] << 8);
          double zoomMultiple = rawVal / 10.0;
          currentZoom.value = zoomMultiple;
          // debugPrint("$zoomMultiple");
          return SiyiCamResponse(
            cmdId: cmdId,
            data: {'zoom_multiple': zoomMultiple},
          );
        }
        break;

      case 0x18: // Request Zoom Value (Format 2 byte terpisah: int & float)
        if (payload.length >= 2) {
          int zoomInt = payload[0];
          int zoomFloat = payload[1];
          double zoomMultiple = zoomInt + (zoomFloat / 10.0);
          return SiyiCamResponse(
            cmdId: cmdId,
            data: {'zoom_multiple': zoomMultiple},
          );
        }
        break;

      case 0x04:
        if (payload.isNotEmpty) {
          int status = payload[0];
          return SiyiCamResponse(
            cmdId: cmdId,
            data: {'auto_focus_success': status == 1},
          );
        }
        break;

      case 0x07:
        if (payload.isNotEmpty) {
          int status = payload[0];
          return SiyiCamResponse(
            cmdId: cmdId,
            data: {'rotation_success': status == 1},
          );
        }
        break;
    }

    return SiyiCamResponse(cmdId: cmdId, data: {'raw_payload': payload});
  }

  static int _toSigned16(int low, int high) {
    int value = low | (high << 8);
    if (value >= 0x8000) {
      value -= 0x10000;
    }
    return value;
  }

  static int _toUint32(Uint8List bytes, int offset) {
    return bytes[offset] |
        (bytes[offset + 1] << 8) |
        (bytes[offset + 2] << 16) |
        (bytes[offset + 3] << 24);
  }

  static String _formatVersion(int verInt) {
    int patch = verInt & 0xFF;
    int minor = (verInt >> 8) & 0xFF;
    int major = (verInt >> 16) & 0xFF;
    return "v$major.$minor.$patch";
    // return "v$major.$minor.$patch (Hex: 0x${verInt.toRadixString(16).toUpperCase()})";
  }
}

class SiyiCamResponse {
  final int cmdId;
  final Map<String, dynamic> data;

  SiyiCamResponse({required this.cmdId, required this.data});
}
