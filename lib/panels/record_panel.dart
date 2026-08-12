import 'package:flutter/material.dart';
import '../enums/camera_id.dart';
import '../services/camera_manager.dart';
import '../services/camera_session.dart';

class RecordPanel extends StatelessWidget {
  const RecordPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = CameraManager.instance;
    final referenceSession = manager.get(CameraId.front);

    return Padding(
      padding: const EdgeInsets.all(8),
      child: ValueListenableBuilder<bool>(
        valueListenable: referenceSession.recording.isRecording,
        builder: (_, isGlobalRecording, __) {
          return Column(
            children: [
              _buildRow(manager.get(CameraId.front), isGlobalRecording),
              const SizedBox(height: 8),
              _buildRow(manager.get(CameraId.left), isGlobalRecording),
              const SizedBox(height: 8),
              _buildRow(manager.get(CameraId.rear), isGlobalRecording),
              const SizedBox(height: 8),
              _buildRow(manager.get(CameraId.right), isGlobalRecording),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRow(CameraSession session, bool isGlobalRecording) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF202535),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(
              session.config.name.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              isGlobalRecording ? "Recording..." : "Idle",
              style: TextStyle(
                color: isGlobalRecording ? Colors.red : Colors.grey.shade400,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              isGlobalRecording ? "00:00:00" : "---",
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          InkWell(
            onTap: () {
              if (isGlobalRecording) {
                session.stopRecordingAll();
              } else {
                session.startRecordingAll();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              width: 84,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isGlobalRecording ? Colors.red : Colors.orange,
                  width: 0.5,
                ),
                color: isGlobalRecording
                    ? Colors.red.withAlpha(150)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isGlobalRecording ? Icons.stop : Icons.fiber_manual_record,
                    color: isGlobalRecording ? Colors.white : Colors.red,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isGlobalRecording ? "STOP" : "START",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
