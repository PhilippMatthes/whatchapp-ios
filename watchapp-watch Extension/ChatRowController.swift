//
//  ChatRowController.swift
//  watchapp-watch Extension
//
//  Created by Philipp Matthes on 23.07.18.
//  Copyright © 2018 Philipp Matthes. All rights reserved.
//

import Foundation
import WatchKit
import UIKit

class ChatRowController: NSObject {
    @IBOutlet weak var titleLabel: WKInterfaceLabel!
    @IBOutlet weak var label: WKInterfaceLabel!
    @IBOutlet weak var backgroundGroup: WKInterfaceGroup!
    @IBOutlet weak var dateLabel: WKInterfaceLabel!
}
