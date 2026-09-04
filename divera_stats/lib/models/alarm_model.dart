import 'package:flutter/material.dart';

class Alarm {
  final int id;
  final String title;
  final String text;
  final DateTime date;
  final String address;
  final int myStatusId;

  Alarm({
    required this.id,
    required this.title,
    required this.text,
    required this.date,
    required this.address,
    required this.myStatusId,
  });

  factory Alarm.fromJson(Map<String, dynamic> json) {
    int rawDate = json['date'] is int
        ? json['date']
        : (int.tryParse(json['date']?.toString() ?? '0') ?? 0);

    DateTime parsedDate = rawDate > 0
        ? DateTime.fromMillisecondsSinceEpoch(rawDate * 1000)
        : DateTime.now();

    return Alarm(
      id: json['id'] is int
          ? json['id']
          : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      title: json['title'] ?? 'Kein Stichwort',
      text: json['text'] ?? '',
      date: parsedDate,
      address: json['address'] ?? '',
      myStatusId: json['ucr_self_status_id'] is int
          ? json['ucr_self_status_id']
          : (int.tryParse(json['ucr_self_status_id']?.toString() ?? '0') ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'text': text,
      'date': date.millisecondsSinceEpoch,
      'address': address,
      'myStatusId': myStatusId,
    };
  }

  factory Alarm.fromMap(Map<String, dynamic> map) {
    return Alarm(
      id: map['id'],
      title: map['title'],
      text: map['text'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      address: map['address'],
      myStatusId: map['myStatusId'] ?? 0,
    );
  }

  // Hilfsmethode für Bezeichnung & Farbe deiner Rückmeldung
  StatusInfo get myStatusInfo {
    switch (myStatusId) {
      case 72063:
        return StatusInfo(label: '3 Min', color: Colors.green);
      case 72066:
        return StatusInfo(label: '8 Min', color: Colors.yellow.shade700);
      case 72067:
        return StatusInfo(label: '>8 Min', color: Colors.orange);
      case 72062:
        return StatusInfo(label: 'Nicht einsatzbereit', color: Colors.red);
      case 72061:
        return StatusInfo(label: 'Außer Dienst', color: Colors.red.shade900);
      default:
        return StatusInfo(label: 'Keine Rückmeldung', color: Colors.grey);
    }
  }
}

class StatusInfo {
  final String label;
  final Color color;

  StatusInfo({required this.label, required this.color});
}