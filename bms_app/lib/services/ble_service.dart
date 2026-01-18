import 'dart:async';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/foundation.dart';
import '../core/models.dart';
import 'bms_service.dart';
import 'persistence_service.dart';
import 'dart:math';

class BleBmsService implements BmsService {
  final _controller = StreamController<BmsData>.broadcast();
  ConnectionState _state = ConnectionState.disconnected;
  BmsData _lastData = BmsData.initial();
  final _logsController = StreamController<List<LogEntry>>.broadcast();
  final List<LogEntry> _logs = [];
  DateTime? _lastUpdate;
  
  BluetoothDevice? _device;
  StreamSubscription? _connectionSubscription;
  final List<BmsData> _history = [];
  final PersistenceService? _persistence;

  BleBmsService([this._persistence]) {
    if (_persistence != null) {
       _lastData = _lastData.copyWith(
          totalChargedAh: _persistence!.getTotalCharged(),
          totalDischargedAh: _persistence!.getTotalDischarged(),
          ovpLimit: _persistence!.getOvpLimit(),
          uvpLimit: _persistence!.getUvpLimit(),
          otpLimit: _persistence!.getOtpLimit(),
       );
       _logs.addAll(_persistence!.loadLogs());
    }
  }

  @override
  Stream<BmsData> get bmsDataStream => _controller.stream;

  @override
  BmsData get currentData => _lastData;

  @override
  List<BmsData> get recentHistory => List.unmodifiable(_history);

  @override
  Stream<List<LogEntry>> get logsStream => _logsController.stream;

  @override
  List<LogEntry> get logs => List.unmodifiable(_logs);

  @override
  ConnectionState get currentState => _state;
  
  // JBD / Xiaoxiang BMS UUIDs
  static const String _serviceUuid = '0000ff00-0000-1000-8000-00805f9b34fb';
  static const String _rxCharUuid = '0000ff01-0000-1000-8000-00805f9b34fb'; // Notification
  static const String _txCharUuid = '0000ff02-0000-1000-8000-00805f9b34fb'; // Write

  // Commands
  static final List<int> _cmdBasicInfo = [0xDD, 0xA5, 0x03, 0x00, 0xFF, 0xFD, 0x77];
  static final List<int> _cmdCellInfo = [0xDD, 0xA5, 0x04, 0x00, 0xFF, 0xFC, 0x77];

  BluetoothCharacteristic? _txCharacteristic;
  final List<int> _incomingBuffer = [];
  Timer? _pollingTimer;

