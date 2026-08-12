import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import 'pages/camera_test_page.dart';
import 'pages/home_page.dart';
import 'services/camera_manager.dart';
import 'services/mediamtx_service.dart';
import 'services/settings_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  MediaKit.ensureInitialized();

  await SettingsManager.instance.initialize();
  // await MediaMTXService.instance.generateConfig();
  // await MediaMTXService.instance.start();
  await CameraManager.instance.initialize();

  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: HomePage()),
  );
}
