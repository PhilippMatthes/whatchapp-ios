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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var webView: WKWebView?
    var timer: DispatchSourceTimer?
    var backgroundTask: UIBackgroundTaskIdentifier?

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
        NSLog("%@", "activationDidCompleteWith activationState:\(activationState) error:\(String(describing: error))")
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
        
        DispatchQueue.main.async {
            let config = WKWebViewConfiguration()
            
            let infinyURL = Bundle.main.path(forResource: "infiny", ofType: "js")!
            let infinyContent = try! String(contentsOfFile: infinyURL, encoding: String.Encoding.utf8)
            let infiny = WKUserScript(source: infinyContent, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
            
            let jqueryURL = Bundle.main.path(forResource: "jquery.min", ofType: "js")!
            let jqueryContent = try! String(contentsOfFile: jqueryURL, encoding: String.Encoding.utf8)
            let jquery = WKUserScript(source: jqueryContent, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
            
            config.userContentController.addUserScript(jquery)
            config.userContentController.addUserScript(infiny)
            
            self.webView = WKWebView(frame: .zero, configuration: config)
            
            self.webView?.customUserAgent = """
            Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3163.100 Safari/537.36
            """
            
            let url = URL(string: "https://web.whatsapp.com/")!
            let request = URLRequest(url: url)
            self.webView?.load(request)
        }
        
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.scrapeInformation()
        }
        self.scrapeInformation()
    }
    
    func scrapeInformation() {
        DispatchQueue.main.async {
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
                    self?.webView?.evaluateJavaScript("getAllChats();") {
                        (result, error) in
                        guard
                            error == nil,
                            let result = result,
                            let chats = result as? [String]
                        else {return}
                        WCSession.default.sendMessage(["chats": chats], replyHandler: nil, errorHandler: nil)
                    }
                }
            }
            self.timer?.schedule(deadline: .now(), repeating: .seconds(1), leeway: .milliseconds(100))
            self.timer?.resume()
        }
    }
}
