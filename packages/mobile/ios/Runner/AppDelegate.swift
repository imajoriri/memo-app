import Flutter
import UIKit
import CoreMotion

let motionManager = CMMotionManager()

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if motionManager.isDeviceMotionAvailable {
      let flutterViewController : FlutterViewController = window?.rootViewController as! FlutterViewController
      let channelMethod = FlutterMethodChannel(name: "deviceMotionUpdates", binaryMessenger: flutterViewController.engine!.binaryMessenger)
      motionManager.deviceMotionUpdateInterval = 1 / 100
      motionManager.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: { (motion, error) in
        guard let motion = motion, error == nil else { return }
        let arguments = [
          "roll": motion.attitude.roll * 180 / Double.pi,
          "pitch": motion.attitude.roll * 180 / Double.pi,
          "yaw": motion.attitude.yaw * 180 / Double.pi,

        ]
        channelMethod.invokeMethod("update", arguments: arguments)
      })
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)

  }
}
