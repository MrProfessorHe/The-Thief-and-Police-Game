import 'package:flutter/material.dart';
import 'host_server.dart';
import 'client_network.dart';

void main() {
  runApp(const MyApp());
}

enum Mode { none, host, join }

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Mode mode = Mode.none;

  @override
  Widget build(BuildContext context) {
    if (mode == Mode.none) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                    onPressed: () => setState(() => mode = Mode.host),
                    child: const Text("HOST GAME")),
                ElevatedButton(
                    onPressed: () => setState(() => mode = Mode.join),
                    child: const Text("JOIN GAME")),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      home: GamePage(isHost: mode == Mode.host),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GamePage extends StatefulWidget {
  final bool isHost;
  const GamePage({super.key, required this.isHost});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final host = HostServer();
  final client = ClientNetwork();

  List players = [];
  int countdown = -1;
  bool ready = false;
  String role = "";
  int score = 0;

  @override
  void initState() {
    super.initState();

    if (widget.isHost) {
      host.start();
    }

    client.onPlayers = (p) => setState(() => players = p);
    client.onCountdown = (v) => setState(() => countdown = v);
    client.onStart = () => setState(() => countdown = 0);
    client.onRole = (r, s) => setState(() {
          role = r;
          score = s;
        });

    client.start(widget.isHost ? "Host" : "Player");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lobby")),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              ready = !ready;
              client.toggleReady(ready);
            },
            child: Text(ready ? "UNREADY" : "READY"),
          ),
          if (countdown > 0)
            Text("Starting in $countdown",
                style: const TextStyle(fontSize: 24)),
          if (role.isNotEmpty)
            Text("🎭 Role: $role  |  💰 Score: $score",
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
          Expanded(
            child: ListView(
              children: players
                  .map((p) => ListTile(
                        title: Text(p["name"]),
                        subtitle: Text(
                            "Score ${p["score"]} | Ready ${p["ready"]}"),
                      ))
                  .toList(),
            ),
          )
        ],
      ),
    );
  }
}
