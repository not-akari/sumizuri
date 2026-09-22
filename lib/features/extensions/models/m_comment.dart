class MComment {
  const MComment({
    required this.author,
    required this.text,
    this.date,
    this.avatarUrl,
  });

  final String author;
  final String text;
  final DateTime? date;
  final String? avatarUrl;
}
