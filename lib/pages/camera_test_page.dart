import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../enums/camera_id.dart';
import '../services/camera_manager.dart';

class CameraTestPage extends StatefulWidget {
  const CameraTestPage({super.key});

  @override
  State<CameraTestPage> createState() => _CameraTestPageState();
}

class _CameraTestPageState extends State<CameraTestPage> {
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
    final front = manager.get(CameraId.front);
    final left = manager.get(CameraId.left);
    final rear = manager.get(CameraId.rear);
    final right = manager.get(CameraId.right);

    return Scaffold(
      appBar: AppBar(title: Text("Camera Test")),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: ColoredBox(
                      color: Colors.black,
                      child: Video(
                        controller: front.videoController!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ColoredBox(
                      color: Colors.black,
                      child: Video(
                        controller: rear.videoController!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: ColoredBox(
                      color: Colors.black,
                      child: Video(
                        controller: left.videoController!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ColoredBox(
                      color: Colors.black,
                      child: Video(
                        controller: right.videoController!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
