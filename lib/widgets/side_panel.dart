import 'package:flutter/material.dart';
import '../panels/record_panel.dart';
import '../panels/settings_panel.dart';
import '../services/ui_manager.dart';
import '../panels/dashboard_panel.dart';
import '../panels/network_panel.dart';

class SidePanel extends StatelessWidget {
  const SidePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF181C2A),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const Divider(height: 1),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return ValueListenableBuilder(
      valueListenable: UiManager.instance.sidePanel,
      builder: (_, mode, _) {
        return Padding(
          padding: const EdgeInsetsGeometry.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  switch (mode) {
                    SidePanelMode.dashboard => "Dashboard",
                    SidePanelMode.network => "Network",
                    SidePanelMode.record => "Record",
                    SidePanelMode.settings => "Settings",
                  },
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildPanelButton(
                Icons.space_dashboard,
                SidePanelMode.dashboard,
                mode,
              ),
              const SizedBox(width: 4),
              _buildPanelButton(Icons.link, SidePanelMode.network, mode),
              const SizedBox(width: 4),
              _buildPanelButton(
                Icons.videocam_outlined,
                SidePanelMode.record,
                mode,
              ),
              const SizedBox(width: 4),
              _buildPanelButton(
                Icons.settings,
                SidePanelMode.settings,
                mode,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPanelButton(
    IconData icon,
    SidePanelMode panel,
    SidePanelMode current,
  ) {
    final selected = current == panel;

    return IconButton(
      onPressed: () {
        UiManager.instance.showPanel(panel);
      },
      icon: Icon(
        icon,
        size: 18,
        color: selected ? Colors.lightBlueAccent : Colors.white54,
      ),
      splashRadius: 18,
      tooltip: panel.name,
    );
  }

  Widget _buildContent() {
    return ValueListenableBuilder(
      valueListenable: UiManager.instance.sidePanel,
      builder: (_, mode, _) {
        switch (mode) {
          case SidePanelMode.dashboard:
            return const DashboardPanel();
          case SidePanelMode.network:
            return const NetworkPanel();
          case SidePanelMode.record:
            return const RecordPanel();
          case SidePanelMode.settings:
            return const SettingsPanel();
        }
      },
    );
  }
}
