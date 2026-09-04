import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/alarm_model.dart';

class DiveraService {
  final String accessKey;

  DiveraService({required this.accessKey});

  Future<String> _saveRawJson(String rawBody) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/divera_raw_response.json');
    await file.writeAsString(rawBody);
    return file.path;
  }

  Future<List<Alarm>> fetchAlarms() async {
    final url = Uri.parse(
      'https://www.divera247.com/api/v2/pull/all?accesskey=$accessKey',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        await _saveRawJson(response.body);

        final dynamic decodedData = jsonDecode(response.body);
        List<Alarm> alarms = [];

        // Pfad im JSON: data -> alarm -> items
        final itemsMap = decodedData['data']?['alarm']?['items'];

        if (itemsMap is Map<String, dynamic>) {
          itemsMap.forEach((key, value) {
            if (value is Map<String, dynamic>) {
              alarms.add(Alarm.fromJson(value));
            }
          });
        }

        // Nach Datum sortieren (neueste zuerst)
        alarms.sort((a, b) => b.date.compareTo(a.date));

        return alarms;
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Fehler beim Auslesen: $e');
    }
  }
}