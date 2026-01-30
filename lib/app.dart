import 'package:flutter/material.dart';
import 'screens/name_screen.dart';
import 'screens/mode_screen.dart';
import 'screens/game_page.dart';

enum AppMode { name, mode, host, join }

class MyGameApp extends StatefulWidget {
  const MyGameApp({super.key});

  @override
  State<MyGameApp> createState() => _MyGameAppState();
}

class _MyGameAppState extends State<MyGameApp> {
  AppMode appMode = AppMode.name;
  String playerName = "";

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _buildScreen(),
    );
  }

  Widget _buildScreen() {
    switch (appMode) {
      case AppMode.name:
        return NameScreen(
          onSubmit: (name) {
            setState(() {
              playerName = name;
              appMode = AppMode.mode;
            });
          },
        );

      case AppMode.mode:
        return ModeScreen(
          onHost: () => setState(() => appMode = AppMode.host),
          onJoin: () => setState(() => appMode = AppMode.join),
        );

      case AppMode.host:
        return GamePage(
          isHost: true,
          playerName: playerName,
        );

      case AppMode.join:
        return GamePage(
          isHost: false,
          playerName: playerName,
        );
    }
  }
}
