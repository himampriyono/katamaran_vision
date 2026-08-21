import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../utils/siyi_command.dart';
import 'parser_ai.dart';
import 'parser_cam.dart';

class SiyiService {
  SiyiService._internal() {
    initMasterPolling();
  }
  static final SiyiService _instance = SiyiService._internal();
  factory SiyiService() => _instance;

  RawDatagramSocket? _socket;
  bool _isInitialized = false;
  Timer? _masterTimer;

  static bool streamAtt = false;
  static bool streamLrf = false;

  final _responseController = StreamController<SiyiResponseData>.broadcast();
  Stream<SiyiResponseData> get responseStream => _responseController.stream;

  static const int portCameraProxy = 37261;
  static const int portAiProxy = 37262;

  String _ip = "";

  Future<void> init(String ip) async {
    _ip = ip;
    if (_isInitialized) return;

    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _isInitialized = true;
      debugPrint("SiyiService: UDP Socket bound to port ${_socket?.port}");

      _socket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          // Datagram? datagram = _socket!.receive();
          // if (datagram != null) {
          //   _responseController.add(
          //     SiyiResponseData(
          //       sourceIp: datagram.address.address,
          //       sourcePort: datagram.port,
          //       data: datagram.data,
          //     ),
          //   );
          // }
          Datagram? datagram;
          while ((datagram = _socket!.receive()) != null) {
            if (datagram != null) {
              _responseController.add(
                SiyiResponseData(
                  sourceIp: datagram.address.address,
                  sourcePort: datagram.port,
                  data: datagram.data,
                ),
              );
            }
          }
        }
      });
    } catch (e) {
      debugPrint("SiyiService Error Init: $e");
    }
  }

  Future<void> startService(String ip) async {
    await init(ip);
    debugPrint("SiyiService aktif terhubung ke IP: $ip");

    sendToAi(SiyiCmd.reqAiStatus);
    sendToAi(SiyiCmd.reqAiTrackStatus);
    sendToAi(SiyiCmd.setAiCoordFlowState(1));

    responseStream.listen((response) {
      if (response.sourcePort == 37261) {
        SiyiCamParser.parse(Uint8List.fromList(response.data));
      } else if (response.sourcePort == 37262) {
        SiyiAiParser.parse(Uint8List.fromList(response.data));
      }
    });
  }

  void sendToCamera(List<int> bytes) {
    _send(bytes, portCameraProxy, "Camera");
  }

  void sendToAi(List<int> bytes) {
    _send(bytes, portAiProxy, "AI Module");
  }

  void _send(List<int> bytes, int targetPort, String label) {
    if (_socket == null || !_isInitialized) {
      return;
    }

    try {
      final targetAddress = InternetAddress(_ip);
      int sent = _socket!.send(bytes, targetAddress, targetPort);
      debugPrint(
        "SiyiService: Terkirim $sent bytes ke $label ($_ip:$targetPort)",
      );
    } catch (e) {
      debugPrint("SiyiService Gagal Kirim ke $label: $e");
    }
  }

  Future<void> enableAndPollLaser() async {
    sendToCamera(SiyiCmd.setLaserStatus(true));

    await Future.delayed(const Duration(milliseconds: 500));

    streamLrf = true;
    sendToCamera(SiyiCmd.reqLaserStatus);
  }

  void disableAndStopLaser() async {
    streamLrf = false;
    sendToCamera(SiyiCmd.setLaserStatus(false));
    await Future.delayed(const Duration(milliseconds: 500));
    sendToCamera(SiyiCmd.reqLaserStatus);
  }

  void initMasterPolling() {
    if (_masterTimer != null && _masterTimer!.isActive) return;

    _masterTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (streamAtt) {
        sendToCamera(SiyiCmd.reqGmbAtt);
      }

      if (streamLrf) {
        sendToCamera(SiyiCmd.reqLaserRange);
      }
    });
  }

  void dispose() {
    _socket?.close();
    _responseController.close();
    _isInitialized = false;
  }
}

class SiyiResponseData {
  final String sourceIp;
  final int sourcePort;
  final List<int> data;

  SiyiResponseData({
    required this.sourceIp,
    required this.sourcePort,
    required this.data,
  });

  String get hexString {
    return data
        .map((b) {
          return b.toRadixString(16).padLeft(2, '0');
        })
        .join(' ');
  }
}
