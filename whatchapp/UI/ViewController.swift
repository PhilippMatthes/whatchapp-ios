//
//  ViewController.swift
//  whatchapp
//
//  Created by Philipp Matthes on 22.07.18.
//  Copyright © 2018 Philipp Matthes. All rights reserved.
//

import UIKit
import WebKit
import Material
import WatchConnectivity

class ViewController: UIViewController {
    
    struct TutorialSlide {
        let title: String
        let text: String
        let image: UIImage
        
        static let all = [
            TutorialSlide(title: "Hi!", text: "To use Whatchapp, you just need to follow these few simple steps. Ready? Swipe to start with the Tutorial!", image: UIImage(named: "screen0-en")!),
            TutorialSlide(title: "Step 1", text: "Open Whatsapp and go to settings - Whatsapp Web/Desktop. Select \"Scan QR Code\".", image: UIImage(named: "screen1-en")!),
            TutorialSlide(title: "Step 2", text: "Open Whatchapp on your Watch and wait for the QR Code to show. If your QR Code does not show, try reloading by force touch. Scan the QR code with the official Whatsapp App!", image: UIImage(named: "screen2-en")!),
            TutorialSlide(title: "That's it!", text: "If there is an error and Whatsapp cannot log us in, try again. After a few moments, you should see your chats!", image: UIImage(named: "screen3-en")!),
            TutorialSlide(title: "One last thing", text: "Whatchapp works via Whatsapp Web. Whatchapp's browser should now show up as Linux x86_64. Don't worry, this is just your phone acting as a PC.", image: UIImage(named: "screen4-en")!)
        ]
    }
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    
    var currentSlideIndex = TutorialSlide.all.count - 1
    var lastUpdate = Storage.lastUpdate
    
    var webView: WKWebView?
    var blurEffectView: UIVisualEffectView?
    var foregroundView: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nextSlide()
        
        if let update = lastUpdate {
            statusLabel.text = "Last Chat Update: \(update.timeAgo())"
            statusLabel.font = RobotoFont.regular(with: 12.0)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.viewController = self
            self.layout(webView: delegate.webView)
        }
    }
    
    func layout(webView: WKWebView?) {
        guard let webView = webView else {return}
        DispatchQueue.main.async {
            self.webView = webView
            self.webView?.isUserInteractionEnabled = false
            self.webView?.layer.zPosition = -3
            self.view.layout(webView).top(0).bottom(0).left(0).right(0)
            
            let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.light)
            self.blurEffectView = UIVisualEffectView(effect: blurEffect)
            self.blurEffectView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.blurEffectView?.layer.zPosition = -2
            self.blurEffectView?.alpha = 0.4
            self.view.layout(self.blurEffectView!).top(0).bottom(0).left(0).right(0)
            
            self.foregroundView = UIView()
            self.foregroundView?.backgroundColor = UIColor(rgb: 0x4BCC71)
            self.foregroundView?.alpha = 0.75
            self.foregroundView?.layer.zPosition = -1
            self.view.layout(self.foregroundView!).top(0).bottom(0).left(0).right(0)
        }
    }
    
    @IBAction func nextSlide() {
        currentSlideIndex = (currentSlideIndex + 1) % TutorialSlide.all.count
        let currentSlide = TutorialSlide.all[currentSlideIndex]
        let toImage = currentSlide.image
        UIView.transition(with: self.imageView, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.imageView.image = toImage
        },completion: nil)
        UIView.transition(with: self.label, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.label.text = currentSlide.text
            self.label.font = RobotoFont.medium(with: 15.0)
        })
        UIView.transition(with: self.titleLabel, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.titleLabel.text = currentSlide.title.capitalized
            self.titleLabel.font = RobotoFont.bold(with: 40.0)
        })
    }
    
    
}

