import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm_model.dart';
import '../services/database_helper.dart';
import '../services/divera_service.dart';
import 'debug_db_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

/// Hauptbildschirm der Anwendung.
/// Zeigt die Einsatzliste basierend auf dem gewählten Zeitfilter an,
/// steuert die Manuelle/Automatische Synchronisation und bietet Zugriff auf Navigation & Debug-Features.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Lokaler State für Alarme, Ladeanzeige und Benutzereinstellungen
  List<Alarm> _allAlarms = [];
  bool _isLoading = false;
  String _savedApiKey = '';
  bool _isDebugMode = false;
  String _timeframe = 'week'; // Standard-Zeitfenster: Letzte Woche

  @override
  void initState() {
    super.initState();
    _loadLocalAlarmsAndSync(); // Beim Initialisieren lokale Daten laden & bei Key-Existenz syncen
  }

  /// Lädt die gespeicherten Einsätze aus SQLite sowie Schlüssel & Zeitfilter aus SharedPreferences.
  Future<void> _loadLocalAlarmsAndSync() async {
    final alarms = await DatabaseHelper.instance.getAllAlarms();
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString('divera_access_key') ?? '';
    final timeframe = prefs.getString('home_timeframe') ?? 'week';

    setState(() {
      _allAlarms = alarms;
      _savedApiKey = key;
      _timeframe = timeframe;
    });

    // Automatische Initial-Synchronisation starten, falls ein API-Schlüssel hinterlegt ist
    if (_savedApiKey.isNotEmpty) {
      _syncWithDivera();
    }
  }

  /// Getter: Filtert die gesamte Alarmliste dynamisch basierend auf dem eingestellten Zeitraum (`_timeframe`).
  List<Alarm> get _filteredAlarms {
    final now = DateTime.now();

    return _allAlarms.where((alarm) {
      switch (_timeframe) {
        case '24h':
          return alarm.date.isAfter(now.subtract(const Duration(hours: 24)));
        case 'week':
          return alarm.date.isAfter(now.subtract(const Duration(days: 7)));
        case 'month':
          return alarm.date.isAfter(now.subtract(const Duration(days: 30)));
        case 'year':
          return alarm.date.isAfter(now.subtract(const Duration(days: 365)));
        case 'all':
        default:
          return true; // Zeigt alle lokal gespeicherten Einsätze an
      }
    }).toList();
  }

  /// Getter: Liefert den menschenlesbaren Text für den Info-Balken oben im UI.
  String get _timeframeLabel {
    switch (_timeframe) {
      case '24h':
        return 'Letzte 24h';
      case 'week':
        return 'Letzte Woche';
      case 'month':
        return 'Letzter Monat';
      case 'year':
        return 'Letztes Jahr';
      case 'all':
      default:
        return 'Alle';
    }
  }

  /// Manuelle/Programmatische Synchronisation mit der DIVERA 24/7 API.
  Future<void> _syncWithDivera() async {
    // Abbruch, falls kein API-Key konfiguriert wurde
    if (_savedApiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kein Accesskey hinterlegt. Bitte öffne die Einstellungen.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // API-Anfrage durchführen & neue Daten in SQLite erfassen/aktualisieren
      final diveraService = DiveraService(accessKey: _savedApiKey);
      final newAlarms = await diveraService.fetchAlarms();

      await DatabaseHelper.instance.insertAlarms(newAlarms);

      // Aktualisierte Liste aus der lokalen Datenbank ziehen
      final updatedAlarms = await DatabaseHelper.instance.getAllAlarms();
      setState(() {
        _allAlarms = updatedAlarms;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${newAlarms.length} Alarme aktualisiert.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Abrufen: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Navigiert zum Einstellungs-Screen und aktualisiert den UI-State nach Rückkehr.
  Future<void> _openSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          isDebugMode: _isDebugMode,
          onDebugModeChanged: (newMode) {
            setState(() {
              _isDebugMode = newMode;
            });
          },
        ),
      ),
    );

    // Falls Einstellungen geändert wurden (Rückgabewert true), Daten neu laden
    if (result == true) {
      _loadLocalAlarmsAndSync();
    }
  }

  /// Debug-Feature: Liest die lokal gespeicherte JSON-Antwort der letzten API-Anfrage aus
  /// und zeigt sie in einem dialogbasierten Textfeld inkl. Kopierfunktion an.
  Future<void> _showRawJsonDialog() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/divera_raw_response.json');

      if (!await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Noch keine Rohdaten vorhanden.')),
          );
        }
        return;
      }

      final rawContent = await file.readAsString();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Debug: JSON-Rohdaten'),
            content: SingleChildScrollView(
              child: SelectableText(
                rawContent,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: rawContent));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('In Zwischenablage kopiert!')),
                  );
                },
                child: const Text('Kopieren'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Schließen'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Lesen: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final displayedAlarms = _filteredAlarms; // Gefilterte Liste für die Anzeige

    return Scaffold(
      appBar: AppBar(
        title: const Text('DIVERA Einsatzstatistik'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        actions: [
          // Exklusive Icons für den aktiven Debug-Modus
          if (_isDebugMode) ...[
            IconButton(
              icon: const Icon(Icons.storage),
              tooltip: 'Debug: DB Tabelle',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DebugDbScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.code),
              tooltip: 'Debug: Raw JSON',
              onPressed: _showRawJsonDialog,
            ),
          ],
          // Allgemeine App-Aktionen
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Statistik',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StatsScreen(alarms: _allAlarms),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Aktualisieren',
            onPressed: _isLoading ? null : _syncWithDivera,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Einstellungen',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Oberer Info-Balken mit Angaben zum Filter und Ladeindikator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey.shade200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Einsätze ($_timeframeLabel): ${displayedAlarms.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),

          // Einsatzliste oder Leermeldung
          Expanded(
            child: displayedAlarms.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Keine Alarme für zeitraum "$_timeframeLabel" vorhanden.'),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _openSettings,
                          icon: const Icon(Icons.settings),
                          label: const Text('Zeitraum oder Key anpassen'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _syncWithDivera, // Pull-to-Refresh Unterstützung
                    child: ListView.builder(
                      itemCount: displayedAlarms.length,
                      itemBuilder: (context, index) {
                        final alarm = displayedAlarms[index];
                        final statusInfo = alarm.myStatusInfo;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          clipBehavior: Clip.antiAlias,
                          child: ExpansionTile(
                            // Icon-Badge mit Farbe des eigenen Status
                            leading: CircleAvatar(
                              backgroundColor: statusInfo.color,
                              child: const Icon(Icons.warning, color: Colors.white),
                            ),
                            // Alarm-Titel und kompakter Status-Chip
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    alarm.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusInfo.color,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    statusInfo.label,
                                    style: TextStyle(
                                      color: statusInfo.color ==
                                              Colors.yellow.shade700
                                          ? Colors.black
                                          : Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Ausrückedatum formatiert
                            subtitle: Text(
                              dateFormat.format(alarm.date),
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12),
                            ),
                            // Ausklappbare Detailansicht für Adresse (nur Debug) & Einsatztext
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Divider(),

                                    // Sensible Adressdaten werden strikt nur im Debug-Modus eingeblendet
                                    if (_isDebugMode && alarm.address.isNotEmpty) ...[
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on,
                                              size: 16, color: Colors.orange),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              alarm.address,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: Colors.orange,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                    ],

                                    // Sachverhalt/Einsatztext
                                    if (alarm.text.isNotEmpty) ...[
                                      Text(
                                        alarm.text,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}