import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let secureScreenChannelName = "wudase/secure_screen"
  private var secureScreenChannel: FlutterMethodChannel?
  private var captureObserver: NSObjectProtocol?
  private var screenshotObserver: NSObjectProtocol?
  private var isMonitoringScreenProtection = false

  private var secureField: UITextField?
  private var protectedView: UIView?
  private weak var protectedSuperview: UIView?
  private var protectedFrame: CGRect = .zero
  private var protectedAutoresizing: UIView.AutoresizingMask = []
  private var protectedTranslatesMask: Bool = true

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
    disableScreenshotBlock()
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
        self.enableScreenshotBlock()
        result(nil)
      case "disable":
        self.stopScreenProtectionMonitoring()
        self.disableScreenshotBlock()
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

  // MARK: - Screenshot block (secure text field trick)
  //
  // iOS has no official API to prevent the screenshot gesture. This wraps the
  // Flutter root view inside the private canvas layer of a
  // UITextField(isSecureTextEntry = true). When the system captures the
  // screen, that layer renders blank — screenshots and screen recordings of
  // the sheet music come out empty, matching Android's FLAG_SECURE behavior.
  //
  // Falls back silently to detect-only mode if the private canvas view can
  // no longer be located on a future iOS version.

  private func enableScreenshotBlock() {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      guard self.secureField == nil, let window = self.window else { return }
      guard let rootView = window.rootViewController?.view else { return }
      guard let parent = rootView.superview else { return }

      let field = UITextField(frame: window.bounds)
      field.isSecureTextEntry = true
      field.isUserInteractionEnabled = false
      field.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      field.translatesAutoresizingMaskIntoConstraints = true
      field.backgroundColor = .clear

      parent.insertSubview(field, belowSubview: rootView)

      guard let canvas = self.findSecureCanvas(in: field) else {
        field.removeFromSuperview()
        return
      }

      self.protectedView = rootView
      self.protectedSuperview = parent
      self.protectedFrame = rootView.frame
      self.protectedAutoresizing = rootView.autoresizingMask
      self.protectedTranslatesMask = rootView.translatesAutoresizingMaskIntoConstraints

      rootView.removeFromSuperview()
      rootView.frame = canvas.bounds
      rootView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      rootView.translatesAutoresizingMaskIntoConstraints = true
      canvas.addSubview(rootView)

      canvas.isUserInteractionEnabled = true
      var view: UIView? = canvas
      while let current = view {
        current.isUserInteractionEnabled = true
        if current === field { break }
        view = current.superview
      }

      self.secureField = field
    }
  }

  private func disableScreenshotBlock() {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      guard let field = self.secureField else { return }
      guard let rootView = self.protectedView, let parent = self.protectedSuperview else {
        field.removeFromSuperview()
        self.secureField = nil
        return
      }

      rootView.removeFromSuperview()
      rootView.frame = self.protectedFrame
      rootView.autoresizingMask = self.protectedAutoresizing
      rootView.translatesAutoresizingMaskIntoConstraints = self.protectedTranslatesMask
      parent.addSubview(rootView)

      field.removeFromSuperview()
      self.secureField = nil
      self.protectedView = nil
      self.protectedSuperview = nil
    }
  }

  private func findSecureCanvas(in field: UITextField) -> UIView? {
    // Force the field to build its layer hierarchy.
    field.layoutIfNeeded()

    let canvasClassNames = [
      "_UITextLayoutCanvasView",
      "_UITextFieldCanvasView",
    ]

    for name in canvasClassNames {
      if let match = firstSubview(of: field, whereClassName: name) {
        return match
      }
    }

    // Fallback: pick the deepest single-child subview branch. On modern iOS
    // the secure field's canvas is the leaf that hosts the blanking layer.
    var candidate: UIView = field
    while let next = candidate.subviews.first, next !== candidate {
      candidate = next
    }
    return candidate === field ? nil : candidate
  }

  private func firstSubview(of view: UIView, whereClassName name: String) -> UIView? {
    for subview in view.subviews {
      if NSStringFromClass(type(of: subview)) == name {
        return subview
      }
      if let found = firstSubview(of: subview, whereClassName: name) {
        return found
      }
    }
    return nil
  }
}
