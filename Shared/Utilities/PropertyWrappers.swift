//
//  PropertyWrappers.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 03/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

@propertyWrapper struct NonNegative<T: Numeric & Comparable> {
    var value: T
    
    var wrappedValue: T {
        get { value }
        
        set {
            if newValue < 0 {
                value = 0
            } else {
                value = newValue
            }
        }
    }
    
    init(wrappedValue: T) {
        if wrappedValue < 0 {
            self.value = 0
        } else {
            self.value = wrappedValue
        }
    }
}
