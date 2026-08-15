import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../services/parser_ai.dart';
import '../services/siyi_service.dart';
import '../utils/siyi_command.dart';

class DashboardPanel extends StatefulWidget {
  const DashboardPanel({super.key});

  @override
  State<DashboardPanel> createState() => _DashboardPanelState();
}

class _DashboardPanelState extends State<DashboardPanel> {
  late StreamSubscription<SiyiResponseData> _siyiSubscribtion;
  bool _isAiActive = false;
  String _targetType = "NONE";
  String _targetPos = "0, 0";
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    _siyiSubscribtion = SiyiService().responseStream.listen((responseData) {
      final aiResponse = SiyiAiParser.parse(
        Uint8List.fromList(responseData.data),
      );

      if (aiResponse != null && aiResponse.cmdId == 0x0A) {
        setState(() {
          _isTracking = aiResponse.data['track'];
        });
      }
    });
  }

  void _toggleAi() {
    setState(() {
      _isAiActive = !_isAiActive;
    });

    SiyiService().sendToAi(SiyiCmd.setAiStatus(_isAiActive ? 1 : 0));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF1A1F2C),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ValueListenableBuilder<AiTargetData>(
            valueListenable: SiyiAiParser.targetData,
            builder: (context, data, _) {
              final isTracking = data.isTracking;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Target Info",
                    style: TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131722),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isTracking
                            ? Colors.green.withAlpha(50)
                            : Colors.white10,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isTracking
                                ? Colors.green.withAlpha(50)
                                : Colors.white.withAlpha(10),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.gps_fixed,
                            color: isTracking
                                ? Colors.greenAccent
                                : Colors.white38,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _InfoTile(label: "TYPE", value: data.targetType),
                              _InfoTile(
                                label: "POS",
                                value: "${data.posX}, ${data.posY}",
                              ),
                              _InfoTile(
                                label: "STATUS",
                                value: isTracking ? "TRACKING" : "IDLE",
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // --- CONTROL SECTION ---
          const Text(
            "CAMERA CONTROL",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ControlInkButton(
                icon: Icons.zoom_in,
                label: "Zoom In",
                color: Colors.lightBlueAccent,
                onTapDown: () => SiyiService().sendToCamera(SiyiCmd.setZoomIn),
                onTapUp: () => SiyiService().sendToCamera(SiyiCmd.setZoomStop),
              ),
              _ControlInkButton(
                icon: Icons.zoom_out,
                label: "Zoom Out",
                color: Colors.lightBlueAccent,
                onTapDown: () => SiyiService().sendToCamera(SiyiCmd.setZoomOut),
                onTapUp: () => SiyiService().sendToCamera(SiyiCmd.setZoomStop),
              ),
              _ControlInkButton(
                icon: Icons.home,
                label: "Gimbal Home",
                color: Colors.orangeAccent,
                onTap: () =>
                    SiyiService().sendToCamera(SiyiCmd.setGimbalCenter),
              ),
              _ControlInkButton(
                icon: Icons.psychology,
                label: _isAiActive ? "AI: ON" : "AI: OFF",
                color: _isAiActive ? Colors.greenAccent : Colors.redAccent,
                isActive: _isAiActive,
                onTap: _toggleAi,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ControlInkButton extends StatelessWidget {
  const _ControlInkButton({
    required this.icon,
    required this.label,
    required this.color,
    this.isActive = false,
    this.onTap,
    this.onTapDown,
    this.onTapUp,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onTapDown;
  final VoidCallback? onTapUp;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onTapDown: onTapDown != null ? (_) => onTapDown!() : null,
        onTapUp: onTapUp != null ? (_) => onTapUp!() : null,
        onTapCancel: onTapUp != null ? () => onTapUp!() : null,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 0.8),
            color: isActive ? color.withAlpha(50) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label, value;
  const _InfoTile({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );
}
