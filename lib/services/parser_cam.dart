import 'dart:typed_data';
import 'package:flutter/material.dart';

class SiyiCamParser {
  static final ValueNotifier<Map<String, double>> gimbalAttitude =
      ValueNotifier<Map<String, double>>({'yaw': 0, 'pitch': 0, 'roll': 0});
  static final ValueNotifier<double> currentZoom = ValueNotifier<double>(1.0);
  static final ValueNotifier<bool> isLrfOn = ValueNotifier<bool>(false);
  static final ValueNotifier<double> lrfDistance = ValueNotifier<double>(0.0);

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

          final attitudeData = {
            'yaw': yaw / 10.0,
            'pitch': pitch / 10.0,
            'roll': roll / 10.0,
          };

          gimbalAttitude.value = attitudeData;
          debugPrint("got att");

          return SiyiCamResponse(cmdId: cmdId, data: attitudeData);
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
          // currentZoom.value = zoomMultiple;
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

      case 0x15:
        if (payload.length >= 2) {
          int rawValue = payload[0] | (payload[1] << 8);

          double distanceInMeters = rawValue / 10.0;

          lrfDistance.value = distanceInMeters;
          debugPrint("got dist");

          return SiyiCamResponse(
            cmdId: cmdId,
            data: {'lrf_distance': distanceInMeters},
          );
        }
        break;

      case 0x31:
        if (payload.isNotEmpty) {
          bool status = payload[0] == 1;
          isLrfOn.value = status;
          return SiyiCamResponse(cmdId: cmdId, data: {'laser_state': status});
        }
        break;

      case 0x32:
        if (payload.isNotEmpty) {
          bool success = payload[0] == 1;
          return SiyiCamResponse(
            cmdId: cmdId,
            data: {'set_laser_success': success},
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
