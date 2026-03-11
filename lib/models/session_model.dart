class SessionModel {
  final String id;
  final String name;
  bool isActive;

  SessionModel({
    required this.id,
    required this.name,
    this.isActive = true,
  });

  void deactivate() {
    isActive = false;
  }

  void activate() {
    isActive = true;
  }
}
