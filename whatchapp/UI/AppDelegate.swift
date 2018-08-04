//
//  AppDelegate.swift
//  whatchapp
//
//  Created by Philipp Matthes on 22.07.18.
//  Copyright © 2018 Philipp Matthes. All rights reserved.
//

import UIKit
import WatchConnectivity
import WebKit
import Material
import Alamofire

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var webView: WKWebView?
    var timer: DispatchSourceTimer?
    var backgroundTask: UIBackgroundTaskIdentifier?
    
    var chat: String?
    
    var viewController: ViewController?
    
    var sentBlobImages = [CompressedBlobImage]()
    
    func downloadConfig(handler: @escaping (WKWebViewConfiguration) -> ()) {
        DispatchQueue.main.async {
            let config = WKWebViewConfiguration()
            
            let jqueryURL = Bundle.main.path(forResource: "jquery.min", ofType: "js")!
            let jqueryContent = try! String(contentsOfFile: jqueryURL, encoding: String.Encoding.utf8)
            let jquery = WKUserScript(source: jqueryContent, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
            
            Alamofire.request("https://gist.githubusercontent.com/PhilippMatthes/2ab484dbf131f782f05a64822d99322c/raw/whatsapp-web-scraping.js").responseString {
                response in
                DispatchQueue.main.async {
                    var infiny: WKUserScript
                    if let infinyContent = response.result.value {
                        infiny = WKUserScript(source: infinyContent, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
                        NSLog("Infiny was downloaded: \(infinyContent.count) symbols")
                    } else {
                        let infinyURL = Bundle.main.path(forResource: "infiny", ofType: "js")!
                        let infinyContent = try! String(contentsOfFile: infinyURL, encoding: String.Encoding.utf8)
                        infiny = WKUserScript(source: infinyContent, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
                        NSLog("Infiny could not be downloaded")
                    }
                    config.userContentController.addUserScript(jquery)
                    config.userContentController.addUserScript(infiny)
                    
                    config.userContentController.add(self, name: "blobToBase64Callback")
                    config.userContentController.add(self, name: "domChangedCallback")
                    
                    handler(config)
                }
            }
        }
    }
    
    var standardReplyHandler: (([String: Any]) -> Void) = {
        reply in
        print(reply)
    }
    
    var standardErrorHandler: ((Error) -> Void) = {
        error in
        print(error)
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        } else {
            NSLog("WCSession not supported (f.e. on iPad).")
        }
        
        return true
    }

}

extension AppDelegate: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        NSLog("%@", "activationDidCompleteWith activationState:\(activationState.rawValue) error:\(String(describing: error))")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        NSLog("%@", "sessionDidBecomeInactive: \(session)")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        NSLog("%@", "sessionDidDeactivate: \(session)")
    }
    
    func sessionWatchStateDidChange(_ session: WCSession) {
        NSLog("%@", "sessionWatchStateDidChange: \(session)")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        NSLog("didReceiveMessage: %@", message)
        
        if let chatName = message["chatName"] as? String {
            self.chat = chatName
        }
        
        if let text = message["sendText"] as? String, let chatName = self.chat {
            DispatchQueue.main.async {
                self.webView?.evaluateJavaScript("sendMessage('\(text)', '\(chatName)');") {
                    result, error in
                    guard
                        error == nil,
                        let success = result as? Bool
                    else {return}
                    replyHandler(["sendTextSuccess": success])
                }
            }
        }
        
        self.start()
    }
}

extension AppDelegate: WKScriptMessageHandler {
    func send(status: String) {
        WCSession.default.sendMessage(["status": status], replyHandler: standardReplyHandler, errorHandler: standardErrorHandler)
    }
    
