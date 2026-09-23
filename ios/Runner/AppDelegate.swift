import Flutter
import UIKit
// Needed to see WorkmanagerPlugin's Swift symbols: Flutter's SPM wrapper used to
// re-export this automatically, but workmanager_apple now builds as a plain
// CocoaPods framework (see release.yml's FLUTTER_SWIFT_PACKAGE_MANAGER=false),
// which requires an explicit module import across the framework boundary.
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // The app uses UIScene, so background handlers must be re-registered here, before this returns.
    WorkmanagerPlugin.registerLaunchHandlers()
    // Lets a notification show while the app is open, and reach the notifications plugin.
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
