import 'dart:async';
import 'dart:math';
import 'persistence_service.dart';
import '../core/models.dart';

abstract class BmsService {
  Stream<BmsData> get bmsDataStream;
  BmsData get currentData;
  List<BmsData> get recentHistory;
  Stream<List<LogEntry>> get logsStream;
  List<LogEntry> get logs;
  Future<void> connect(String address);
  Future<void> disconnect();
  ConnectionState get currentState;
  void resetStats();
  Future<void> updateProtectionLimits({double? ovp, double? uvp, double? otp});
}

class MockBmsService implements BmsService {
  final _controller = StreamController<BmsData>.broadcast();
  final _logsController = StreamController<List<LogEntry>>.broadcast();
  Timer? _timer;
  ConnectionState _state = ConnectionState.disconnected;
  BmsData _lastData = BmsData.initial();
  final List<BmsData> _history = [];
  final List<LogEntry> _logs = [];
  final PersistenceService? _persistence;

  MockBmsService([this._persistence]) {
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

  @override
  Future<void> connect(String address) async {
    _state = ConnectionState.connecting;
    _updateData(_generateRandomData(_state));
    
    // Simulate connection delay
    await Future.delayed(const Duration(seconds: 1));
    _state = ConnectionState.connected;
    
    _addLog(LogEntry(
      timestamp: DateTime.now(),
      title: 'Sync Completed',
      message: 'Initial sync with SeaSmart interface successful.',
      severity: LogSeverity.info,
      secondaryStatus: 'SeaSmart Protocol',
    ));
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateData(_generateRandomData(ConnectionState.connected));
      
      // Randomly generate warnings for testing UI
      if (Random().nextDouble() < 0.05) {
        _handleRandomAlerts();
      }
    });
  }

  void _handleRandomAlerts() {
    final rand = Random().nextDouble();
    if (rand < 0.3) {
      _addLog(LogEntry(
        timestamp: DateTime.now(),
        title: 'High SOC Imbalance',
        message: 'Deviation between cell voltages exceeds 10% threshold.',
        severity: LogSeverity.warning,
        secondaryStatus: 'Maintenance Recommended',
        metadata: {'Delta': '15.2%', 'Pack SOC': '82%'},
      ));
    } else if (rand < 0.6) {
      _addLog(LogEntry(
        timestamp: DateTime.now(),
        title: 'Temp High Warning',
        message: 'Internal battery compartment ambient temperature rising.',
        severity: LogSeverity.warning,
        secondaryStatus: 'Environmental',
        metadata: {'Probe B': '48°C', 'Limit': '45°C'},
      ));
    } else {
       _addLog(LogEntry(
        timestamp: DateTime.now(),
        title: 'Cell Over-Voltage',
        message: 'High voltage detected during charging cycle.',
        severity: LogSeverity.critical,
        secondaryStatus: 'Immediate Action Required',
        metadata: {'Measured Value': '3.85V', 'Limit': '3.65V'},
      ));
    }
  }

  void _updateData(BmsData data) {
    // Accumulate stats
    double newCharged = _lastData.totalChargedAh;
    double newDischarged = _lastData.totalDischargedAh;

    if (data.current > 0) {
       newCharged += data.current * (1 / 3600); // Ah = A * (s/3600)
    } else if (data.current < 0) {
       newDischarged += data.current.abs() * (1 / 3600);
    }

    final enrichedData = data.copyWith(
      totalChargedAh: newCharged,
      totalDischargedAh: newDischarged,
    );

    _lastData = enrichedData;
    _history.add(enrichedData);
    if (_history.length > 500) _history.removeAt(0);
    _controller.add(enrichedData);

    // Periodic save
    if (_persistence != null && Random().nextDouble() < 0.05) { // ~Every 20 updates
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
  Future<void> disconnect() async {
    _timer?.cancel();
    _state = ConnectionState.disconnected;
    _updateData(_generateRandomData(_state));
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

    _addLog(LogEntry(
      timestamp: DateTime.now(),
      title: 'Settings Updated',
      message: 'Protection limits updated: OVP=${ovp?.toStringAsFixed(2) ?? _lastData.ovpLimit}, UVP=${uvp?.toStringAsFixed(2) ?? _lastData.uvpLimit}, OTP=${otp?.toStringAsFixed(0) ?? _lastData.otpLimit}',
      severity: LogSeverity.info,
    ));
  }

  BmsData _generateRandomData(ConnectionState state) {
    if (state != ConnectionState.connected) {
      return BmsData.initial();
    }

    final random = Random();
    final voltage = 13.0 + random.nextDouble(); // 13.0 - 14.0V
    final current = -10.0 + random.nextDouble() * 20.0; // -10A to +10A
    final soc = 80.0 + random.nextDouble() * 20.0;
    
    return BmsData(
      voltage: voltage,
      current: current,
      power: voltage * current,
      soc: soc,
      temperature: 25.0 + random.nextDouble() * 5.0,
      cellVoltages: List.generate(4, (_) => 3.2 + random.nextDouble() * 0.2), // 4 cells LiFePo4
      isCharging: current > 0,
      connectionState: state,
      ovpLimit: _lastData.ovpLimit,
      uvpLimit: _lastData.uvpLimit,
      otpLimit: _lastData.otpLimit,
      totalChargedAh: _lastData.totalChargedAh,
      totalDischargedAh: _lastData.totalDischargedAh,
    );
  }
}
