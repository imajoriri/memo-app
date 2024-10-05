//
//  ShareViewController.swift
//  SharedExtension
//
//  Created by 今城洸幸 on 2024/09/14.
//

import UIKit
import SwiftUI
import Social
import UniformTypeIdentifiers
import FirebaseCore
import FirebaseFirestore
import FirebaseAppCheck

class YourAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
  func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
    return AppAttestProvider(app: app)
  }
}

class ShareViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    firebaseSetUp()

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

  func firebaseSetUp() {
    let providerFactory = YourAppCheckProviderFactory()
    AppCheck.setAppCheckProviderFactory(providerFactory)

    let configFileName: String
#if DEBUG
    configFileName = "GoogleService-Info-debug"
#else
    configFileName = "GoogleService-Info-release"
#endif
    guard let filePath = Bundle.main.path(forResource: "\(configFileName)", ofType: "plist"),
          let options = FirebaseOptions(contentsOfFile: filePath) else {
      fatalError("Firebase plist file is not found.")
    }
    FirebaseApp.configure(options: options)
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
          let db = Firestore.firestore()
          let query = db.collection("users").document("test4").collection("memos").order(by: "createdAt", descending: true).limit(to: 1)
          Task {
            do {
              let document = try await query.getDocuments()
              guard let doc = document.documents.first else {
                return
              }

              let content = (doc.data()["content"] ?? "") as! String
              print(content)
              let data = content.data(using: .utf8)!
              do {
                var dic = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) as? [[String: Any]]
                let insertText = ["insert": text]
                dic?.insert(insertText, at: 0)
                let id = doc.documentID
                let json = try JSONSerialization.data(withJSONObject: dic, options: [])
                let jsonString = String(data: json, encoding: .utf8)
                try await db.collection("users").document("test4").collection("memos").document(id).setData(["content": jsonString])
              } catch {
                  print("JSONのデシリアライズに失敗しました: \(error)")
              }
            } catch {
              print("Error adding document:")
            }
          }
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

  func close() {
    NotificationCenter.default.post(name: NSNotification.Name("close"), object: nil)
  }
}
