//
//  ShareViewController.swift
//  SharedExtension
//
//  Created by 今城洸幸 on 2024/09/14.
//

import UIKit
import Social
import Flutter

class ShareViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    showFlutter()
  }

  func showFlutter() {
    let flutterEngine = FlutterEngine(name: "share_extension", project: nil)
    flutterEngine.run(withEntrypoint: "shareExtension")
    let flutterViewController = FlutterViewController(engine: flutterEngine, nibName: nil, bundle: nil)

    addChild(flutterViewController)
    view.addSubview(flutterViewController.view)
    flutterViewController.view.frame = view.bounds
  }
}

//class ShareViewController: SLComposeServiceViewController {
//
//    override func isContentValid() -> Bool {
//        // Do validation of contentText and/or NSExtensionContext attachments here
//        return true
//    }
//
//    override func didSelectPost() {
//        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
//
//        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
//        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
//    }
//
//    override func configurationItems() -> [Any]! {
//        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
//        return []
//    }
//
//}
