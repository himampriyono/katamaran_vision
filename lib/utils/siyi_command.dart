import 'dart:typed_data';

class SiyiCmd {
  // ==================== Camera Commands ===================

  // Req Firmware Info 0x01
  static Uint8List reqFwInfo = format(0x01);

  // Req Hardware ID 0x02
  static Uint8List reqHwId = format(0x02);

  // Set Cam Zoom In 0x05
  static Uint8List setZoomIn = format(0x05, [0x01]);

  // Set Cam Zoom Out 0x05
  static Uint8List setZoomOut = format(0x05, [0xFF]);

  // Set Cam Zoom Stop 0x05
  static Uint8List setZoomStop = format(0x05, [0x00]);

  // Req Zoom Val 0x18
  static Uint8List reqZoomVal = format(0x18);

  // Req Gimbal Attitude 0x0D
  static Uint8List reqGmbAtt = format(0x0D);

  // Set Gimbal Center 0x08
  static Uint8List setGimbalCenter = format(0x08, [0x01]);

  // Set Auto Focus
  static Uint8List setAutoFocus(int x, int y) {
    return format(0x04, [
      0x01,
      x & 0xFF,
      (x >> 8) & 0xFF,
      y & 0xFF,
      (y >> 8) & 0xFF,
    ]);
  }

  //Set Gimbal Rotation
  static Uint8List gimbalRotation(int yawSpeed, int pitchSpeed) {
    return format(0x07, [yawSpeed & 0xFF, pitchSpeed & 0xFF]);
  }

  // Set Gimbal Attitude (Yaw & Pitch)
  static Uint8List setGimbalAtt(int yaw, int pitch) {
    return format(0x0E, [
      yaw & 0xFF, (yaw >> 8) & 0xFF, // Yaw: Low byte, High byte (Little Endian)
      pitch & 0xFF,
      (pitch >> 8) & 0xFF, // Pitch: Low byte, High byte (Little Endian)
    ]);
  }

  // Req Current Work Mode 0x19
  static Uint8List reqWorkMode = format(0x19);

  // Req Gimbal Config Info 0x0A
  static Uint8List cmdReqGimbConf = format(0x0A);

  // Set Cam Capture 0x0C
  static Uint8List cmdCapture = format(0x0C, [0x00]);

  // Set Cam Record 0x0C
  static Uint8List cmdRecord = format(0x0C, [0x02]);

  // Req Temp of Point 0x12 (Thermal)
  static Uint8List requestPointTemp(int x, int y, int flag) {
    return format(0x12, [
      x & 0xFF,
      (x >> 8) & 0xFF,
      y & 0xFF,
      (y >> 8) & 0xFF,
      flag,
    ]);
  }

  // Format SD Card 0x48
  static Uint8List cmdFormatSDCard = format(0x48);

  // ===================== AI MODULE COMMANDS =========================

  // Request AI Firmware Version Number 0x01
  static Uint8List reqAiFwInfo = format(0x01);

  // Request AI Module Identification Status 0x03
  static Uint8List reqAiStatus = format(0x03);

  // Set AI Module Identification Status 0x04 (toggle: 0 = Off, 1 = On)
  static Uint8List setAiStatus(int toggle) {
    return format(0x04, [toggle]);
  }

  // Request AI Module Tracking Status 0x05
  static Uint8List reqAiTrackStatus = format(0x05);

  static Uint8List setTrackTarget(
    int trackAction,
    int x,
    int y, {
    int rx = 0,
    int ry = 0,
  }) {
    return format(0x06, [
      trackAction,
      x & 0xFF, (x >> 8) & 0xFF, // touch_lx (Low, High)
      y & 0xFF, (y >> 8) & 0xFF, // touch_ly (Low, High)
      rx & 0xFF, (rx >> 8) & 0xFF, // touch_rx (Low, High)
      ry & 0xFF, (ry >> 8) & 0xFF, // touch_ry (Low, High)
    ]);
  }

  // Obtain Coordinate Information Flow State of AI Module 0x08
  static Uint8List reqAiCoordFlowState = format(0x08);

  // Set Coordinate Information Flow State 0x09 (toggle: 1 = Open, 0 = Close)
  static Uint8List setAiCoordFlowState(int toggle) {
    return format(0x09, [toggle]);
  }

  // ===================== Core Formatter & CRC16 ================================

  static Uint8List format(int cmdId, [List<int> payload = const []]) {
    List<int> packet = [];

    // 1. Header (STX) -> 0x55, 0x66
    packet.add(0x55);
    packet.add(0x66);

    // 2. Control Byte (Data packet with ACK requested / need ack = 0x01)
    packet.add(0x01);

    // 3. Data Length (Little Endian: Low byte first, then High byte)
    int len = payload.length;
    packet.add(len & 0xFF); // Low Byte
    packet.add((len >> 8) & 0xFF); // High Byte

    // 4. Sequence (Default 0x0000)
    packet.add(0x00);
    packet.add(0x00);

    // 5. Command ID
    packet.add(cmdId);

    // 6. Payload Data
    packet.addAll(payload);

    // 7. Hitung CRC16 dari seluruh paket yang terkumpul
    int crc = _calculateCRC16(packet);

    // 8. Append CRC16 (Little Endian: Low byte first, then High byte)
    packet.add(crc & 0xFF);
    packet.add((crc >> 8) & 0xFF);

    return Uint8List.fromList(packet);
  }

