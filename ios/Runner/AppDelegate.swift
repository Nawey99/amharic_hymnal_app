import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let secureScreenChannelName = "wudase/secure_screen"
  private var secureScreenChannel: FlutterMethodChannel?
  private let storageChannelName = "wudase/storage"
  private var storageChannel: FlutterMethodChannel?
  private var captureObserver: NSObjectProtocol?
  private var screenshotObserver: NSObjectProtocol?
  private var isMonitoringScreenProtection = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    configureSecureScreenChannel()
    configureStorageChannel()
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

  /// Free space, and keeping re-downloadable files (hymns, audio, sheet
  /// music) out of iCloud and device backups.
  private func configureStorageChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }

    let channel = FlutterMethodChannel(
      name: storageChannelName,
      binaryMessenger: controller.binaryMessenger
    )
    storageChannel = channel
    channel.setMethodCallHandler { call, result in
      guard
        let arguments = call.arguments as? [String: Any],
        let path = arguments["path"] as? String
      else {
        result(FlutterError(code: "bad_args", message: "A path is required.", details: nil))
        return
      }
      var url = URL(fileURLWithPath: path, isDirectory: true)

      switch call.method {
      case "excludeFromBackup":
        // Excluding a directory excludes everything in it, including files
        // added later.
        do {
          var values = URLResourceValues()
          values.isExcludedFromBackup = true
          try url.setResourceValues(values)
          result(nil)
        } catch {
          result(FlutterError(code: "failed", message: error.localizedDescription, details: nil))
        }
      case "freeBytes":
        do {
          let values = try url.resourceValues(forKeys: [
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeAvailableCapacityKey,
          ])
          if let important = values.volumeAvailableCapacityForImportantUsage {
            result(NSNumber(value: important))
          } else if let capacity = values.volumeAvailableCapacity {
            result(NSNumber(value: capacity))
          } else {
            result(nil)
          }
        } catch {
          result(FlutterError(code: "failed", message: error.localizedDescription, details: nil))
        }
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
