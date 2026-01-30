import 'package:flutter/material.dart';

class LobbyScreen extends StatelessWidget {
  final List players;
  final bool ready;
  final int countdown;
  final VoidCallback onToggleReady;

  const LobbyScreen({
    super.key,
    required this.players,
    required this.ready,
    required this.countdown,
    required this.onToggleReady,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onToggleReady,
          child: Text(ready ? "UNREADY" : "READY"),
        ),
        if (countdown > 0)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              "Game starts in $countdown",
              style: const TextStyle(fontSize: 20),
            ),
          ),
        Expanded(
          child: ListView(
            children: players
                .map((p) => ListTile(
                      leading: Icon(
                        p["ready"] ? Icons.check_circle : Icons.hourglass_empty,
                        color: p["ready"] ? Colors.green : Colors.grey,
                      ),
                      title: Text(p["name"]),
                      subtitle: Text("Score: ${p["score"]}"),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}
