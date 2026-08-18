import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'services/siyi_service.dart';
import 'utils/siyi_command.dart';
import 'services/parser_cam.dart';
import 'services/parser_ai.dart';

void main() {
  runApp(const SiyiLabApp());
}

class SiyiLabApp extends StatelessWidget {
  const SiyiLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIYI Camera Testing Lab',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const SiyiLabScreen(),
    );
  }
}

class SiyiLabScreen extends StatefulWidget {
  const SiyiLabScreen({super.key});

  @override
  State<SiyiLabScreen> createState() => _SiyiLabScreenState();
}

class _SiyiLabScreenState extends State<SiyiLabScreen> {
  final TextEditingController _ipController = TextEditingController(
    text: "192.168.137.112",
  );

  final SiyiService _siyiService = SiyiService();
  final List<String> _logList = [];

  @override
  void initState() {
    super.initState();
    _startService();
  }

  void _startService() async {
    String ip = _ipController.text.trim();
    await _siyiService.init(ip);
    _addLog("SiyiService aktif terhubung ke IP: $ip");

    // Mendengarkan stream balikan data dari UDP
    _siyiService.responseStream.listen((response) {
      // Kita filter khusus yang datang dari port kamera (37261) atau cek formatnya
      if (response.sourcePort == 37261) {
        var parsedCam = SiyiCamParser.parse(Uint8List.fromList(response.data));

        if (parsedCam != null) {
          _addLog(
            "📥 [CAM PARSED] CmdID: 0x${parsedCam.cmdId.toRadixString(16).padLeft(2, '0')}\n   Data: ${parsedCam.data}",
          );
        } else {
          _addLog(
            "📥 [RAW] ${response.data.length} bytes (Gagal parse/Bukan cam)",
          );
        }
      } else if (response.sourcePort == 37262) {
        var parsedAi = SiyiAiParser.parse(Uint8List.fromList(response.data));
        // if (parsedAi != null) {
        //   _addLog(
        //     "🤖 [AI] Cmd 0x${parsedAi.cmdId.toRadixString(16).padLeft(2, '0')}: ${parsedAi.data}",
        //   );
        // }
      }
    });
  }

  void _addLog(String text) {
    setState(() {
      _logList.insert(0, "[${TimeOfDay.now().format(context)}] $text");
    });
  }

  @override
  void dispose() {
    _siyiService.dispose();
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab Pengujian Perintah Kamera SIYI'),
        backgroundColor: Colors.grey[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // IP & Reconnect
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ipController,
                    decoration: const InputDecoration(
                      labelText: 'IP Jetson',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    _siyiService.dispose();
                    _startService();
                  },
                  child: const Text('Reconnect'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Panel Tombol Uji Perintah Kamera Satu Per Satu
            const Text(
              'Uji Command Kamera:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // 1. Cek Firmware
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                  ),
                  onPressed: () {
                    _siyiService.sendToCamera(SiyiCmd.reqFwInfo);
                    _addLog("📤 [OUT] Kirim Req Firmware (0x01)");
                  },
                  child: const Text('Req Firmware (0x01)'),
                ),

                // 2. Cek Posisi Gimbal (Attitude)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[800],
                  ),
                  onPressed: () {
                    _siyiService.sendToCamera(SiyiCmd.reqGmbAtt);
                    _addLog("📤 [OUT] Kirim Req Gimbal Attitude (0x0D)");
                  },
                  child: const Text('Req Gimbal Attitude (0x0D)'),
                ),

