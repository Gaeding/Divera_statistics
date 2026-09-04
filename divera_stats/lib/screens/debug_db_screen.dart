import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/alarm_model.dart';
import '../services/database_helper.dart';

class DebugDbScreen extends StatefulWidget {
  const DebugDbScreen({super.key});

  @override
  State<DebugDbScreen> createState() => _DebugDbScreenState();
}

class _DebugDbScreenState extends State<DebugDbScreen> {
  List<Alarm> _dbAlarms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRawDbEntries();
  }

  Future<void> _fetchRawDbEntries() async {
    setState(() => _isLoading = true);
    final alarms = await DatabaseHelper.instance.getAllAlarms();
    setState(() {
      _dbAlarms = alarms;
      _isLoading = false;
    });
  }

  // Löschvorgang ausführen
  Future<void> _deleteEntry(int id) async {
    await DatabaseHelper.instance.deleteAlarm(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eintrag ID $id wurde dauerhaft gelöscht.')),
      );
    }
    _fetchRawDbEntries();
  }

  // Zweistufiger Bestätigungsdialog
  Future<void> _confirmAndDelete(Alarm alarm) async {
    // 1. Erste Bestätigungsabfrage
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

    if (firstConfirm != true) return;

    // 2. Zweite finale Bestätigungsabfrage
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRawDbEntries,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dbAlarms.isEmpty
              ? const Center(child: Text('Tabelle "alarms" ist leer.'))
              : SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
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
                      rows: _dbAlarms.map((alarm) {
                        return DataRow(
                          cells: [
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                tooltip: 'Eintrag löschen',
                                onPressed: () => _confirmAndDelete(alarm),
                              ),
                            ),
                            DataCell(
                              SelectableText(alarm.id.toString()),
                              onLongPress: () => _copyToClipboard(alarm.id.toString()),
                            ),
                            DataCell(SelectableText(alarm.title)),
                            DataCell(
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 200),
                                child: SelectableText(
                                  alarm.text,
                                  maxLines: 2,
                                ),
                              ),
                            ),
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

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"$text" kopiert!'), duration: const Duration(seconds: 1)),
    );
  }
}