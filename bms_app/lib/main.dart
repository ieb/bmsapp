import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'services/bms_service.dart';
import 'features/connection/connection_screen.dart';
import 'features/dashboard/dashboard_screen.dart';

import 'services/service_manager.dart';
import 'services/persistence_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final persistence = PersistenceService(prefs);
  
  runApp(BMSApp(persistence: persistence));
}

class BMSApp extends StatelessWidget {
  final PersistenceService persistence;
  const BMSApp({super.key, required this.persistence});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ServiceManager(MockBmsService(persistence), persistence)),
        ProxyProvider<ServiceManager, BmsService>(
          update: (_, manager, __) => manager.service,
        ),
        Provider<PersistenceService>.value(value: persistence),
      ],
      child: Consumer<ServiceManager>(
        builder: (context, manager, _) => MaterialApp(
          title: 'BMS Monitor',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: manager.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const ConnectionScreen(),
          routes: {
            '/dashboard': (context) => const DashboardScreen(),
          },
        ),
      ),
    );
  }
}
