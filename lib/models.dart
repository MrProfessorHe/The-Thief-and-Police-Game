class Player {
  String id;
  String name;
  bool ready;
  int score;
  String role;

  Player({
    required this.id,
    required this.name,
    this.ready = false,
    this.score = 0,
    this.role = "",
  });

  Map<String, dynamic> toPublicJson() {
    return {
      "id": id,
      "name": name,
      "ready": ready,
      "score": score,
    };
  }
}
