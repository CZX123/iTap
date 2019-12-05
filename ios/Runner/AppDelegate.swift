import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
  ) -> Bool {

    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
      name: "com.irs.itap/requireLocation",
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler({
      (call: FlutterMethodCall, result: FlutterResult) -> Void in
      guard call.method == "requireLocation" else {
        result(FlutterMethodNotImplemented)
        return
      }
        if #available(iOS 13, *) {
            result(true)
        } else {
            result(false)
        }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
