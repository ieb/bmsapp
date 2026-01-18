import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/models.dart';
import '../../services/bms_service.dart';
import '../../services/service_manager.dart';
import '../dashboard/widgets/glass_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _ovpController;
  late TextEditingController _uvpController;
  late TextEditingController _otpController;
  late TextEditingController _cloudEndpointController;
  late TextEditingController _cloudApiKeyController;
  bool _isSaving = false;
  bool _isTestingCloud = false;

  @override
  void initState() {
    super.initState();
    final bmsService = Provider.of<BmsService>(context, listen: false);
    final serviceManager = Provider.of<ServiceManager>(context, listen: false);
    
    final bmsData = bmsService.currentData;
    _ovpController = TextEditingController(text: bmsData.ovpLimit.toStringAsFixed(2));
    _uvpController = TextEditingController(text: bmsData.uvpLimit.toStringAsFixed(2));
    _otpController = TextEditingController(text: bmsData.otpLimit.toStringAsFixed(0));
    
    _cloudEndpointController = TextEditingController(text: serviceManager.cloudEndpoint);
    _cloudApiKeyController = TextEditingController(text: serviceManager.cloudApiKey);
  }

  @override
  void dispose() {
    _ovpController.dispose();
    _uvpController.dispose();
    _otpController.dispose();
    _cloudEndpointController.dispose();
    _cloudApiKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    
    try {
      final ovp = double.tryParse(_ovpController.text);
      final uvp = double.tryParse(_uvpController.text);
      final otp = double.tryParse(_otpController.text);

      if (ovp != null || uvp != null || otp != null) {
        await Provider.of<BmsService>(context, listen: false).updateProtectionLimits(
          ovp: ovp,
          uvp: uvp,
          otp: otp,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings saved successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e'), backgroundColor: AppTheme.critical),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveCloudSettings() async {
    final manager = Provider.of<ServiceManager>(context, listen: false);
    manager.setCloudEndpoint(_cloudEndpointController.text.trim());
    manager.setCloudApiKey(_cloudApiKeyController.text.trim());
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cloud settings saved')),
    );
  }

  Future<void> _testCloudConnection() async {
    setState(() => _isTestingCloud = true);
    try {
      final manager = Provider.of<ServiceManager>(context, listen: false);
      final success = await manager.testCloudConnection(
        _cloudEndpointController.text.trim(),
        _cloudApiKeyController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Connection Successful' : 'Connection Failed'),
            backgroundColor: success ? AppTheme.primary : AppTheme.critical,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTestingCloud = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          GlassCard(
            title: 'Protection Limits',
            child: Column(
              children: [
                _buildEditableSettingRow('Over Voltage Cut-off', _ovpController, 'V'),
                const Divider(color: Colors.white10),
                _buildEditableSettingRow('Under Voltage Cut-off', _uvpController, 'V'),
                const Divider(color: Colors.white10),
                _buildEditableSettingRow('Over Temp Cut-off', _otpController, '°C'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isSaving 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            title: 'App Settings',
            child: Consumer<ServiceManager>(
              builder: (context, manager, _) => Column(
                children: [
                  SwitchListTile(
                    title: const Text('Dark Mode', style: TextStyle(color: Colors.white)),
                    value: manager.isDarkMode,
                    onChanged: (val) => manager.toggleDarkMode(val),
                    activeTrackColor: AppTheme.primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(color: Colors.white10),
                  ListTile(
                    title: const Text('Version', style: TextStyle(color: Colors.white)),
                    trailing: const Text('1.0.0', style: TextStyle(color: Colors.grey)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            title: 'Cloud Integration',
            child: Consumer<ServiceManager>(
              builder: (context, manager, _) => Column(
                children: [
                  SwitchListTile(
                    title: const Text('Enable Sync', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Periodic telemetry upload', style: TextStyle(color: Colors.grey, fontSize: 10)),
                    value: manager.isCloudEnabled,
                    onChanged: (val) => manager.setCloudEnabled(val),
                    activeTrackColor: AppTheme.primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 12),
                  _buildCloudField('Endpoint URL', _cloudEndpointController, 'e.g. https://api.io/data'),
                  const SizedBox(height: 12),
                  _buildCloudField('API Key', _cloudApiKeyController, 'Your secret key', obscureText: true),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isTestingCloud ? null : _testCloudConnection,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            side: const BorderSide(color: AppTheme.primary),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: _isTestingCloud 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                            : const Text('TEST CONNECTION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveCloudSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('SAVE CLOUD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            title: 'Maintenance',
            child: Column(
              children: [
                ListTile(
                  title: const Text('Reset Statistics', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Clears total charged/load Ah', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  trailing: const Icon(Icons.refresh, color: AppTheme.accentWarning),
                  contentPadding: EdgeInsets.zero,
                  onTap: () => _showResetDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloudField(String label, TextEditingController controller, String hint, {bool obscureText = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primary)),
          ),
        ),
      ],
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Reset Statistics?', style: TextStyle(color: Colors.white)),
        content: const Text('This will permanently clear total charged and load history.', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Provider.of<BmsService>(context, listen: false).resetStats();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Statistics reset successfully')),
              );
            },
            child: const Text('RESET', style: TextStyle(color: AppTheme.critical)),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableSettingRow(String label, TextEditingController controller, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white))),
          SizedBox(
            width: 80,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                suffixText: ' $unit',
                suffixStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                isDense: true,
                border: InputBorder.none,
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primary)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
