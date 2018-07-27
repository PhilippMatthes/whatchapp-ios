//
//  Models.swift
//  whatchapp
//
//  Created by Philipp Matthes on 26.07.18.
//  Copyright © 2018 Philipp Matthes. All rights reserved.
//

import Foundation

struct Contribution: Codable, Equatable {
    let message: Message
    let own: Bool
    let quote: Quote
    let author: Author
    
    private enum CodingKeys: String, CodingKey {
        case message = "message"
        case own = "own"
        case quote = "quote"
        case author = "author"
    }
}

struct Message: Codable, Equatable {
    let caption: String?
    let message: String?
    let system: String?
    
    private enum CodingKeys: String, CodingKey {
        case caption = "caption"
        case message = "message"
        case system = "system"
    }
}

struct Quote: Codable, Equatable {
    let message: String?
    let author: Author
    
    private enum CodingKeys: String, CodingKey {
        case message = "message"
        case author = "author"
    }
}

struct Author: Codable, Equatable {
    let number: String?
    let numberColor: String?
    let name: String?
    let contact: String?
    let contactColor: String?
    
    private enum CodingKeys: String, CodingKey {
        case number = "number"
        case numberColor = "numberColor"
        case name = "name"
        case contact = "contact"
        case contactColor = "contactColor"
    }
    
    func computedName() -> String {
        var name = self.contact ?? ""
        name += self.name ?? ""
        if let number = self.number {
            name += " \(number)"
        }
        return name
    }

}

struct Chat: Codable, Equatable {
    let name: String
    let message: String
    let date: String
    
    private enum CodingKeys: String, CodingKey {
        case name = "name"
        case message = "message"
        case date = "date"
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
