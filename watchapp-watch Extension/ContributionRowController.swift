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
    @IBOutlet weak var citationBackgroundGroup: WKInterfaceGroup!
    @IBOutlet weak var backgroundGroup: WKInterfaceGroup!
    @IBOutlet weak var messageLabel: WKInterfaceLabel!
    @IBOutlet weak var authorLabel: WKInterfaceLabel!
    @IBOutlet weak var authorUserNameLabel: WKInterfaceLabel!
    @IBOutlet weak var citationAuthorLabel: WKInterfaceLabel!
    @IBOutlet weak var citationAuthorUserNameLabel: WKInterfaceLabel!
    @IBOutlet weak var citationMessageLabel: WKInterfaceLabel!
}
