import Cocoa
import FlutterMacOS

let mainFlutterViewController = FlutterViewController()
let mainChannelMethod = FlutterMethodChannel(name: "main_window", binaryMessenger: mainFlutterViewController.engine.binaryMessenger)

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {

    let windowFrame = self.frame
    self.contentViewController = mainFlutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: mainFlutterViewController)
    FloatingPanel()

    super.awakeFromNib()
  }
}
