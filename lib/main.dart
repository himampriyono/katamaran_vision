import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'pages/camera_test_page.dart';
import 'pages/home_page.dart';
import 'services/camera_manager.dart';
import 'services/mediamtx_service.dart';
import 'services/settings_manager.dart';
import 'services/siyi_service.dart';
import 'utils/storage_manager.dart';
import 'utils/utils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageManager.cleanupOldVideos();

  MediaKit.ensureInitialized();

  await SettingsManager.instance.initialize();
  final targetIp = SettingsManager.instance.getShipIp();
  await SiyiService().startService(targetIp);
  await CameraManager.instance.initialize();

  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: HomePage()),
  );
}
