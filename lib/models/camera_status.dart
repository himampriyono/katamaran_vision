import 'package:flutter/material.dart';
import '../enums/camera_state.dart';

class CameraStatus {
  final CameraState state;
  final String message;

  const CameraStatus({required this.state, this.message = ''});

  CameraStatus copyWith({CameraState? state, String? message}) {
    return CameraStatus(
      state: state ?? this.state,
      message: message ?? this.message,
    );
  }
}
