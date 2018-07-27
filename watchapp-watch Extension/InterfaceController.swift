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
    
    @IBAction func refresh() {
        DispatchQueue.main.async{self.setTitle("Communicating...")}
        WCSession.default.sendMessage(["request": "data"], replyHandler: {
            (response) -> Void in
            if let qrcode = response["qrcode"] as? String {
                guard let imageData = Data(base64Encoded: qrcode), let image = UIImage(data: imageData) else {return}
                self.showQRCode(image: image)
            } else if let chats = response["chats"] {
                self.handleChatResponse(chats: chats)
            } else if let status = response["status"] as? String {
                self.receivedStatusMessage(status)
            }
        }) {
            (err) -> Void in
            print(err)
        }
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        self.whatsappIcon.setAlpha(0.0)
        self.table.setAlpha(0.0)
        self.qrCodeImageView.setAlpha(0.0)
        self.backgroundGroup.setBackgroundColor(.black)
        
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
        
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) {
            _ in
            if let lastUpdateData = UserDefaults.standard.object(forKey: "update") as? Data {
                let lastUpdate = try! JSONDecoder().decode(ChatUpdate.self, from: lastUpdateData)
                self.conversations = lastUpdate.chats
                DispatchQueue.main.async {
                    DispatchQueue.main.async{self.setTitle("\(lastUpdate.timeAgo())")}
                }
            }
        }
    }
    
    func showQRCode(image: UIImage) {
        self.qrCodeImageView.setImage(image)
        self.backgroundGroup.setBackgroundColor(.white)
        self.table.setAlpha(0.0)
        self.qrCodeImageView.setAlpha(1.0)
        self.whatsappIcon.setAlpha(1.0)
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
        DispatchQueue.main.async{self.setTitle("Just now")}
        
        let data = try! JSONEncoder().encode(update)
        UserDefaults.standard.set(data, forKey: "update")
    }
    
    func showConversations() {
        self.table.setNumberOfRows(self.conversations.count, withRowType: "row")
        for (i, conversation) in self.conversations.enumerated() {
            let row = table.rowController(at: i) as! ChatRowController
            row.titleLabel.setText(conversation.name)
            row.label.setText(conversation.message)
            row.dateLabel.setText(conversation.date)
        }
        self.backgroundGroup.setBackgroundColor(.black)
        self.table.setAlpha(1.0)
        self.qrCodeImageView.setAlpha(0.0)
        self.whatsappIcon.setAlpha(0.0)
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
        NSLog("Session activation did complete with activation state: \(activationState), error: \(error)")
        WCSession.default.sendMessage(["request": "data"], replyHandler: {
            (response) -> Void in
            if let qrcode = response["qrcode"] as? String {
                guard let imageData = Data(base64Encoded: qrcode), let image = UIImage(data: imageData) else {return}
                self.showQRCode(image: image)
            } else if let chats = response["chats"] {
                self.handleChatResponse(chats: chats)
            } else if let status = response["status"] as? String {
                self.receivedStatusMessage(status)
            }
        }) {
            (err) -> Void in
            print(err)
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let qrcode = message["qrcode"] as? String {
            guard let imageData = Data(base64Encoded: qrcode), let image = UIImage(data: imageData) else {return}
            showQRCode(image: image)
        } else if let chats = message["chats"] {
            self.handleChatResponse(chats: chats)
        } else if let status = message["status"] as? String {
            self.receivedStatusMessage(status)
        }
    }
}

