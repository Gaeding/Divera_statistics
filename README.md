# Divera Stats 🚒📊

Divera Stats ist eine speziell für Einsatzkräfte entwickelte Begleit-App zur Auswertung und Verwaltung von Alarmierungen aus dem DIVERA 24/7 System. 
Die Anwendung speichert alle Einsatzdaten lokal auf dem Gerät und ermöglicht eine detaillierte, historische Analyse des eigenen Einsatzgeschehens – auch ohne aktive Internetverbindung.

---

# Hauptfunktionen

* **Intelligente Einsatzübersicht:** Auflistung aller Alarme mit dynamischen Zeitfiltern (Letzte 24h, Woche, Monat, Jahr, Alle) und farbigen Badges für den individuell gesetzten Status (z. B. "3 Min", "8 Min", "Nicht einsatzbereit").
* **Automatische Hintergrund-Synchronisation:** Die App ruft alle 3 Stunden automatisch neue Einsätze über die DIVERA-API ab, ohne dass die App geöffnet sein muss.
* **Statistiken & Auswertung:** Grafische Aufbereitung der Einsatzhistorie zur Analyse von Einsatzfrequenz und eigenem Ausrückeverhalten.
* **Datenschutzkonformes Backup-System:** Einsatzdaten können als JSON exportiert und auf andere Geräte übertragen werden. Sensible Informationen wie Einsatzadressen werden dabei automatisch aus der Exportdatei entfernt.
* **Offline-Verfügbarkeit:** Alle abgerufenen Daten werden in einer sicheren, lokalen SQLite-Datenbank auf dem Smartphone gespeichert.
* **Dark Mode:** Ein nativer, augenschonender Dunkelmodus für optimale Ablesbarkeit bei Nachteinsätzen.

---

# Installation & Setup (Für Endnutzer)

1. Lade dir die neueste Version der App unter **[Releases](https://github.com/Gaeding/Divera_statistics/releases/tag/V1.0.1)** als `.apk`-Datei herunter und installiere sie auf deinem Android-Smartphone.
2. Um deine Einsatzdaten abzurufen, benötigst du deinen persönlichen **DIVERA 24/7 Accesskey**.
3. **Wo finde ich den Key?**
* Logge dich im Browser bei DIVERA 24/7 ein.
* Gehe auf `Einstellungen` ➔ `Setup` (oder Profil-Einstellungen).
* Kopiere den `API-Accesskey` und füge ihn in der Divera Stats App unter "Einstellungen" ein.



*Hinweis zum Datenschutz: Diese App kommuniziert ausschließlich mit der offiziellen DIVERA 24/7 API. 
Der persönliche Accesskey sowie alle abgerufenen Einsatzdaten verlassen das Smartphone nicht und werden rein lokal verarbeitet.*

---

# Build-Anleitung (Für Entwickler)

Wenn du das Projekt selbst kompilieren oder weiterentwickeln möchtest, benötige das [Flutter SDK].

1. Repository klonen:
   
git clone https://github.com/Gaeding/divera_stats.git
cd divera_stats

2. Abhängigkeiten installieren:

flutter pub get

3. Release-APK bauen:

flutter build apk --release

Die fertige Datei liegt anschließend unter `build/app/outputs/flutter-apk/app-release.apk`.

---

# Tech-Stack

Dieses Projekt wurde mit folgenden Kerntechnologien umgesetzt:

* **Framework:** Flutter / Dart
* **Lokale Datenbank:** `sqflite`
* **Hintergrunddienste:** `workmanager`
* **Netzwerk:** `http`
* **Datenverwaltung & Export:** `shared_preferences`, `share_plus`, `path_provider`

---

# Roadmap / Geplante Features

* [x] Datenschutzkonformer Backup-Export
* [x] Erweitertes Hintergrund-Logging (72h)
* [x] iOS-Unterstützung (Apple App Store)
* [ ] Weitere Diagrammtypen in der Statistik-Ansicht
* [ ] Individuelle Filterung nach Einsatzstichworten

---

# Haftungsausschluss (Disclaimer)

**Dies ist ein inoffizielles Community-Projekt und keine offizielle Software der DIVERA GmbH.**
Die Nutzung dieser App erfolgt auf eigene Gefahr. Für verpasste Alarmierungen, fehlerhafte Darstellungen, Datenverlust oder sonstige technische Ausfälle wird keinerlei Haftung übernommen. **Diese App ersetzt unter keinen Umständen den offiziellen digitalen Meldeempfänger (Pager) oder die offizielle DIVERA 24/7-App.**

---

# Lizenz

Dieses Projekt steht unter der **MIT License**.
© 2026 Marcel Gäding
