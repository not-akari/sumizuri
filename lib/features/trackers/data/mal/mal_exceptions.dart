sealed class MalException implements Exception {
  MalException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The login is missing, refused or has run out and cannot be renewed.
class MalTokenException extends MalException {
  MalTokenException([
    super.message = 'Your MyAnimeList login has expired. Connect again.',
  ]);
}

class MalRateLimitException extends MalException {
  MalRateLimitException([
    super.message = 'MyAnimeList is busy. Try again in a minute.',
  ]);
}

class MalNotFoundException extends MalException {
  MalNotFoundException([super.message = 'Not found on MyAnimeList.']);
}

class MalRequestException extends MalException {
  MalRequestException(super.message, {this.status});

  final int? status;
}

class MalNetworkException extends MalException {
  MalNetworkException([
    super.message = 'Could not reach MyAnimeList. Check your connection.',
  ]);
}

class MalSearchTooShortException extends MalException {
  MalSearchTooShortException() : super('The search text is too short.');
}