    func start() {
        if webView == nil {
            self.send(status: "Starting browser...")
            let frame = CGRect(x: 0, y: 0, width: Screen.width, height: Screen.height)
            self.downloadConfig() {
                config in
                DispatchQueue.main.async {
                    self.webView = WKWebView(frame: frame, configuration: config)
                    self.webView?.customUserAgent = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36"
                    let url = URL(string: "https://web.whatsapp.com/")!
                    let request = URLRequest(url: url)
                    self.webView?.load(request)
                    self.viewController?.layout(webView: self.webView)
                    self.webView?.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
                }
            }
        }
        performJavascriptActions()
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            NSLog("\(String(describing: self)) started Background Task")
        }
    }
    
    func handleQRCodeOutput(_ result: Any?, _ error: Error?) {
        guard error == nil, let result = result as? String else {return}
        let components = result.components(separatedBy: "data:image/png;base64,")
        guard components.count == 2 else {return}
        let base64 = components[1]
        WCSession.default.sendMessage(["qrcode" : base64], replyHandler: standardReplyHandler, errorHandler: standardErrorHandler)
    }
    
    func handleGetAllChats(_ result: Any?, _ error: Error?) {
        guard
            error == nil,
            let chats = result
            else {return}
        let decoder = JSONDecoder()
        let json = String(describing: chats)
        guard
            let jsonData = json.data(using: .utf8),
            let conversations = try? decoder.decode([Chat].self, from: jsonData),
            conversations.count > 0
            else {return}
        let update = ChatUpdate(chats: conversations)
        Storage.lastUpdate = update
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(update) else {return}
        WCSession.default.sendMessage(["chats": data], replyHandler: standardReplyHandler, errorHandler: standardErrorHandler)
    }
    
    func handleConfirmLogin(_ result: Any?, _ error: Error?) {
        guard
            error == nil,
            let result = result
            else {return}
        if let result = result as? Bool {
            if result {
                WCSession.default.sendMessage(["status": "Logged back in..."], replyHandler: standardReplyHandler, errorHandler: standardErrorHandler)
                print("Was logged in on another device, logged back in.")
            }
        }
    }
    
    func handleAllVisibleMessages(_ result: Any?, _ error: Error?) {
        guard
            error == nil,
            let jsonAny = result
            else {return}
        let decoder = JSONDecoder()
        let json = String(describing: jsonAny)
        guard
            let jsonData = json.data(using: .utf8),
            let messages = try? decoder.decode([ChatMessage].self, from: jsonData),
            messages.count > 0
        else {return}
        let encoder = JSONEncoder()
        guard
            let data = try? encoder.encode(messages),
            let chat = self.chat
            else {return}
        WCSession.default.sendMessage([chat: data], replyHandler: standardReplyHandler, errorHandler: standardErrorHandler)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            guard let webView = webView else {return}
            if webView.estimatedProgress == 1.0 {
                send(status: "Loading...")
            } else {
                send(status: "Loaded \(Int(webView.estimatedProgress*100))%")
            }
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print(message.name)
        if message.name == "blobToBase64Callback" {
            handleBlobToBase64Callback(message: message)
        }
        if message.name == "domChangedCallback" {
            handleDomChangedCallback(message: message)
        }
    }
    
    func handleBlobToBase64Callback(message: WKScriptMessage) {
        let json = String(describing: message.body)
        guard
            let jsonData = json.data(using: .utf8),
            let blobImage = try? JSONDecoder().decode(BlobImage.self, from: jsonData)
            else {return}
        guard
            let compressedBlobImage = CompressedBlobImage(blobImage),
            let encryptedData = try? JSONEncoder().encode(compressedBlobImage),
            let deflatedData = encryptedData.deflate()
            else {return}
        if !sentBlobImages.contains(compressedBlobImage) {
            WCSession.default.sendMessage(["blobImage": deflatedData], replyHandler: standardReplyHandler, errorHandler: standardErrorHandler)
            let bcf = ByteCountFormatter()
            bcf.allowedUnits = [.useKB]
            bcf.countStyle = .file
            let string = bcf.string(fromByteCount: Int64(deflatedData.count))
            print(string)
            sentBlobImages.append(compressedBlobImage)
        }
    }
    
    func handleDomChangedCallback(message: WKScriptMessage) {
        performJavascriptActions()
    }
    
    func performJavascriptActions() {
        DispatchQueue.main.async {
            self.webView?.evaluateJavaScript("getQRCodeBase64();") {
                (result, error) in
                self.handleQRCodeOutput(result, error)
            }
            self.webView?.evaluateJavaScript("getAllChatsAsJson();") {
                (result, error) in
                self.handleGetAllChats(result, error)
            }
            self.webView?.evaluateJavaScript("confirmLoginOnThisDevice();") {
                (result, error) in
                self.handleConfirmLogin(result, error)
            }
            if let chatName = self.chat {
                self.webView?.evaluateJavaScript("selectChatWithName('\(chatName)');") {
                    (result, error) in
                    guard error == nil else {return}
                }
                self.webView?.evaluateJavaScript("allVisibleMessages();") {
                    (result, error) in
                    self.handleAllVisibleMessages(result, error)
                }
            }
        }
    }
}
