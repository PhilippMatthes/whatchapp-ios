//
//  ArrayExtension.swift
//  whatchapp
//
//  Created by Philipp Matthes on 31.07.18.
//  Copyright © 2018 Philipp Matthes. All rights reserved.
//

import Foundation

extension Array where Element:Equatable {
    func removeDuplicates() -> [Element] {
        var result = [Element]()
        
        for value in self {
            if result.contains(value) == false {
                result.append(value)
            }
        }
        
        return result
    }
}
