//
//  ChatLogViewController.swift
//  watchapp-watch Extension
//
//  Created by Philipp Matthes on 27.07.18.
//  Copyright © 2018 Philipp Matthes. All rights reserved.
//

import Foundation
import WatchConnectivity
import WatchKit
import UIKit
import CoreML

class ChatLogViewController: WKInterfaceController {
    
    @IBOutlet weak var table: WKInterfaceTable!
    
    var chat: String!
    var messages = [ChatMessage]()
    var blobImages = [CompressedBlobImage]()
    let model = SentimentPolarity()
    
    var standardReplyHandler: (([String: Any]) -> Void) = {
        reply in
        print(reply)
    }
    
    var standardErrorHandler: ((Error) -> Void) = {
        error in
        print(error)
    }
    
    @IBAction func refresh() {
        WCSession.default.sendMessage(["chatName": chat], replyHandler: {
            reply in
            self.session(WCSession.default, didReceiveMessage: reply, replyHandler: self.standardReplyHandler)
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
        
        guard let context = context as? [String: String] else {return}
        self.chat = context["chatName"]
        
        WCSession.default.delegate = self
        
        refresh()
    }
    
    @IBAction func reply() {
        guard let lastMessage = messages.last else {return}
        let text = lastMessage.children.map {$0.message ?? ""}.joined(separator: " ")
        let prediction = ClassificationService().predictSentiment(from: text)
        self.presentTextInputController(
            withSuggestions: prediction.emoji,
            allowedInputMode: .allowEmoji){
                (results) -> Void in
                guard let results = results as? [String] else {return}
                let text = results.joined(separator: " ")
                WCSession.default.sendMessage(["sendText": text], replyHandler: {
                    reply in
                    guard let success = reply["sendTextSuccess"] as? Bool else {return}
                    WKInterfaceDevice().play(success ? .success : .failure)
                }, errorHandler: self.standardErrorHandler)
        }
    }
}

extension ChatLogViewController: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        if let status = message["status"] as? String {
            self.receivedStatusMessage(status)
            return
        }
        if let blobImage = message["blobImage"] as? Data {
            self.receivedBlobImage(blobImage)
            return
        }
        guard
            let data = message[chat] as? Data
            else {return}
        let messages = try! JSONDecoder().decode([ChatMessage].self, from: data)
        if self.messages != messages {
            self.messages = messages
            showMessages()
            WKInterfaceDevice().play(.click)
        }
    }
    
    func receivedBlobImage(_ data: Data) {
        guard
            let decompressedData = data.inflate(),
            let compressedBlobImage = try? JSONDecoder().decode(CompressedBlobImage.self, from: decompressedData)
        else {return}
        blobImages.append(compressedBlobImage)
        showMessages()
    }
    
    func showMessages() {
        if self.messages.count != table.numberOfRows {
            table.setNumberOfRows(self.messages.count, withRowType: "row")
        }
        for (i, message) in self.messages.enumerated() {
            let row = table.rowController(at: i) as! ContributionRowController
            row.prepare(message, blobImages)
        }
        self.table.scrollToRow(at: self.messages.count-1)
    }
    
    func receivedStatusMessage(_ status: String) {
        DispatchQueue.main.async{self.setTitle(status)}
    }
}
