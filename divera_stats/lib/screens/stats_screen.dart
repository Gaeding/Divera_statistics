import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/alarm_model.dart';

/// Enum zur zeitlichen Filterung im Statistik-Bereich.
enum DateFilter { all, currentYear, currentMonth, currentWeek, lastYear }

/// Statistik-Bildschirm der App.
/// Bietet interaktive Filter und visualisiert Einsätze über Torten-, Wochentags- und Monatsdiagramme.
class StatsScreen extends StatefulWidget {
  final List<Alarm> alarms;

  const StatsScreen({super.key, required this.alarms});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  DateFilter _selectedDateFilter = DateFilter.all;
  String _selectedKeyword = 'Alle';

  /// Extrahiert alle eindeutigen Einsatz-Stichwörter für das Filter-Dropdown.
  List<String> _getAvailableKeywords() {
    Set<String> keywords = {'Alle'};
    for (var alarm in widget.alarms) {
      if (alarm.title.isNotEmpty) {
        keywords.add(alarm.title);
      }
    }
    return keywords.toList();
  }

  /// Filtert die Alarm-Liste dynamisch nach gewähltem Zeitraum und Stichwort.
  List<Alarm> get _filteredAlarms {
    final now = DateTime.now();

    return widget.alarms.where((alarm) {
      bool matchesDate = true;
      switch (_selectedDateFilter) {
        case DateFilter.currentYear:
          matchesDate = alarm.date.year == now.year;
          break;
        case DateFilter.currentMonth:
          matchesDate =
              alarm.date.year == now.year && alarm.date.month == now.month;
          break;
        case DateFilter.currentWeek:
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final endOfWeek = startOfWeek.add(const Duration(days: 7));
          matchesDate = alarm.date.isAfter(
                  startOfWeek.subtract(const Duration(seconds: 1))) &&
              alarm.date.isBefore(endOfWeek);
          break;
        case DateFilter.lastYear:
          matchesDate = alarm.date.year == (now.year - 1);
          break;
        case DateFilter.all:
        default:
          matchesDate = true;
          break;
      }

      bool matchesKeyword = true;
      if (_selectedKeyword != 'Alle') {
        matchesKeyword = alarm.title.toLowerCase().contains(_selectedKeyword.toLowerCase());
      }

      return matchesDate && matchesKeyword;
    }).toList();
  }

  /// Aggregiert Einsätze nach Monaten ("MM/YY").
  Map<String, int> _getMonthlyStats(List<Alarm> filtered) {
    Map<String, int> stats = {};
    for (var alarm in filtered) {
      String monthKey =
          "${alarm.date.month.toString().padLeft(2, '0')}/${alarm.date.year.toString().substring(2)}";
      stats[monthKey] = (stats[monthKey] ?? 0) + 1;
    }
    return stats;
  }

