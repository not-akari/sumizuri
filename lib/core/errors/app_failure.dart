// Defines the app wide failure types returned by repositories instead of throwing.
sealed class AppFailure {
  const AppFailure(this.message, {this.cause});

  final String message;
  final Object? cause;

  String get displayMessage => message;
}

class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message, {super.cause});
}

class DatabaseFailure extends AppFailure {
  const DatabaseFailure(super.message, {super.cause});
}

class NotFoundFailure extends AppFailure {
  const NotFoundFailure(super.message, {super.cause});
}

class ExtensionFailure extends AppFailure {
  const ExtensionFailure(super.message, {super.cause});

  @override
  String get displayMessage {
    // Failing to open a page is the built-in browser's doing, not the source's.
    if (message.contains('The page could not be loaded')) {
      return '$message\n\nSumizuri\'s built-in browser could not open this '
          'site. It may be down, or blocking the app. Try again in a moment.';
    }
    return '$message\n\nThis comes from the source\'s own code, not Sumizuri.';
  }
}

class NotImplementedFailure extends AppFailure {
  const NotImplementedFailure(super.message);
}

// The response looked like a Cloudflare or similar challenge page.
class ChallengeFailure extends AppFailure {
  const ChallengeFailure(super.message, {required this.url});

  final String url;
}

class UnknownFailure extends AppFailure {
  const UnknownFailure(super.message, {super.cause});
}

class SecurityFailure extends AppFailure {
  const SecurityFailure(super.message, {super.cause});
}
