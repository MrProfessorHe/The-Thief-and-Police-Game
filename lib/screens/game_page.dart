import 'package:flutter/material.dart';
import '../host_server.dart';
import '../client_network.dart';
import 'lobby_screen.dart';
import 'role_screen.dart';
import 'score_screen.dart';

class GamePage extends StatefulWidget {
  final bool isHost;
  final String playerName;

  const GamePage({
    super.key,
    required this.isHost,
    required this.playerName,
  });

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  int currentRound = 1;
  String myId = "";
  bool gameStarted = false;
  final host = HostServer();
  final client = ClientNetwork();
  bool hasGuessed = false;

  int navIndex = 0;
  bool ready = false;
  int countdown = -1;
  String role = "";
  List players = [];

  @override
  void initState() {
    super.initState();

    if (widget.isHost) {
      host.start();
    }

    // 👥 PLAYERS
    client.onPlayers = (p) {
      setState(() {
        players = p;
        final me = p.firstWhere(
          (e) => e["name"] == widget.playerName,
          orElse: () => null,
        );
        if (me != null) myId = me["id"];
      });
    };

    // ⏱ COUNTDOWN
    client.onCountdown = (v) {
      setState(() {
        countdown = v;
      });
    };

    // 🎭 ROLE
    client.onRole = (r, _) {
      setState(() {
        role = r;
      });
    };

    // 🚀 GAME START
    client.onStart = () {
      setState(() {
        gameStarted = true;
        navIndex = 1;
        hasGuessed = false; // reset at round start
      });
    };

    // 🧮 ROUND RESULT  ✅ MUST BE BEFORE start()
    client.onRoundResult = (correct, police, thief) {
      if (!mounted) return;

      setState(() {
        hasGuessed = true;
      });

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Round Result"),
          content: Text(
            correct
                ? "✅ Police caught the Thief!"
                : "❌ Wrong guess! Thief escaped.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    };

    client.onRound = (round) {
      setState(() {
        currentRound = round;
      });
    };

    // ▶️ START CLIENT LAST
    client.start(widget.playerName);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      LobbyScreen(
        players: players,
        ready: ready,
        countdown: countdown,
        onToggleReady: () {
          ready = !ready;
          client.toggleReady(ready);
          setState(() {});
        },
      ),
      gameStarted
          ? RoleScreen(
              role: role,
              players: players,
              myPlayerId: myId,
              isPolice: role == "Police",
              hasGuessed: hasGuessed,
              currentRound: currentRound, // ✅
              onGuess: (id) {
                if (hasGuessed) return;
                setState(() => hasGuessed = true);
                client.guess(id);
              },
              onShuffle: () {
  setState(() {
    hasGuessed = false;
  });
  client.shuffleRoles();
},
            )
          : const Center(child: Text("Game not started")),
      ScoreScreen(players: players),
    ];

    final titles = ["Lobby", "Your Role", "Leaderboard"];

    return Scaffold(
      appBar: AppBar(title: Text(titles[navIndex])),
      body: screens[navIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navIndex,
        onTap: (i) => setState(() => navIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.group), label: "Lobby"),
          BottomNavigationBarItem(icon: Icon(Icons.security), label: "Role"),
          BottomNavigationBarItem(
              icon: Icon(Icons.leaderboard), label: "Scores"),
        ],
      ),
    );
  }
}
