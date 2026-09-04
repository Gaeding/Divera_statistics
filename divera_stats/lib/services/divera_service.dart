import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/alarm_model.dart';

/// Service-Klasse zur Kommunikation mit der DIVERA 24/7 REST-API.
/// Handhabt den HTTP-Abruf der Einsatzdaten, das lokale Caching der JSON-Rohdaten
/// für Debug-Zwecke sowie das Parsing der JSON-Struktur in `Alarm`-Objekte.
class DiveraService {
  final String accessKey;

  DiveraService({required this.accessKey});

  /// Hilfsmethode: Speichert die unparsed JSON-Antwort der API als lokale Datei.
  /// Ermöglicht die spätere Inspektion der Rohdaten über den Debug-Modus der App.
  Future<String> _saveRawJson(String rawBody) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/divera_raw_response.json');
    await file.writeAsString(rawBody);
    return file.path;
  }

  /// Ruft alle Alarme vom DIVERA 24/7 Server ab.
  /// Gibt eine nach Datum absteigend sortierte Liste von `Alarm`-Objekten zurück.
  Future<List<Alarm>> fetchAlarms() async {
    // API-Endpoint für den Gesamtabruf mit personalisiertem Accesskey
    final url = Uri.parse(
      'https://www.divera247.com/api/v2/pull/all?accesskey=$accessKey',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Rohdaten für den Debug-Inspector abspeichern
        await _saveRawJson(response.body);

        final dynamic decodedData = jsonDecode(response.body);
        List<Alarm> alarms = [];

        // Gezielter Zugriff auf den Objekt-Pfad in der DIVERA API: data -> alarm -> items
        final itemsMap = decodedData['data']?['alarm']?['items'];

        // DIVERA liefert 'items' meist als Map mit den Alarm-IDs als Keys
        if (itemsMap is Map<String, dynamic>) {
          itemsMap.forEach((key, value) {
            if (value is Map<String, dynamic>) {
              alarms.add(Alarm.fromJson(value));
            }
          });
        }

        // Alarme chronologisch absteigend sortieren (neueste Einsätze zuerst)
        alarms.sort((a, b) => b.date.compareTo(a.date));

        return alarms;
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      // Weiterreichen von Netzwerk- oder Parsing-Fehlern
      throw Exception('Fehler beim Auslesen: $e');
    }
  }
}