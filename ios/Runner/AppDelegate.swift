import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let secureScreenChannelName = "wudase/secure_screen"
  private var secureScreenChannel: FlutterMethodChannel?
  private var captureObserver: NSObjectProtocol?
  private var screenshotObserver: NSObjectProtocol?
  private var isMonitoringScreenProtection = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    configureSecureScreenChannel()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationWillTerminate(_ application: UIApplication) {
    stopScreenProtectionMonitoring()
    super.applicationWillTerminate(application)
  }

  private func configureSecureScreenChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }

    let channel = FlutterMethodChannel(
      name: secureScreenChannelName,
      binaryMessenger: controller.binaryMessenger
    )
    secureScreenChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(FlutterError(code: "unavailable", message: "Screen protection is unavailable.", details: nil))
        return
      }

      switch call.method {
      case "enable":
        self.startScreenProtectionMonitoring()
        result(nil)
      case "disable":
        self.stopScreenProtectionMonitoring()
        result(nil)
      case "isCaptured":
        result(UIScreen.main.isCaptured)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func startScreenProtectionMonitoring() {
    guard !isMonitoringScreenProtection else { return }
    isMonitoringScreenProtection = true

    captureObserver = NotificationCenter.default.addObserver(
      forName: UIScreen.capturedDidChangeNotification,
      object: UIScreen.main,
      queue: .main
    ) { [weak self] _ in
      self?.secureScreenChannel?.invokeMethod(
        "captureChanged",
        arguments: UIScreen.main.isCaptured
      )
    }

    screenshotObserver = NotificationCenter.default.addObserver(
      forName: UIApplication.userDidTakeScreenshotNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.secureScreenChannel?.invokeMethod("screenshotTaken", arguments: nil)
    }

    secureScreenChannel?.invokeMethod(
      "captureChanged",
      arguments: UIScreen.main.isCaptured
    )
  }

  private func stopScreenProtectionMonitoring() {
    guard isMonitoringScreenProtection else { return }
    isMonitoringScreenProtection = false

    if let captureObserver = captureObserver {
      NotificationCenter.default.removeObserver(captureObserver)
      self.captureObserver = nil
    }
    if let screenshotObserver = screenshotObserver {
      NotificationCenter.default.removeObserver(screenshotObserver)
      self.screenshotObserver = nil
    }
  }
}
