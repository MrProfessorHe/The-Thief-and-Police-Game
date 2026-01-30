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
  bool lobbyOpen = true; // ✅ NEW

  int maxRounds = 5;
  bool gameLocked = false;

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
    lobbyOpen = false; // ❌ close lobby during game
    navIndex = 1;
    hasGuessed = false;
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

    client.onRoundConfig = (max) {
      setState(() {
        maxRounds = max;
      });
    };

client.onReset = () {
  if (!mounted) return;

  setState(() {
    // 🔁 GAME STATE RESET
    currentRound = 1;
    gameStarted = false;
    hasGuessed = false;
    role = "";

    // ✅ THIS IS THE KEY LINE
    lobbyOpen = true;   // 👈 REOPEN LOBBY

    // ✅ READY BUTTON RESET
    ready = false;

    // UI
    navIndex = 0;
    countdown = -1;
  });
};





client.onFinalWinner = (name, score) {
  if (!mounted) return;

setState(() {
  gameStarted = false;
  lobbyOpen = false; // ❌ still closed
  ready = false;
  navIndex = 0;
  role = "";
  hasGuessed = false;
});


  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: const Text("🏆 Game Over"),
      content: Text("Winner: $name\nScore: $score"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("OK"),
        ),
      ],
    ),
  );
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
        lobbyOpen: lobbyOpen,

        // 👇 HOST DATA
        isHost: widget.isHost,
        gameStarted: gameStarted,
        maxRounds: maxRounds,

        onToggleReady: () {
          ready = !ready;
          client.toggleReady(ready);
          setState(() {});
        },

        // 👇 HOST ACTIONS
        onSetRounds: widget.isHost ? (v) => client.setRounds(v) : null,

        onEndGame: widget.isHost ? () => client.endGame() : null,

        onPlayAgain: widget.isHost ? () => client.resetGame() : null,
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
