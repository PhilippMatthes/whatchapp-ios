//
//  Storage.swift
//  whatchapp
//
//  Created by Philipp Matthes on 26.07.18.
//  Copyright © 2018 Philipp Matthes. All rights reserved.
//

import Foundation

class Storage {
    
    static var lastUpdate: ChatUpdate? {
        get {
            guard
                let data = UserDefaults.standard.object(forKey: "lastUpdate") as? Data,
                let decoded = try? JSONDecoder().decode(ChatUpdate.self, from: data)
            else {return nil}
            return decoded
        }
        set {
            guard
                let newValue = newValue,
                let encoded = try? JSONEncoder().encode(newValue)
            else {return}
            UserDefaults.standard.set(encoded, forKey: "lastUpdate")
        }
    }
    
}
