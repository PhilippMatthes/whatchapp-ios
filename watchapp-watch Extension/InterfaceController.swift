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
    
    var conversations: [String]!
    
    @IBAction func refresh() {
        WCSession.default.sendMessage(["request": "data"], replyHandler: {
            (response) -> Void in
            if let qrcode = response["qrcode"] as? String {
                guard let imageData = Data(base64Encoded: qrcode), let image = UIImage(data: imageData) else {return}
                self.showQRCode(image: image)
            } else if let chats = response["chats"] as? [String] {
                self.showConversations(chats)
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
    }
    
    func showQRCode(image: UIImage) {
        self.qrCodeImageView.setImage(image)
        self.backgroundGroup.setBackgroundColor(.white)
        self.table.setAlpha(0.0)
        self.qrCodeImageView.setAlpha(1.0)
        self.whatsappIcon.setAlpha(1.0)
    }
    
    func showConversations(_ conversations: [String]) {
        guard conversations != self.conversations else {return}
        self.conversations = conversations
        self.table.setNumberOfRows(conversations.count / 3, withRowType: "row")
        for (i, _) in conversations.enumerated() {
            if i % 3 == 0 {
                let row = table.rowController(at: i / 3) as! ChatRowController
                row.titleLabel.setText(conversations[i])
                row.label.setText(conversations[i+1])
            }
        }
        self.backgroundGroup.setBackgroundColor(.black)
        self.table.setAlpha(1.0)
        self.qrCodeImageView.setAlpha(0.0)
        self.whatsappIcon.setAlpha(0.0)
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
            } else if let chats = response["chats"] as? [String] {
                self.showConversations(chats)
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
        } else if let chats = message["chats"] as? [String] {
            showConversations(chats)
        }
    }
}

