//
//  SwiftUIconditional.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 30/07/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

extension View {
    
    /// Sets the style for lists within this view.
    public func defaultSideBarListStyle() -> some View {
        if #available(iOS 14.0, *) {
            return AnyView(self.listStyle(InsetGroupedListStyle()))
        } else {
            return AnyView(self.listStyle(GroupedListStyle()))
        }
    }
}
