import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final TextEditingController _apiKeyController = TextEditingController();
  int _debugClickCount = 0;
  late bool _currentDebugState;
  String _selectedTimeframe = 'week'; // Standard: Letzte Woche

  @override
  void initState() {
    super.initState();
    _currentDebugState = widget.isDebugMode;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKeyController.text = prefs.getString('divera_access_key') ?? '';
      _selectedTimeframe = prefs.getString('home_timeframe') ?? 'week';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('divera_access_key', _apiKeyController.text.trim());
    await prefs.setString('home_timeframe', _selectedTimeframe);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Einstellungen gespeichert!')),
      );
      Navigator.pop(context, true);
    }
  }

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
            // API-Konfiguration
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
            const SizedBox(height: 24),

            // Filter für Hauptseite
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
                DropdownMenuItem(
                  value: '24h',
                  child: Text('Letzte 24 Stunden'),
                ),
                DropdownMenuItem(
                  value: 'week',
                  child: Text('Letzte Woche (7 Tage)'),
                ),
                DropdownMenuItem(
                  value: 'month',
                  child: Text('Letzter Monat (30 Tage)'),
                ),
                DropdownMenuItem(
                  value: 'year',
                  child: Text('Letztes Jahr (365 Tage)'),
                ),
                DropdownMenuItem(
                  value: 'all',
                  child: Text('Alle Einsätze'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedTimeframe = value);
                }
              },
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveSettings,
                    icon: const Icon(Icons.save),
                    label: const Text('Speichern'),
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
                  label: const Text('Löschen',
                      style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 12),

            // Hintergrund-Synchronisation
            const Text(
              'Hintergrund-Synchronisation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Die App ruft automatisch alle 3 Stunden neue Einsatzdaten ab. Damit Android die Aufgabe im Hintergrund nicht blockiert, sollte die Akku-Optimierung angepasst werden.',
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
                          Icon(Icons.battery_saver,
                              color: Colors.orange.shade800),
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
                        style: TextStyle(fontSize: 12),
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
              const SizedBox(height: 8),
              const ExpansionTile(
                title: Text(
                  'Hinweis für Samsung, Xiaomi & Huawei',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      'Einige Hersteller nutzen eigene Energiesparmodi. Stelle sicher, dass unter:\n'
                      '• Einstellungen -> Apps -> DIVERA Einsatzstatistik -> Akku\n'
                      'die Option "Unbeschränkt" bzw. "Keine Einschränkungen" gewählt ist.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ] else if (Platform.isIOS) ...[
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    'Unter iOS entscheidet das System automatisch anhand der Nutzungshäufigkeit über die Hintergrund-Aktualisierung.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],

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

            Center(
              child: GestureDetector(
                onTap: _handleCopyrightTap,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      const Text(
                        'DIVERA Einsatzstatistik v1.0.0',
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