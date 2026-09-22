class MPage {
  const MPage({
    required this.index,
    this.imageUrl,
    this.text,
    this.isLocalFile = false,
  });

  final int index;

  final String? imageUrl;
  final String? text;

  final bool isLocalFile;
}
