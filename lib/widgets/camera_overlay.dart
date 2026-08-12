import 'package:flutter/material.dart';
import '../enums/camera_state.dart';
import '../models/camera_status.dart';
import '../services/camera_session.dart';
import '../services/camera_manager.dart';

class CameraOverlay extends StatelessWidget {
  const CameraOverlay({super.key, required this.session});

  final CameraSession session;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: session.status,
      builder: (_, status, _) {
        return Column(
          children: [
            _buildTopBar(status),
            const Spacer(),
            _buildBottomBar(status),
          ],
        );
      },
    );
  }

  Widget _buildTopBar(CameraStatus status) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.config.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                  ),
                ),
              ],
            ),
          ),
          _buildRecBadge(),
        ],
      ),
    );
  }

  Widget _buildRecBadge() {
    return ValueListenableBuilder(
      valueListenable: session.recording.isRecording,
      builder: (_, recording, _) {
        if (!recording) return SizedBox();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.withAlpha(180),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 8, color: Colors.white),

              SizedBox(width: 4),

              Text(
                'REC',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(CameraStatus status) {
    final CameraManager manager = CameraManager.instance;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _statusColor(status.state),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black)],
            ),
          ),

          const SizedBox(width: 4),

          Expanded(
            child: Text(
              _statusText(status.state),
              style: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 11,
                shadows: [Shadow(color: Colors.black, blurRadius: 2)],
              ),
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(flex: 2, child: SizedBox()),

          ValueListenableBuilder(
            valueListenable: manager.fullscreenCamera,
            builder: (_, __, ___) {
              final isFullscreen = manager.isFullscreen(session.config.id);

              return GestureDetector(
                onTap: () {
                  manager.toggleFullscreen(session.config.id);
                },
                child: Icon(
                  isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  color: Colors.white,
                  size: 24,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _statusText(CameraState state) {
    switch (state) {
      case CameraState.disconnected:
        return 'Disconnected';

      case CameraState.connecting:
        return 'Connecting...';

      case CameraState.reconnecting:
        return 'Reconnecting...';

      case CameraState.playing:
        return 'Connected';

      case CameraState.error:
        return 'Connection Error';
    }
  }

  Color _statusColor(CameraState state) {
    switch (state) {
      case CameraState.playing:
        return Colors.green.shade600;

      case CameraState.connecting:
        return Colors.orange;

      case CameraState.reconnecting:
        return Colors.amber;

      case CameraState.error:
        return Colors.grey;

      case CameraState.disconnected:
        return Colors.red;
    }
  }
}
