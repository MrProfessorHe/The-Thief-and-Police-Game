import 'dart:convert';
import 'dart:io';
import 'models.dart';

int currentRound = 1;
final int maxRounds = 10;
bool roundActive = false;
String? thiefId;

class HostServer {
  static const int port = 7777;

  RawDatagramSocket? socket;
  final Map<String, Player> players = {};
  bool countdownActive = false;

  final List<String> rolePriority = [
    "Police",
    "Thief",
    "King",
    "Queen",
    "Emperor",
    "Prince",
    "Minister",
    "Advisor",
    "Commander",
    "Soldier",
    "Kundan",
  ];

  final Map<String, int> rolePoints = {
    "King": 2000,
    "Queen": 1800,
    "Emperor": 1700,
    "Prince": 1200,
    "Police": 0,
    "Thief": 0,
    "Minister": 1000,
    "Advisor": 800,
    "Commander": 600,
    "Soldier": 500,
    "Kundan": 100,
  };

  Future<void> start() async {
    socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      port,
    );
    socket!.broadcastEnabled = true;

    print("🟢 HOST running on UDP $port");

    socket!.listen((event) {
      if (event == RawSocketEvent.read) {
        final dg = socket!.receive();
        if (dg == null) return;

        final msg = jsonDecode(utf8.decode(dg.data));
        final id = "${dg.address.address}:${dg.port}";

        handle(msg, dg.address, dg.port, id);
      }
    });
  }

  void handle(Map msg, InternetAddress addr, int port, String id) {
    switch (msg["type"]) {
      case "guess":
        handleGuess(id, msg["targetId"]);
        break;

        case "shuffle":
          if (!roundActive) {
            currentRound++;
            resetReady();
            assignRolesAndScores();
            broadcast({"type": "start"});
            broadcastRound();
            resendRoles();
          }
          break;



      case "discover":
        send(addr, port, {"type": "host_ack"});
        break;

      case "join":
        players.putIfAbsent(
          id,
          () => Player(id: id, name: msg["name"]),
        );
        broadcastPlayers();
        break;

      case "ready":
        players[id]?.ready = msg["ready"];
        broadcastPlayers();
        checkLobby();
        break;
    }
  }

  void checkLobby() async {
    if (players.length < 2) return;

    final allReady = players.values.every((p) => p.ready);

    if (allReady && !countdownActive) {
      countdownActive = true;

      for (int i = 3; i > 0; i--) {
        broadcast({"type": "countdown", "value": i});
        await Future.delayed(const Duration(seconds: 1));
        if (!countdownActive) return;
      }

      assignRolesAndScores();

      // 🔁 resend roles AFTER start (UDP safety)
      broadcast({"type": "start"});
      broadcastRound();
      resendRoles();
    }

    if (!allReady && countdownActive) {
      countdownActive = false;
      broadcast({"type": "countdown_cancel"});
    }
  }

  void assignRolesAndScores() {
    final list = players.values.toList();
    list.shuffle();

    thiefId = null;
    roundActive = true;

    for (int i = 0; i < list.length; i++) {
      final role = rolePriority[i];

      list[i].role = role;

      if (role == "Thief") {
        thiefId = list[i].id;
      }

      final parts = list[i].id.split(":");
      send(
        InternetAddress(parts[0]),
        int.parse(parts[1]),
        {
          "type": "role",
          "role": role,
        },
      );
    }

    broadcastPlayers(); // score unchanged here
  }

  void broadcastPlayers() {
    broadcast({
      "type": "players",
      "players": players.values.map((p) => p.toPublicJson()).toList(),
    });
  }

  void broadcast(Map data) {
    final bytes = utf8.encode(jsonEncode(data));
    for (final id in players.keys) {
      final parts = id.split(":");
      socket!.send(bytes, InternetAddress(parts[0]), int.parse(parts[1]));
    }
  }

  void send(InternetAddress addr, int port, Map data) {
    socket!.send(
      utf8.encode(jsonEncode(data)),
      addr,
      port,
    );
  }

  void handleGuess(String policeId, String targetId) {
    final police = players[policeId];
    if (police == null) return;

    if (!roundActive || police.role != "Police") return;

    roundActive = false;

    bool correct = targetId == thiefId;

    if (correct) {
      police.score += 1500;
    } else {
      players[thiefId!]?.score += 1500;
    }

    broadcast({
      "type": "round_result",
      "correct": correct,
      "police": police.name,
      "thief": players[thiefId!]?.name,
    });

    broadcastPlayers();

    if (currentRound == maxRounds) {
      endGame();
    }
  }

  void endGame() {
    final winner = players.values.reduce((a, b) => a.score > b.score ? a : b);

    broadcast({
      "type": "final_winner",
      "name": winner.name,
      "score": winner.score,
    });
  }

  void resetReady() {
    for (final p in players.values) {
      p.ready = false;
    }
  }

  void resendRoles() {
    for (final p in players.values) {
      if (p.role.isEmpty) continue;

      final parts = p.id.split(":");
      send(
        InternetAddress(parts[0]),
        int.parse(parts[1]),
        {
          "type": "role",
          "role": p.role,
          "points": rolePoints[p.role] ?? 0,
        },
      );
    }
  }
  void broadcastRound() {
  broadcast({
    "type": "round",
    "value": currentRound,
  });
}

}
