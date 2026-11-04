import Flutter
import UIKit
import FirebaseAuth

class SceneDelegate: FlutterSceneDelegate {
  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    for urlContext in URLContexts {
      let url = urlContext.url
      NSLog("🔗 [SceneDelegate] openURLContext: %@", url.absoluteString)
      if Auth.auth().canHandle(url) {
        return
      }
    }
    super.scene(scene, openURLContexts: URLContexts)
  }
}

