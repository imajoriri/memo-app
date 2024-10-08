//
//  Floating.swift
//  Runner
//
//  Created by 今城洸幸 on 2024/09/13.
//

import Cocoa
import FlutterMacOS
import SwiftUI
import Firebase

let flutterEngine = FlutterEngine(name: "my flutter engine", project: nil)
let panelFlutterViewController = FlutterViewController(engine: flutterEngine, nibName: nil, bundle: nil)
let panelChannelMethod = FlutterMethodChannel(name: "panel_window", binaryMessenger: panelFlutterViewController.engine.binaryMessenger)

class FloatingPanel: NSPanel {

  init() {
    super.init(contentRect: NSRect(x: 0, y: 0, width: 1200, height: 600),
               styleMask: [.nonactivatingPanel,
                           .titled,
                           .resizable,
                           .closable,
                           .fullSizeContentView
               ],
               backing: .buffered,
               defer: false
    )

    flutterEngine.run(withEntrypoint: "panel")
    self.contentView = panelFlutterViewController.view
    self.contentViewController = panelFlutterViewController
    RegisterGeneratedPlugins(registry: panelFlutterViewController)

    // Set this if you want the panel to remember its size/position
    self.setFrameAutosaveName("a unique name")

    // Allow the pannel to be on top of almost all other windows
    self.isFloatingPanel = true
    self.level = .floating

    // Allow the pannel to appear in a fullscreen space
    self.collectionBehavior.insert(.fullScreenAuxiliary)

    // While we may set a title for the window, don't show it
    self.titleVisibility = .hidden
    self.titlebarAppearsTransparent = true

    // Keep the panel around after closing since I expect the user to open/close it often
    self.isReleasedWhenClosed = false

    // Hide the traffic icons (standard close, minimize, maximize buttons)
    self.standardWindowButton(.closeButton)?.isHidden = true
    self.standardWindowButton(.miniaturizeButton)?.isHidden = true
    self.standardWindowButton(.zoomButton)?.isHidden = true

    setupNotification()
    setHandler()
  }

  private func setupNotification() {
    NotificationCenter.default.addObserver(self, selector: #selector(handleDidBecomeKeyNotification(_:)), name: NSWindow.didBecomeKeyNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(handleDidResignKeyNotification(_:)), name: NSWindow.didResignKeyNotification, object: nil)
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  @objc private func handleDidBecomeKeyNotification(_ notification: Notification) {
    panelChannelMethod.invokeMethod("active", arguments: nil)
  }

  @objc private func handleDidResignKeyNotification(_ notification: Notification) {
    panelChannelMethod.invokeMethod("inactive", arguments: nil)
  }

  override var canBecomeMain: Bool {
    return true
  }

  override var canBecomeKey: Bool {
      return true
  }

  override func resignMain() {
    super.resignMain()
    // ここでcloseを呼ばないことで、inactiveになってもウィンドウが閉じない
    // close()
  }

  func setHandler() {
    // Flutter側でのイベントを受け取る
    panelChannelMethod.setMethodCallHandler { (call, result) in
      switch call.method {
      case "resizePanel":
        self.setFrameSize(call: call)
        return
      case "open":
        self.orderFront(nil)
        self.makeKey()
      case "close":
        self.close()
        return
      default:
        result(FlutterMethodNotImplemented)
        return
      }
    }
  }

  var frameWidth: CGFloat {
    return self.frame.width
  }

  var frameHeight: CGFloat {
    return self.frame.height
  }

  /// ウィンドウ左下を基準とした縦のポジション
  var positionY: CGFloat {
    return self.frame.origin.y
  }

  /// ウィンドウ左下を基準とした横のポジション
  var positionX: CGFloat {
    return self.frame.origin.x
  }

  /// windowのサイズを変える
  ///
  /// ウィンドウが画面下にあれば上に大きくor小さくなり、
  /// 画面上にあれば下に大きくorちいさくなる。
  func setFrameSize(call: FlutterMethodCall) {
    if let args = call.arguments as? [String: Any] {
      let width = (args["width"] as? Int) ?? Int(self.frameWidth)
      let height = (args["height"] as? Int) ?? Int(self.frameHeight)

      // ウィンドウの位置によって上が伸びるか下が伸びるかのコードだが、
      // 使わないのでコメントアウトするが、いつか使うかもなのでコードを残しておく
      let screenHeight = NSScreen.main?.frame.height ?? 1080
      // ウィンドウの上部から画面上部までの距離
      let distanceToTop = screenHeight - (self.positionY + self.frameHeight)
      // ウィンドウの下部から画面下部までの距離
      let distanceToBottom = self.positionY
      if distanceToTop < distanceToBottom {
        // NSPointは左下を基準とするため、Frameサイズ変更時に上を固定するためにframeHeight - CGFloat(height)を足している
        let frame = NSRect(origin: NSPoint(x: self.positionX, y: self.positionY + (self.frameHeight - CGFloat(height))),
                           size: NSSize(width: width, height: height))
        self.animator().setFrame(frame, display: true, animate: true)
      } else {
        let frame = NSRect(origin: NSPoint(x: self.positionX, y: self.positionY),
                           size: NSSize(width: width, height: height)
        )
        self.animator().setFrame(frame, display: true, animate: true)
      }

    } else {
      print(FlutterError(code: "INVALID_ARGUMENT", message: "Width or height is not provided", details: nil))
    }
  }

}
