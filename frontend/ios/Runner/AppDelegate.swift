import Flutter
import UIKit
import GoogleMaps


@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    var secrets: NSDictionary?

    if let path = Bundle.main.path(forResource: "secrets", ofType: "plist") {
        secrets = NSDictionary(contentsOfFile: path)
    }

    if let dict = secrets {
        let googleMapsKey = dict["GOOGLE_MAPS_API_KEY"] as? String

        // Initialize google maps.
        if let key = googleMapsKey {
          GMSServices.provideAPIKey(key)
        }
    }
      
    GeneratedPluginRegistrant.register(with: self)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
