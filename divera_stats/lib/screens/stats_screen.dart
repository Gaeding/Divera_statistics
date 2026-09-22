import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/alarm_model.dart';

/// Bildschirm zur visuellen Aufbereitung der Einsatzstatistiken
/// inklusive ausklappbarer Filter, Multi-Select Status-Filter, Diagrammen
/// und Monats-Drill-Down, der bei Klick auf einen Monat die tagesgenaue Ansicht zeigt.
class StatsScreen extends StatefulWidget {
  final List<Alarm> alarms;

  const StatsScreen({super.key, required this.alarms});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  // Filter-Zustände
  String _selectedTimeframe = 'all';
  String _selectedKeyword = 'all';

  // Multi-Select Status-Filter: Standardmäßig sind alle relevanten IDs aktiv
  final Set<String> _selectedStatusValues = {
    '72063', // 3 Min
    '72066', // 8 Min
    '72067', // >8 Min
    '72062', // Nicht einsatzbereit
    '72061', // Außer Dienst
    '0',     // Keine Rückmeldung
  };

  // Zustand für den aktiven Monats-Drill-Down (z.B. "09/26")
  String? _drillDownMonth;

  @override
  Widget build(BuildContext context) {
    // 1. Stichworte dynamisch ermitteln und FEU, TH, BMA fix einbinden
    final Set<String> keywordsSet = {'all', 'FEU', 'TH', 'BMA'};
    for (var alarm in widget.alarms) {
      if (alarm.title.isNotEmpty) {
        keywordsSet.add(alarm.title.trim());
      }
    }
    final List<String> availableKeywords = keywordsSet.toList();

    // 2. Gefilterte Alarme ermitteln (inkl. Drill-Down)
    final filteredAlarms = _getFilteredAlarms();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Einsatzstatistik'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // --- AUSKLAPPBARE FILTER-CARD ---
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                initiallyExpanded: false,
                leading: const Icon(Icons.filter_list, color: Colors.redAccent),
                title: Text(
                  'Filter anpassen (${filteredAlarms.length} Einsätze)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: Text(
                  _getFilterSummaryText(),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        
                        // Zeitraum Filter
                        DropdownButtonFormField<String>(
                          value: _selectedTimeframe,
                          decoration: const InputDecoration(
                            labelText: 'Zeitraum',
                            prefixIcon: Icon(Icons.calendar_today, size: 20),
                          ),
                          items: const [
                            DropdownMenuItem(value: '24h', child: Text('Letzte 24 Stunden')),
                            DropdownMenuItem(value: 'week', child: Text('Letzte 7 Tage')),
                            DropdownMenuItem(value: 'month', child: Text('Letzte 30 Tage')),
                            DropdownMenuItem(value: 'year', child: Text('Letztes Jahr (365 Tage)')),
                            DropdownMenuItem(value: 'all', child: Text('Alle Daten')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedTimeframe = val);
                          },
                        ),
                        const SizedBox(height: 12),

                        // Stichwort Filter
                        DropdownButtonFormField<String>(
                          value: availableKeywords.contains(_selectedKeyword) ? _selectedKeyword : 'all',
                          decoration: const InputDecoration(
                            labelText: 'Stichwort',
                            prefixIcon: Icon(Icons.label_outline, size: 20),
                          ),
                          items: availableKeywords.map((kw) {
                            return DropdownMenuItem(
                              value: kw,
                              child: Text(kw == 'all' ? 'Alle Stichworte' : kw),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedKeyword = val);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Status-Rückmeldungen Überschrift & Aktionen
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'Status-Rückmeldungen:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedStatusValues.addAll(['72063', '72066', '72067', '72062', '72061', '0']);
                                    });
                                  },
                                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(40, 30)),
                                  child: const Text('Alle', style: TextStyle(fontSize: 12)),
                                ),
                                const Text('•', style: TextStyle(color: Colors.grey)),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedStatusValues.clear();
                                    });
                                  },
                                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(40, 30)),
                                  child: const Text('Keine', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Checkbox-Liste für Status-Rückmeldungen
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade700),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              _buildCheckboxTile('Nur 3 Min', '72063', Colors.green),
                              _buildCheckboxTile('Nur 8 Min', '72066', Colors.yellow.shade700),
                              _buildCheckboxTile('Nur >8 Min', '72067', Colors.orange),
                              _buildCheckboxTile('Nicht einsatzbereit', '72062', Colors.red),
                              _buildCheckboxTile('Außer Dienst', '72061', Colors.red.shade900),
                              _buildCheckboxTile('Keine Rückmeldung', '0', Colors.grey),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --- DIAGRAMME & AUSWERTUNGEN ---
            if (filteredAlarms.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'Keine Einsätze für die gewählte Filterkombination vorhanden.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Auswertung basierend auf ${filteredAlarms.length} gefilterten Einsätzen',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade400),
                ),
              ),

              // 1. Status-Verteilung (PieChart)
              const Text(
                'Status-Verteilung',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: _buildStatusPieChart(filteredAlarms),
              ),

              const SizedBox(height: 24),

              // 2. Stichwort-Verteilung (FEU, TH, BMA, Sonstige)
              const Text(
                'Einsätze nach Stichwort (FEU / TH / BMA)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: _buildKeywordPieChart(filteredAlarms),
              ),

              const SizedBox(height: 24),

              // 3. Wochentags-Diagramm
              const Text(
                'Einsätze nach Wochentagen',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: _buildWeekdayChart(filteredAlarms),
              ),

              const SizedBox(height: 24),

              // 4. Uhrzeit-Diagramm (Stundengenau)
              const Text(
                'Einsätze nach Uhrzeit (Stunden)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: _buildHourlyChart(filteredAlarms),
              ),

              const SizedBox(height: 24),

              // 5. Monats-Diagramm / Tages-Drill-Down Chart
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _drillDownMonth == null
                        ? 'Einsätze nach Monaten (Tippen für Tagesansicht)'
                        : 'Tagesansicht im Monat $_drillDownMonth',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (_drillDownMonth != null)
                    TextButton(
                      onPressed: () => setState(() => _drillDownMonth = null),
                      child: const Text('Monate anzeigen', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: _drillDownMonth == null
                    ? _buildMonthChart(filteredAlarms)
                    : _buildDailyChartForMonth(filteredAlarms, _drillDownMonth!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxTile(String label, String valueKey, Color color) {
    final isSelected = _selectedStatusValues.contains(valueKey);
    return CheckboxListTile(
      title: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        ],
      ),
      value: isSelected,
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      onChanged: (bool? checked) {
        setState(() {
          if (checked == true) {
            _selectedStatusValues.add(valueKey);
          } else {
            _selectedStatusValues.remove(valueKey);
          }
        });
      },
    );
  }

  String _getFilterSummaryText() {
    List<String> activeFilters = [];
    if (_selectedTimeframe != 'all') activeFilters.add('Zeit: $_selectedTimeframe');
    if (_selectedKeyword != 'all') activeFilters.add('Stichwort: $_selectedKeyword');
    if (_drillDownMonth != null) activeFilters.add('Monat: $_drillDownMonth');
    if (_selectedStatusValues.length < 6) {
      activeFilters.add('Status (${_selectedStatusValues.length}/6)');
    }

    return activeFilters.isEmpty ? 'Alle Einsätze (keine Filter aktiv)' : activeFilters.join(' • ');
  }

  List<Alarm> _getFilteredAlarms() {
    final now = DateTime.now();

    return widget.alarms.where((alarm) {
      // 1. Zeit-Filter
      bool matchesTime = true;
      switch (_selectedTimeframe) {
        case '24h':
          matchesTime = alarm.date.isAfter(now.subtract(const Duration(hours: 24)));
          break;
        case 'week':
          matchesTime = alarm.date.isAfter(now.subtract(const Duration(days: 7)));
          break;
        case 'month':
          matchesTime = alarm.date.isAfter(now.subtract(const Duration(days: 30)));
          break;
        case 'year':
          matchesTime = alarm.date.isAfter(now.subtract(const Duration(days: 365)));
          break;
      }
      if (!matchesTime) return false;

      // 2. Stichwort-Filter
      if (_selectedKeyword != 'all') {
        final title = alarm.title.trim();
        if (_selectedKeyword == 'FEU') {
          if (!title.contains('FEU')) return false;
        } else if (_selectedKeyword == 'TH') {
          if (!title.contains('TH')) return false;
        } else if (_selectedKeyword == 'BMA') {
          if (!title.contains('BMA')) return false;
        } else {
          if (title != _selectedKeyword) return false;
        }
      }

      // 3. Status-Filter (Mehrfachauswahl prüfen)
      final statusKey = alarm.myStatusId.toString();
      if (!_selectedStatusValues.contains(statusKey)) {
        return false;
      }

      return true;
    }).toList();
  }

  Widget _buildStatusPieChart(List<Alarm> alarms) {
    Map<String, int> statusCounts = {};
    for (var alarm in alarms) {
      final label = alarm.myStatusInfo.label;
      statusCounts[label] = (statusCounts[label] ?? 0) + 1;
    }

    final sections = statusCounts.entries.map((entry) {
      final color = _getStatusColor(entry.key);
      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${entry.value}',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 35,
              sections: sections,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: statusCounts.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _getStatusColor(entry.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${entry.key} (${entry.value})',
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildKeywordPieChart(List<Alarm> alarms) {
    int feuCount = 0;
    int thCount = 0;
    int bmaCount = 0;
    int otherCount = 0;

    for (var alarm in alarms) {
      final title = alarm.title.toUpperCase();
      if (title.contains('BMA')) {
        bmaCount++;
      } else if (title.contains('FEU')) {
        feuCount++;
      } else if (title.contains('TH')) {
        thCount++;
      } else {
        otherCount++;
      }
    }

    Map<String, int> keywordData = {};
    if (feuCount > 0) keywordData['FEU'] = feuCount;
    if (thCount > 0) keywordData['TH'] = thCount;
    if (bmaCount > 0) keywordData['BMA'] = bmaCount;
    if (otherCount > 0) keywordData['Sonstige'] = otherCount;

    if (keywordData.isEmpty) {
      return const Center(child: Text('Keine Stichworte vorhanden'));
    }

    final sections = keywordData.entries.map((entry) {
      final color = _getKeywordColor(entry.key);
      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${entry.value}',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 35,
              sections: sections,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: keywordData.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _getKeywordColor(entry.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${entry.key} (${entry.value})',
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String label) {
    if (label.contains('3')) return Colors.green;
    if (label.contains('8')) return Colors.yellow.shade700;
    if (label.contains('Nicht') || label.contains('nein')) return Colors.red;
    if (label.contains('Außer')) return Colors.red.shade900;
    return Colors.grey;
  }

  Color _getKeywordColor(String keyword) {
    switch (keyword) {
      case 'FEU':
        return Colors.deepOrange;
      case 'TH':
        return Colors.blue;
      case 'BMA':
        return Colors.purple;
      case 'Sonstige':
      default:
        return Colors.blueGrey;
    }
  }

  Widget _buildWeekdayChart(List<Alarm> alarms) {
    List<int> weekdayCounts = List.filled(7, 0);
    for (var alarm in alarms) {
      weekdayCounts[alarm.date.weekday - 1]++;
    }

    int maxY = weekdayCounts.reduce((a, b) => a > b ? a : b);
    if (maxY < 4) maxY = 4;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY.toDouble(),
        barTouchData: BarTouchDataNotifier().touchData,
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 28,
              getTitlesWidget: (val, meta) => Text(
                val.toInt().toString(),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                const days = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
                if (val.toInt() >= 0 && val.toInt() < days.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(days[val.toInt()], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        gridData: FlGridData(show: true, horizontalInterval: 1, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(7, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: weekdayCounts[i].toDouble(),
                color: Colors.orangeAccent,
                width: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildHourlyChart(List<Alarm> alarms) {
    List<int> hourlyCounts = List.filled(24, 0);
    for (var alarm in alarms) {
      hourlyCounts[alarm.date.hour]++;
    }

    int maxY = hourlyCounts.reduce((a, b) => a > b ? a : b);
    if (maxY < 4) maxY = 4;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY.toDouble(),
        barTouchData: BarTouchDataNotifier().touchData,
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 28,
              getTitlesWidget: (val, meta) => Text(
                val.toInt().toString(),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                int hour = val.toInt();
                if (hour >= 0 && hour < 24 && hour % 3 == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text('${hour}h', style: const TextStyle(fontSize: 10)),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        gridData: FlGridData(show: true, horizontalInterval: 1, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(24, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: hourlyCounts[i].toDouble(),
                color: Colors.amber,
                width: 8,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          );
        }),
      ),
    );
  }

  /// Monats-Diagramm mit Touch/Drill-Down auf den jeweiligen Monat
  Widget _buildMonthChart(List<Alarm> alarms) {
    Map<String, int> monthCounts = {};
    for (var alarm in alarms) {
      final key = DateFormat('MM/yy').format(alarm.date);
      monthCounts[key] = (monthCounts[key] ?? 0) + 1;
    }

    final sortedKeys = monthCounts.keys.toList()..sort();

    int maxY = monthCounts.values.isEmpty ? 4 : monthCounts.values.reduce((a, b) => a > b ? a : b);
    if (maxY < 4) maxY = 4;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY.toDouble(),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final monthKey = sortedKeys[group.x.toInt()];
              return BarTooltipItem(
                '$monthKey\n${rod.toY.toInt()} Einsätze (Tippen für Tagesansicht)',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
              );
            },
          ),
          touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
            if (event is FlTapUpEvent && response != null && response.spot != null) {
              final touchedIndex = response.spot!.touchedBarGroupIndex;
              if (touchedIndex >= 0 && touchedIndex < sortedKeys.length) {
                final selectedMonth = sortedKeys[touchedIndex];
                setState(() {
                  _drillDownMonth = selectedMonth;
                });
              }
            }
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 28,
              getTitlesWidget: (val, meta) => Text(
                val.toInt().toString(),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                if (val.toInt() >= 0 && val.toInt() < sortedKeys.length) {
                  final monthStr = sortedKeys[val.toInt()];
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      monthStr,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        gridData: FlGridData(show: true, horizontalInterval: 1, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(sortedKeys.length, (i) {
          final monthStr = sortedKeys[i];
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: monthCounts[monthStr]!.toDouble(),
                color: Colors.redAccent,
                width: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
      ),
    );
  }

  /// NEU: Tagesgenaues Diagramm für den ausgewählten Monat (Drill-Down Ansicht)
  Widget _buildDailyChartForMonth(List<Alarm> alarms, String monthYearKey) {
    // Teile z.B. "09/26" in Monat und Jahr auf
    final parts = monthYearKey.split('/');
    if (parts.length != 2) return const SizedBox.shrink();
    
    int targetMonth = int.tryParse(parts[0]) ?? 1;
    int targetYear = 2000 + (int.tryParse(parts[1]) ?? 0);

    // Ermittle die Anzahl der Tage im Monat
    int daysInMonth = DateTime(targetYear, targetMonth + 1, 0).day;

    // Zähle die Alarme tagesgenau (Index 0 = Tag 1, Index 30 = Tag 31)
    List<int> dailyCounts = List.filled(daysInMonth, 0);
    for (var alarm in alarms) {
      if (alarm.date.month == targetMonth && alarm.date.year == targetYear) {
        int dayIndex = alarm.date.day - 1;
        if (dayIndex >= 0 && dayIndex < daysInMonth) {
          dailyCounts[dayIndex]++;
        }
      }
    }

    int maxY = dailyCounts.isEmpty ? 4 : dailyCounts.reduce((a, b) => a > b ? a : b);
    if (maxY < 4) maxY = 4;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY.toDouble(),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              int day = group.x.toInt() + 1;
              return BarTooltipItem(
                'Tag $day.$monthYearKey\n${rod.toY.toInt()} Einsätze',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 28,
              getTitlesWidget: (val, meta) => Text(
                val.toInt().toString(),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                int day = val.toInt() + 1;
                // Zeige alle 5 Tage eine Beschriftung (1, 5, 10, 15, 20, 25, 30), damit es übersichtlich bleibt
                if (day == 1 || day % 5 == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text('$day.', style: const TextStyle(fontSize: 9)),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        gridData: FlGridData(show: true, horizontalInterval: 1, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(daysInMonth, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: dailyCounts[i].toDouble(),
                color: Colors.amber,
                width: daysInMonth > 28 ? 6 : 10, // Schmalere Balken bei 31 Tagen für saubere Abstände
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class BarTouchDataNotifier {
  BarTouchData get touchData => BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            return BarTooltipItem(
              rod.toY.toInt().toString(),
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            );
          },
        ),
      );
}