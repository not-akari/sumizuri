/// Thrown when a download is paused or cancelled. It is not a failure, so no retry.
class DownloadStopped implements Exception {
  const DownloadStopped();

  @override
  String toString() => 'The download was stopped.';
}
