import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class FireGameDialog extends StatefulWidget {
  const FireGameDialog({super.key});

  @override
  State<FireGameDialog> createState() => _FireGameDialogState();
}

class _FireGameDialogState extends State<FireGameDialog> {
  int _score = 0;
  int _timeLeft = 15; // 15 Sekunden Zeit
  bool _isPlaying = true;
  Timer? _gameTimer;
  Timer? _fireTimer;
  
  // Liste der aktiven Feuer mit relativen Positionen (0.0 bis 1.0)
  final List<FireItem> _fires = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    // Timer für den Countdown des Spiels
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _endGame();
      }
    });

    // Timer, der regelmäßig neue Feuer auf dem Bildschirm spawnt
    _fireTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (_isPlaying) {
        setState(() {
          // Maximal 8 Feuer gleichzeitig auf dem Bildschirm
          if (_fires.length < 8) {
            _fires.add(
              FireItem(
                id: DateTime.now().millisecondsSinceEpoch,
                // Zufällige Position im Spielfeld
                x: _random.nextDouble() * 0.8 + 0.1,
                y: _random.nextDouble() * 0.7 + 0.15,
              ),
            );
          }
        });
      }
    });
  }

  void _extinguishFire(FireItem fire) {
    if (!_isPlaying) return;
    setState(() {
      _fires.remove(fire);
      _score += 10; // 10 Punkte pro gelöschtem Feuer
    });
  }

  void _endGame() {
    _gameTimer?.cancel();
    _fireTimer?.cancel();
    setState(() {
      _isPlaying = false;
    });
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _fireTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey.shade900,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header mit Score und Timer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text('Score: $_score', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                Text(
                  'Zeit: ${_timeLeft}s',
                  style: TextStyle(
                    color: _timeLeft <= 5 ? Colors.red : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.grey),
            
            // Spielfeld für die Feuer
            Expanded(
              child: Stack(
                children: [
                  if (_isPlaying && _fires.isEmpty)
                    const Center(
                      child: Text('Lösche die Brände!', style: TextStyle(color: Colors.white54)),
                    ),
                  
                  // Rendere alle aktiven Feuer an ihrer Position
                  for (var fire in _fires)
                    Positioned(
                      left: fire.x * (MediaQuery.of(context).size.width * 0.75 - 50),
                      top: fire.y * (MediaQuery.of(context).size.height * 0.45 - 50),
                      child: GestureDetector(
                        onTap: () => _extinguishFire(fire),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                            Icons.local_fire_department,
                            color: Colors.redAccent,
                            size: 48,
                          ),
                        ),
                      ),
                    ),

                  // Game Over / Endscreen Ansicht
                  if (!_isPlaying)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.redAccent),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🔥 Einsatz beendet! 🔥', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text('Erreichte Punkte: $_score', style: const TextStyle(color: Colors.orangeAccent, fontSize: 16)),
                            const SizedBox(height: 16),
                            ElevatedButton.styleFrom(backgroundColor: Colors.redAccent).wrap(
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _score = 0;
                                    _timeLeft = 15;
                                    _isPlaying = true;
                                    _fires.clear();
                                  });
                                  _startGame();
                                },
                                child: const Text('Nochmal löschen', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Schließen-Button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Schließen', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}

// Hilfsklasse für die Position eines Feuers
class FireItem {
  final int id;
  final double x;
  final double y;

  FireItem({required this.id, required this.x, required this.y});
}

// Kleine Extension, damit der Button-Wrap im Code kompakter bleibt
extension on ButtonStyle {
  Widget wrap(Widget child) => child;
}