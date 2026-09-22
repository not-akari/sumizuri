class MEntry {
  const MEntry({
    required this.url,
    required this.title,
    this.coverUrl,
    this.bannerUrl,
    this.author,
    this.description,
    this.rating,
    this.status,
    this.genres,
    this.webUrl,
  });

  final String url;

  final String title;
  final String? coverUrl;

  final String? bannerUrl;
  final String? author;
  final String? description;

  final double? rating;
  final String? status;
  final List<String>? genres;

  MEntry mergedOver(MEntry fallback) => MEntry(
    url: url.isEmpty ? fallback.url : url,
    title: title.isEmpty ? fallback.title : title,
    coverUrl: _text(coverUrl) ?? fallback.coverUrl,
    bannerUrl: _text(bannerUrl) ?? fallback.bannerUrl,
    author: _text(author) ?? fallback.author,
    description: _text(description) ?? fallback.description,
    rating: rating ?? fallback.rating,
    status: _text(status) ?? fallback.status,
    genres: (genres == null || genres!.isEmpty) ? fallback.genres : genres,
    webUrl: _text(webUrl) ?? fallback.webUrl,
  );

  static String? _text(String? value) =>
      value == null || value.trim().isEmpty ? null : value;

  final String? webUrl;
}
