import Flutter
import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    print("🚀 [AppDelegate] didFinishLaunchingWithOptions")
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }
    application.registerForRemoteNotifications()

    return super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
  }

  func didInitializeImplicitFlutterEngine(
    _ engineBridge: FlutterImplicitEngineBridge
  ) {
    GeneratedPluginRegistrant.register(
      with: engineBridge.pluginRegistry
    )
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    print("✅ [AppDelegate] APNs device token received: \(tokenString)")

    Messaging.messaging().apnsToken = deviceToken
    Auth.auth().setAPNSToken(deviceToken, type: .unknown)

    super.application(
      application,
      didRegisterForRemoteNotificationsWithDeviceToken: deviceToken
    )
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("❌ [AppDelegate] APNs registration failed: \(error.localizedDescription)")

    super.application(
      application,
      didFailToRegisterForRemoteNotificationsWithError: error
    )
  }

  override func responds(to aSelector: Selector!) -> Bool {
    if aSelector == #selector(UIApplicationDelegate.application(_:didReceiveRemoteNotification:fetchCompletionHandler:)) {
      return true
    }
    return super.responds(to: aSelector)
  }

  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable : Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    print("🔔 [AppDelegate] didReceiveRemoteNotification triggered: \(userInfo.keys)")

    Messaging.messaging().appDidReceiveMessage(userInfo)

    if Auth.auth().canHandleNotification(userInfo) {
      print("✅ [AppDelegate] Notification handled by FirebaseAuth")
      completionHandler(.noData)
      return
    }

    print("ℹ️ [AppDelegate] Notification passed to super")
    super.application(
      application,
      didReceiveRemoteNotification: userInfo,
      fetchCompletionHandler: completionHandler
    )
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    print("🔗 [AppDelegate] open URL: \(url.absoluteString)")
    if Auth.auth().canHandle(url) {
      return true
    }
    return super.application(app, open: url, options: options)
  }
}

