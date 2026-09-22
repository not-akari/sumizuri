String sourceKeyOf({
  String? repoUrl,
  String? repoSourceId,
  required String name,
  required String baseUrl,
}) {
  if (repoUrl != null && repoSourceId != null) {
    return 'r|$repoUrl|$repoSourceId';
  }
  return 'c|$name|$baseUrl';
}