                // 3. Cek Work Mode
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[800],
                  ),
                  onPressed: () {
                    _siyiService.sendToCamera(SiyiCmd.reqWorkMode);
                    _addLog("📤 [OUT] Kirim Req Work Mode (0x19)");
                  },
                  child: const Text('Req Work Mode (0x19)'),
                ),

                // 4. Center Gimbal
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[800],
                  ),
                  onPressed: () {
                    _siyiService.sendToCamera(SiyiCmd.setGimbalCenter);
                    _addLog("📤 [OUT] Kirim Set Gimbal Center (0x08)");
                  },
                  child: const Text('Set Gimbal Center (0x08)'),
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink[800],
                  ),
                  onPressed: () {
                    _siyiService.sendToCamera(SiyiCmd.reqZoomVal);
                    _addLog("📤 [OUT] Req Zoom Value (0x18)");
                  },
                  child: const Text('Req Zoom Value (0x18)'),
                ),

                // 6. Zoom In (Tekan sekali)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[700],
                  ),
                  onPressed: () {
                    _siyiService.sendToCamera(SiyiCmd.setZoomIn);
                    _addLog("📤 [OUT] Kirim Zoom In");
                  },
                  child: const Text('Zoom In'),
                ),

                // 7. Stop Zoom
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                  ),
                  onPressed: () {
                    _siyiService.sendToCamera(SiyiCmd.setZoomStop);
                    _addLog("📤 [OUT] Kirim Zoom Stop");
                  },
                  child: const Text('Zoom Stop'),
                ),

                // 8. Zoom Out (Tekan sekali)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple[900],
                  ),
                  onPressed: () {
                    _siyiService.sendToCamera(SiyiCmd.setZoomOut);
                    _addLog("📤 [OUT] Kirim Zoom Out");
                  },
                  child: const Text('Zoom Out'),
                ),

                // 9. Auto Focus
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[800],
                  ),
                  onPressed: () {
                    // Contoh mentarget kordinat tengah (misal X: 640, Y: 360)
                    _siyiService.sendToCamera(SiyiCmd.setAutoFocus(640, 360));
                    _addLog("📤 [OUT] Kirim Auto Focus ke (640, 360)");
                  },
                  child: const Text('Auto Focus (0x04)'),
                ),

                // Yaw Kanan (Kecepatan +50)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[700],
                  ),
                  onPressed: () {
                    _siyiService.sendToCamera(SiyiCmd.gimbalRotation(50, 0));
                    _addLog("📤 [OUT] Putar Yaw Kanan (Speed: 50)");
                  },
                  child: const Text('Yaw Kanan (50)'),
                ),

                // Yaw Kiri (Kecepatan -50)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[900],
                  ),
                  onPressed: () {
                    _siyiService.sendToCamera(SiyiCmd.gimbalRotation(-50, 0));
                    _addLog("📤 [OUT] Putar Yaw Kiri (Speed: -50)");
                  },
                  child: const Text('Yaw Kiri (-50)'),
                ),

                // Tombol Stop (Wajib dikirim untuk menghentikan rotasi)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[800],
                  ),
                  onPressed: () {
                    _siyiService.sendToCamera(SiyiCmd.gimbalRotation(0, 0));
                    _addLog("📤 [OUT] Hentikan Rotasi (0, 0)");
                  },
                  child: const Text('Stop Rotasi'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Text(
              'Uji Command Modul AI (Port 37262):',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.purpleAccent,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey[800]),
                  onPressed: () {
                    _siyiService.sendToAi (SiyiCmd.reqAiFwInfo);
                    _addLog("📤 [OUT-AI] Req AI Firmware (0x01)");
                  },
                  child: const Text('Req AI Firmware (0x01)'),
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[800],
                  ),
                  onPressed: () {
                    _siyiService.sendToAi(SiyiCmd.reqAiStatus);
                    _addLog("📤 [OUT-AI] Req AI Status (0x03)");
                  },
                  child: const Text('Req AI Status (0x03)'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[600],
                  ),
                  onPressed: () {
                    _siyiService.sendToAi(SiyiCmd.setAiStatus(1)); // ON
                    _addLog("📤 [OUT-AI] Set AI ON (0x04)");
                  },
                  child: const Text('AI ON (0x04)'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[900],
                  ),
                  onPressed: () {
                    _siyiService.sendToAi(SiyiCmd.setAiStatus(0)); // OFF
                    _addLog("📤 [OUT-AI] Set AI OFF (0x04)");
                  },
                  child: const Text('AI OFF (0x04)'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple[800],
                  ),
                  onPressed: () {
                    _siyiService.sendToAi(SiyiCmd.reqAiTrackStatus);
                    _addLog("📤 [OUT-AI] Req Track Status (0x05)");
                  },
                  child: const Text('Req Track Status (0x05)'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[800],
                  ),
                  onPressed: () {
                    // Buka stream koordinat target (Cmd 0x09, toggle: 1)
                    _siyiService.sendToAi(SiyiCmd.setAiCoordFlowState(1));
                    _addLog("📤 [OUT-AI] Open Coord Stream (0x09)");
                  },
                  child: const Text('Open Coord Stream (0x09)'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[800],
                  ),
                  onPressed: () {
                    _siyiService.sendToAi(SiyiCmd.setAiCoordFlowState(0));
                    _addLog("📤 [OUT-AI] Close Coord Stream (0x09)");
                  },
                  child: const Text('Close Coord Stream (0x09)'),
                ),

                // 1. Mulai Tracking di Titik Tengah (640, 360)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[800],
                  ),
                  onPressed: () {
                    // Kirim action 1 (Track) di titik X:640, Y:360
                    _siyiService.sendToAi(SiyiCmd.setTrackTarget(1, 640, 360));
                    _addLog(
                      "📤 [OUT-AI] Start Track Target di (640, 360) (0x06)",
                    );
                  },
                  child: const Text('Start Track (640,360)'),
                ),

                // 2. Batalkan Tracking (Cancel)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[900],
                  ),
                  onPressed: () {
                    // Kirim action 0 (Cancel)
                    _siyiService.sendToAi(SiyiCmd.setTrackTarget(0, 0, 0));
                    _addLog("📤 [OUT-AI] Cancel Track Target (0x06)");
                  },
                  child: const Text('Cancel Track (0x06)'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            const Text(
              'Live Log & Response Parser:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.greenAccent,
              ),
            ),
            const SizedBox(height: 8),

            // Area Log
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: ListView.builder(
                  itemCount: _logList.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        _logList[index],
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
