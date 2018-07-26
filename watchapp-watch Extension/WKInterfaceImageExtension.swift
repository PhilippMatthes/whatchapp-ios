//
//  WKInterfaceImageExtension.swift
//  watchapp-watch Extension
//
//  Created by Philipp Matthes on 23.07.18.
//  Copyright © 2018 Philipp Matthes. All rights reserved.
//

import Foundation
import WatchKit

extension WKInterfaceImage {
    public func imageFromUrl(_ urlString: String) {
        
        if let url = NSURL(string: urlString) {
            
            let request = NSURLRequest(url: url as URL)
            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config)
            
            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()
            let task = session.dataTask(with: request as URLRequest, completionHandler: {(data, response, error) in
                if let imageData = data as Data? {
                    DispatchQueue.main.async {
                        self.setImageData(imageData)
                        dispatchGroup.leave()
                    }
                } else {
                    dispatchGroup.leave()
                }
            });
            
            task.resume()
            dispatchGroup.wait()
        }
    }
}
