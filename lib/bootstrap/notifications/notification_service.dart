abstract class NotificationService {
  Future<void> init();

  /// Asks the system for permission to show notifications (phones). True when it is given.
  Future<bool> requestPermission();

  Future<bool> isPermitted();

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  });
}
