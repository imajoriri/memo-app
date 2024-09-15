//
//  ShareViewController.swift
//  SharedExtension
//
//  Created by 今城洸幸 on 2024/09/14.
//

import UIKit
import SwiftUI
import Social
import Flutter
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()

    guard
      let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
      let itemProvider = extensionItem.attachments?.first else {
      self.close()
      return
    }
    checkUrlType(itemProvider: itemProvider)
    checkTextType(itemProvider: itemProvider)

    // SwitUIでcloseボタン押した際に、モーダルを閉じる。
    NotificationCenter.default.addObserver(forName: NSNotification.Name("close"), object: nil, queue: nil) { _ in
       DispatchQueue.main.async {
          self.close()
       }
    }
  }

  func checkUrlType(itemProvider: NSItemProvider) {
    // テキストが共有された場合
    if itemProvider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {

      itemProvider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { data, error in
        guard let url = data as? NSURL else { return  }
        DispatchQueue.main.async {
          let contentView = UIHostingController(rootView: ShareExtensionView(text: url.absoluteString ?? ""))
          self.addChild(contentView)
          self.view.addSubview(contentView.view)

          // set up constraints
          contentView.view.translatesAutoresizingMaskIntoConstraints = false
          contentView.view.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
          contentView.view.bottomAnchor.constraint (equalTo: self.view.bottomAnchor).isActive = true
          contentView.view.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
          contentView.view.rightAnchor.constraint (equalTo: self.view.rightAnchor).isActive = true
        }
      }
    }
  }

  func checkTextType(itemProvider: NSItemProvider) {
    // テキストが共有された場合
    if itemProvider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
      itemProvider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { data, error in
        guard let sharedText = data as? String else { return }
        DispatchQueue.main.async {
          let contentView = UIHostingController(rootView: ShareExtensionView(text: sharedText))
          self.addChild(contentView)
          self.view.addSubview(contentView.view)

          // set up constraints
          contentView.view.translatesAutoresizingMaskIntoConstraints = false
          contentView.view.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
          contentView.view.bottomAnchor.constraint (equalTo: self.view.bottomAnchor).isActive = true
          contentView.view.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
          contentView.view.rightAnchor.constraint (equalTo: self.view.rightAnchor).isActive = true
        }
      }
    }
  }

  func close() {
    self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
  }
}

struct ShareExtensionView: View {
  @State private var text: String

  init(text: String) {
    self.text = text
  }

  var body: some View {
    NavigationStack{
      VStack(spacing: 20){
        Text("Text")
        TextField("Text", text: $text, axis: .vertical)
          .lineLimit(3...6)
          .textFieldStyle(.roundedBorder)

        Button {
          // TODO: Something with the text
          self.close()
        } label: {
          Text("Post")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)

        Spacer()
      }
      .padding()
      .navigationTitle("Share Extension")
      .toolbar {
        Button("Cancel") {
          self.close()
        }
      }
    }
  }

  // so we can close the whole extension
  func close() {
    NotificationCenter.default.post(name: NSNotification.Name("close"), object: nil)
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
