import 'package:flutter/material.dart';

import '../models/camera_config.dart';
import '../services/camera_manager.dart';
import '../services/settings_manager.dart';

class NetworkPanel extends StatelessWidget {
  const NetworkPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: SettingsManager.instance.cameras,
            builder: (_, cameras, _) {
              return GridView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: cameras.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.8,
                ),
                itemBuilder: (_, index) {
                  return CameraNetworkCard(config: cameras[index]);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 250,
            ), // Batasi lebar maksimal
            child: const ShipIpCard(),
          ),
        ),
      ],
    );
  }
}

class CameraNetworkCard extends StatefulWidget {
  const CameraNetworkCard({super.key, required this.config});

  final CameraConfig config;

  @override
  State<CameraNetworkCard> createState() => _CameraNetworkCardState();
}

class _CameraNetworkCardState extends State<CameraNetworkCard> {
  late final TextEditingController _urlController;
  late bool _autoConnect;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.config.rtspUrl);
    _autoConnect = widget.config.autoConnect;
  }

  @override
  void didUpdateWidget(CameraNetworkCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.config != widget.config) {
      _urlController.text = widget.config.rtspUrl;
      _autoConnect = widget.config.autoConnect;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF202535),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${widget.config.name} Camera",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Transform.rotate(
                angle: -45,
                child: const Icon(Icons.link, size: 16, color: Colors.blue),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _isEditing
                    ? TextField(
                        controller: _urlController,
                        autofocus: true,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: UnderlineInputBorder(),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white38),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.lightBlue),
                          ),
                        ),
                      )
                    : Text(
                        widget.config.rtspUrl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade300,
                          fontSize: 14,
                        ),
                      ),
              ),
              InkWell(
                onTap: () async {
                  if (_isEditing) {
                    final config = widget.config.copyWith(
                      rtspUrl: _urlController.text.trim(),
                      autoConnect: _autoConnect,
                    );

                    await CameraManager.instance.updateCamera(config);
                  }

                  setState(() {
                    _isEditing = !_isEditing;
                  });
                },
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    _isEditing ? Icons.save : Icons.edit,
                    size: 14,
                    color: _isEditing ? Colors.green : Colors.orangeAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              setState(() {
                _autoConnect = !_autoConnect;
              });
            },
            child: Row(
              children: [
                SizedBox(width: 4),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white70),
                    borderRadius: BorderRadius.circular(2),
                    color: _autoConnect ? Colors.blue : Colors.transparent,
                  ),
                  child: _autoConnect
                      ? const Icon(Icons.check, size: 9, color: Colors.white)
                      : null,
                ),

                const SizedBox(width: 8),

                const Text(
                  "Auto Connect",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ShipIpCard extends StatefulWidget {
  const ShipIpCard({super.key});

  @override
  State<ShipIpCard> createState() => _ShipIpCardState();
}

class _ShipIpCardState extends State<ShipIpCard> {
  late final TextEditingController _ipController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(
      text: SettingsManager.instance.getShipIp(),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF202535),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.router, size: 20, color: Colors.blue),
          const SizedBox(width: 10),
          const Text(
            "Ship IP:",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: SettingsManager.instance.shipIp,
              builder: (_, currentIp, _) {
                if (!_isEditing && _ipController.text != currentIp) {
                  _ipController.text = currentIp;
                }

                return _isEditing
                    ? TextField(
                        controller: _ipController,
                        autofocus: true,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: UnderlineInputBorder(),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white38),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.lightBlue),
                          ),
                        ),
                      )
                    : Text(
                        currentIp,
                        style: TextStyle(
                          color: Colors.grey.shade300,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      );
              },
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () async {
              if (_isEditing) {
                final newIp = _ipController.text.trim();
                await SettingsManager.instance.saveShipIp(newIp);
              }

              setState(() {
                _isEditing = !_isEditing;
              });
            },
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                _isEditing ? Icons.save : Icons.edit,
                size: 16,
                color: _isEditing ? Colors.green : Colors.orangeAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
