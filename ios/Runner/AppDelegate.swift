import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Đăng ký MethodChannel báo thức (đối chiếu với MainActivity.kt bên Android).
    // Dùng registrar(forPlugin:) thay vì lấy binaryMessenger từ window.rootViewController,
    // vì template mới đã chuyển sang vòng đời UIScene nên AppDelegate không còn giữ window.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "WakeUpAlarmPlugin") {
      AlarmPlugin.register(with: registrar)
    } else {
      NSLog("[WakeUp] Không lấy được registrar cho AlarmPlugin — báo thức sẽ không hoạt động")
    }
  }
}