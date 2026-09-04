import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // Zugriff auf den globalen themeNotifier

/// Einstellungsbildschirm der App.
/// Erlaubt die direkte Verwaltung von API-Key (mit eigenem Speicher-Button),
/// sowie die sofortige Live-Übernahme von Dark Mode, Zeitfilter und Akku-Optionen.
class SettingsScreen extends StatefulWidget {
  final bool isDebugMode;
  final Function(bool) onDebugModeChanged;

  const SettingsScreen({
    super.key,
    required this.isDebugMode,
    required this.onDebugModeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Controller für das API-Key Eingabefeld
  final TextEditingController _apiKeyController = TextEditingController();
  
  // Zähler für das Easter-Egg (10-mal Tippen für den Debug-Modus)
  int _debugClickCount = 0;
  late bool _currentDebugState;
  
  // Ausgewählter Zeitraum für die Hauptseite
  String _selectedTimeframe = 'week';
  
  // Zustand für den Dark Mode Schalter
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _currentDebugState = widget.isDebugMode;
    _loadSettings();
  }

  /// Lädt gespeicherte Einstellungen beim Öffnen des Screens aus den SharedPreferences.
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKeyController.text = prefs.getString('divera_access_key') ?? '';
      _selectedTimeframe = prefs.getString('home_timeframe') ?? 'week';
      _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    });
  }

  /// Speichert speziell den API-Key (wird über den separaten Button aufgerufen).
  Future<void> _saveApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('divera_access_key', _apiKeyController.text.trim());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API-Key erfolgreich gespeichert!')),
      );
      // Signalisiert dem HomeScreen beim Verlassen, dass Daten neu geladen werden sollen
      Navigator.pop(context, true);
    }
  }

  /// Löscht den API-Key aus den SharedPreferences.
  Future<void> _clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('divera_access_key');
    setState(() {
      _apiKeyController.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Accesskey gelöscht.')),
      );
    }
  }

  /// Öffnet die systeminternen Android-Akkueinstellungen via Intent.
  Future<void> _requestDisableBatteryOptimization() async {
    if (Platform.isAndroid) {
      const intent = AndroidIntent(
        action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
      );

      try {
        await intent.launch();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Einstellungen konnten nicht geöffnet werden.'),
            ),
          );
        }
      }
    }
  }

  /// Versteckter Trigger für den Debug-Modus (10x auf den Footer tippen).
  void _handleCopyrightTap() {
    if (_currentDebugState) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debug-Modus ist bereits aktiv!'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    setState(() {
      _debugClickCount++;
    });

    int remaining = 10 - _debugClickCount;

    if (remaining > 0 && remaining <= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Noch $remaining-mal tippen für Debug-Modus!'),
          duration: const Duration(milliseconds: 500),
        ),
      );
    } else if (remaining <= 0) {
      setState(() {
        _currentDebugState = true;
      });
      widget.onDebugModeChanged(true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚀 Debug-Modus aktiviert! (Gültig bis App-Neustart)'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Sektion: API-Konfiguration & Key-Buttons direkt darunter ---
            const Text(
              'API-Konfiguration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hinterlege hier deinen DIVERA Accesskey. Dieser bleibt sicher auf dem Smartphone gespeichert.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'DIVERA Accesskey',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
            ),
            const SizedBox(height: 12),

            // Speichern- und Löschen-Buttons direkt unter dem API-Schlüssel
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveApiKey,
                    icon: const Icon(Icons.save),
                    label: const Text('Key speichern'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _clearApiKey,
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('Löschen', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 12),

            // --- Sektion: Darstellung & Design (Sofortige Live-Übernahme) ---
            const Text(
              'Darstellung',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Dunkler Modus (Dark Mode)'),
              subtitle: const Text('Angenehm bei Einsätzen im Dunkeln'),
              secondary: const Icon(Icons.dark_mode),
              value: _isDarkMode,
              onChanged: (value) async {
                setState(() {
                  _isDarkMode = value;
                });
                // Sofort global umschalten und in SharedPreferences speichern
                themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('is_dark_mode', value);
              },
            ),
            const SizedBox(height: 16),

            // --- Sektion: Standard-Filter für die Hauptseite (Sofortige Live-Übernahme) ---
            const Text(
              'Anzeige auf der Hauptseite',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Wähle, aus welchem Zeitraum die Einsätze standardmäßig auf der Hauptseite angezeigt werden sollen.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedTimeframe,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_view_week),
              ),
              items: const [
                DropdownMenuItem(value: '24h', child: Text('Letzte 24 Stunden')),
                DropdownMenuItem(value: 'week', child: Text('Letzte Woche (7 Tage)')),
                DropdownMenuItem(value: 'month', child: Text('Letzter Monat (30 Tage)')),
                DropdownMenuItem(value: 'year', child: Text('Letztes Jahr (365 Tage)')),
                DropdownMenuItem(value: 'all', child: Text('Alle Einsätze')),
              ],
              onChanged: (value) async {
                if (value != null) {
                  setState(() => _selectedTimeframe = value);
                  // Direkt beim Auswählen persistent abspeichern
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('home_timeframe', value);
                }
              },
            ),

            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 12),

            // --- Sektion: Status des letzten Datenbankabrufs ---
            FutureBuilder<SharedPreferences>(
              future: SharedPreferences.getInstance(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final prefs = snapshot.data!;
                final lastSyncStr = prefs.getString('last_sync_time');
                final lastSuccess = prefs.getBool('last_sync_success') ?? false;

                String formattedTime = 'Noch kein Abruf erfolgt';
                if (lastSyncStr != null) {
                  final dt = DateTime.parse(lastSyncStr).toLocal();
                  formattedTime = '${dt.day}.${dt.month}.${dt.year} um ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} Uhr';
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Letzter Datenbankabruf',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              lastSyncStr == null
                                  ? Icons.help_outline
                                  : (lastSuccess ? Icons.check_circle : Icons.error),
                              color: lastSyncStr == null
                                  ? Colors.grey
                                  : (lastSuccess ? Colors.green : Colors.red),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Zeitpunkt: $formattedTime', style: const TextStyle(fontSize: 13)),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Status: ${lastSyncStr == null ? "Keine Daten" : (lastSuccess ? "Erfolgreich" : "Fehlgeschlagen")}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: lastSuccess ? Colors.green.shade700 : Colors.red.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // --- Sektion: Hintergrund-Synchronisation & Akku-Hinweise ---
            const Text(
              'Hintergrund-Synchronisation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Die App ruft automatisch alle 3 Stunden neue Einsatzdaten ab.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            if (Platform.isAndroid) ...[
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.battery_saver, color: Colors.orange.shade800),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Hintergrund-Sync Optimierung',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Damit Android den 3-Stunden-Sync nicht stoppt, wähle in den Akku-Einstellungen für diese App "Unbeschränkt".',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _requestDisableBatteryOptimization,
                        icon: const Icon(Icons.settings),
                        label: const Text('Akku-Einstellungen öffnen'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade800,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Debug-Anzeige, falls aktiv
            if (_currentDebugState) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.bug_report, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'Debug-Modus ist AKTIV',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 40),

            // --- Footer / App-Info mit verstecktem Debug-Trigger ---
            Center(
              child: GestureDetector(
                onTap: _handleCopyrightTap,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      const Text(
                        'Divera Stats v1.0.0',
                        style: TextStyle(
                            color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Build 100 • © Marcel Gäding',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}