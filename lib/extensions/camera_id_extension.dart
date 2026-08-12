import '../enums/camera_id.dart';

extension CameraIdExtension on CameraId {
  String get key {
    switch (this) {
      case CameraId.front:
        return 'front';

      case CameraId.rear:
        return 'rear';

      case CameraId.left:
        return 'left';

      case CameraId.right:
        return 'right';
    }
  }

  String get defaultName {
    switch (this) {
      case CameraId.front:
        return 'Front';

      case CameraId.rear:
        return 'Rear';

      case CameraId.left:
        return 'Left';

      case CameraId.right:
        return 'Right';
    }
  }
}