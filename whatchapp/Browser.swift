//
//  Browser.swift
//  whatchapp
//
//  Created by Philipp Matthes on 26.07.18.
//  Copyright © 2018 Philipp Matthes. All rights reserved.
//

import Foundation
import WatchConnectivity
import WebKit

class Browser {
    
    var webView: WKWebView?
    var timer: DispatchSourceTimer?
    var backgroundTask: UIBackgroundTaskIdentifier?
    var chat: String?
    
    func start(andOpenChat chat: String?) {
        self.chat = chat
        DispatchQueue.main.async {
            WCSession.default.sendMessage(["status": "Starting browser..."], replyHandler: nil, errorHandler: nil)
            
            let config = WKWebViewConfiguration()
            
            let infinyURL = Bundle.main.path(forResource: "infiny", ofType: "js")!
            let infinyContent = try! String(contentsOfFile: infinyURL, encoding: String.Encoding.utf8)
            let infiny = WKUserScript(source: infinyContent, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
            
            let jqueryURL = Bundle.main.path(forResource: "jquery.min", ofType: "js")!
            let jqueryContent = try! String(contentsOfFile: jqueryURL, encoding: String.Encoding.utf8)
            let jquery = WKUserScript(source: jqueryContent, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
            
            config.userContentController.addUserScript(jquery)
            config.userContentController.addUserScript(infiny)
            
            self.webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 100, height: 1000), configuration: config)
            
            self.webView?.customUserAgent = """
            Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3163.100 Safari/537.36
            """
            
            let url = URL(string: "https://web.whatsapp.com/")!
            let request = URLRequest(url: url)
            self.webView?.load(request)
        }
        
        WCSession.default.sendMessage(["status": "Scheduling tasks..."], replyHandler: nil, errorHandler: nil)
        
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.scrapeInformation()
        }
        self.scrapeInformation()
    }
    
    func scrapeInformation() {
        DispatchQueue.main.async {
            WCSession.default.sendMessage(["status": "Updating..."], replyHandler: nil, errorHandler: nil)
            self.timer = DispatchSource.makeTimerSource(queue : DispatchQueue.main)
            self.timer?.setEventHandler {
                [weak self] in
                DispatchQueue.main.async {
                    self?.webView?.evaluateJavaScript("getQRCodeBase64();") {
                        (result, error) in
                        guard error == nil, let result = result as? String else {return}
                        let components = result.components(separatedBy: "data:image/png;base64,")
                        guard components.count == 2 else {return}
                        let base64 = components[1]
                        WCSession.default.sendMessage(["qrcode" : base64], replyHandler: nil, errorHandler: nil)
                    }
                    self?.webView?.evaluateJavaScript("getAllChatsAsJson();") {
                        (result, error) in
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
                        WCSession.default.sendMessage(["chats": data], replyHandler: nil, errorHandler: nil)
                    }
                    self?.webView?.evaluateJavaScript("confirmLoginOnThisDevice()") {
                        (result, error) in
                        guard
                            error == nil,
                            let result = result
                            else {return}
                        if let result = result as? Bool {
                            if result {
                                WCSession.default.sendMessage(["status": "Logged back in..."], replyHandler: nil, errorHandler: nil)
                                print("Was logged in on another device, logged back in.")
                            }
                        }
                    }
                    if let chat = self?.chat {
                        self?.webView?.evaluateJavaScript("selectChatWithName('\(chat)');") {
                            (result, error) in
                            guard error == nil else {return}
                        }
                        self?.webView?.evaluateJavaScript("getAllCurrentlyShowingMessagesAsJson();") {
                            (result, error) in
                            guard
                                error == nil,
                                let jsonAny = result
                            else {return}
                            let decoder = JSONDecoder()
                            let json = String(describing: jsonAny)
                            guard
                                let jsonData = json.data(using: .utf8)
                                //let contributions = try? decoder.decode([Contribution].self, from: jsonData),
                                //contributions.count > 0
                            else {return}
                            let contributions = try! decoder.decode([Contribution].self, from: jsonData)
                            let encoder = JSONEncoder()
                            guard let data = try? encoder.encode(contributions) else {return}
                            WCSession.default.sendMessage([chat: data], replyHandler: nil, errorHandler: nil)
                        }
                    }
                }
            }
            self.timer?.schedule(deadline: .now(), repeating: .seconds(1), leeway: .milliseconds(100))
            self.timer?.resume()
        }
    }
    
}
