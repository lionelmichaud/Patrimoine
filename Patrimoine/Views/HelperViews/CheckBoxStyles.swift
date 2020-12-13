//
//  CheckBoxStyles.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 13/12/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

// MARK: - Check Box - Syle de Toggle customisé
struct CheckboxToggleStyle: ToggleStyle {
    enum Size {
        case small
        case medium
        case large
    }
    
    let size: Size
    
    func makeBody(configuration: Configuration) -> some View {
        return HStack {
            configuration.label
            Spacer()
            if size == Size.small {
                Image(systemName: configuration.isOn ? "checkmark.square" : "square")
                    .resizable()
                    .frame(width: 15, height: 15)
                    .onTapGesture { configuration.isOn.toggle() }
            } else if size == Size.medium {
                Image(systemName: configuration.isOn ? "checkmark.square" : "square")
                    .resizable()
                    .frame(width: 22, height: 22)
                    .onTapGesture { configuration.isOn.toggle() }
            } else {
                Image(systemName: configuration.isOn ? "checkmark.square" : "square")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .onTapGesture { configuration.isOn.toggle() }
            }
        }
    }
}

// MARK: - Library Modifiers

// swiftlint:disable type_name
struct ToggleModifiers_Library: LibraryContentProvider {
    @LibraryContentBuilder
    func modifiers(base: Toggle<ContentView>) -> [LibraryItem] {
        LibraryItem(base.toggleStyle(CheckboxToggleStyle(size :.large)),
                    title                                     : "Toggle Check Box",
                    category                                  : .control,
                    matchingSignature                         : "checkbox")
    }
}
