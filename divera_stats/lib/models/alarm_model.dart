import 'package:flutter/material.dart';

/// Repräsentiert einen einzelnen DIVERA 24/7 Einsatz/Alarm.
class Alarm {
  final int id;
  final String title;
  final String text;
  final DateTime date;
  final String address;
  final int myStatusId; // Eigene Rückmeldung/Status-ID aus DIVERA

  Alarm({
    required this.id,
    required this.title,
    required this.text,
    required this.date,
    required this.address,
    required this.myStatusId,
  });

  /// Erstellt eine `Alarm`-Instanz aus der DIVERA API JSON-Antwort.
  /// Enthält Fallbacks & Konvertierungen für abweichende Datentypen.
  factory Alarm.fromJson(Map<String, dynamic> json) {
    // Unix-Timestamp (in Sekunden) sichern und parsen
    int rawDate = json['date'] is int
        ? json['date']
        : (int.tryParse(json['date']?.toString() ?? '0') ?? 0);

    // Timestamp von Sekunden in Millisekunden umrechnen für DateTime
    DateTime parsedDate = rawDate > 0
        ? DateTime.fromMillisecondsSinceEpoch(rawDate * 1000)
        : DateTime.now();

    return Alarm(
      // ID sicher parsen (falls API String statt Int liefert)
      id: json['id'] is int
          ? json['id']
          : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      title: json['title'] ?? 'Kein Stichwort',
      text: json['text'] ?? '',
      date: parsedDate,
      address: json['address'] ?? '',
      // Eigene Status-ID aus dem DIVERA Feld 'ucr_self_status_id' extrahieren
      myStatusId: json['ucr_self_status_id'] is int
          ? json['ucr_self_status_id']
          : (int.tryParse(json['ucr_self_status_id']?.toString() ?? '0') ?? 0),
    );
  }

  /// Wandelt das Objekt in ein Map-Format um, um es in der SQLite-Datenbank zu speichern.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'text': text,
      'date': date.millisecondsSinceEpoch, // Datum als Millisekunden-Timestamp speichern
      'address': address,
      'myStatusId': myStatusId,
    };
  }

  /// Wandelt das Objekt in ein Map-Format um, um es für den Backup-Export als JSON zu nutzen.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'text': text,
      'date': date.millisecondsSinceEpoch,
      'address': address,
      'ucr_self_status_id': myStatusId, // Entspricht dem DIVERA-Feldnamen beim Parsen
    };
  }

  /// Erstellt ein `Alarm`-Objekt aus einem aus der SQLite-Datenbank gelesenen Eintrag.
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

  /// Berechnet die visuelle Status-Information (Text-Label und Badge-Farbe)
  /// basierend auf der individuellen DIVERA Status-ID (`myStatusId`).
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

/// Hilfsklasse zur einfachen Weitergabe von UI-Eigenschaften für Status-Badges.
class StatusInfo {
  final String label;
  final Color color;

  StatusInfo({required this.label, required this.color});
}