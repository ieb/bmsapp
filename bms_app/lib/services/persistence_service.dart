import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models.dart';

class PersistenceService {
  static const String _keyTotalCharged = 'total_charged_ah';
  static const String _keyTotalDischarged = 'total_discharged_ah';
  static const String _keyLogs = 'app_logs';
  static const String _keyOvpLimit = 'ovp_limit';
  static const String _keyUvpLimit = 'uvp_limit';
  static const String _keyOtpLimit = 'otp_limit';
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyCloudEnabled = 'cloud_enabled';
  static const String _keyCloudEndpoint = 'cloud_endpoint';
  static const String _keyCloudApiKey = 'cloud_api_key';
  static const String _keyDeviceId = 'device_id';

  final SharedPreferences _prefs;

  PersistenceService(this._prefs);

  double getTotalCharged() => _prefs.getDouble(_keyTotalCharged) ?? 0.0;
  Future<void> setTotalCharged(double value) => _prefs.setDouble(_keyTotalCharged, value);

  double getTotalDischarged() => _prefs.getDouble(_keyTotalDischarged) ?? 0.0;
  Future<void> setTotalDischarged(double value) => _prefs.setDouble(_keyTotalDischarged, value);
  
  // Actually let's just add the new ones
  double getOvpLimit() => _prefs.getDouble(_keyOvpLimit) ?? 3.65;
  Future<void> setOvpLimit(double value) => _prefs.setDouble(_keyOvpLimit, value);

  double getUvpLimit() => _prefs.getDouble(_keyUvpLimit) ?? 2.50;
  Future<void> setUvpLimit(double value) => _prefs.setDouble(_keyUvpLimit, value);

  double getOtpLimit() => _prefs.getDouble(_keyOtpLimit) ?? 65.0;
  Future<void> setOtpLimit(double value) => _prefs.setDouble(_keyOtpLimit, value);

  bool getDarkMode() => _prefs.getBool(_keyDarkMode) ?? true;
  Future<void> setDarkMode(bool value) => _prefs.setBool(_keyDarkMode, value);

  bool getCloudEnabled() => _prefs.getBool(_keyCloudEnabled) ?? false;
  Future<void> setCloudEnabled(bool value) => _prefs.setBool(_keyCloudEnabled, value);

  String getCloudEndpoint() => _prefs.getString(_keyCloudEndpoint) ?? 'https://api.example.com/telemetry';
  Future<void> setCloudEndpoint(String value) => _prefs.setString(_keyCloudEndpoint, value);

  String getCloudApiKey() => _prefs.getString(_keyCloudApiKey) ?? '';
  Future<void> setCloudApiKey(String value) => _prefs.setString(_keyCloudApiKey, value);

  String getOrCreateDeviceId() {
    String? id = _prefs.getString(_keyDeviceId);
    if (id == null) {
      // Generate a simple anonymous ID
      final rand = (DateTime.now().millisecondsSinceEpoch % 100000).toString();
      id = 'BMS-UNIT-$rand';
      _prefs.setString(_keyDeviceId, id);
    }
    return id;
  }

  Future<void> saveLogs(List<LogEntry> logs) async {
     // Simple JSON serialization for logs
     final List<Map<String, dynamic>> logData = logs.map((log) => {
       'timestamp': log.timestamp.toIso8601String(),
       'title': log.title,
       'message': log.message,
       'severity': log.severity.index,
       'secondaryStatus': log.secondaryStatus,
       'metadata': log.metadata,
     }).toList();
     await _prefs.setString(_keyLogs, jsonEncode(logData));
  }

  List<LogEntry> loadLogs() {
    final String? logString = _prefs.getString(_keyLogs);
    if (logString == null) return [];
    
    try {
      final List<dynamic> logData = jsonDecode(logString);
      return logData.map((data) => LogEntry(
        timestamp: DateTime.parse(data['timestamp']),
        title: data['title'],
        message: data['message'],
        severity: LogSeverity.values[data['severity']],
        secondaryStatus: data['secondaryStatus'],
        metadata: (data['metadata'] as Map?)?.cast<String, String>(),
      )).toList();
    } catch (e) {
      return [];
    }
  }
}
