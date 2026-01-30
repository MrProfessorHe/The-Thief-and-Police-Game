import 'dart:convert';
import 'dart:io';
import 'models.dart';

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
    "Prince": 1500,
    "Police": 1200,
    "Thief": 1200,
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
      broadcast({"type": "start"});
    }

    if (!allReady && countdownActive) {
      countdownActive = false;
      broadcast({"type": "countdown_cancel"});
    }
  }

  void assignRolesAndScores() {
    final list = players.values.toList();
    list.shuffle();

    for (int i = 0; i < list.length; i++) {
      final role = rolePriority[i];
      final points = rolePoints[role] ?? 0;

      list[i].role = role;
      list[i].score += points;

      final parts = list[i].id.split(":");
      send(
        InternetAddress(parts[0]),
        int.parse(parts[1]),
        {
          "type": "role",
          "role": role,
          "points": points,
        },
      );

      print("🎭 ${list[i].name} → $role (+$points)");
    }

    broadcastPlayers();
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
}
