import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/models.dart';
import '../../services/bms_service.dart';
// import '../dashboard/widgets/glass_card.dart'; // We'll build custom cards for this specific design

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  String _selectedRange = '1H';
  final List<String> _ranges = ['1H', '6H', '12H', '24H'];

  @override
  Widget build(BuildContext context) {
    return Consumer<BmsService>(
      builder: (context, service, child) {
        final history = service.recentHistory;
        final currentData = service.currentData;
        final isCharging = currentData.current > 0;

        return Scaffold(
          backgroundColor: AppTheme.backgroundLight, // Should be dynamic based on theme, but design uses specific backgrounds
          // Using a Container with the app's background color to be safe
          body: Container(
             color: Theme.of(context).scaffoldBackgroundColor,
             child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTimeRangeSelector(),
                    const SizedBox(height: 24),
                    _buildAnalyticsChartSection(history, currentData, isCharging),
                    const SizedBox(height: 16),
                    _buildStatsGrid(currentData),
                    const SizedBox(height: 16),
                    _buildConnectionDetails(),
                    const SizedBox(height: 24), // Bottom padding
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: _ranges.map((range) {
          final isSelected = _selectedRange == range;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedRange = range),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  range,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? AppTheme.primary : Colors.grey,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAnalyticsChartSection(List<BmsData> history, BmsData currentData, bool isCharging) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LIVE CURRENT',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        currentData.current.toStringAsFixed(1),
                        style: TextStyle(
                          color: isCharging ? AppTheme.primary : AppTheme.accentWarning,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Amps',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text(
                        isCharging ? 'CHARGING' : 'DISCHARGING',
                        style: TextStyle(
                          color: isCharging ? AppTheme.primary : AppTheme.accentWarning,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.bolt,
                        color: isCharging ? AppTheme.primary : AppTheme.accentWarning,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'UPDATES EVERY 2S',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Chart
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                 // Background Grid (Custom Painter or Container hack)
                 Positioned.fill(
                   child: CustomPaint(painter: GridPainter()),
                 ),
                 // Chart
                 LineChart(
                   _buildChartData(history),
                 ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Charging', AppTheme.primary),
              const SizedBox(width: 24),
              _buildLegendItem('Discharging', AppTheme.accentWarning),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8, 
          height: 8, 
          decoration: BoxDecoration(
            color: color, 
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BmsData data) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'TOTAL CHARGED',
            data.totalChargedAh.toStringAsFixed(1),
            'Ah',
            'Since last reset',
            Icons.trending_up,
            AppTheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'TOTAL LOAD',
            data.totalDischargedAh.toStringAsFixed(1),
            'Ah',
            'Since last reset',
            Icons.trending_down,
            AppTheme.accentWarning,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String unit, String trend, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: 4),
                  Text(
                    trend,
                    style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              title.contains('CHARGED') ? Icons.add_circle : Icons.remove_circle,
              size: 64,
              color: color.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'NETWORK & TELEMETRY',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              _buildConnectionRow(
                Icons.hub,
                'SeaSmart Gateway',
                '192.168.1.142',
                'STABLE',
                'Latency: 42ms',
                AppTheme.primary,
              ),
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.05)),
              _buildConnectionRow(
                Icons.cell_tower,
                'Cloud Sync',
                'Last synced 4 mins ago',
                'SYNC NOW',
                '',
                Colors.grey,
                isAction: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionRow(IconData icon, String title, String subtitle, String status, String subStatus, Color color, {bool isAction = false}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: isAction ? Colors.grey : AppTheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
              ],
            ),
          ),
          if (isAction)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                if (subStatus.isNotEmpty)
                  Text(subStatus, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10)),
              ],
            ),
        ],
      ),
    );
  }

  LineChartData _buildChartData(List<BmsData> history) {
    if (history.isEmpty) return LineChartData();

    final spots = history.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.current);
    }).toList();

    double minY = -50;
    double maxY = 50;
    
    // Dynamic range if data exceeds bounds
    if (history.isNotEmpty) {
       final minVal = history.map<double>((e) => e.current).reduce((double a, double b) => a < b ? a : b);
       final maxVal = history.map<double>((e) => e.current).reduce((double a, double b) => a > b ? a : b);
       if (minVal < minY) minY = minVal * 1.2;
       if (maxVal > maxY) maxY = maxVal * 1.2;
    }

    return LineChartData(
      gridData: FlGridData(show: false), // We use custom background grid
      titlesData: FlTitlesData(
         show: true,
         rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
         topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
         bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
         leftTitles: AxisTitles(
           sideTitles: SideTitles(
             showTitles: true,
             reservedSize: 40,
             interval: 25, 
             getTitlesWidget: (value, meta) {
               return Text(
                 '${value > 0 ? '+' : ''}${value.toInt()}A',
                 style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10),
               );
             },
           ),
         ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (history.isNotEmpty ? history.length - 1 : 0).toDouble(),
      minY: minY,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppTheme.primary, // We need gradient or segment coloring for +/-? 
          // FLChart doesn't easily support segment coloring based on value in one line without complex shader.
          // For now, let's use the primary color, or maybe a gradient?
          gradient: const LinearGradient(
            colors: [AppTheme.accentWarning, AppTheme.primary],
            stops: [0.45, 0.55], // Rough transition around 0 if range is symetric?
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
           shadow: const Shadow(color: AppTheme.primary, blurRadius: 4),
        ),
      ],
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          HorizontalLine(
            y: 0,
            color: AppTheme.primary.withValues(alpha: 0.3),
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const step = 40.0;
    
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
