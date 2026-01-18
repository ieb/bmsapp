import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../services/bms_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final bmsService = Provider.of<BmsService>(context);
    
    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: StreamBuilder<List<LogEntry>>(
            stream: bmsService.logsStream,
            initialData: bmsService.logs,
            builder: (context, snapshot) {
              final logs = snapshot.data ?? [];
              final filteredLogs = _selectedFilter == 'All' 
                  ? logs 
                  : logs.where((l) => l.severity.name.toLowerCase() == _selectedFilter.toLowerCase()).toList();

              if (filteredLogs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_turned_in, size: 64, color: Colors.grey.withValues(alpha: 0.2)),
                      const SizedBox(height: 16),
                      Text(
                        'NO ALERTS FOUND',
                        style: TextStyle(
                          color: Colors.grey.withValues(alpha: 0.5),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredLogs.length + 1,
                itemBuilder: (context, index) {
                  if (index == filteredLogs.length) {
                    return _buildEndOfLog();
                  }
                  return _buildLogEntry(filteredLogs[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            _filterItem('All'),
            _filterItem('Critical'),
            _filterItem('Warning'),
            _filterItem('Info'),
          ],
        ),
      ),
    );
  }

  Widget _filterItem(String label) {
    final isSelected = _selectedFilter == label;
    Color activeColor = AppTheme.primary;
    if (label == 'Critical') activeColor = AppTheme.critical;
    if (label == 'Warning') activeColor = AppTheme.warning;
    if (label == 'Info') activeColor = AppTheme.info;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedFilter = label),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? activeColor : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: isSelected 
                    ? (label == 'All' ? Colors.black : Colors.white) 
                    : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogEntry(LogEntry entry) {
    Color severityColor = AppTheme.info;
    IconData icon = Icons.info;
    
    if (entry.severity == LogSeverity.critical) {
      severityColor = AppTheme.critical;
      icon = Icons.dangerous;
    } else if (entry.severity == LogSeverity.warning) {
      severityColor = AppTheme.warning;
      icon = Icons.warning;
    } else if (entry.severity == LogSeverity.info) {
       icon = entry.title.contains('Charge') ? Icons.bolt : Icons.sync;
    }

    final isCritical = entry.severity == LogSeverity.critical;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCritical 
              ? AppTheme.critical.withValues(alpha: 0.3) 
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (isCritical)
            Positioned(
              left: 0,
              top: 16,
              bottom: 16,
              width: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.critical,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: severityColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(icon, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.title.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: -0.5,
                              ),
                            ),
                            if (entry.secondaryStatus != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  entry.secondaryStatus!.toUpperCase(),
                                  style: TextStyle(
                                    color: severityColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatTimestamp(entry.timestamp),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Icon(Icons.sensors, color: AppTheme.primary, size: 14),
                      ],
                    ),
                  ],
                ),
                if (entry.metadata != null && entry.metadata!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _buildMetadata(entry.metadata!),
                  ),
                const SizedBox(height: 12),
                Text(
                  entry.message,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadata(Map<String, String> metadata) {
    if (metadata.length == 1) {
       final key = metadata.keys.first;
       final value = metadata.values.first;
       return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
             color: Colors.black.withValues(alpha: 0.2),
             borderRadius: BorderRadius.circular(4),
             border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
                Text(key.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
             ],
          ),
       );
    }
    
    return Row(
      children: metadata.entries.map((e) {
        return Expanded(
          child: Container(
            margin: e.key == metadata.keys.first ? const EdgeInsets.only(right: 4) : const EdgeInsets.only(left: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.key.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(e.value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEndOfLog() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Container(width: 40, height: 1, color: Colors.grey.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          const Text(
            'END OF LOG (LAST 24H)',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.primary, width: 0.5),
              backgroundColor: AppTheme.primary.withValues(alpha: 0.05),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: const Text(
               'LOAD HISTORICAL',
               style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}";
  }
}
