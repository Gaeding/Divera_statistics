import 'package:flutter/material.dart';

/// Hilfsklasse zur Bereitstellung der DIVERA API-Key Anleitung (Setup-Guide).
class ApiKeyGuideHelper {
  
  /// Zeigt den Dialog mit der Schritt-für-Schritt-Anleitung an.
  static void showGuideDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('DIVERA API-Key Anleitung'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Um deine Einsatzdaten abzurufen, benötigt die App deinen persönlichen DIVERA 24/7 Accesskey.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              const Text(
                'So findest du deinen Key im Browser:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              _buildGuideStep('1.', 'Logge dich am PC oder im Browser bei DIVERA 24/7 ein.'),
              _buildGuideStep('2.', 'Öffne oben rechts dein Profil bzw. gehe auf Einstellungen ➔ Setup.'),
              _buildGuideStep('3.', 'Scrolle zum Bereich für Schnittstellen / API.'),
              _buildGuideStep('4.', 'Kopiere den API-Accesskey und füge ihn in dieser App unter Einstellungen ein.'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade700),
                ),
                child: const Text(
                  'Hinweis: Der Key bleibt absolut sicher auf deinem Gerät und wird nur für die offizielle Abfrage genutzt.',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Verstanden'),
          ),
        ],
      ),
    );
  }

  /// Hilfsmethode für die strukturierten Schritte
  static Widget _buildGuideStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(number, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}