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
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF1A1F2C),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "TARGET INFORMATION",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder(
            valueListenable: SiyiAiParser.targetData,
            builder: (context, data, _) {
              final bool isTracking = data.isTracking;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF131722),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isTracking
                        ? Colors.green.withAlpha(100)
                        : Colors.white10,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isTracking
                            ? Colors.green.withAlpha(30)
                            : Colors.white.withAlpha(15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.gps_fixed,
                        color: isTracking ? Colors.greenAccent : Colors.white38,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _InfoTile(label: "TYPE", value: data.targetType),
                          _InfoTile(label: "DISTANCE", value: "-"),
                          _InfoTile(
                            label: "STATUS",
                            value: isTracking ? "LOCKED" : "SEARCHING",
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const Text(
            "CAMERA CONTROL",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),

          Column(
            children: [
              // --- BARIS PERTAMA: ZOOM IN & ZOOM OUT ---
              Row(
                children: [
                  Expanded(
                    child: _ControlInkButton(
                      icon: Icons.zoom_in,
                      label: "Zoom In",
                      color: Colors.lightBlueAccent,
                      onTapDown: () =>
                          SiyiService().sendToCamera(SiyiCmd.setZoomIn),
                      onTapUp: () =>
                          SiyiService().sendToCamera(SiyiCmd.setZoomStop),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ControlInkButton(
                      icon: Icons.zoom_out,
                      label: "Zoom Out",
                      color: Colors.lightBlueAccent,
                      onTapDown: () =>
                          SiyiService().sendToCamera(SiyiCmd.setZoomOut),
                      onTapUp: () =>
                          SiyiService().sendToCamera(SiyiCmd.setZoomStop),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // --- BARIS KEDUA: GIMBAL HOME & AI MODE / CANCEL TRACKING ---
              ValueListenableBuilder(
                valueListenable: SiyiAiParser.targetData,
                builder: (_, targetData, __) {
                  final bool isTracking = targetData.isTracking;

                  return Row(
                    children: [
                      // Tombol Gimbal Home selalu ada di kiri baris kedua
                      Expanded(
                        child: _ControlInkButton(
                          icon: Icons.fullscreen_exit_outlined,
                          label: "Gimbal Home",
                          color: Colors.orangeAccent,
                          onTap: () => SiyiService().sendToCamera(
                            SiyiCmd.setGimbalCenter,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Sisi kanan baris kedua berubah dinamis (AI Mode atau Cancel Tracking)
                      Expanded(
                        child: isTracking
                            ? _ControlInkButton(
                                icon: Icons.cancel_outlined,
                                label: "Cancel Track",
                                color: Colors.redAccent,
                                isActive: true,
                                onTap: () {
                                  SiyiService().sendToAi(
                                    SiyiCmd.setTrackTarget(0, 0, 0),
                                  );
                                },
                              )
                            : ValueListenableBuilder(
                                valueListenable: SiyiAiParser.isAiMode,
                                builder: (_, isAI, __) {
                                  return _ControlInkButton(
                                    icon: Icons.view_in_ar,
                                    label: isAI ? "AI: ON" : "AI: OFF",
                                    color: isAI
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                                    isActive: isAI,
                                    onTap: () {
                                      isAI
                                          ? SiyiService().sendToAi(
                                              SiyiCmd.setAiStatus(0),
                                            )
                                          : SiyiService().sendToAi(
                                              SiyiCmd.setAiStatus(1),
                                            );
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 0.8),
            color: isActive ? color.withAlpha(50) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
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
