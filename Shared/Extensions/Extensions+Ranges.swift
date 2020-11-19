//
//  Extensions+Ranges.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 19/11/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

extension ClosedRange {
    func hasIntersection(with: ClosedRange) -> Bool where Bound: Strideable, Bound.Stride: SignedInteger {
        return self.clamped(to: with).count > 1 ||
            with.clamped(to: self) .count > 1
    }
}
