//
//  BasicStructs.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import os
import Foundation
import SwiftUI

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "BasicStructs")

// MARK: - Point(x, y)

struct Point: Codable, ExpressibleByArrayLiteral {
    typealias ArrayLiteralElement = Double
    
    var x: Double
    var y: Double
    
    init(arrayLiteral elements: Double...) {
        self.x = elements[0]
        self.y = elements[1]
    }
    
    init(_ x: Double, _ y: Double) {
        self.x = x
        self.y = y
    }
}

// MARK: - Ordre de tri

enum SortingOrder {
    case ascending
    case descending
    
    var imageSystemName: String {
        switch self {
            case .ascending:
                return "arrow.up.circle"
            case .descending:
                return "arrow.down.circle"
        }
    }
    mutating func toggle() {
        switch self {
            case .ascending:
                self = .descending
            case .descending:
                self = .ascending
        }
    }
}

struct BrutNetTaxable {
    var brut    : Double
    var net     : Double
    var taxable : Double
}
