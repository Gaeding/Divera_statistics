import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Benötigt für das Speichern des Sync-Status
import '../models/alarm_model.dart';

/// Service-Klasse zur Kommunikation mit der DIVERA 24/7 REST-API.
/// Handhabt den HTTP-Abruf, das Caching von Rohdaten, das Parsing von Alarmen
/// sowie die Protokollierung des letzten Abruf-Status (Zeitpunkt & Erfolg).
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

  /// Hilfsmethode: Protokolliert den Zeitpunkt und den Erfolg des letzten Abrufs
  /// in den lokalen SharedPreferences (gilt sowohl für Foreground als auch Background-Sync).
  Future<void> _updateSyncLog(bool success) async {
    final prefs = await SharedPreferences.getInstance();
    // Aktuellen ISO-Zeitstempel speichern
    await prefs.setString('last_sync_time', DateTime.now().toIso8601String());
    // Erfolgsstatus (true/false) speichern
    await prefs.setBool('last_sync_success', success);
  }

  /// Ruft alle Alarme vom DIVERA 24/7 Server ab.
  /// Gibt eine nach Datum absteigend sortierte Liste von `Alarm`-Objekten zurück.
  Future<List<Alarm>> fetchAlarms() async {
    // API-Endpoint URL mit personalisiertem Accesskey zusammenbauen
    final url = Uri.parse(
      'https://www.divera247.com/api/v2/pull/all?accesskey=$accessKey',
    );

    try {
      final response = await http.get(url);

      // HTTP-Status 200 bedeutet erfolgreiche Verbindung und Datenübertragung
      if (response.statusCode == 200) {
        // Rohdaten-JSON für Debug-Zwecke sichern
        await _saveRawJson(response.body);

        final dynamic decodedData = jsonDecode(response.body);
        List<Alarm> alarms = [];

        // Gezielter Zugriff auf den verschachtelten DIVERA-Datenpfad: data -> alarm -> items
        final itemsMap = decodedData['data']?['alarm']?['items'];

        if (itemsMap is Map<String, dynamic>) {
          itemsMap.forEach((key, value) {
            if (value is Map<String, dynamic>) {
              alarms.add(Alarm.fromJson(value));
            }
          });
        }

        // Alarme chronologisch absteigend sortieren (neueste Einsätze zuerst)
        alarms.sort((a, b) => b.date.compareTo(a.date));

        // Sync-Protokoll auf Erfolg (true) aktualisieren
        await _updateSyncLog(true);

        return alarms;
      } else {
        // Bei HTTP-Fehler (z. B. 401 Unauthorized oder 500 Server Error) Protokoll auf Fehler (false) setzen
        await _updateSyncLog(false);
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      // Bei Netzwerkfehlern oder Exceptions ebenfalls Protokoll auf Fehler (false) setzen
      await _updateSyncLog(false);
      throw Exception('Fehler beim Auslesen: $e');
    }
  }
}