import 'package:flutter/material.dart';

class NameScreen extends StatefulWidget {
  final Function(String) onSubmit;
  const NameScreen({super.key, required this.onSubmit});

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Enter Name")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: "Player Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isEmpty) return;
                widget.onSubmit(controller.text.trim());
              },
              child: const Text("CONTINUE"),
            ),
          ],
        ),
      ),
    );
  }
}