  /// Aggregiert Einsätze nach Wochentagen (Montag bis Sonntag).
  Map<String, int> _getWeekdayStats(List<Alarm> filtered) {
    Map<String, int> stats = {
      'Mo': 0,
      'Di': 0,
      'Mi': 0,
      'Do': 0,
      'Fr': 0,
      'Sa': 0,
      'So': 0,
    };

    const weekdayKeys = ['', 'Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

    for (var alarm in filtered) {
      int wd = alarm.date.weekday; // 1 = Montag, 7 = Sonntag
      if (wd >= 1 && wd <= 7) {
        String key = weekdayKeys[wd];
        stats[key] = (stats[key] ?? 0) + 1;
      }
    }
    return stats;
  }

  /// Zählt die Verteilung der eigenen Rückmeldungen (`myStatusId`).
  Map<String, int> _getStatusStats(List<Alarm> filtered) {
    Map<String, int> stats = {
      '3 Min': 0,
      '8 Min': 0,
      '>8 Min': 0,
      'Nicht einsatzbereit': 0,
      'Außer Dienst': 0,
      'Sonstige': 0,
    };

    for (var alarm in filtered) {
      switch (alarm.myStatusId) {
        case 72063:
          stats['3 Min'] = (stats['3 Min'] ?? 0) + 1;
          break;
        case 72066:
          stats['8 Min'] = (stats['8 Min'] ?? 0) + 1;
          break;
        case 72067:
          stats['>8 Min'] = (stats['>8 Min'] ?? 0) + 1;
          break;
        case 72062:
          stats['Nicht einsatzbereit'] =
              (stats['Nicht einsatzbereit'] ?? 0) + 1;
          break;
        case 72061:
          stats['Außer Dienst'] = (stats['Außer Dienst'] ?? 0) + 1;
          break;
        default:
          stats['Sonstige'] = (stats['Sonstige'] ?? 0) + 1;
      }
    }
    return stats;
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredAlarms;
    final statusStats = _getStatusStats(filteredList);
    final monthlyStats = _getMonthlyStats(filteredList);
    final weekdayStats = _getWeekdayStats(filteredList);
    final availableKeywords = _getAvailableKeywords();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Einsatzstatistik'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter-Bereich am oberen Bildschirmrand
          Container(
            padding: const EdgeInsets.all(12.0),
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade900
                : Colors.grey.shade100,
            child: Column(
              children: [
                // Zeitraum-Auswahl
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    const Text('Zeitraum:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<DateFilter>(
                        value: _selectedDateFilter,
                        isExpanded: true,
                        underline: Container(height: 1, color: Colors.grey),
                        items: const [
                          DropdownMenuItem(value: DateFilter.all, child: Text('Alle Daten')),
                          DropdownMenuItem(value: DateFilter.currentYear, child: Text('Dieses Jahr')),
                          DropdownMenuItem(value: DateFilter.currentMonth, child: Text('Dieser Monat')),
                          DropdownMenuItem(value: DateFilter.currentWeek, child: Text('Diese Woche')),
                          DropdownMenuItem(value: DateFilter.lastYear, child: Text('Letztes Jahr')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedDateFilter = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Stichwort-Auswahl
                Row(
                  children: [
                    const Icon(Icons.label, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    const Text('Stichwort:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<String>(
                        value: availableKeywords.contains(_selectedKeyword)
                            ? _selectedKeyword
                            : 'Alle',
                        isExpanded: true,
                        underline: Container(height: 1, color: Colors.grey),
                        items: availableKeywords.map((keyword) {
                          return DropdownMenuItem(
                            value: keyword,
                            child: Text(keyword),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedKeyword = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Scrollbarer Statistik-Bereich
          Expanded(
            child: filteredList.isEmpty
                ? const Center(
                    child: Text('Keine Einsätze für die ausgewählten Filter gefunden.'),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Kennzahl-Kachel: Summe der gefilterten Einsätze
                        Card(
                          color: Colors.redAccent.shade100,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Gefilterte Einsätze',
                                  style: TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                                Text(
                                  '${filteredList.length}',
                                  style: const TextStyle(
                                      fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Tortendiagramm: Rückmeldungen
                        const Text(
                          'Verteilung deiner Rückmeldungen',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 35,
                              sections: [
                                if ((statusStats['3 Min'] ?? 0) > 0)
                                  PieChartSectionData(
                                    color: Colors.green,
                                    value: statusStats['3 Min']!.toDouble(),
                                    title: '${statusStats['3 Min']}',
                                    radius: 45,
                                    titleStyle: const TextStyle(
                                        color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                if ((statusStats['8 Min'] ?? 0) > 0)
                                  PieChartSectionData(
                                    color: Colors.yellow.shade700,
                                    value: statusStats['8 Min']!.toDouble(),
                                    title: '${statusStats['8 Min']}',
                                    radius: 45,
                                    titleStyle: const TextStyle(
                                        color: Colors.black, fontWeight: FontWeight.bold),
                                  ),
                                if ((statusStats['>8 Min'] ?? 0) > 0)
                                  PieChartSectionData(
                                    color: Colors.orange,
                                    value: statusStats['>8 Min']!.toDouble(),
                                    title: '${statusStats['>8 Min']}',
                                    radius: 45,
                                    titleStyle: const TextStyle(
                                        color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                if ((statusStats['Nicht einsatzbereit'] ?? 0) > 0)
                                  PieChartSectionData(
                                    color: Colors.red,
                                    value: statusStats['Nicht einsatzbereit']!.toDouble(),
                                    title: '${statusStats['Nicht einsatzbereit']}',
                                    radius: 45,
                                    titleStyle: const TextStyle(
                                        color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                if ((statusStats['Außer Dienst'] ?? 0) > 0)
                                  PieChartSectionData(
                                    color: Colors.red.shade900,
                                    value: statusStats['Außer Dienst']!.toDouble(),
                                    title: '${statusStats['Außer Dienst']}',
                                    radius: 45,
                                    titleStyle: const TextStyle(
                                        color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Legende zum Tortendiagramm
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            _buildLegendItem('3 Min', Colors.green),
                            _buildLegendItem('8 Min', Colors.yellow.shade700),
                            _buildLegendItem('>8 Min', Colors.orange),
                            _buildLegendItem('Nicht einsatzbereit', Colors.red),
                            _buildLegendItem('Außer Dienst', Colors.red.shade900),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Säulendiagramm: Einsätze nach Wochentagen
                        const Text(
                          'Einsätze nach Wochentagen',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: BarChart(
                            BarChartData(
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      List<String> keys = weekdayStats.keys.toList();
                                      int index = value.toInt();
                                      if (index >= 0 && index < keys.length) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 6),
                                          child: Text(
                                            keys[index],
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        );
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                              ),
                              barGroups: weekdayStats.entries.toList().asMap().entries.map((entry) {
                                return BarChartGroupData(
                                  x: entry.key,
                                  barRods: [
                                    BarChartRodData(
                                      toY: entry.value.value.toDouble(),
                                      color: Colors.orangeAccent,
                                      width: 16,
                                      borderRadius: BorderRadius.circular(4),
                                    )
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Säulendiagramm: Einsätze nach Monaten
                        if (monthlyStats.isNotEmpty) ...[
                          const Text(
                            'Einsätze nach Monaten',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 200,
                            child: BarChart(
                              BarChartData(
                                borderData: FlBorderData(show: false),
                                titlesData: FlTitlesData(
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        List<String> keys = monthlyStats.keys.toList();
                                        int index = value.toInt();
                                        if (index >= 0 && index < keys.length) {
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 6),
                                            child: Text(
                                              keys[index],
                                              style: const TextStyle(fontSize: 10),
                                            ),
                                          );
                                        }
                                        return const Text('');
                                      },
                                    ),
                                  ),
                                ),
                                barGroups: monthlyStats.entries.toList().asMap().entries.map((entry) {
                                  return BarChartGroupData(
                                    x: entry.key,
                                    barRods: [
                                      BarChartRodData(
                                        toY: entry.value.value.toDouble(),
                                        color: Colors.redAccent,
                                        width: 16,
                                        borderRadius: BorderRadius.circular(4),
                                      )
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Hilfswidget zum Erstellen eines Legenden-Eintrags.
  Widget _buildLegendItem(String title, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(title, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}