# 🇩🇪 Deutsch

### **Neue Funktionen & Features**

* **Stundengenaues Uhrzeit-Diagramm:** Ein neues Balkendiagramm zeigt die Einsatzverteilung exakt nach Tagesstunden (0 bis 23 Uhr) an.
* **Erweiterte Stichwort-Analyse:** Ein zusätzliches Diagramm unterscheidet Einsätze nun übersichtlich nach den Hauptkategorien **FEU** (Feuer), **TH** (Technische Hilfeleistung), **BMA** (Brandmeldeanlage) und **Sonstige**.
* **Monats-Drill-Down mit Tagesansicht:** Durch Antippen eines Monatsbalkens schaltet das Diagramm tagesgenau auf die Ansicht des jeweiligen Monats (Tag 1 bis Ende des Monats) um.
* **Multi-Select Status-Filter:** Status-Rückmeldungen lassen sich nun bequem über eine Checkbox-Mehrfachauswahl filtern (standardmäßig sind alle Stati aktiviert).
* **API-Key Setup-Anleitung:** Eine integrierte Schritt-für-Schritt-Anleitung (abrufbar über die Hilfe-Buttons in den Einstellungen) unterstützt neue Nutzer beim Abrufen des DIVERA 24/7 API-Accesskeys.

### **Verbesserungen & UI-Optimierungen**

* **Stabile Stichwort-Filter:** Die Hauptgruppen **FEU** und **TH** sind fest im Dropdown-Filter verankert.
* **Optimierte Filter-UI:** Kompaktere Anordnung der "Alle/Keine"-Schaltflächen für die Status-Rückmeldungen für eine perfekte Darstellung auf allen Bildschirmgrößen.
* **Erweiterter Backup-Export:** Exportiert Einsatzdaten zuverlässig im JSON-Format, während sensible Adressdaten konsequent weggelassen werden.

### **Unter der Haube (Entwicklung & Stabilität)**

* Performance-Optimierungen beim Laden lokaler SQLite-Datenbanken (`DatabaseHelper`).
* Verfeinertes Aktivitäts-Logging (`app_activity.log`) zur präzisen Nachverfolgung von Vordergrund- und Hintergrund-Synchronisationen (Workmanager).

---

# 🇬🇧 English

### **New Functions & Features**

* **Hourly Distribution Chart:** A new bar chart displays the alarm distribution precisely by hour of the day (0 to 23 hours).
* **Extended Keyword Analysis:** An additional chart categorizes alarms clearly into main groups such as **FEU** (Fire), **TH** (Technical Rescue), **BMA** (Fire Alarm System), and **Others**.
* **Monthly Drill-Down with Daily View:** Tapping on a monthly bar seamlessly switches the chart to a day-by-day view (Day 1 to the end of the month) for that specific month.
* **Multi-Select Status Filter:** Status responses can now be easily filtered using a multi-select checkbox list (all statuses are enabled by default).
* **API Key Setup Guide:** An integrated step-by-step guide (accessible via help buttons in the settings) assists new users in retrieving their DIVERA 24/7 API access key.

### **Improvements & UI Optimizations**

* **Stable Keyword Filters:** The main groups **FEU** and **TH** are permanently anchored in the dropdown filter.
* **Optimized Filter UI:** A more compact arrangement of the "All/None" buttons for status responses to ensure a flawless layout across all screen sizes.
* **Advanced Backup Export:** Reliably exports alarm data in JSON format while consistently omitting sensitive address data.

### **Under the Hood (Development & Stability)**

* Performance optimizations when loading local SQLite databases (`DatabaseHelper`).
* Refined activity logging (`app_activity.log`) for precise tracking of foreground and background synchronizations (Workmanager).