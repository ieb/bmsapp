import 'dart:async';
import 'package:flutter/foundation.dart';
import 'bms_service.dart';
import 'cloud_service.dart';
import 'persistence_service.dart';
import '../core/models.dart';

class ServiceManager extends ChangeNotifier {
  BmsService _activeService;
  bool _isDarkMode;
  final PersistenceService _persistence;
  final CloudService _cloudService = CloudService();
  Timer? _cloudSyncTimer;
  BmsData? _latestData;
  StreamSubscription? _dataSubscription;

  ServiceManager(this._activeService, this._persistence) : _isDarkMode = _persistence.getDarkMode() {
    _initCloudSync();
  }

  BmsService get service => _activeService;

  void setService(BmsService newService) {
    if (_activeService != newService) {
      _dataSubscription?.cancel();
      _activeService.disconnect(); // Disconnect old service
      _activeService = newService;
      _listenToData();
      notifyListeners();
    }
  }

  void _initCloudSync() {
    _listenToData();
    _startCloudSyncTimer();
  }

  void _listenToData() {
    _dataSubscription = _activeService.bmsDataStream.listen((data) {
      _latestData = data;
    });
  }

  void _startCloudSyncTimer() {
    _cloudSyncTimer?.cancel();
    _cloudSyncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _syncToCloud();
    });
  }

  Future<void> _syncToCloud() async {
    if (!_persistence.getCloudEnabled() || _latestData == null) return;

    await _cloudService.uploadTelemetry(
      data: _latestData!,
      endpoint: _persistence.getCloudEndpoint(),
      apiKey: _persistence.getCloudApiKey(),
      deviceId: _persistence.getOrCreateDeviceId(),
    );
  }

  bool get isDarkMode => _isDarkMode;
  
  // Cloud Getters
  bool get isCloudEnabled => _persistence.getCloudEnabled();
  String get cloudEndpoint => _persistence.getCloudEndpoint();
  String get cloudApiKey => _persistence.getCloudApiKey();

  // Cloud Setters
  void setCloudEnabled(bool value) {
    _persistence.setCloudEnabled(value);
    notifyListeners();
  }

  void setCloudEndpoint(String value) {
    _persistence.setCloudEndpoint(value);
    notifyListeners();
  }

  void setCloudApiKey(String value) {
    _persistence.setCloudApiKey(value);
    notifyListeners();
  }

  Future<bool> testCloudConnection(String endpoint, String apiKey) {
    return _cloudService.testConnection(endpoint, apiKey);
  }

  void toggleDarkMode(bool value) {
    _isDarkMode = value;
    _persistence.setDarkMode(value);
    notifyListeners();
  }
}
