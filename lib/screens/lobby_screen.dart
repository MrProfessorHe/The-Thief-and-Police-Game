import 'package:flutter/material.dart';

class LobbyScreen extends StatelessWidget {
  final List players;
  final bool ready;
  final int countdown;

  final bool isHost;
  final bool gameStarted;
  final int maxRounds;
  final bool lobbyOpen; // ✅ FIXED

  final VoidCallback onToggleReady;
  final Function(int)? onSetRounds;
  final VoidCallback? onEndGame;
  final VoidCallback? onPlayAgain;

  const LobbyScreen({
    super.key,
    required this.players,
    required this.ready,
    required this.countdown,

    // ✅ CORRECT ASSIGNMENT
    required this.lobbyOpen,

    required this.isHost,
    required this.gameStarted,
    required this.maxRounds,
    required this.onToggleReady,
    this.onSetRounds,
    this.onEndGame,
    this.onPlayAgain,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// 🎮 HOST CONTROLS (ONLY HOST SEES)
        if (isHost && !gameStarted)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                const Text(
                  "Total Rounds",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                DropdownButton<int>(
                  value: maxRounds,
                  items: [3, 5, 7, 10, 12, 15, 20, 25, 30, 40, 50]
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text("$e Rounds"),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) onSetRounds?.call(v);
                  },
                ),
              ],
            ),
          ),

        /// ✅ READY BUTTON (VISIBLE ONLY WHEN LOBBY OPEN)
        if (lobbyOpen && countdown <= 0)
          ElevatedButton(
            onPressed: onToggleReady,
            child: Text(ready ? "UNREADY" : "READY"),
          ),

        /// ⏱ COUNTDOWN
        if (countdown > 0)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              "Game starts in $countdown",
              style: const TextStyle(fontSize: 20),
            ),
          ),

        /// 🛑 END GAME (HOST ONLY)
        if (isHost && gameStarted)
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: onEndGame,
            child: const Text("END GAME"),
          ),

        /// 🔁 PLAY AGAIN (HOST ONLY)
        if (isHost && !gameStarted && onPlayAgain != null)
          ElevatedButton(
            onPressed: onPlayAgain,
            child: const Text("PLAY AGAIN"),
          ),

        /// 👥 PLAYER LIST
        Expanded(
          child: ListView(
            children: players
                .map(
                  (p) => ListTile(
                    leading: Icon(
                      p["ready"]
                          ? Icons.check_circle
                          : Icons.hourglass_empty,
                      color: p["ready"] ? Colors.green : Colors.grey,
                    ),
                    title: Text(p["name"]),
                    subtitle: Text("Score: ${p["score"]}"),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
