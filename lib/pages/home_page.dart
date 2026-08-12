import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../enums/camera_id.dart';
import '../enums/camera_state.dart';
import '../services/camera_manager.dart';
import '../services/camera_session.dart';
import '../widgets/camera_overlay.dart';
import '../widgets/main_appbar.dart';
import '../widgets/side_panel.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CameraManager manager = CameraManager.instance;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      manager.connectAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10152B),
      appBar: const MainAppbar(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ValueListenableBuilder<CameraId?>(
              valueListenable: manager.fullscreenCamera,
              builder: (_, fullscreen, _) {
                if (fullscreen != null) {
                  return _buildFullscreen(manager.get(fullscreen));
                }

                return _buildNormalLayout(constraints);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildVideo(CameraSession session) {
    debugPrint("Build ${session.config.name}");
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: ColoredBox(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Video(
              controller: session.videoController!,
              controls: NoVideoControls,
              fit: BoxFit.contain,
            ),
            CameraOverlay(session: session),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalLayout(BoxConstraints constraints) {
    final front = manager.get(CameraId.front);
    final left = manager.get(CameraId.left);
    final rear = manager.get(CameraId.rear);
    final right = manager.get(CameraId.right);

    const spacing = 12.0;
    const padding = 8.0;
    final frontHeight = (constraints.maxHeight - 2 * padding - spacing) * 2 / 3;
    final frontWidth = frontHeight * 16 / 9;
    final bottomHeight =
        (constraints.maxHeight - 2 * padding - spacing) * 1 / 3;
    final bottomWidth = bottomHeight * 16 / 9;
    final sideWidth = constraints.maxWidth - (frontWidth + 2 * padding + spacing);

    return Padding(
      padding: const EdgeInsets.all(padding),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: frontWidth,
                height: frontHeight,
                child: _buildVideo(front),
              ),
              const SizedBox(width: spacing),
              SizedBox(
                width: sideWidth,
                height: frontHeight,
                child: const SidePanel(),
              ),
            ],
          ),
          const SizedBox(height: spacing),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: bottomWidth,
                height: bottomHeight,
                child: _buildVideo(left),
              ),

              const SizedBox(width: spacing),

              SizedBox(
                width: bottomWidth,
                height: bottomHeight,
                child: _buildVideo(rear),
              ),

              const SizedBox(width: spacing),

              SizedBox(
                width: bottomWidth,
                height: bottomHeight,
                child: _buildVideo(right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFullscreen(CameraSession session) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: _buildVideo(session),
    );
  }
}
