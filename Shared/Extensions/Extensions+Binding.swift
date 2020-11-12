//
//  Extensions+Binding.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 11/11/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import SwiftUI

extension Binding {
    static func ??(lhs: Binding<Optional<Value>>, rhs: Value) -> Binding<Value> {
        return Binding(get: { lhs.wrappedValue ?? rhs },
                       set: { lhs.wrappedValue = $0 })
    }
}
