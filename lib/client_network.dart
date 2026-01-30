import 'dart:convert';
import 'dart:io';

class ClientNetwork {
  static const int port = 7777;

  RawDatagramSocket? socket;
  InternetAddress? hostAddr;
  int? hostPort;

  Function(List)? onPlayers;
  Function(int)? onCountdown;
  Function()? onStart;
  Function(String, int)? onRole;

  Future<void> start(String name) async {
    socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      0,
    );
    socket!.broadcastEnabled = true;

    socket!.listen((event) {
      if (event == RawSocketEvent.read) {
        final dg = socket!.receive();
        if (dg == null) return;

        final msg = jsonDecode(utf8.decode(dg.data));
        handle(msg, dg.address, dg.port);
      }
    });

    sendBroadcast({"type": "discover"});
    Future.delayed(const Duration(milliseconds: 500), () {
      send({"type": "join", "name": name});
    });
  }

  void handle(Map msg, InternetAddress addr, int port) {
    switch (msg["type"]) {
      case "host_ack":
        hostAddr = addr;
        hostPort = port;
        break;
      case "players":
        onPlayers?.call(msg["players"]);
        break;
      case "countdown":
        onCountdown?.call(msg["value"]);
        break;
      case "countdown_cancel":
        onCountdown?.call(-1);
        break;
      case "start":
        onStart?.call();
        break;
      case "role":
        onRole?.call(msg["role"], msg["points"]);
        break;
    }
  }

  void toggleReady(bool ready) {
    send({"type": "ready", "ready": ready});
  }

  void send(Map data) {
    if (hostAddr == null) return;
    socket!.send(
      utf8.encode(jsonEncode(data)),
      hostAddr!,
      hostPort!,
    );
  }

  void sendBroadcast(Map data) {
    socket!.send(
      utf8.encode(jsonEncode(data)),
      InternetAddress("255.255.255.255"),
      port,
    );
  }
}
