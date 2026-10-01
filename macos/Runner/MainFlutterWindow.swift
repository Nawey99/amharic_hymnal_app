import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private let secureScreenChannelName = "wudase/secure_screen"
  private var secureScreenChannel: FlutterMethodChannel?
  private var defaultSharingType: NSWindow.SharingType = .readOnly

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    defaultSharingType = self.sharingType
    configureSecureScreenChannel(controller: flutterViewController)

    super.awakeFromNib()
  }

  private func configureSecureScreenChannel(controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: secureScreenChannelName,
      binaryMessenger: controller.engine.binaryMessenger
    )
    secureScreenChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(FlutterError(code: "unavailable", message: "Screen protection is unavailable.", details: nil))
        return
      }

      switch call.method {
      case "enable":
        self.setScreenProtection(enabled: true)
        result(nil)
      case "disable":
        self.setScreenProtection(enabled: false)
        result(nil)
      case "isCaptured":
        result(false)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func setScreenProtection(enabled: Bool) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.sharingType = enabled ? .none : self.defaultSharingType
    }
  }
}
