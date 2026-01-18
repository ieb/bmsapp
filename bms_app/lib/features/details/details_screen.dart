import 'package:flutter/material.dart' hide ConnectionState;
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../services/bms_service.dart';
import '../../core/models.dart';
import '../dashboard/widgets/glass_card.dart'; // Reuse GlassCard

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BmsData>(
      stream: Provider.of<BmsService>(context).bmsDataStream,
      initialData: Provider.of<BmsService>(context, listen: false).currentData,
      builder: (context, snapshot) {
        final data = snapshot.data ?? BmsData.initial();
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CELL VOLTAGES',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                ),
                itemCount: data.cellVoltages.length,
                itemBuilder: (context, index) {
                  final voltage = data.cellVoltages[index];
                  // Calculate delta from average (mock logic)
                  final avg = data.cellVoltages.isNotEmpty 
                      ? data.cellVoltages.reduce((a, b) => a + b) / data.cellVoltages.length 
                      : 0.0;
                  final delta = voltage - avg;
                  
                  return GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'CELL ${index + 1}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${voltage.toStringAsFixed(3)}V',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(3)}V',
                              style: TextStyle(
                                color: delta.abs() < 0.05 ? AppTheme.accentSuccess : AppTheme.accentWarning,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              GlassCard(
                title: 'TEMPERATURES',
                icon: const Icon(Icons.thermostat, color: AppTheme.accentSuccess),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Cell Stack', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(
                            '${data.temperature.toStringAsFixed(1)}°C',
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('MOSFET', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(
                            '${(data.temperature + 5).toStringAsFixed(1)}°C', // Mock offset
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
