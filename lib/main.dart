// import 'package:flutter/material.dart';
// import 'package:media_kit/media_kit.dart';

// import 'pages/camera_test_page.dart';
// import 'pages/home_page.dart';
// import 'services/camera_manager.dart';
// import 'services/mediamtx_service.dart';
// import 'services/settings_manager.dart';
// import 'utils/storage_manager.dart';
// import 'utils/utils.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await StorageManager.cleanupOldVideos();

//   MediaKit.ensureInitialized();

//   await SettingsManager.instance.initialize();
//   await CameraManager.instance.initialize();

//   runApp(
//     const MaterialApp(debugShowCheckedModeBanner: false, home: HomePage()),
//   );
// }

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const SiyiTestApp());
}

class SiyiTestApp extends StatelessWidget {
  const SiyiTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIYI UDP Test GCS',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const UdpTestScreen(),
    );
  }
}

class UdpTestScreen extends StatefulWidget {
  const UdpTestScreen({super.key});

  @override
  State<UdpTestScreen> createState() => _UdpTestScreenState();
}

class _UdpTestScreenState extends State<UdpTestScreen> {
  // TODO: Ganti dengan IP Address Jetson yang terhubung ke GCS (LAN/VPN)
  final TextEditingController _ipController =
      TextEditingController(text: "192.168.137.78");

  RawDatagramSocket? _socket;
  bool _isListening = false;
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _initUdpSocket();
  }

  Future<void> _initUdpSocket() async {
    try {
      // Bind ke port lokal acak (0) agar bebas
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      setState(() {
        _isListening = true;
      });
      _addLog("Socket UDP berhasil di-bind ke port lokal: ${_socket?.port}");

      // Mendengarkan data masuk (balikan dari Jetson/Perangkat)
      _socket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          Datagram? datagram = _socket!.receive();
          if (datagram != null) {
            String hexData = datagram.data
                .map((b) => b.toRadixString(16).padLeft(2, '0'))
                .join(' ');
            _addLog(
                "📥 Terima ${datagram.data.length} bytes dari ${datagram.address.address}:${datagram.port}\n   Data (Hex): $hexData");
          }
        }
      });
    } catch (e) {
      _addLog("Gagal bind socket: $e");
    }
  }

  void _sendTestData(int targetPort, String targetName) {
    if (_socket == null) {
      _addLog("Socket belum siap!");
      return;
    }

    final ipStr = _ipController.text.trim();
    if (ipStr.isEmpty) {
      _addLog("IP Jetson belum diisi!");
      return;
    }

    try {
      final targetAddress = InternetAddress(ipStr);
      
      // Contoh paket biner dummy (bisa diganti header SIYI nantinya)
      List<int> dummyPayload = [0x55, 0xAA, 0x01, 0x02, 0x03]; 

      int bytesSent = _socket!.send(dummyPayload, targetAddress, targetPort);
      _addLog("📤 Terkirim $bytesSent bytes ke $targetName ($ipStr:$targetPort)");
    } catch (e) {
      _addLog("Gagal mengirim ke $targetName: $e");
    }
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, "[${TimeOfDay.now().format(context)}] $message");
    });
    if (kDebugMode) {
      print(message);
    }
  }

  @override
  void dispose() {
    _socket?.close();
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Uji Coba UDP Proxy SIYI (GCS)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Input IP Jetson
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'IP Address Jetson (LAN / VPN)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.router),
              ),
            ),
            const SizedBox(height: 16),

            // Status Socket
            Row(
              children: [
                Icon(
                  _isListening ? Icons.check_circle : Icons.error,
                  color: _isListening ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  _isListening ? 'UDP Socket Aktif & Siap' : 'Socket Belum Siap',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tombol Aksi Pengujian
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              onPressed: () => _sendTestData(37261, 'Kamera (.25)'),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Kirim Tes ke Kamera (Port 37261)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
              onPressed: () => _sendTestData(37262, 'AI Module (.60)'),
              icon: const Icon(Icons.psychology),
              label: const Text('Kirim Tes ke AI Module (Port 37262)'),
            ),
            const SizedBox(height: 16),

            const Text(
              'Log Aktivitas & Respon:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),

            // Area Log Konsol
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        _logs[index],
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}