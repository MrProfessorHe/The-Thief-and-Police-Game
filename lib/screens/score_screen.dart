import 'package:flutter/material.dart';

class ScoreScreen extends StatelessWidget {
  final List players;

  const ScoreScreen({super.key, required this.players});

  @override
  Widget build(BuildContext context) {
    final sorted = [...players];
    sorted.sort((a, b) => b["score"].compareTo(a["score"]));

    return ListView.builder(
      itemCount: sorted.length,
      itemBuilder: (_, i) {
        final p = sorted[i];
        final medal = i == 0
            ? "🥇"
            : i == 1
                ? "🥈"
                : i == 2
                    ? "🥉"
                    : "";

        return ListTile(
          leading: Text(medal, style: const TextStyle(fontSize: 24)),
          title: Text(p["name"]),
          trailing: Text(
            p["score"].toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
}
