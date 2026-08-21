import 'package:flutter/material.dart';
import '../services/parser_cam.dart';
import '../services/siyi_service.dart';
import '../utils/siyi_command.dart';
import '../services/parser_ai.dart'; // Pastikan path import parser AI sesuai

class CameraControlPanel extends StatefulWidget {
  const CameraControlPanel({super.key});

  @override
  State<CameraControlPanel> createState() => _CameraControlPanelState();
}

class _CameraControlPanelState extends State<CameraControlPanel> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: [
            ValueListenableBuilder(
              valueListenable: SiyiCamParser.isLrfOn,
              builder: (context, lrfOn, _) {
                final isLrfOn = lrfOn;

                return ValueListenableBuilder(
                  valueListenable: SiyiAiParser.isAiMode,
                  builder: (context, data, _) {
                    final isAiOn = data;

                    return ValueListenableBuilder<AiTargetData>(
                      valueListenable: SiyiAiParser.targetData,
                      builder: (context, data, _) {
                        final isTracking = data.isTracking;

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131722),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isTracking
                                  ? Colors.green.withAlpha(120)
                                  : Colors.white10,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    isAiOn ? data.targetType : "AI OFF",
                                    style: TextStyle(
                                      color: isAiOn ? Colors.white : Colors.red,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "TARGET TYPE",
                                    style: TextStyle(
                                      color: Colors.blueGrey,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: 12),
                              Column(
                                children: [
                                  Text(
                                    "--",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "TARGET POSITION",
                                    style: TextStyle(
                                      color: Colors.blueGrey,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: 12),
                              Column(
                                children: [
                                  ValueListenableBuilder(
                                    valueListenable: SiyiCamParser.lrfDistance,
                                    builder: (context, dist, _) {
                                      return Text(
                                        isLrfOn
                                            ? "${dist.toStringAsFixed(1)}m"
                                            : "LASER OFF",
                                        style: TextStyle(
                                          color: isLrfOn
                                              ? Colors.white
                                              : Colors.red,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "TARGET DISTANCE",
                                    style: TextStyle(
                                      color: Colors.blueGrey,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),

        // Zoom In
        _ControlIconButton(
          icon: Icons.zoom_in,
          color: Colors.lightBlueAccent,
          onTapDown: () => SiyiService().sendToCamera(SiyiCmd.setZoomIn),
          onTapUp: () => SiyiService().sendToCamera(SiyiCmd.setZoomStop),
        ),
        const SizedBox(height: 8),

        // Zoom Out
        _ControlIconButton(
          icon: Icons.zoom_out,
          color: Colors.lightBlueAccent,
          onTapDown: () => SiyiService().sendToCamera(SiyiCmd.setZoomOut),
          onTapUp: () => SiyiService().sendToCamera(SiyiCmd.setZoomStop),
        ),
        const SizedBox(height: 8),

        // Gimbal Home
        _ControlIconButton(
          icon: Icons.home,
          color: Colors.orangeAccent,
          onTap: () => SiyiService().sendToCamera(SiyiCmd.setGimbalCenter),
        ),
        const SizedBox(height: 8),

        // Toggle AI
        ValueListenableBuilder(
          valueListenable: SiyiAiParser.targetData,
          builder: (_, targetData, __) {
            final bool isTracking = targetData.isTracking;
            return Row(
              children: [
                isTracking
                    ? _ControlIconButton(
                        icon: Icons.view_in_ar,
                        color: Colors.green,
                        isActive: isTracking,
                        onTap: () {
                          SiyiService().sendToAi(
                            SiyiCmd.setTrackTarget(0, 0, 0),
                          );
                        },
                      )
                    : ValueListenableBuilder(
                        valueListenable: SiyiAiParser.isAiMode,
                        builder: (_, isAI, __) {
                          return _ControlIconButton(
                            icon: Icons.view_in_ar,
                            color: isAI ? Colors.orange : Colors.red,
                            onTap: () {
                              if (isAI) {
                                SiyiService().sendToAi(SiyiCmd.setAiStatus(0));
                                SiyiService.streamAtt = false;
                                SiyiService().disableAndStopLaser();
                              } else {
                                SiyiService().sendToAi(SiyiCmd.setAiStatus(1));
                                SiyiService.streamAtt = true;
                                SiyiService().enableAndPollLaser();
                              }
                            },
                          );
                        },
                      ),
              ],
            );
          },
        ),
        SizedBox(height: 8),
        ValueListenableBuilder(
          valueListenable: SiyiCamParser.isLrfOn,
          builder: (_, lrfOn, __) {
            final bool isLrfOn = lrfOn;

            return ValueListenableBuilder(
              valueListenable: SiyiAiParser.isAiMode,
              builder: (context, isAion, _) {
                if (isAion) return SizedBox.shrink();

                return Row(
                  children: [
                    _ControlIconButton(
                      icon: Icons.sensors,
                      color: isLrfOn ? Colors.green : Colors.red,
                      isActive: isLrfOn,
                      onTap: () {
                        if (isLrfOn) {
                          SiyiService().disableAndStopLaser();
                        } else {
                          SiyiService().enableAndPollLaser();
                        }
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _ControlIconButton extends StatelessWidget {
  const _ControlIconButton({
    required this.icon,
    required this.color,
    this.isActive = false,
    this.onTap,
    this.onTapDown,
    this.onTapUp,
  });

  final IconData icon;
  final Color color;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onTapDown;
  final VoidCallback? onTapUp;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onTapDown: onTapDown != null ? (_) => onTapDown!() : null,
      onTapUp: onTapUp != null ? (_) => onTapUp!() : null,
      onTapCancel: onTapUp != null ? () => onTapUp!() : null,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? color.withAlpha(50) : Colors.black45,
          border: Border.all(color: color, width: 0.8),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
