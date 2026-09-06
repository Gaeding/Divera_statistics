import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'models/alarm_model.dart';
import 'screens/home_screen.dart';
import 'services/database_helper.dart';
import 'services/divera_service.dart';

/// Eindeutiger Task-Name für den Hintergrunddienst.
const String fetchDiveraTask = 'fetchDiveraAlarmsTask';

/// Globaler Notifier zur Laufzeit-Umschaltung zwischen Light- und Dark-Modus.
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

/// Einstiegspunkt für den Workmanager-Hintergrundprozess.
/// Läuft in einem separaten Isolate, um periodisch Einsatzdaten abzurufen.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == fetchDiveraTask) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final apiKey = prefs.getString('divera_access_key') ?? '';

        if (apiKey.isNotEmpty) {
          final diveraService = DiveraService(accessKey: apiKey);
          List<Alarm> newAlarms = await diveraService.fetchAlarms(source: 'Hintergrund (Workmanager)');

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

/// Haupt-Einstiegspunkt der Flutter-Anwendung.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Blendet die Status- und Navigationsleiste vollständig aus (Immersive Mode)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const MyApp());

  // Gespeicherte Theme-Präferenz beim App-Start auslesen
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('is_dark_mode') ?? false;
  themeNotifier.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;

  // Workmanager initialisieren (Produktionsmodus: Debug-Bannner/Meldungen aus)
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );

  // Periodischen Task für den Hintergrund-Sync (alle 3 Stunden) registrieren
  await Workmanager().registerPeriodicTask(
    'divera_3h_sync',
    fetchDiveraTask,
    frequency: const Duration(hours: 3),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );

  runApp(const MyApp());
}

/// Wurzel-Widget der App. Lauscht auf Theme-Änderungen und steuert das Design.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentThemeMode, child) {
        return MaterialApp(
          title: 'DIVERA Einsatzstatistik',
          debugShowCheckedModeBanner: false,
          themeMode: currentThemeMode,
          // Helles Design-Schema
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
            useMaterial3: true,
          ),
          // Dunkles Design-Schema (Dark Mode)
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.redAccent,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}