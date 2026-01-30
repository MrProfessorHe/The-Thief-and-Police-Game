import 'package:flutter/material.dart';

class RoleScreen extends StatelessWidget {
  final String myPlayerId;
  final String role;
  final List players;
  final bool isPolice;
  final bool hasGuessed; // ✅ ADD THIS
  final Function(String) onGuess;
  final VoidCallback onShuffle;
  final int currentRound;

  const RoleScreen({
    super.key,
    required this.role,
    required this.players,
    required this.myPlayerId,
    required this.isPolice,
    required this.hasGuessed,
    required this.currentRound, // ✅
    required this.onGuess,
    required this.onShuffle,
  });

  @override
  Widget build(BuildContext context) {
    if (role.isEmpty) {
      return const Center(
        child: Text(
          "Waiting for role...",
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 20),

        Text(
          "🔁 Round $currentRound",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          "🎭 Your Role: $role",
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const Divider(),

        // 🚓 POLICE CAN GUESS
        if (isPolice)
          Expanded(
            child: ListView(
              children: players
                  .where((p) => p["id"] != myPlayerId) // remove self
                  .map(
                    (p) => ListTile(
                      title: Text(p["name"]),
                      trailing: ElevatedButton(
                        onPressed: hasGuessed ? null : () => onGuess(p["id"]),
                        child: const Text("CATCH"),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

        // 🔀 SHUFFLE ONLY AFTER GUESS
        if (isPolice)
          ElevatedButton(
            onPressed: hasGuessed ? onShuffle : null,
            child: const Text("🔀 Shuffle Next Round"),
          ),
      ],
    );
  }
}
