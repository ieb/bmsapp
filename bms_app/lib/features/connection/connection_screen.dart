import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../services/ble_service.dart';
import '../../services/seasmart_service.dart';
import '../../services/bms_service.dart';
import '../../services/persistence_service.dart';
import '../../services/service_manager.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final TextEditingController _ipController = TextEditingController(text: '192.168.1.100');
  
  // Scanning state
  bool _isScanning = false;
  List<ScanResult> _scanResults = [];
  
  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }
  
  void _connectHttp(BuildContext context) async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) return;

    final persistence = Provider.of<PersistenceService>(context, listen: false);
    final service = SeaSmartService()..init(persistence);
    // Update active service
    Provider.of<ServiceManager>(context, listen: false).setService(service);
    
    // Connect
    await service.connect(ip);
    
    if (!context.mounted) return;
    Navigator.of(context).pushReplacementNamed('/dashboard');
  }

  Future<void> _connectBle(BluetoothDevice device) async {
     final persistence = Provider.of<PersistenceService>(context, listen: false);
     final service = BleBmsService(persistence);
     Provider.of<ServiceManager>(context, listen: false).setService(service);
     
     await service.connect(device.remoteId.toString());

     if (!mounted) return;
     Navigator.of(context).pushReplacementNamed('/dashboard');
  }

  void _connectMock(BuildContext context) async {
    final persistence = Provider.of<PersistenceService>(context, listen: false);
    final service = MockBmsService(persistence);
    Provider.of<ServiceManager>(context, listen: false).setService(service);
    
    await service.connect('mock');
    
    if (!context.mounted) return;
    Navigator.of(context).pushReplacementNamed('/dashboard');
  }

  void _startScan() async {
    setState(() => _isScanning = true);
    setState(() => _scanResults = []);
    
    // Create temp service just for scanning
    final scanService = BleBmsService();
    scanService.startScan().listen((results) {
      if (mounted) {
        setState(() => _scanResults = results);
      }
    });

    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() => _isScanning = false);
        scanService.stopScan();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Icon(
                Icons.battery_charging_full,
                size: 64,
                color: AppTheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Connect to BMS',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold
                ),
              ),
              const SizedBox(height: 16),
              
              // MOCK BUTTON FOR TESTING
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: OutlinedButton.icon(
                  onPressed: () => _connectMock(context),
                  icon: const Icon(Icons.bug_report, size: 18),
                  label: const Text('Connect Mock (Test)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                    side: const BorderSide(color: Colors.grey, width: 0.5),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // SeaSmart Connection Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.hub, color: Colors.grey),
                        const SizedBox(width: 12),
                        const Text('SeaSmart Gateway', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _ipController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'IP Address',
                        labelStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _connectHttp(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Connect via HTTP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              const Text('OR', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),

              // BLE Section
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isScanning ? null : _startScan,
                  icon: _isScanning 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                      : const Icon(Icons.bluetooth),
                  label: Text(_isScanning ? 'Scanning...' : 'Scan for Devices'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              
              if (_scanResults.isNotEmpty) ...[
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _scanResults.length,
                  itemBuilder: (context, index) {
                     final result = _scanResults[index];
                     final name = result.device.platformName.isNotEmpty ? result.device.platformName : 'Unknown Device';
                     return ListTile(
                       title: Text(name, style: const TextStyle(color: Colors.white)),
                       subtitle: Text(result.device.remoteId.toString(), style: const TextStyle(color: Colors.grey)),
                       trailing: ElevatedButton(
                         child: const Text('Connect'),
                         onPressed: () async {
                           await _connectBle(result.device);
                         },
                       ),
                     );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
