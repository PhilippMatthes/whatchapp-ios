//
//  Models.swift
//  whatchapp
//
//  Created by Philipp Matthes on 26.07.18.
//  Copyright © 2018 Philipp Matthes. All rights reserved.
//

import Foundation
import UIKit

struct QueuedMessage: Codable, Equatable {
    let chatName: String
    let text: String
    var sent = false
    var pending = false
    
    init(chatName: String, text: String) {
        self.chatName = chatName
        self.text = text
    }
    
    private enum CodingKeys: String, CodingKey{
        case chatName = "chatName"
        case text = "text"
    }
}

struct ChatMessage: Codable, Equatable {
    let own: Bool
    let children: [PartialMessage]
    
    private enum CodingKeys: String, CodingKey {
        case own = "own"
        case children = "children"
    }
}

struct BlobImage: Codable, Equatable {
    let blobUrl: String
    let base64raw: String
    
    private enum CodingKeys: String, CodingKey {
        case blobUrl = "blobUrl"
        case base64raw = "base64"
    }
    
    func rendered() -> UIImage? {
        let componentsPNG = base64raw.components(separatedBy: "data:image/png;base64,")
        let componentsJPEG = base64raw.components(separatedBy: "data:image/jpeg;base64,")
        var base64: String
        if componentsPNG.count == 2 {
            base64 = componentsPNG[1]
        } else if componentsJPEG.count == 2 {
            base64 = componentsJPEG[1]
        } else {
            return nil
        }
        guard let imageData = Data(base64Encoded: base64), let image = UIImage(data: imageData) else {return nil}
        return image
    }
}

struct CompressedBlobImage: Codable, Equatable {
    
    let blobUrl: String
    let compressedData: Data
    
    private enum CodingKeys: String, CodingKey {
        case blobUrl = "blobUrl"
        case compressedData = "compressedData"
    }
    
    init?(_ blobImage: BlobImage) {
        guard
            let image = blobImage.rendered(),
            let shrinkedImage = image.resizedImage(targetSize: CGSize(width: 500.0, height: 500.0)),
            let compressedImage = shrinkedImage.jpegData(compressionQuality: 0.5),
            let compressedData = compressedImage.deflate()
        else {return nil}
        self.compressedData = compressedData
        self.blobUrl = blobImage.blobUrl
    }
    
    func rendered() -> UIImage? {
        guard
            let decompressedData = compressedData.inflate(),
            let image = UIImage(data: decompressedData)
        else {return nil}
        return image
    }
}

struct PartialMessage: Codable, Equatable {
    let message: String?
    let color: String?
    let alpha: CGFloat?
    let size: String?
    let src: String?
    
    private enum CodingKeys: String, CodingKey {
        case message = "message"
        case color = "color"
        case alpha = "alpha"
        case size = "size"
        case src = "src"
    }
}

struct Chat: Codable, Equatable {
    let name: String
    let message: String
    let date: String
    let imgURL: String?
    
    private enum CodingKeys: String, CodingKey {
        case name = "name"
        case message = "message"
        case date = "date"
        case imgURL = "imgURL"
    }
}

struct ChatUpdate: Codable, Equatable {
    let chats: [Chat]
    let date: Date
    
    private enum CodingKeys: String, CodingKey {
        case chats = "chats"
        case date = "date"
    }
    
    init(chats: [Chat]) {
        self.chats = chats
        self.date = Date()
    }
    
    func timeAgo() -> String {
        return date.timeAgo();
    }
}
