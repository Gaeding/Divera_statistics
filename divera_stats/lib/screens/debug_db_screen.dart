import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/alarm_model.dart';
import '../services/database_helper.dart';

/// Screen für den DB Inspector im Debug-Modus.
/// Zeigt den direkten Inhalt der SQLite-Tabelle "alarms" an und bietet
/// administrative Funktionen wie das Löschen einzelner Einsätze.
class DebugDbScreen extends StatefulWidget {
  const DebugDbScreen({super.key});

  @override
  State<DebugDbScreen> createState() => _DebugDbScreenState();
}

class _DebugDbScreenState extends State<DebugDbScreen> {
  // Lokaler State für Rohdaten und Ladeanzeige
  List<Alarm> _dbAlarms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRawDbEntries(); // Beim Erstellen des Screens Daten laden
  }

  /// Ruft alle unzensierten Datensätze direkt aus der lokalen SQLite-Datenbank ab.
  Future<void> _fetchRawDbEntries() async {
    setState(() => _isLoading = true);
    final alarms = await DatabaseHelper.instance.getAllAlarms();
    setState(() {
      _dbAlarms = alarms;
      _isLoading = false;
    });
  }

  /// Führt den eigentlichen Löschbefehl in SQLite aus und aktualisiert die Liste.
  Future<void> _deleteEntry(int id) async {
    await DatabaseHelper.instance.deleteAlarm(id);
    
    // Prüfen, ob der Screen noch aktiv ist, bevor SnackBars gezeigt werden
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eintrag ID $id wurde dauerhaft gelöscht.')),
      );
    }
    _fetchRawDbEntries(); // Tabelle nach dem Löschen neu laden
  }

  /// Zweistufiger Bestätigungsdialog (Doppelabfrage) zur Vermeidung versehentlichen Löschens.
  Future<void> _confirmAndDelete(Alarm alarm) async {
    // 1. Erste Warnstufe: Standard-Bestätigung mit Einsatzdetails
    bool? firstConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Eintrag löschen?'),
          ],
        ),
        content: Text(
          'Möchtest du den Einsatz "${alarm.title}" (ID: ${alarm.id}) wirklich aus der lokalen Datenbank löschen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Weiter'),
          ),
        ],
      ),
    );

    // Abbrechen, falls Stufe 1 verneint wurde
    if (firstConfirm != true) return;

    // 2. Zweite Warnstufe: Finale, unumkehrbare Bestätigung
    if (mounted) {
      bool? secondConfirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.delete_forever, color: Colors.red),
              SizedBox(width: 8),
              Text('Endgültige Bestätigung'),
            ],
          ),
          content: Text(
            'ACHTUNG: Dieser Vorgang kann nicht rückgängig gemacht werden!\n\nID ${alarm.id} jetzt endgültig löschen?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('JA, DAUERHAFT LÖSCHEN'),
            ),
          ],
        ),
      );

      // Erst nach doppelter Zusage den Löschbefehl senden
      if (secondConfirm == true) {
        await _deleteEntry(alarm.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DB Inspector (${_dbAlarms.length} Einträge)'),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        actions: [
          // Button zum manuellen Reorganisieren/Neuladen der Tabellendaten
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRawDbEntries,
          )
        ],
      ),
      // Bedingte Anzeige: Ladeanzeige vs. Leere Tabelle vs. Datentabelle
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dbAlarms.isEmpty
              ? const Center(child: Text('Tabelle "alarms" ist leer.'))
              : SingleChildScrollView(
                  scrollDirection: Axis.vertical, // Vertikales Scrollen
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal, // Horizontales Scrollen für breite Tabellen
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(Colors.grey.shade200),
                      columns: const [
                        DataColumn(
                          label: Text('Aktion', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text('ID (id)', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text('Titel (title)', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text('Text (text)', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text('Adresse (address)', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text('Timestamp (date)', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text('Status ID (myStatusId)', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                      // Iteration über alle DB-Einträge zur Erstellung der Zeilen
                      rows: _dbAlarms.map((alarm) {
                        return DataRow(
                          cells: [
                            // Aktions-Spalte: Lösch-Icon
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                tooltip: 'Eintrag löschen',
                                onPressed: () => _confirmAndDelete(alarm),
                              ),
                            ),
                            // ID-Spalte (mit Long-Press zum Kopieren)
                            DataCell(
                              SelectableText(alarm.id.toString()),
                              onLongPress: () => _copyToClipboard(alarm.id.toString()),
                            ),
                            DataCell(SelectableText(alarm.title)),
                            // Text spaltenweise eingrenzen gegen Layout-Overflows
                            DataCell(
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 200),
                                child: SelectableText(
                                  alarm.text,
                                  maxLines: 2,
                                ),
                              ),
                            ),
                            // Adress-Spalte (im Debug-Modus hier unzensiert einsehbar)
                            DataCell(
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 180),
                                child: SelectableText(
                                  alarm.address,
                                  maxLines: 2,
                                ),
                              ),
                            ),
                            DataCell(SelectableText(alarm.date.millisecondsSinceEpoch.toString())),
                            DataCell(SelectableText(alarm.myStatusId.toString())),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
    );
  }

  /// Hilfsmethode zum Kopieren von Zellwerten in die Zwischenablage
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"$text" kopiert!'), duration: const Duration(seconds: 1)),
    );
  }
}