//
//  Extensions+File.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Working with numbers
public extension Int {
    
    /**
     :returns: *true* if self is even number
     */
    var isEven: Bool {
        return ( self % 2 == 0 )
    }
    
    var estPair: Bool {
        return ( self % 2 == 0 )
    }
    
    /**
     :returns: *true* if self is odd number
     */
    var isOdd: Bool {
        return ( self % 2 != 0 )
    }
    
    var estImpair: Bool {
        return ( self % 2 != 0 )
    }
    
    /**
     :returns: *true* if self is positive number
     */
    var isPositive: Bool {
        return ( self > 0 )
    }
    
    /**
     :returns: *true* if self is negative number
     */
    var isNegative: Bool {
        return ( self < 0 )
    }
    
    /**
     :returns: *true* if self is zero
     */
    var isZero: Bool {
        return ( self == 0 )
    }
    
    /**
     :returns: *true* if self is positive or zero
     */
    var isPOZ: Bool {
        return ( self.isPositive || self.isZero )
    }
    
    /**
     :returns: cast self to Double
     */
    func double() -> Double {
        return Double(self)
    }
    
    /**
     :returns: cast self to Float
     */
    func float() -> Float {
        return Float(self)
    }
    
    /**
     This method will repeat *closure* n times. Possible way of usage:
     
     12.times { ... do something ... }
     
     :param: closure is a given code that will be invoked
     */
    func times(closure: () -> Void) {
        for _ in 0 ..< self {
            closure()
        }
    }
    
    func times (iterator: () -> Void) {
        for _ in 0...self {
            iterator()
        }
    }
}
