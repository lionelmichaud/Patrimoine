//
//  ButtonStyles.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 13/12/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

// MARK: - Syle de bouton Rectangle à coins arrondis
struct RoundedRectButtonStyle: ButtonStyle {
    var color     : Color     = .accentColor
    var width     : CGFloat?
    var height    : CGFloat?
    var alignment : Alignment = .center
    
    public func makeBody(configuration: RoundedRectButtonStyle.Configuration) -> some View {
        MyButton(configuration : configuration,
                 color         : color,
                 width         : width,
                 height        : height,
                 alignment     : alignment)
    }
    
    struct MyButton: View {
        let configuration : RoundedRectButtonStyle.Configuration
        var color         : Color     = .accentColor
        var width         : CGFloat?
        var height        : CGFloat?
        var alignment     : Alignment = .center
        
        var body: some View {
            
            return configuration.label
                .frame(width: width, height: height, alignment: alignment)
                .foregroundColor(.white)
                .padding(15)
                .background(RoundedRectangle(cornerRadius: 5).fill(color))
                .compositingGroup()
                .shadow(color: .black, radius: 3)
                .opacity(configuration.isPressed ? 0.5 : 1.0)
        }
    }
}

extension Button {
    func roundedRectButtonStyle(color     : Color     = .accentColor,
                                width     : CGFloat?,
                                height    : CGFloat?  = nil,
                                alignment : Alignment = .center) -> some View {
        self.buttonStyle(RoundedRectButtonStyle(color: color, width: width, height: height, alignment: alignment))
    }
}

// MARK: - Syle de bouton Capsule - façon iOS 14
struct CapsuleButtonStyle: ButtonStyle {
    var color     : Color     = Color("buttonBackgroundColor")
    var width     : CGFloat?
    var height    : CGFloat?
    var alignment : Alignment = .center
    var withShadow: Bool      = false
    
    public func makeBody(configuration: CapsuleButtonStyle.Configuration) -> some View {
        MyButton(configuration : configuration,
                 color         : color,
                 width         : width,
                 height        : height,
                 alignment     : alignment)
    }
    
    struct MyButton: View {
        let configuration : CapsuleButtonStyle.Configuration
        var color         : Color     = Color("buttonBackgroundColor")
        var width         : CGFloat?
        var height        : CGFloat?
        var alignment     : Alignment = .center
        var withShadow    : Bool      = false
        
        var body: some View {
            
            return configuration.label
                .frame(width: width, height: height, alignment: alignment)
                .foregroundColor(.accentColor)
                .padding(.vertical, 5.0)
                .padding(.horizontal, 10.0)
                .background(Capsule(style: .continuous).fill(color))
                //.compositingGroup()
                //.shadow(color: .black, radius: 3)
                .opacity(configuration.isPressed ? 0.4 : 1.0)
        }
    }
}

extension Button {
    func capsuleButtonStyle(color     : Color     = Color("buttonBackgroundColor"),
                            width     : CGFloat?  = nil,
                            height    : CGFloat?  = nil,
                            alignment : Alignment = .center) -> some View {
        self.buttonStyle(CapsuleButtonStyle(color: color, width: width, height: height, alignment: alignment))
    }
}

// Button(iconName: "play.fill") {
extension Button where Label == Image {
    init(iconName: String, action: @escaping () -> Void) {
        self.init(action: action) {
            Image(systemName: iconName)
        }
    }
}

// MARK: - Previews

struct ButtonsViews_Previews: PreviewProvider {
    struct RoundedRectButtonStyleView: View {
        var body: some View {
            VStack {
                Button("Tap Me!") {
                    print("button pressed!")
                }.roundedRectButtonStyle(color: .blue, width: 200)
            }
        }
    }
    
    struct CapsuleButtonStyleView: View {
        var body: some View {
            VStack {
                Button("Tap Me!") {
                    print("button pressed!")
                }.capsuleButtonStyle(color: Color("buttonBackgroundColor"))
            }
        }
    }
    
    static let itemSelection = [(label: "item 1", selected: true),
                                (label: "item 2", selected: true)]
    
    static var previews: some View {
        Group {
            Group {
                RoundedRectButtonStyleView()
                    .previewLayout(PreviewLayout.sizeThatFits)
                    .padding()
                    .previewDisplayName("RoundedRectButtonStyleView")
                CapsuleButtonStyleView()
                    .preferredColorScheme(.dark)
                    .previewLayout(PreviewLayout.sizeThatFits)
                    .padding()
                    .previewDisplayName("CapsuleButtonStyleView")
                CapsuleButtonStyleView()
                    .preferredColorScheme(.light)
                    .previewLayout(PreviewLayout.sizeThatFits)
                    .padding()
                    .previewDisplayName("CapsuleButtonStyleView")
            }
        }
    }
}

// MARK: - Library Modifiers

// swiftlint:disable type_name
struct ButtonModifiers_Library: LibraryContentProvider {
    @LibraryContentBuilder
    func modifiers(base: Button<ContentView>) -> [LibraryItem] {
        LibraryItem(base.roundedRectButtonStyle(color : .blue, width : 200),
                    title                             : "Rounded Rect Button",
                    category                          : .control,
                    matchingSignature                 : "roundrectbutton")
        LibraryItem(base.capsuleButtonStyle(color : Color("buttonBackgroundColor")),
                    title                         : "Capsule Rect Button",
                    category                      : .control,
                    matchingSignature             : "capsulebutton")
    }
}
