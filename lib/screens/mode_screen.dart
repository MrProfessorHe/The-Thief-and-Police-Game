import 'package:flutter/material.dart';

class ModeScreen extends StatelessWidget {
  final VoidCallback onHost;
  final VoidCallback onJoin;

  const ModeScreen({
    super.key,
    required this.onHost,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Choose Mode")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: onHost,
              child: const Text("HOST GAME"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onJoin,
              child: const Text("JOIN GAME"),
            ),
          ],
        ),
      ),
    );
  }
}
