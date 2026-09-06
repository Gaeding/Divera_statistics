import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/alarm_model.dart';
import 'database_helper.dart';

/// Hilfsklasse für den datenschutzkonformen Backup-Export und -Import.
class BackupHelper {

  /// Exportiert alle Alarme als JSON-Datei, entfernt dabei jedoch die Adressen.
  /// Nutzt `share_plus`, um die Datei zu teilen.
  static Future<bool> exportDataWithoutAddresses() async {
    try {
      // 1. Alle lokalen Alarme aus der Datenbank holen
      final List<Alarm> alarms = await DatabaseHelper.instance.getAllAlarms();

      // 2. Daten konvertieren und das Adressfeld explizit leeren/entfernen
      final List<Map<String, dynamic>> sanitizedData = alarms.map((alarm) {
        final json = alarm.toJson();
        json['address'] = ''; // Adresse für den Datenschutz entfernen
        return json;
      }).toList();

      final jsonString = jsonEncode(sanitizedData);

      // 3. Temporäre Datei im App-Verzeichnis speichern
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final file = File('${directory.path}/divera_stats_backup_$timestamp.json');
      await file.writeAsString(jsonString);

      // 4. System-Teilen-Dialog öffnen
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Divera Stats Backup (ohne Einsatzadressen)',
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Importiert eine zuvor exportierte JSON-Backup-Datei und speichert sie in SQLite.
  static Future<int> importData() async {
    try {
      // Dateiauswahl öffnen (unterstützt JSON-Dateien)
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        
        final List<dynamic> decodedList = jsonDecode(jsonString);
        List<Alarm> importedAlarms = [];

        for (var item in decodedList) {
          if (item is Map<String, dynamic>) {
            // Falls beim Import eine alte Adresse drin sein sollte, zur Sicherheit leeren
            item['address'] = ''; 
            importedAlarms.add(Alarm.fromJson(item));
          }
        }

        // In die lokale Datenbank einfügen (bestehende IDs werden überschrieben/ergänzt)
        await DatabaseHelper.instance.insertAlarms(importedAlarms);
        return importedAlarms.length;
      }
      return 0;
    } catch (e) {
      return -1; // Fehler beim Import
    }
  }
}