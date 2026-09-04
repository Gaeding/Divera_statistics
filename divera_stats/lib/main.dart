import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'models/alarm_model.dart';
import 'screens/home_screen.dart';
import 'services/database_helper.dart';
import 'services/divera_service.dart';

/// Eindeutiger Bezeichner für den Workmanager-Hintergrundtask.
const String fetchDiveraTask = 'fetchDiveraAlarmsTask';

/// Einstiegspunkt für den Workmanager-Hintergrundprozess.
/// Läuft isoliert im Hintergrund, um periodisch Einsatzdaten abzurufen.
/// `@pragma('vm:entry-point')` verhindert, dass Tree-Shaking den Code im Release-Build entfernt.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == fetchDiveraTask) {
      try {
        // API-Schlüssel aus den lokalen SharedPreferences auslesen
        final prefs = await SharedPreferences.getInstance();
        final apiKey = prefs.getString('divera_access_key') ?? '';

        // Synchronisation nur ausführen, wenn ein gültiger Key hinterlegt ist
        if (apiKey.isNotEmpty) {
          final diveraService = DiveraService(accessKey: apiKey);
          List<Alarm> newAlarms = await diveraService.fetchAlarms();

          // Neue/aktualisierte Alarme direkt in die lokale SQLite-Datenbank schreiben
          if (newAlarms.isNotEmpty) {
            await DatabaseHelper.instance.insertAlarms(newAlarms);
          }
        }
        return Future.value(true); // Signalisiert dem System den erfolgreichen Abschluss
      } catch (e) {
        return Future.value(false); // Signalisiert einen Fehler (Android versucht ggf. Retry)
      }
    }
    return Future.value(true);
  });
}

/// Einstiegspunkt der Flutter-Anwendung.
void main() async {
  // Stellt sicher, dass die Flutter-Engine vor Asynchronen-Aufrufen (z. B. Workmanager) bereit ist
  WidgetsFlutterBinding.ensureInitialized();

  // Workmanager initialisieren und den Callback-Handler registrieren
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false, // Für Release-Builds auf 'false' setzen, um Test-Benachrichtigungen zu deaktivieren
  );

  // Periodischen Hintergrund-Task registrieren
  await Workmanager().registerPeriodicTask(
    'divera_3h_sync',
    fetchDiveraTask,
    frequency: const Duration(hours: 3), // Im Produktivbetrieb auf 'Duration(hours: 3)' anpassen
    constraints: Constraints(
      networkType: NetworkType.connected, // Task wird nur bei aktiver Internetverbindung ausgeführt
    ),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep, // Behält bestehende Aufgaben bei App-Neustart bei
  );

  runApp(const MyApp());
}

/// Wurzel-Widget der Anwendung. Konfiguriert das globale Theme und die Startseite.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DIVERA Einsatzstatistik',
      debugShowCheckedModeBanner: false, // Blendet das Debug-Banner oben rechts aus
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}