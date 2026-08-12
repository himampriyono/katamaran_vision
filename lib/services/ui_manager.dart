import 'package:flutter/foundation.dart';

enum SidePanelMode { dashboard, network, record }

class UiManager {
  UiManager._();

  static final UiManager instance = UiManager._();

  final ValueNotifier<SidePanelMode> sidePanel = ValueNotifier(
    SidePanelMode.dashboard,
  );

  void showPanel(SidePanelMode panel) {
    sidePanel.value = panel;
  }
}
