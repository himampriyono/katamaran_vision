import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../extensions/camera_id_extension.dart';
import '../models/camera_config.dart';
import '../utils/utils.dart';
import 'settings_manager.dart';

class MediaMTXService {
  MediaMTXService._();

  static final instance = MediaMTXService._();

  Process? _process;

  bool get isRunning => _process != null;

  Future<bool> start() async {
    if (!Utils.hasMediaMtx) {
      debugPrint("MediaMTX not found.");
      return false;
    }

    await _killExistingProcess();

    final workingDirectory = File(Utils.mediamtxPath).parent.path;

    try {
      _process = await Process.start(
        Utils.mediamtxPath,
        [],
        workingDirectory: workingDirectory,
      );

      _process!.stdout
          .transform(utf8.decoder)
          .listen((e) => debugPrint("[MediaMTX] $e"));

      _process!.stderr
          .transform(utf8.decoder)
          .listen((e) => debugPrint("[MediaMTX] $e"));

      _process!.exitCode.then((code) {
        debugPrint("[MediaMTX] Exit : $code");
        _process = null;
      });

      return true;
    } catch (e) {
      debugPrint('[MediaMTX] Failed to start: $e');
      _process = null;
      return false;
    }
  }

  Future<void> stop() async {
    final process = _process;

    if (process == null) {
      return;
    }

    debugPrint('[MediaMTX] Stopping PID: ${process.pid}');

    process.kill();

    final code = await process.exitCode;

    debugPrint('[MediaMTX] Exit: $code');

    if (identical(_process, process)) {
      _process = null;
    }
  }

  Future<void> restart() async {
    await stop();
    await start();
  }

  Future<void> _killExistingProcess() async {
    if (Platform.isWindows) {
      await Process.run('taskkill', ['/IM', 'mediamtx.exe', '/F']);
    } else if (Platform.isLinux) {
      await Process.run('pkill', ['-x', 'mediamtx']);
    }
  }

  Future<void> generateConfig() async {
    final configFile = File(
      path.join(File(Utils.mediamtxPath).parent.path, 'mediamtx.yml'),
    );

    final buffer = StringBuffer();

    buffer.writeln('api: yes');
    buffer.writeln();
    buffer.writeln('paths:');

    for (final camera in SettingsManager.instance.cameras.value) {
      if (camera.rtspUrl.trim().isEmpty) {
        continue;
      }

      buffer.writeln('  ${camera.id.key}:');
      buffer.writeln('    source: ${camera.rtspUrl}');
      buffer.writeln('    rtspTransport: tcp');
      buffer.writeln();
    }

    await configFile.writeAsString(buffer.toString());
    debugPrint('MediaMTX config generated');
  }

  Future<bool> updatePath(CameraConfig config) async {
    final client = HttpClient();

    try {
      final pathName = config.id.key;

      final uri = Uri.parse(
        'http://127.0.0.1:9997/v3/config/paths/patch/$pathName',
      );

      final request = await client.patchUrl(uri);

      request.headers.contentType = ContentType.json;

      request.write(jsonEncode({'source': config.rtspUrl}));

      final response = await request.close();

      final body = await response.transform(utf8.decoder).join();

      debugPrint(
        '[MediaMTX] Update ${config.id.key}: '
        '${response.statusCode} $body',
      );

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('[MediaMTX] Failed to update ${config.id.key}: $e');
      return false;
    } finally {
      client.close();
    }
  }
}
