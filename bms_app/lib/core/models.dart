class BmsData {
  final double voltage;
  final double current;
  final double power;
  final double soc;
  final double temperature;
  final List<double> cellVoltages;
  final bool isCharging;
  final double balanceCapacity;
  final double nominalCapacity;
  final int cycleCount;
  final DateTime? manufactureDate;
  final List<bool> protectionStatus; // Decoded bits
  final int protectionStatusRaw; // Raw bits
  final double version;
  final bool mosfetCharge;
  final bool mosfetDischarge;
  final int balanceStatusLow;
  final int balanceStatusHigh;
  final ConnectionState connectionState;
  final double totalChargedAh;
  final double totalDischargedAh;
  final double ovpLimit;
  final double uvpLimit;
  final double otpLimit;

  BmsData({
    required this.voltage,
    required this.current,
    required this.power,
    required this.soc,
    required this.temperature,
    required this.cellVoltages,
    required this.isCharging,
    this.balanceCapacity = 0,
    this.nominalCapacity = 0,
    this.cycleCount = 0,
    this.manufactureDate,
    this.protectionStatus = const [],
    this.protectionStatusRaw = 0,
    this.version = 0,
    this.mosfetCharge = false,
    this.mosfetDischarge = false,
    this.balanceStatusLow = 0,
    this.balanceStatusHigh = 0,
    required this.connectionState,
    this.totalChargedAh = 0,
    this.totalDischargedAh = 0,
    this.ovpLimit = 3.65,
    this.uvpLimit = 2.50,
    this.otpLimit = 65,
  });

  factory BmsData.initial() {
    return BmsData(
      voltage: 0,
      current: 0,
      power: 0,
      soc: 0,
      temperature: 0,
      cellVoltages: [],
      isCharging: false,

      connectionState: ConnectionState.disconnected,
      balanceCapacity: 0,
      nominalCapacity: 0,
      cycleCount: 0,
      manufactureDate: null,
      protectionStatus: [],
      protectionStatusRaw: 0,
      version: 0,
      mosfetCharge: false,
      mosfetDischarge: false,
      balanceStatusLow: 0,
      balanceStatusHigh: 0,
      totalChargedAh: 0,
      totalDischargedAh: 0,
      ovpLimit: 3.65,
      uvpLimit: 2.50,
      otpLimit: 65,
    );
  }

  BmsData copyWith({
    double? voltage,
    double? current,
    double? power,
    double? soc,
    double? temperature,
    List<double>? cellVoltages,
    bool? isCharging,

    ConnectionState? connectionState,
    double? balanceCapacity,
    double? nominalCapacity,
    int? cycleCount,
    DateTime? manufactureDate,
    List<bool>? protectionStatus,
    int? protectionStatusRaw,
    double? version,
    bool? mosfetCharge,
    bool? mosfetDischarge,
    int? balanceStatusLow,
    int? balanceStatusHigh,
    double? totalChargedAh,
    double? totalDischargedAh,
    double? ovpLimit,
    double? uvpLimit,
    double? otpLimit,
  }) {
    return BmsData(
      voltage: voltage ?? this.voltage,
      current: current ?? this.current,
      power: power ?? this.power,
      soc: soc ?? this.soc,
      temperature: temperature ?? this.temperature,
      cellVoltages: cellVoltages ?? this.cellVoltages,
      isCharging: isCharging ?? this.isCharging,

      connectionState: connectionState ?? this.connectionState,
      balanceCapacity: balanceCapacity ?? this.balanceCapacity,
      nominalCapacity: nominalCapacity ?? this.nominalCapacity,
      cycleCount: cycleCount ?? this.cycleCount,
      manufactureDate: manufactureDate ?? this.manufactureDate,
      protectionStatus: protectionStatus ?? this.protectionStatus,
      protectionStatusRaw: protectionStatusRaw ?? this.protectionStatusRaw,
      version: version ?? this.version,
      mosfetCharge: mosfetCharge ?? this.mosfetCharge,
      mosfetDischarge: mosfetDischarge ?? this.mosfetDischarge,
      balanceStatusLow: balanceStatusLow ?? this.balanceStatusLow,
      balanceStatusHigh: balanceStatusHigh ?? this.balanceStatusHigh,
      totalChargedAh: totalChargedAh ?? this.totalChargedAh,
      totalDischargedAh: totalDischargedAh ?? this.totalDischargedAh,
      ovpLimit: ovpLimit ?? this.ovpLimit,
      uvpLimit: uvpLimit ?? this.uvpLimit,
      otpLimit: otpLimit ?? this.otpLimit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'voltage': voltage,
      'current': current,
      'power': power,
      'soc': soc,
      'temperature': temperature,
      'isCharging': isCharging,
      'totalChargedAh': totalChargedAh,
      'totalDischargedAh': totalDischargedAh,
      'ovpLimit': ovpLimit,
      'uvpLimit': uvpLimit,
      'otpLimit': otpLimit,
      'cellVoltages': cellVoltages,
      'mosfetCharge': mosfetCharge,
      'mosfetDischarge': mosfetDischarge,
      'protectionStatusRaw': protectionStatusRaw,
      'cycleCount': cycleCount,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

enum ConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

enum LogSeverity { info, warning, critical }

class LogEntry {
  final DateTime timestamp;
  final String title;
  final String message;
  final LogSeverity severity;
  final String? secondaryStatus;
  final Map<String, String>? metadata;

  LogEntry({
    required this.timestamp,
    required this.title,
    required this.message,
    required this.severity,
    this.secondaryStatus,
    this.metadata,
  });
}
