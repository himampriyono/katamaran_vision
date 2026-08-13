import 'dart:async';

import 'package:flutter/material.dart';
import '../enums/camera_id.dart';
import '../services/camera_manager.dart';
import '../services/camera_session.dart';
import '../services/recording_manager.dart';

class RecordPanel extends StatelessWidget {
  const RecordPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = CameraManager.instance;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          _RecordRow(session: manager.get(CameraId.front)),
          const SizedBox(height: 8),
          _RecordRow(session: manager.get(CameraId.left)),
          const SizedBox(height: 8),
          _RecordRow(session: manager.get(CameraId.rear)),
          const SizedBox(height: 8),
          _RecordRow(session: manager.get(CameraId.right)),
          const SizedBox(height: 8),
          _buildAIOControl()
        ],
      ),
    );
  }
}

class _RecordRow extends StatefulWidget {
  const _RecordRow({required this.session});

  final CameraSession session;

  @override
  State<_RecordRow> createState() => _RecordRowState();
}

class _RecordRowState extends State<_RecordRow> {
  Timer? _timer;
  String _durationText = "00:00:00";

  @override
  void initState() {
    super.initState();
  }

  void _startTimer() {
    _stopTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      final startTime = RecordingManager.instance.getStartTime(
        widget.session.config.id,
      );

      if (startTime != null) {
        final elapsed = DateTime.now().difference(startTime);
        if (mounted) {
          setState(() => _durationText = _formatDuration(elapsed.inSeconds));
        }
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _durationText = "00:00:00";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final recordingMgr = RecordingManager.instance;

    return ValueListenableBuilder<Map<CameraId, DateTime?>>(
      valueListenable: RecordingManager.instance.startTimes,
      builder: (_, startTimes, _) {
        final startTime = startTimes[widget.session.config.id];
        final isRec = startTime != null;

        if (isRec && (_timer == null || !_timer!.isActive)) {
          _startTimer();
        } else if (!isRec) {
          _stopTimer();
        }

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
                  widget.session.config.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  isRec ? "Recording..." : "Idle",
                  style: TextStyle(
                    color: isRec ? Colors.red : Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  isRec ? _durationText : "---",
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              InkWell(
                onTap: () {
                  if (isRec) {
                    recordingMgr.stopCamera(widget.session.config);
                  } else {
                    recordingMgr.startCamera(widget.session.config);
                  }
                  setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  width: 84,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isRec ? Colors.red : Colors.orange,
                      width: 0.5,
                    ),
                    color: isRec
                        ? Colors.red.withAlpha(150)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isRec ? Icons.stop : Icons.fiber_manual_record,
                        color: isRec ? Colors.white : Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isRec ? "STOP" : "START",
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
      },
    );
  }
}

Widget _buildAIOControl() {
  return ValueListenableBuilder<Map<CameraId, DateTime?>>(
    valueListenable: RecordingManager.instance.startTimes,
    builder: (_, isrecord, _) {
      final recordingMgr = RecordingManager.instance;
      final isRec = CameraId.values.every(
        (id) => recordingMgr.getStartTime(id) != null,
      );

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF202535),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: () {
                if (isRec) {
                  recordingMgr.stopAllCamera();
                } else {
                  recordingMgr.startAllCamera();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                width: 120,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isRec ? Colors.red : Colors.orange,
                    width: 0.5,
                  ),
                  color: isRec ? Colors.red.withAlpha(150) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isRec ? Icons.stop : Icons.fiber_manual_record,
                      color: isRec ? Colors.white : Colors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isRec ? "STOP ALL" : "START ALL",
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
    },
  );
}
