import 'package:flutter/material.dart';
import '../services/siyi_service.dart';
import '../utils/siyi_command.dart';
import '../services/parser_ai.dart'; // Pastikan path import parser AI sesuai

class CameraControlPanel extends StatefulWidget {
  const CameraControlPanel({super.key});

  @override
  State<CameraControlPanel> createState() => _CameraControlPanelState();
}

class _CameraControlPanelState extends State<CameraControlPanel> {
  bool _isAiActive = false;

  void _toggleAi() {
    setState(() {
      _isAiActive = !_isAiActive;
    });

    SiyiService().sendToAi(SiyiCmd.setAiStatus(_isAiActive ? 1 : 0));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      // decoration: BoxDecoration(
      //   color: const Color(0xFF1A1F2C).withOpacity(0.8),
      //   borderRadius: BorderRadius.circular(8),
      //   border: Border.all(color: Colors.white24, width: 0.8),
      // ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ValueListenableBuilder<AiTargetData>(
            valueListenable: SiyiAiParser.targetData,
            builder: (context, data, _) {
              final isTracking = data.isTracking;

              return Container(
                width: 140,
                padding: const EdgeInsets.all(6),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "TARGET",
                          style: TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isTracking
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.targetType,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Text(
                    //   "POS: ${data.posX}, ${data.posY}",
                    //   style: const TextStyle(
                    //     color: Colors.white70,
                    //     fontSize: 10,
                    //   ),
                    // ),
                  ],
                ),
              );
            },
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
          _ControlIconButton(
            icon: Icons.psychology,
            color: _isAiActive ? Colors.greenAccent : Colors.redAccent,
            isActive: _isAiActive,
            onTap: _toggleAi,
          ),
        ],
      ),
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
