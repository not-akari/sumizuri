class Repo {
  const Repo({
    required this.id,
    required this.url,
    required this.name,
    required this.addedAt,
  });

  final int id;
  final String url;
  final String name;
  final DateTime addedAt;
}
