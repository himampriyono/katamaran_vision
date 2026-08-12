import 'package:flutter/material.dart';
import '../enums/camera_id.dart';

class CameraConfig {
  final CameraId id;
  final String name;
  final String rtspUrl;
  final bool autoConnect;

  const CameraConfig({
    required this.id,
    required this.name,
    required this.rtspUrl,
    required this.autoConnect,
  });

  CameraConfig copyWith({
    CameraId? id,
    String? name,
    String? rtspUrl,
    bool? autoConnect,
  }) {
    return CameraConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      rtspUrl: rtspUrl ?? this.rtspUrl,
      autoConnect: autoConnect ?? this.autoConnect,
    );
  }
}
