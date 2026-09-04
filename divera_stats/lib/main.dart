import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'models/alarm_model.dart';
import 'screens/home_screen.dart';
import 'services/database_helper.dart';
import 'services/divera_service.dart';

const String fetchDiveraTask = 'fetchDiveraAlarmsTask';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == fetchDiveraTask) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final apiKey = prefs.getString('divera_access_key') ?? '';

        if (apiKey.isNotEmpty) {
          final diveraService = DiveraService(accessKey: apiKey);
          List<Alarm> newAlarms = await diveraService.fetchAlarms();

          if (newAlarms.isNotEmpty) {
            await DatabaseHelper.instance.insertAlarms(newAlarms);
          }
        }
        return Future.value(true);
      } catch (e) {
        return Future.value(false);
      }
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true, // Setze auf false für Produktionsmodus
  );

  await Workmanager().registerPeriodicTask(
    'divera_3h_sync',
    fetchDiveraTask,
    frequency: const Duration(minutes: 15), // Für Testzwecke auf 15 Minuten gesetzt
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep, // Korrigiertes Enum
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DIVERA Einsatzstatistik',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}