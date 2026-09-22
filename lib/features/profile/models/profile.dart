class Profile {
  const Profile({
    required this.id,
    required this.name,
    this.avatarPath,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String? avatarPath;
  final DateTime createdAt;
}
