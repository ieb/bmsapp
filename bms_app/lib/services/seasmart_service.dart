import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/models.dart';
import 'bms_service.dart';
import 'persistence_service.dart';
import 'dart:math';

class SeaSmartService implements BmsService {
  final _controller = StreamController<BmsData>.broadcast();
  ConnectionState _state = ConnectionState.disconnected;
  BmsData _lastData = BmsData.initial();
  final List<BmsData> _history = [];
  final _logsController = StreamController<List<LogEntry>>.broadcast();
  final List<LogEntry> _logs = [];
  PersistenceService? _persistence;
  DateTime? _lastUpdate;
  
  // SeaSmart Protocol Constants
  static const int _pgnDcBatteryStatus = 127508;
  static const int _pgnJbdRegisters = 130829;

  // JBD Registers (0x03)
  static const int _regVoltageU16 = 5;
  static const int _regCurrentS16 = 7;
  static const int _regSocU8 = 24;
  static const int _regNtcCountU8 = 27;
  static const int _regNtcReadingsU8 = 28;

  StreamSubscription? _streamSubscription;
  final List<int> _buffer = [];

  static final SeaSmartService _instance = SeaSmartService._internal();
  factory SeaSmartService() => _instance;
  SeaSmartService._internal();

  void init(PersistenceService persistence) {
    _persistence = persistence;
    _lastData = _lastData.copyWith(
       totalChargedAh: _persistence!.getTotalCharged(),
       totalDischargedAh: _persistence!.getTotalDischarged(),
       ovpLimit: _persistence!.getOvpLimit(),
       uvpLimit: _persistence!.getUvpLimit(),
       otpLimit: _persistence!.getOtpLimit(),
    );
     _logs.clear();
     _logs.addAll(_persistence!.loadLogs());
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

  @override
  Future<void> connect(String address) async {
    _state = ConnectionState.connecting;
    _updateData(_lastData.copyWith(connectionState: _state));

    try {
      // SeaSmart usually streams data from a URL like http://<ip>:8080/api/stream or similar.
      // Assuming 'address' is the full base URL or IP.
      final uri = Uri.parse(address.startsWith('http') ? address : 'http://$address');
      
      final request = http.Request('GET', uri);
      final response = await request.send();

      if (response.statusCode == 200) {
        _state = ConnectionState.connected;
        _updateData(_lastData.copyWith(connectionState: _state));
        
        _streamSubscription = response.stream.listen(
          (chunk) {
            _processChunk(chunk);
          },
          onError: (error) {
            debugPrint('SeaSmart Stream Error: $error');
            _disconnectWithError();
          },
          onDone: () {
            debugPrint('SeaSmart Stream Closed');
            _disconnectWithError();
          },
        );
      } else {
        debugPrint('SeaSmart Connection Failed: ${response.statusCode}');
        _disconnectWithError();
      }

    } catch (e) {
      debugPrint('SeaSmart Connection Error: $e');
      _disconnectWithError();
    }
  }

  void _disconnectWithError() {
    _state = ConnectionState.error;
    _updateData(_lastData.copyWith(connectionState: _state));
    _streamSubscription?.cancel();
  }

  void _processChunk(List<int> chunk) {
    // SeaSmart sends newline separated NMEA 0183-like sentences: $PCDIN,...
    // Append chunk to buffer
    _buffer.addAll(chunk);
    
    // Process buffer line by line
    while (true) {
        // Find newline
        final newlineIndex = _buffer.indexOf(10); // \n
        if (newlineIndex == -1) break;
        
        // Extract line
        final lineBytes = _buffer.sublist(0, newlineIndex);
        final line = String.fromCharCodes(lineBytes).trim();
        
        // Remove from buffer
        _buffer.removeRange(0, newlineIndex + 1);
        
        if (line.isNotEmpty) {
           _parseSentence(line);
        }
    }
  }

  void _parseSentence(String sentence) {
    // Format: $PCDIN,PGN,Timestamp,Source,HexStringData*Checksum
    if (!sentence.startsWith(r'$PCDIN')) return;
    
    // Checksum validation - Optional: *XX at end.
    final starIndex = sentence.lastIndexOf('*');
    if (starIndex == -1) return;
    
    final content = sentence.substring(0, starIndex);
    final parts = content.split(',');
    
    if (parts.length < 5) return;
    
    try {
      final pgn = int.tryParse(parts[1], radix: 16);
      final hexData = parts[4];
      
      if (pgn == _pgnDcBatteryStatus) { // 127508 (0x1F214)
         _decodeDcBatteryStatus(hexData);
      } else if (pgn == _pgnJbdRegisters) { // 130829 (0x1FF0D)
         _decodeJbdRegisters(hexData);
      }
    } catch (e) {
      debugPrint('Error parsing sentence: $e');
    }
  }

  // Helper to convert hex string to ByteData
  ByteData _hexToByteData(String hex) {
    if (hex.length % 2 != 0) hex = '0$hex';
    final bytes = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }

  void _decodeDcBatteryStatus(String hexData) {
     final data = _hexToByteData(hexData);
     if (data.lengthInBytes < 8) return;
     
     final voltage = data.getUint16(1, Endian.little) * 0.01;
     final current = data.getInt16(3, Endian.little) * 0.1;
     
     final newData = _lastData.copyWith(
       voltage: voltage,
       current: current,
       power: voltage * current,
       connectionState: ConnectionState.connected,
     );
     _updateData(newData);
  }

  void _decodeJbdRegisters(String hexData) {
    final data = _hexToByteData(hexData);
    // 130829 Structure: Mfr Code (2 bytes) = 0x9FFE
    if (data.lengthInBytes < 4) return;
    
    final mfrCode = data.getUint16(0, Endian.little);
    if (mfrCode != 0x9FFE) return;
    
    final register = data.getUint8(3);
    
    if (register == 0x03) {
      // Decode Reg 0x03 (Basic Info)
      if (data.lengthInBytes < _regNtcReadingsU8) return;

      final voltage = data.getUint16(_regVoltageU16, Endian.little) * 0.01;
      final current = data.getInt16(_regCurrentS16, Endian.little) * 0.01;
      final soc = data.getUint8(_regSocU8).toDouble();
      
      // Temps
      final ntcCount = data.getUint8(_regNtcCountU8);
      double temp = 0;
      if (ntcCount > 0 && data.lengthInBytes >= _regNtcReadingsU8 + 2) {
         temp = (data.getUint16(_regNtcReadingsU8, Endian.little) * 0.1) - 273.15;
      }
      
      final newData = _lastData.copyWith(
        voltage: voltage,
        current: current,
        power: voltage * current,
        soc: soc,
        temperature: temp,
        connectionState: ConnectionState.connected,
      );
      _updateData(newData);
      
    } else if (register == 0x04) {
      // Decode Reg 0x04 (Cells)
      if (data.lengthInBytes < 5) return;
      
      final byteLen = data.getUint8(4);
      final numCells = byteLen ~/ 2;
      
      List<double> cells = [];
      for (int i = 0; i < numCells; i++) {
        if (data.lengthInBytes >= 5 + (i * 2) + 2) {
           cells.add(data.getUint16(5 + i * 2, Endian.little) * 0.001);
        }
      }
      
      final newData = _lastData.copyWith(
        cellVoltages: cells,
        connectionState: ConnectionState.connected,
      );
      _updateData(newData);
    }
  }

  @override
  Future<void> disconnect() async {
     _streamSubscription?.cancel();
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
    
    // TODO: Implement actual SeaSmart (N2K/HTTP) write command if applicable
    _addLog(LogEntry(
      timestamp: DateTime.now(),
      title: 'Settings Updated',
      message: 'Protection limits updated and saved to local storage.',
      severity: LogSeverity.info,
    ));
  }
}
