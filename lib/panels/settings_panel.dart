import 'package:flutter/material.dart';
import '../services/settings_manager.dart'; // Sesuaikan path import dengan project kamu

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF1A1F2C),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- HEADER ---
          const Text(
            "APPLICATION SETTINGS",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: 1,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // --- SHIP IP SETTING ---
          const Text(
            "Ship IP Address",
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 6),
          ValueListenableBuilder<String>(
            valueListenable: SettingsManager.instance.shipIp,
            builder: (context, ip, _) {
              // Kita buat controller lokal atau text field sederhana
              final ipController = TextEditingController(text: ip);
              ipController.selection = TextSelection.fromPosition(
                TextPosition(offset: ipController.text.length),
              );

              return TextField(
                controller: ipController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFF131722),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Colors.lightBlueAccent),
                  ),
                ),
                onSubmitted: (newIp) {
                  if (newIp.isNotEmpty) {
                    SettingsManager.instance.saveShipIp(newIp);
                  }
                },
              );
            },
          ),
          const SizedBox(height: 20),

          // --- PAN SENSITIVITY SETTING ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Gimbal Pan Sensitivity",
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
              ValueListenableBuilder<double>(
                valueListenable: SettingsManager.instance.panSensitivity,
                builder: (context, sensitivity, _) {
                  return Text(
                    sensitivity.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.lightBlueAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          ValueListenableBuilder<double>(
            valueListenable: SettingsManager.instance.panSensitivity,
            builder: (context, sensitivity, _) {
              return Slider(
                value: sensitivity,
                min: 4.0,
                max: 15.0,
                divisions: 20, // Interval 0.5
                activeColor: Colors.lightBlueAccent,
                inactiveColor: Colors.white24,
                onChanged: (newValue) {
                  SettingsManager.instance.savePanSensitivity(newValue);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
