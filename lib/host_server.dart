import 'dart:convert';
import 'dart:io';
import 'models.dart';

class HostServer {
  static const int port = 7777;

  RawDatagramSocket? socket;
  final Map<String, Player> players = {};

  bool countdownActive = false;

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

  void handle(
    Map<String, dynamic> msg,
    InternetAddress addr,
    int port,
    String id,
  ) {
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
    if (players.length < 3) return;

    final allReady = players.values.every((p) => p.ready);

    if (allReady && !countdownActive) {
      countdownActive = true;
      for (int i = 3; i > 0; i--) {
        broadcast({"type": "countdown", "value": i});
        await Future.delayed(const Duration(seconds: 1));
        if (!countdownActive) return;
      }
      broadcast({"type": "start"});
    }

    if (!allReady && countdownActive) {
      countdownActive = false;
      broadcast({"type": "countdown_cancel"});
    }
  }

  void broadcastPlayers() {
    broadcast({
      "type": "players",
      "players": players.values.map((p) => p.toPublicJson()).toList(),
    });
  }

  void broadcast(Map<String, dynamic> data) {
    final bytes = utf8.encode(jsonEncode(data));
    for (final id in players.keys) {
      final parts = id.split(":");
      socket!.send(bytes, InternetAddress(parts[0]), int.parse(parts[1]));
    }
  }

  void send(
    InternetAddress addr,
    int port,
    Map<String, dynamic> data,
  ) {
    socket!.send(
      utf8.encode(jsonEncode(data)),
      addr,
      port,
    );
  }
}
