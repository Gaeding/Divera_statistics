import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm_model.dart';

/// Service-Klasse zur Kommunikation mit der DIVERA 24/7 REST-API.
/// Handhabt den HTTP-Abruf, das Caching von Rohdaten, das Parsing von Alarmen
/// sowie die Protokollierung des letzten Abruf-Status und einer Historie (App-Aktivitäten).
class DiveraService {
  final String accessKey;

  DiveraService({required this.accessKey});

  /// Hilfsmethode: Speichert die unparsed JSON-Antwort der API als lokale Datei
  /// für den späteren Zugriff im Debug-Modus.
  Future<String> _saveRawJson(String rawBody) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/divera_raw_response.json');
    await file.writeAsString(rawBody);
    return file.path;
  }

  /// Hilfsmethode: Protokolliert den Zeitpunkt, den Erfolg und die Quelle des Abrufs
  /// sowohl in den SharedPreferences (für den UI-Status) als auch in einer dauerhaften Log-Datei.
  Future<void> _updateSyncLog(bool success, String source) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = DateTime.now().toIso8601String();

    // UI-Status aktualisieren
    await prefs.setString('last_sync_time', timestamp);
    await prefs.setBool('last_sync_success', success);
    await prefs.setString('last_sync_source', source);

    // Detaillierten Log-Eintrag in die Protokolldatei schreiben
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logFile = File('${directory.path}/app_activity.log');
      
      final statusText = success ? 'ERFOLGREICH' : 'FEHLGESCHLAGEN';
      final logEntry = '[$timestamp] [$source] Datenabruf $statusText\n';

      // Zeile an die bestehende Log-Datei anhängen
      await logFile.writeAsString(logEntry, mode: FileMode.append);
    } catch (_) {
      // Fehler beim Schreiben des Logs ignorieren, um den Hauptfluss nicht zu stören
    }
  }

  /// Ruft alle Alarme vom DIVERA 24/7 Server ab.
  /// [source] beschreibt, ob der Abruf aus dem Vordergrund oder Hintergrund getriggert wurde.
  Future<List<Alarm>> fetchAlarms({String source = 'Vordergrund'}) async {
    final url = Uri.parse(
      'https://www.divera247.com/api/v2/pull/all?accesskey=$accessKey',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Rohdaten-JSON für Debug-Zwecke sichern
        await _saveRawJson(response.body);

        final dynamic decodedData = jsonDecode(response.body);
        List<Alarm> alarms = [];

        final itemsMap = decodedData['data']?['alarm']?['items'];

        if (itemsMap is Map<String, dynamic>) {
          itemsMap.forEach((key, value) {
            if (value is Map<String, dynamic>) {
              alarms.add(Alarm.fromJson(value));
            }
          });
        }

        // Alarme chronologisch absteigend sortieren
        alarms.sort((a, b) => b.date.compareTo(a.date));

        // Protokollieren: Erfolg + Quelle
        await _updateSyncLog(true, source);

        return alarms;
      } else {
        // Protokollieren: Fehler + Quelle
        await _updateSyncLog(false, source);
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      // Protokollieren: Exception + Quelle
      await _updateSyncLog(false, source);
      throw Exception('Fehler beim Auslesen: $e');
    }
  }
}