  // ... (existing scan methods)
  Stream<List<ScanResult>> startScan() {
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
       try {
         FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
       } catch (e) {
         debugPrint('Error starting scan: $e');
       }
    }
    return FlutterBluePlus.scanResults;
  }
  
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  @override
  Future<void> connect(String address) async {
    _state = ConnectionState.connecting;
    _updateData(_lastData.copyWith(connectionState: _state));

    try {
      await stopScan();
      
      final device = BluetoothDevice.fromId(address);
      _device = device;
      
      await device.connect(autoConnect: false);
      
      _connectionSubscription = device.connectionState.listen((BluetoothConnectionState state) {
        if (state == BluetoothConnectionState.connected) {
          _state = ConnectionState.connected;
          _discoverServices(device);
        } else if (state == BluetoothConnectionState.disconnected) {
          _state = ConnectionState.disconnected;
          _pollingTimer?.cancel();
          _updateData(_lastData.copyWith(connectionState: _state));
        }
        _updateData(_lastData.copyWith(connectionState: _state));
      });

    } catch (e) {
      debugPrint('Connection Error: $e');
      _state = ConnectionState.error;
      _updateData(_lastData.copyWith(connectionState: _state));
    }
  }

  Future<void> _discoverServices(BluetoothDevice device) async {
    try {
      List<BluetoothService> services = await device.discoverServices();
      BluetoothService? bmsService;
      
      for (var s in services) {
        if (s.uuid.toString() == _serviceUuid) {
          bmsService = s;
          break;
        }
      }

      if (bmsService != null) {
        for (var c in bmsService.characteristics) {
          if (c.uuid.toString() == _rxCharUuid) {
            await c.setNotifyValue(true);
            c.onValueReceived.listen(_onDataReceived);
          } else if (c.uuid.toString() == _txCharUuid) {
            _txCharacteristic = c;
          }
        }
        
        // Start polling
        _startPolling();
      } else {
        debugPrint('BMS Service not found');
      }
    } catch (e) {
      debugPrint('Service Discovery Error: $e');
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    bool toggle = false;
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_txCharacteristic != null) {
        final cmd = toggle ? _cmdCellInfo : _cmdBasicInfo;
        _txCharacteristic!.write(cmd, withoutResponse: true);
        toggle = !toggle;
      }
    });
  }

  void _onDataReceived(List<int> data) {
    // Basic Packet Reassembly (Start 0xDD, Stop 0x77)
    // Simply append and check for complete packet for now
    _incomingBuffer.addAll(data);
    
    // Check for Start Byte
    int startIndex = _incomingBuffer.indexOf(0xDD);
    if (startIndex == -1) {
      _incomingBuffer.clear(); // No start byte, garbage
      return;
    }
    
    // Check for Stop Byte after Start Byte
    int stopIndex = _incomingBuffer.indexOf(0x77, startIndex);
    
    if (stopIndex != -1) {
      // We have a potential packet
      final packet = _incomingBuffer.sublist(startIndex, stopIndex + 1);
      
      // Process if valid check
      if (_validateChecksum(packet)) {
        _parsePacket(packet);
      }
      
      // Remove processed data from buffer
      _incomingBuffer.removeRange(0, stopIndex + 1);
    }
  }

  bool _validateChecksum(List<int> packet) {
    // Length check
    if (packet.length < 7) return false;
    
    // Payload is at index 4, length is at index 3?
    // JS: msg.slice(4, msg.length-3)
    // Structure: [DD, CMD, STATUS, LEN, DATA..., CHK1, CHK2, 77]
    
    // Verify length byte? packet[3] should match data length
    int dataLen = packet[3];
    if (packet.length != dataLen + 7) return false; // Basic length validation
    
    int sum = 0;
    for (int i = 4; i < packet.length - 3; i++) {
        sum += packet[i];
    }
    
    int checksum = 0x10000 - (sum + dataLen); // Note: JS uses dataLen (msg[3]) in sum logic: sumOfPayload+msg[3]
    
    int highByte = (checksum & 0xFF00) >> 8;
    int lowByte = (checksum & 0xFF);
    
    return highByte == packet[packet.length - 3] && lowByte == packet[packet.length - 2];
  }

  void _parsePacket(List<int> packet) {
    final cmd = packet[1];
    final data = packet.sublist(4, packet.length - 3);
    final byteData = ByteData.sublistView(Uint8List.fromList(data));

    if (cmd == 0x03) {
      if (data.length < 22) return; // Basic validation for minimum length

      // 0x00: Voltage U16 10mV
      final voltage = byteData.getUint16(0) * 0.01;
      // 0x02: Current S16 10mA
      final current = byteData.getInt16(2) * 0.01;
      // 0x04: Balance Cap U16 10mAh
      final balCap = byteData.getUint16(4) * 0.01;
      // 0x06: Nominal Cap U16 10mAh
      final nomCap = byteData.getUint16(6) * 0.01;
      // 0x08: Cycles U16
      final cycles = byteData.getUint16(8);
      // 0x0A: Date U16
      final date = _parseDate(byteData.getUint16(10));
      // 0x0C: Balance Status Low U16
      final balLow = byteData.getUint16(12);
      // 0x0E: Balance Status High U16
      final balHigh = byteData.getUint16(14);
      // 0x10: Protection Status U16
      final protectRaw = byteData.getUint16(16);
      final protectList = _parseProtection(protectRaw);
      // 0x12: Version U8
      final version = data[18] / 10.0; // Assuming 0x10 = 1.0
      // 0x13: SoC U8
      final soc = data[19].toDouble();
      // 0x14: FET Status U8
      final fetByte = data[20];
      final fetCharge = (fetByte & 1) != 0;
      final fetDischarge = (fetByte & 2) != 0;
      // 0x15: Cell Count U8
      // final cellCount = data[21];
      // 0x16: NTC Count U8
      final ntcCount = data[22];
      
      // Parse Temps (starting at 23)
      double temp = 0;
      if (ntcCount > 0 && data.length >= 23 + (ntcCount * 2)) {
         // Reading first NTC for main temp display
         // Unit 0.1K. Kelvin = Celsius + 273.15
         // TempC = (Val * 0.1) - 273.15
         temp = (byteData.getUint16(23) * 0.1) - 273.15;
      }

      final newData = _lastData.copyWith(
        voltage: voltage,
        current: current,
        power: voltage * current,
        soc: soc,
        temperature: temp,
        balanceCapacity: balCap,
        nominalCapacity: nomCap,
        cycleCount: cycles,
        manufactureDate: date,
        protectionStatus: protectList,
        protectionStatusRaw: protectRaw,
        version: version,
        mosfetCharge: fetCharge,
        mosfetDischarge: fetDischarge,
        balanceStatusLow: balLow,
        balanceStatusHigh: balHigh,
        connectionState: ConnectionState.connected,
      );
      _updateData(newData);

    } else if (cmd == 0x04) {
      if (packet.length < 4) return;
      // Length is at index 3
      int numCells = packet[3] ~/ 2;
      
      // Safety check against buffer overread if packet was truncated
      if (data.length < numCells * 2) {
         numCells = data.length ~/ 2;
      }

      List<double> cells = [];
      for (int i = 0; i < numCells; i++) {
        cells.add(byteData.getUint16(i * 2) * 0.001); // mV -> V
      }
      
      final newData = _lastData.copyWith(
        cellVoltages: cells,
        connectionState: ConnectionState.connected,
      );
      _updateData(newData);
    }
  }

  DateTime _parseDate(int dateRaw) {
    // bits 15:9 = year - 2000
    // bits 8:5 = month
    // bits 4:0 = day
    final year = (dateRaw >> 9) + 2000;
    final month = (dateRaw >> 5) & 0x0F;
    final day = dateRaw & 0x1F;
    try {
      return DateTime(year, month == 0 ? 1 : month, day == 0 ? 1 : day);
    } catch (e) {
      return DateTime.now(); // Fallback
    }
  }

  List<bool> _parseProtection(int raw) {
    // bit 0: Cell overvolt
    // bit 1: Cell undervolt
    // ... (up to 12 bits defined in spec)
    List<bool> flags = [];
    for (int i = 0; i < 16; i++) {
      flags.add((raw & (1 << i)) != 0);
    }
    return flags;
  }

  @override
  Future<void> disconnect() async {
    _pollingTimer?.cancel();
    await _device?.disconnect();
    await _connectionSubscription?.cancel();
    _state = ConnectionState.disconnected;
    _updateData(_lastData.copyWith(connectionState: _state));
  }

  void _updateData(BmsData data) {
    // Accumulate stats based on time delta
    final now = DateTime.now();
    double newCharged = _lastData.totalChargedAh;
    double newDischarged = _lastData.totalDischargedAh;

    if (_lastUpdate != null) {
       final deltaSeconds = now.difference(_lastUpdate!).inMilliseconds / 1000.0;
       if (data.current > 0) {
          newCharged += data.current * (deltaSeconds / 3600);
       } else if (data.current < 0) {
          newDischarged += data.current.abs() * (deltaSeconds / 3600);
       }
    }
    _lastUpdate = now;

    final enrichedData = data.copyWith(
      totalChargedAh: newCharged,
      totalDischargedAh: newDischarged,
    );

    _lastData = enrichedData;
    _history.add(enrichedData);
    if (_history.length > 500) _history.removeAt(0);
    _controller.add(enrichedData);

    // Periodic save
    if (_persistence != null && Random().nextDouble() < 0.05) {
       _persistence!.setTotalCharged(newCharged);
       _persistence!.setTotalDischarged(newDischarged);
    }
  }

  void _addLog(LogEntry log) {
    _logs.insert(0, log); // Newest first
    if (_logs.length > 100) _logs.removeLast();
    _logsController.add(_logs);
    
    if (_persistence != null) {
       _persistence!.saveLogs(_logs);
    }
  }

  @override
  void resetStats() {
    _lastData = _lastData.copyWith(
      totalChargedAh: 0,
      totalDischargedAh: 0,
    );
    _controller.add(_lastData);
    if (_persistence != null) {
       _persistence!.setTotalCharged(0);
       _persistence!.setTotalDischarged(0);
    }
  }

  @override
  Future<void> updateProtectionLimits({double? ovp, double? uvp, double? otp}) async {
    _lastData = _lastData.copyWith(
      ovpLimit: ovp,
      uvpLimit: uvp,
      otpLimit: otp,
    );
    _controller.add(_lastData);
    
    if (_persistence != null) {
      if (ovp != null) await _persistence!.setOvpLimit(ovp);
      if (uvp != null) await _persistence!.setUvpLimit(uvp);
      if (otp != null) await _persistence!.setOtpLimit(otp);
    }
    
    // TODO: Implement actual BLE write command for protection limits
    _addLog(LogEntry(
      timestamp: DateTime.now(),
      title: 'Settings Updated',
      message: 'Protection limits updated and saved to local storage.',
      severity: LogSeverity.info,
    ));
  }
}