  // Algoritma CCITT CRC16 standard yang digunakan SIYI
  static int _calculateCRC16(List<int> data) {
    int crc = 0x0000;

    for (int byte in data) {
      int temp = (crc >> 8) & 0xFF;
      int index = (byte ^ temp) & 0xFF;
      int oldCrc = _crc16Table[index];
      crc = ((crc << 8) & 0xFFFF) ^ oldCrc;
    }

    return crc & 0xFFFF;
  }

  static const List<int> _crc16Table = [
    0x0000,
    0x1021,
    0x2042,
    0x3063,
    0x4084,
    0x50a5,
    0x60c6,
    0x70e7,
    0x8108,
    0x9129,
    0xa14a,
    0xb16b,
    0xc18c,
    0xd1ad,
    0xe1ce,
    0xf1ef,
    0x1231,
    0x0210,
    0x3273,
    0x2252,
    0x52b5,
    0x4294,
    0x72f7,
    0x62d6,
    0x9339,
    0x8318,
    0xb37b,
    0xa35a,
    0xd3bd,
    0xc39c,
    0xf3ff,
    0xe3de,
    0x2462,
    0x3443,
    0x0420,
    0x1401,
    0x64e6,
    0x74c7,
    0x44a4,
    0x5485,
    0xa56a,
    0xb54b,
    0x8528,
    0x9509,
    0xe5ee,
    0xf5cf,
    0xc5ac,
    0xd58d,
    0x3653,
    0x2672,
    0x1611,
    0x0630,
    0x76d7,
    0x66f6,
    0x5695,
    0x46b4,
    0xb75b,
    0xa77a,
    0x9719,
    0x8738,
    0xf7df,
    0xe7fe,
    0xd79d,
    0xc7bc,
    0x48c4,
    0x58e5,
    0x6886,
    0x78a7,
    0x0840,
    0x1861,
    0x2802,
    0x3823,
    0xc9cc,
    0xd9ed,
    0xe98e,
    0xf9af,
    0x8948,
    0x9969,
    0xa90a,
    0xb92b,
    0x5af5,
    0x4ad4,
    0x7ab7,
    0x6a96,
    0x1a71,
    0x0a50,
    0x3a33,
    0x2a12,
    0xdbfd,
    0xcbdc,
    0xfbbf,
    0xeb9e,
    0x9b79,
    0x8b58,
    0xbb3b,
    0xab1a,
    0x6ca6,
    0x7c87,
    0x4ce4,
    0x5cc5,
    0x2c22,
    0x3c03,
    0x0c60,
    0x1c41,
    0xedae,
    0xfd8f,
    0xcdec,
    0xddcd,
    0xad2a,
    0xbd0b,
    0x8d68,
    0x9d49,
    0x7e97,
    0x6eb6,
    0x5ed5,
    0x4ef4,
    0x3e13,
    0x2e32,
    0x1e51,
    0x0e70,
    0xff9f,
    0xefbe,
    0xdfdd,
    0xcffc,
    0xbf1b,
    0xaf3a,
    0x9f59,
    0x8f78,
    0x9188,
    0x81a9,
    0xb1ca,
    0xa1eb,
    0xd10c,
    0xc12d,
    0xf14e,
    0xe16f,
    0x1080,
    0x00a1,
    0x30c2,
    0x20e3,
    0x5004,
    0x4025,
    0x7046,
    0x6067,
    0x83b9,
    0x9398,
    0xa3fb,
    0xb3da,
    0xc33d,
    0xd31c,
    0xe37f,
    0xf35e,
    0x02b1,
    0x1290,
    0x22f3,
    0x32d2,
    0x4235,
    0x5214,
    0x6277,
    0x7256,
    0xb5ea,
    0xa5cb,
    0x95a8,
    0x8589,
    0xf56e,
    0xe54f,
    0xd52c,
    0xc50d,
    0x34e2,
    0x24c3,
    0x14a0,
    0x0481,
    0x7466,
    0x6447,
    0x5424,
    0x4405,
    0xa7db,
    0xb7fa,
    0x8799,
    0x97b8,
    0xe75f,
    0xf77e,
    0xc71d,
    0xd73c,
    0x26d3,
    0x36f2,
    0x0691,
    0x16b0,
    0x6657,
    0x7676,
    0x4615,
    0x5634,
    0xd94c,
    0xc96d,
    0xf90e,
    0xe92f,
    0x99c8,
    0x89e9,
    0xb98a,
    0xa9ab,
    0x5844,
    0x4865,
    0x7806,
    0x6827,
    0x18c0,
    0x08e1,
    0x3882,
    0x28a3,
    0xcb7d,
    0xdb5c,
    0xeb3f,
    0xfb1e,
    0x8bf9,
    0x9bd8,
    0xabbb,
    0xbb9a,
    0x4a75,
    0x5a54,
    0x6a37,
    0x7a16,
    0x0af1,
    0x1ad0,
    0x2ab3,
    0x3a92,
    0xfd2e,
    0xed0f,
    0xdd6c,
    0xcd4d,
    0xbdaa,
    0xad8b,
    0x9de8,
    0x8dc9,
    0x7c26,
    0x6c07,
    0x5c64,
    0x4c45,
    0x3ca2,
    0x2c83,
    0x1ce0,
    0x0cc1,
    0xef1f,
    0xff3e,
    0xcf5d,
    0xdf7c,
    0xaf9b,
    0xbfba,
    0x8fd9,
    0x9ff8,
    0x6e17,
    0x7e36,
    0x4e55,
    0x5e74,
    0x2e93,
    0x3eb2,
    0x0ed1,
    0x1ef0,
  ];
}
