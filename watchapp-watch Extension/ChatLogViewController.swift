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

class ChatLogViewController: WKInterfaceController {
    
    @IBOutlet weak var table: WKInterfaceTable!
    
    let brightGreen = UIColor(rgb: 0xB8E994, alpha: 1.0)
    let darkGreen = UIColor(rgb: 0x78e08f, alpha: 1.0)
    
    var chat: String!
    var contributions = [Contribution]()
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        guard let context = context as? [String: String] else {return}
        self.chat = context["chatName"]
        
        WCSession.default.delegate = self
        
        WCSession.default.sendMessage(["chatName": chat], replyHandler: {
            reply in
            print(reply)
        }, errorHandler: {
            error in
            print(error)
        })
    }
    
}

extension ChatLogViewController: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let status = message["status"] as? String {
            self.receivedStatusMessage(status)
            return
        }
        guard
            let data = message[chat] as? Data,
            let contributions = try? JSONDecoder().decode([Contribution].self, from: data)
        else {return}
        print(contributions.count)
        if self.contributions != contributions {
            self.contributions = contributions
            showContributions()
        }
    }
    
    func showContributions() {
        self.table.setNumberOfRows(self.contributions.count, withRowType: "row")
        for (i, contribution) in self.contributions.enumerated() {
            let row = table.rowController(at: i) as! ContributionRowController
            
            row.messageLabel.setText((contribution.message.message ?? "") + (contribution.message.caption ?? "") +  (contribution.message.system ?? ""))
            if contribution.message.system != nil && contribution.message.system != "" {
                row.backgroundGroup.setBackgroundColor(UIColor.gray)
                row.messageLabel.setHorizontalAlignment(.center)
            } else {
                row.backgroundGroup.setBackgroundColor(contribution.own ? darkGreen : .white)
                row.messageLabel.setHorizontalAlignment(.left)
            }
            if let citationMessage = contribution.quote.message, citationMessage != "" {
                row.citationBackgroundGroup.setHidden(false)
                row.citationMessageLabel.setText(citationMessage)
                row.citationAuthorLabel.setText(contribution.quote.author.computedName())
                row.citationAuthorUserNameLabel.setText(contribution.quote.author.name)
                row.citationAuthorLabel.setTextColor(UIColor(
                    fromHexString: contribution.quote.author.contactColor ?? contribution.quote.author.numberColor
                ))
            } else {
                row.citationBackgroundGroup.setHidden(true)
            }
            if contribution.author.name != "" || contribution.author.computedName() != "" {
                row.authorLabel.setText(contribution.author.computedName())
                row.authorUserNameLabel.setText(contribution.author.name)
                row.authorLabel.setTextColor(UIColor(fromHexString: contribution.author.contactColor ?? contribution.author.numberColor))
            }
        }
    }
    
    func receivedStatusMessage(_ status: String) {
        DispatchQueue.main.async{self.setTitle(status)}
    }
}
