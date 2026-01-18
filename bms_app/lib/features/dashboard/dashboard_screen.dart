import 'package:flutter/material.dart' hide ConnectionState;
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../services/bms_service.dart';
import '../../core/models.dart';

import 'widgets/soc_gauge.dart';
import '../details/details_screen.dart';
import '../history/trends_screen.dart';
import '../settings/settings_screen.dart';
import '../alerts/alerts_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardHome(),
    const TrendsScreen(),
    const DetailsScreen(),
    const AlertsScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      drawer: _buildDrawer(context),
      body: StreamBuilder<BmsData>(
        stream: Provider.of<BmsService>(context).bmsDataStream,
        initialData: Provider.of<BmsService>(context, listen: false).currentData,
        builder: (context, snapshot) {
          final data = snapshot.data ?? BmsData.initial();
          
          return SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(context, data),
                Expanded(
                  child: _pages[_selectedIndex],
                ),
                _buildBottomNav(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.backgroundDark,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.surfaceDark),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.battery_charging_full, color: AppTheme.primary, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'BMS MONITOR',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                   'System Diagnostic Tool',
                   style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
          _drawerItem(context, Icons.swap_horiz, 'Change Connection', () {
            Navigator.pushReplacementNamed(context, '/');
          }),
          _drawerItem(context, Icons.dashboard, 'Dashboard', () {
             Navigator.pop(context);
             setState(() => _selectedIndex = 0);
          }),
          _drawerItem(context, Icons.assignment_late, 'Alerts & Logs', () {
             Navigator.pop(context);
             setState(() => _selectedIndex = 3);
          }),
          const Divider(color: Colors.white10),
          _drawerItem(context, Icons.info_outline, 'About', () {}),
        ],
      ),
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }

  Widget _buildHeader(BuildContext context, BmsData data) {
    String title = 'BATTERY DASHBOARD';
    if (_selectedIndex == 1) title = 'HISTORY';
    if (_selectedIndex == 2) title = 'CELL DETAILS';
    if (_selectedIndex == 3) title = 'ALERTS & LOG';
    if (_selectedIndex == 4) title = 'SETUP';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: AppTheme.primary, size: 24),
              onPressed: () => Scaffold.of(context).openDrawer(),
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14, 
                fontWeight: FontWeight.bold, 
                color: Colors.grey,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  data.connectionState == ConnectionState.connected ? 'BLE Connected' : 'OFFLINE',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 32, left: 24, right: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1C1D),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navItem(Icons.dashboard, 'DASH', 0),
          _navItem(Icons.history, 'HIST', 1),
          _navItem(Icons.battery_charging_full, 'CELLS', 2),
          _navItem(Icons.assignment_late, 'ALERTS', 3),
          _navItem(Icons.settings, 'SETUP', 4),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? AppTheme.primary : Colors.grey;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onItemTapped(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color),
                const SizedBox(height: 4),
                Text(
                  label.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

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
              children: [
                const SizedBox(height: 20),
                SizedBox(
                  height: 250,
                  width: 250,
                  child: SocGauge(percentage: data.soc),
                ),
                const SizedBox(height: 10),
                _buildRuntimeEstimate(context, data),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     _buildInfoChip(Icons.thermostat, '${data.temperature.toStringAsFixed(1)}°C'),
                     const SizedBox(width: 16),
                     _buildInfoChip(Icons.health_and_safety, '100% SOH'),
                  ],
                ),
                const SizedBox(height: 32),
                _buildStatsGrid(context, data),
                const SizedBox(height: 16),
                _buildInfoGrid(context, data),
              ],
            ),
          );
        }
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
             fontSize: 12, 
             fontWeight: FontWeight.bold,
             color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildRuntimeEstimate(BuildContext context, BmsData data) {
    if (data.current == 0) {
       return const Text(
          'Standby',
          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
       );
    }
    
    // Simple estimation logic
    final isDischarging = data.current < 0;
    final remainingAh = data.nominalCapacity > 0 
        ? data.nominalCapacity * (data.soc / 100) 
        : 100 * (data.soc / 100); // Fallback to 100Ah if unknown
        
    double hours = 0;
    if (isDischarging) {
       hours = remainingAh / data.current.abs();
    } else {
       final chargeNeed = (data.nominalCapacity > 0 ? data.nominalCapacity : 100) - remainingAh;
       hours = chargeNeed / data.current;
    }
    
    // Cap insane values
    if (hours > 99) hours = 99;
    
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    
    return Text(
      '${h}h ${m}m until ${isDischarging ? 'discharge' : 'full'}',
      style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 14),
    );
  }

  Widget _buildStatsGrid(BuildContext context, BmsData data) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'VOLTAGE',
                data.voltage.toStringAsFixed(2),
                'V',
                Icons.bolt,
                AppTheme.primary,
                // Mock trend for design
                trend: '+0.12V',
                trendColor: const Color(0xFF0BDA54),
                trendIcon: Icons.trending_up,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'CURRENT',
                data.current.toStringAsFixed(2),
                'A',
                Icons.electric_bolt,
                const Color(0xFFFA5C38),
                trend: data.isCharging ? 'Charging' : 'Discharging',
                trendColor: const Color(0xFFFA5C38),
                trendIcon: Icons.trending_down,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1B2A2C),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
            boxShadow: [
               BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    Text(
                      'REAL-TIME POWER',
                      style: TextStyle(
                        color: Colors.grey[400], 
                        fontSize: 10, 
                        fontWeight: FontWeight.bold, 
                        letterSpacing: 1.0
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        children: [
                           TextSpan(
                             text: data.power.abs().toStringAsFixed(1),
                             style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                           ),
                           const TextSpan(
                             text: ' W',
                             style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.grey),
                           ),
                        ],
                      ),
                    ),
                 ],
               ),
               Container(
                 width: 64,
                 height: 64,
                 decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                 ),
                 child: const Icon(Icons.speed, color: AppTheme.primary, size: 32),
               ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatCard(
      String title, 
      String value, 
      String unit, 
      IconData icon, 
      Color iconColor,
      {String? trend, Color? trendColor, IconData? trendIcon}
  ) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1B2A2C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
           boxShadow: [
               BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
            ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text(
                   title, 
                   style: TextStyle(
                     color: Colors.grey[400], 
                     fontSize: 10, 
                     fontWeight: FontWeight.bold,
                     letterSpacing: 1.0,
                   ),
                 ),
                 Icon(icon, color: iconColor, size: 20),
               ],
             ),
             const SizedBox(height: 8),
             RichText(
                text: TextSpan(
                  children: [
                     TextSpan(
                       text: value,
                       style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                     ),
                     TextSpan(
                       text: ' $unit',
                       style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.grey),
                     ),
                  ],
                ),
             ),
             const SizedBox(height: 8),
             if (trend != null)
               Row(
                 children: [
                   Icon(trendIcon, color: trendColor, size: 12),
                   const SizedBox(width: 4),
                   Text(
                     trend,
                     style: TextStyle(color: trendColor, fontSize: 10, fontWeight: FontWeight.bold),
                   ),
                 ],
               ),
          ],
        ),
      );
  }
  
  Widget _buildInfoGrid(BuildContext context, BmsData data) {
     return Row(
       children: [
         Expanded(child: _buildInfoBox('Cycle Count', '${data.cycleCount}', 'Cycles', Icons.autorenew)),
         const SizedBox(width: 16),
         Expanded(child: _buildInfoBox('Uptime', '24', 'Days', Icons.timer)), // Mock uptime
       ],
     );
  }
  
  Widget _buildInfoBox(String title, String value, String unit, IconData icon) {
     return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
           children: [
              Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                 ),
                 child: Icon(icon, color: Colors.grey, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    Text(
                       title.toUpperCase(),
                       style: TextStyle(
                          color: Colors.grey[400], 
                          fontSize: 10, 
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                       ),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        children: [
                           TextSpan(
                             text: value,
                             style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                           ),
                           TextSpan(
                             text: ' $unit',
                             style: const TextStyle(fontSize: 10, fontWeight: FontWeight.normal, color: Colors.grey),
                           ),
                        ],
                      ),
                    ),
                 ],
              ),
           ],
        ),
     );
  }
}
