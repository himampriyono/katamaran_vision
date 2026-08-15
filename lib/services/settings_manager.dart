import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../enums/camera_id.dart';
import '../extensions/camera_id_extension.dart';
import '../models/camera_config.dart';
import 'mediamtx_service.dart';

class SettingsManager {
  SettingsManager._();

  static final SettingsManager instance = SettingsManager._();

  final ValueNotifier<List<CameraConfig>> cameras =
      ValueNotifier<List<CameraConfig>>([]);

  final ValueNotifier<String> shipIp = ValueNotifier<String>("192.168.137.78");

  late SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    if (!_prefs.containsKey("ship_ip")) {
      await _prefs.setString("ship_ip", "192.168.137.78");
    }
    shipIp.value = _prefs.getString("ship_ip") ?? "192.168.137.78";

    if (!_prefs.containsKey("camera_${CameraId.front.key}_name")) {
      await reset();
      return;
    }

    cameras.value = CameraId.values.map(_loadCamera).toList();
  }

  String getShipIp() {
    return shipIp.value;
  }

  Future<void> saveShipIp(String ip) async {
    shipIp.value = ip;
    await _prefs.setString("ship_ip", ip);
  }

  CameraConfig getCamera(CameraId id) {
    return cameras.value.firstWhere((camera) => camera.id == id);
  }

  Future<void> saveCamera(CameraConfig config) async {
    final index = cameras.value.indexWhere((e) => e.id == config.id);

    if (index == -1) return;

    final list = List<CameraConfig>.from(cameras.value);
    list[index] = config;
    cameras.value = list;

    await _saveCamera(config);

    await MediaMTXService.instance.updatePath(config);
  }

  Future<void> reset() async {
    final configs = CameraId.values.map(_defaultCamera).toList();

    cameras.value = configs;

    for (final config in configs) {
      await _saveCamera(config);
    }

    await saveShipIp("192.168.137.78");
  }

  CameraConfig _loadCamera(CameraId id) {
    return CameraConfig(
      id: id,
      name: _prefs.getString("camera_${id.key}_name") ?? id.defaultName,
      rtspUrl: _prefs.getString("camera_${id.key}_rtsp") ?? "",
      autoConnect: _prefs.getBool("camera_${id.key}_auto") ?? true,
    );
  }

  Future<void> _saveCamera(CameraConfig config) async {
    await _prefs.setString("camera_${config.id.key}_name", config.name);

    await _prefs.setString("camera_${config.id.key}_rtsp", config.rtspUrl);

    await _prefs.setBool("camera_${config.id.key}_auto", config.autoConnect);
  }

  CameraConfig _defaultCamera(CameraId id) {
    return CameraConfig(
      id: id,
      name: id.defaultName,
      rtspUrl: "",
      autoConnect: true,
    );
  }
}
