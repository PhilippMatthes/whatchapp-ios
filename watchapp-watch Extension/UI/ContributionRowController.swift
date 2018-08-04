//
//  ContributionRowController.swift
//  watchapp-watch Extension
//
//  Created by Philipp Matthes on 27.07.18.
//  Copyright © 2018 Philipp Matthes. All rights reserved.
//

import Foundation
import WatchKit
import UIKit

class ContributionRowController: NSObject {
    
    @IBOutlet weak var backgroundGroup: WKInterfaceGroup!

    @IBOutlet weak var label1: WKInterfaceLabel!
    @IBOutlet weak var label2: WKInterfaceLabel!
    @IBOutlet weak var label3: WKInterfaceLabel!
    @IBOutlet weak var label4: WKInterfaceLabel!
    @IBOutlet weak var label5: WKInterfaceLabel!
    @IBOutlet weak var label6: WKInterfaceLabel!
    @IBOutlet weak var label7: WKInterfaceLabel!
    @IBOutlet weak var label8: WKInterfaceLabel!
    @IBOutlet weak var label9: WKInterfaceLabel!
    @IBOutlet weak var label10: WKInterfaceLabel!
    
    @IBOutlet weak var imageGroup: WKInterfaceGroup!
    @IBOutlet weak var image: WKInterfaceImage!
    
    func prepare(_ message: ChatMessage, _ blobImages: [CompressedBlobImage]) {
        let brightGreen = UIColor(rgb: 0x78e08f, alpha: 1.0)
        backgroundGroup.setBackgroundColor(message.own ? brightGreen : .white)
        let labels = [label1, label2, label3, label4, label5, label6, label7, label8, label9, label10]
        for label in labels {
            label?.setHidden(true)
        }
        image.setHidden(true)
        imageGroup.setHidden(true)
        for (i, partialMessage) in message.children.removeDuplicates().enumerated() {
            let label = labels[i]
            if partialMessage.message != "" {
                label?.setHidden(false)
                label?.setText(partialMessage.message)
                label?.setTextColor(UIColor(fromHexString: partialMessage.color))
            }
            if let alpha = partialMessage.alpha {
                label?.setAlpha(alpha)
            } else {
                label?.setAlpha(1.0)
            }
            for blobImage in blobImages {
                if blobImage.blobUrl == partialMessage.src {
                    image.setImage(blobImage.rendered())
                    image.setHidden(false)
                    image.setAlpha(0.0)
                    imageGroup.setBackgroundImage(blobImage.rendered())
                    imageGroup.setCornerRadius(6.0)
                    imageGroup.setHidden(false)
                }
            }
        }
    }
}
