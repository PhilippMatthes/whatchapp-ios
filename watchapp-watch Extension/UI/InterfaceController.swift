//
//  InterfaceController.swift
//  watchapp-watch Extension
//
//  Created by Philipp Matthes on 22.07.18.
//  Copyright © 2018 Philipp Matthes. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class InterfaceController: WKInterfaceController {
    
    @IBOutlet weak var table: WKInterfaceTable!
    @IBOutlet weak var whatsappIcon: WKInterfaceImage!
    @IBOutlet weak var backgroundGroup: WKInterfaceGroup!
    @IBOutlet weak var qrCodeImageView: WKInterfaceImage!
    
    var conversations = [Chat]()
    var timer: Timer?
    var blobImages = [CompressedBlobImage]()
    
    var standardReplyHandler: (([String: Any]) -> Void) = {
        reply in
        print(reply)
    }
    
    var standardErrorHandler: ((Error) -> Void) = {
        error in
        print(error)
    }
    
    @IBAction func refresh() {
        WCSession.default.sendMessage(["request": "data"], replyHandler: {
            (response) -> Void in
            self.session(WCSession.default, didReceiveMessage: response, replyHandler: self.standardReplyHandler)
        }, errorHandler: standardErrorHandler) 
    }
    
    override func willActivate() {
        super.willActivate()
        
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        self.whatsappIcon.setHidden(true)
        self.table.setHidden(true)
        self.qrCodeImageView.setHidden(true)
        self.backgroundGroup.setBackgroundColor(.black)
        
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
        
        if let lastUpdateData = UserDefaults.standard.object(forKey: "update") as? Data {
            let lastUpdate = try! JSONDecoder().decode(ChatUpdate.self, from: lastUpdateData)
            self.conversations = lastUpdate.chats
            self.showConversations()
        }
        
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) {
            _ in
            if let lastUpdateData = UserDefaults.standard.object(forKey: "update") as? Data {
                let lastUpdate = try! JSONDecoder().decode(ChatUpdate.self, from: lastUpdateData)
                self.conversations = lastUpdate.chats
                DispatchQueue.main.async {
                    self.setTitle("↻ \(lastUpdate.timeAgo())")
                }
            }
        }
    }
    
    func showQRCode(image: UIImage) {
        self.qrCodeImageView.setImage(image)
        self.backgroundGroup.setBackgroundColor(.white)
        self.table.setHidden(true)
        self.qrCodeImageView.setHidden(false)
        self.whatsappIcon.setHidden(false)
    }
    
    func handleChatResponse(chats: Any) {
        guard
            let updateData = chats as? Data,
            let update = try? JSONDecoder().decode(ChatUpdate.self, from: updateData)
        else {return}
        if self.conversations != update.chats {
            self.conversations = update.chats
            showConversations()
        }
        WKInterfaceDevice().play(.click)
        DispatchQueue.main.async{self.setTitle("↻ Just now")}
        
        let data = try! JSONEncoder().encode(update)
        UserDefaults.standard.set(data, forKey: "update")
    }
    
    func showConversations() {
        if self.conversations.count != table.numberOfRows {
            self.table.setNumberOfRows(self.conversations.count, withRowType: "row")
        }
        for (i, conversation) in self.conversations.enumerated() {
            let row = table.rowController(at: i) as! ChatRowController
            row.prepare(conversation, blobImages)
        }
        self.backgroundGroup.setBackgroundColor(.black)
        self.table.setHidden(false)
        self.qrCodeImageView.setHidden(true)
        self.whatsappIcon.setHidden(true)
    }
    
    func receivedBlobImage(_ data: Data) {
        guard
            let decompressedData = data.inflate(),
            let compressedBlobImage = try? JSONDecoder().decode(CompressedBlobImage.self, from: decompressedData)
            else {return}
        if !blobImages.contains(compressedBlobImage) {
            blobImages.append(compressedBlobImage)
            showConversations()
        }
    }
    
    func receivedStatusMessage(_ status: String) {
        DispatchQueue.main.async{self.setTitle(status)}
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        let context = ["chatName": conversations[rowIndex].name]
        self.pushController(withName: "ChatLogViewController", context: context)
    }
}


extension InterfaceController: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        NSLog("Session activation did complete with activation state: \(activationState), error: \(String(describing: error))")
        WCSession.default.sendMessage(["request": "data"], replyHandler: {
            (response) -> Void in
            self.session(session, didReceiveMessage: response, replyHandler: self.standardReplyHandler)
        }, errorHandler: standardErrorHandler)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        if let qrcode = message["qrcode"] as? String {
            guard let imageData = Data(base64Encoded: qrcode), let image = UIImage(data: imageData) else {return}
            showQRCode(image: image)
        } else if let chats = message["chats"] {
            handleChatResponse(chats: chats)
        } else if let status = message["status"] as? String {
            receivedStatusMessage(status)
        } else if let blobImage = message["blobImage"] as? Data {
            self.receivedBlobImage(blobImage)
        }
    }
}

