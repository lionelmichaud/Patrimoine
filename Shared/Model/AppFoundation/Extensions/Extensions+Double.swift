//
//  Extensions+Double.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

extension Double {
    var roundedString: String {
        String(format: "%.f", self.rounded())
    }
}

extension Double: Randomizable {
    static func randomized(in range: ClosedRange<Double>) -> Double {
        Double.random(in: range)
    }
}
