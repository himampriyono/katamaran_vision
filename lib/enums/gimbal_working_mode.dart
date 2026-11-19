enum GimbalWorkingMode {
  lock,
  follow,
  fpv;

  String get label {
    switch (this) {
      case GimbalWorkingMode.lock:
        return 'LOCK';
      case GimbalWorkingMode.follow:
        return 'FOLLOW';
      case GimbalWorkingMode.fpv:
        return 'FPV';
    }
  }

  int get commandValue {
    switch (this) {
      case GimbalWorkingMode.lock:
        return 3;
      case GimbalWorkingMode.follow:
        return 4;
      case GimbalWorkingMode.fpv:
        return 5;
    }
  }
}
