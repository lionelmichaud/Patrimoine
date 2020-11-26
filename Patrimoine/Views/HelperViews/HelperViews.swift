//
//  HelperViews.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 08/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import ActivityIndicatorView // https://github.com/exyte/ActivityIndicatorView.git

// MARK: - Syle de bouton Rectangle à coins arrondis
struct RoundedRectButtonStyle: ButtonStyle {
    var color     : Color     = .accentColor
    var width     : CGFloat?  = nil
    var height    : CGFloat?  = nil
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
        var width         : CGFloat?  = nil
        var height        : CGFloat?  = nil
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
    func roundedRectButtonStyle(color : Color     = .accentColor,
                       width          : CGFloat?  = nil,
                       height         : CGFloat?  = nil,
                       alignment      : Alignment = .center) -> some View {
        self.buttonStyle(RoundedRectButtonStyle(color: color, width: width, height: height, alignment: alignment))
    }
}

// MARK: - Syle de bouton Capsule - façon iOS 14
struct CapsuleButtonStyle: ButtonStyle {
    var color     : Color     = Color("buttonBackgroundColor")
    var width     : CGFloat?  = nil
    var height    : CGFloat?  = nil
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
        var width         : CGFloat?  = nil
        var height        : CGFloat?  = nil
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

// MARK: - Custom modifiers
struct Title: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.largeTitle)
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

extension View {
    func titleStyle() -> some View {
        self.modifier(Title())
    }
}

// MARK: - Progress bar
struct ProgressBar: View {
    private let value             : Double
    private let minValue          : Double
    private let maxValue          : Double
    private let backgroundEnabled : Bool
    private let labelsEnabled     : Bool
    private let backgroundColor   : Color
    private let foregroundColor   : Color
    private let formater          : NumberFormatter?
    
    init(value             : Double,
         minValue          : Double,
         maxValue          : Double,
         backgroundEnabled : Bool  = true,
         labelsEnabled     : Bool  = false,
         backgroundColor   : Color = .secondary,
         foregroundColor   : Color = .blue,
         formater          : NumberFormatter? = nil) {
        self.value             = value.clamp(low: minValue, high: maxValue)
        self.minValue          = minValue
        self.maxValue          = max (minValue+0.01, maxValue)
        self.backgroundEnabled = backgroundEnabled
        self.labelsEnabled     = labelsEnabled
        self.backgroundColor   = backgroundColor
        self.foregroundColor   = foregroundColor
        self.formater          = formater
    }
    
    var body: some View {
        VStack(alignment: .center,spacing: 10) {
            GeometryReader { geometryReader in
                ZStack(alignment: .leading) {
                    if self.backgroundEnabled {
                        Capsule()
                            .frame(height: 20)
                            .foregroundColor(self.backgroundColor) // 4
                    } else {
                        Capsule()
                            .stroke(self.backgroundColor)
                            .frame(height: 20)
                    }
                    
                    ZStack(alignment: .trailing) {
                        Capsule()
                            .frame(width: self.progress(value: self.value,
                                                        width: geometryReader.size.width),
                                   height: 20)
                            .foregroundColor(self.foregroundColor)
                            .animation(.linear)
                        Text("\(self.percentage(value: self.value))%")
                            .foregroundColor(.white) // 6
                            .font(.system(size: 14))
                            .fontWeight(.bold)
                            .padding(.trailing, 10)
                    }
                }
            }
            
            if labelsEnabled {
                HStack() {
                    if let formater = self.formater {
                        Text(formater.string(from: minValue as NSNumber) ?? "")
                            .fontWeight(.bold)
                        Spacer()
                        Text(formater.string(from: maxValue as NSNumber) ?? "")
                            .fontWeight(.bold)
                    } else {
                        Text(minValue.roundedString)
                            .fontWeight(.bold)
                        Spacer()
                        Text(maxValue.roundedString)
                            .fontWeight(.bold)
                    }
                }
                .font(.system(size: 14))
            }
        }
        .frame(height: (labelsEnabled ? 40 : 20))
        
    }
    
    private func progress(value: Double,
                          width: CGFloat) -> CGFloat {
        let percentage = (value - minValue) / (maxValue - minValue)
        return width *  CGFloat(percentage)
    }
    private func percentage(value: Double) -> Int {
        Int(100 * (value - minValue) / (maxValue - minValue))
    }
}

// MARK: - Progress circle
struct ProgressCircle: View {
    enum Stroke {
        case line
        case dotted
        
        func strokeStyle(lineWidth: CGFloat) -> StrokeStyle {
            switch self {
                case .line:
                    return StrokeStyle(lineWidth: lineWidth,
                                       lineCap: .round)
                case .dotted:
                    return StrokeStyle(lineWidth: lineWidth,
                                       lineCap: .round,
                                       dash: [12])
            }
        }
    }
    
    private let value             : Double
    private let minValue          : Double
    private let maxValue          : Double
    private let style             : Stroke
    private let backgroundEnabled : Bool
    private let labelsEnabled     : Bool
    private let backgroundColor   : Color
    private let foregroundColor   : Color
    private let lineWidth         : CGFloat
    
    init(value             : Double,
         minValue          : Double,
         maxValue          : Double,
         style             : Stroke  = .line,
         backgroundEnabled : Bool    = true,
         labelsEnabled     : Bool    = true,
         backgroundColor   : Color   = .secondary,
         foregroundColor   : Color   = .blue,
         lineWidth         : CGFloat = 10) {
        self.value             = value.clamp(low: minValue, high: maxValue)
        self.minValue          = minValue
        self.maxValue          = max (minValue+0.01, maxValue)
        self.style             = style
        self.backgroundEnabled = backgroundEnabled
        self.labelsEnabled     = labelsEnabled
        self.backgroundColor   = backgroundColor
        self.foregroundColor   = foregroundColor
        self.lineWidth         = lineWidth
    }
    
    var body: some View {
        ZStack {
            if backgroundEnabled {
                Circle()
                    .stroke(lineWidth: lineWidth)
                    .foregroundColor(backgroundColor)
            }
            
            Circle()
                .trim(from: 0, to: CGFloat((value - minValue) / (maxValue - minValue)))
                .stroke(style: style.strokeStyle(lineWidth: lineWidth))
                .foregroundColor(foregroundColor)
                .rotationEffect(Angle(degrees: -90))
                .animation(.easeIn)
            Text("\(percentage(value: value))%")
                .font(.system(size: 14))
                .fontWeight(.bold)
        }
    }
    
    private func percentage(value: Double) -> Int {
        Int(100 * (value - minValue) / (maxValue - minValue))
    }
}

// MARK: - Activity Indicator
struct ActivityIndicator: UIViewRepresentable {
    @Binding var shouldAnimate: Bool
    
    func makeUIView(context: Context) -> UIActivityIndicatorView {
        return UIActivityIndicatorView()
    }
    
    func updateUIView(_ uiView: UIActivityIndicatorView,
                      context: Context) {
        if self.shouldAnimate {
            uiView.startAnimating()
        } else {
            uiView.stopAnimating()
        }
    }
}


// MARK: - Multi line TextField
struct MultilineTextField: View {
    
    private var placeholder: String
    private var onCommit: (() -> Void)?
    @State private var viewHeight: CGFloat = 40 //start with one line
    @State private var shouldShowPlaceholder = false
    @Binding private var text: String
    
    private var internalText: Binding<String> {
        Binding<String>(get: { self.text } ) {
            self.text = $0
            self.shouldShowPlaceholder = $0.isEmpty
        }
    }
    
    var body: some View {
        UITextViewWrapper(text: self.internalText, calculatedHeight: $viewHeight, onDone: onCommit)
            .frame(minHeight: viewHeight, maxHeight: viewHeight)
            .background(placeholderView, alignment: .topLeading)
    }
    
    var placeholderView: some View {
        Group {
            if shouldShowPlaceholder {
                Text(placeholder).foregroundColor(.gray)
                    .padding(.leading, 4)
                    .padding(.top, 8)
            }
        }
    }
    
    init (_ placeholder: String = "", text: Binding<String>, onCommit: (() -> Void)? = nil) {
        self.placeholder = placeholder
        self.onCommit = onCommit
        self._text = text
        self._shouldShowPlaceholder = State<Bool>(initialValue: self.text.isEmpty)
    }
    
}

private struct UITextViewWrapper: UIViewRepresentable {
    typealias UIViewType = UITextView
    
    @Binding var text: String
    @Binding var calculatedHeight: CGFloat
    var onDone: (() -> Void)?
    
    func makeUIView(context: UIViewRepresentableContext<UITextViewWrapper>) -> UITextView {
        let textField = UITextView()
        textField.delegate = context.coordinator
        
        textField.isEditable = true
        textField.font = UIFont.preferredFont(forTextStyle: .body)
        textField.isSelectable = true
        textField.isUserInteractionEnabled = true
        textField.isScrollEnabled = false
        textField.backgroundColor = UIColor.clear
        if nil != onDone {
            textField.returnKeyType = .done
        }
        
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return textField
    }
    
    func updateUIView(_ uiView: UITextView, context: UIViewRepresentableContext<UITextViewWrapper>) {
        if uiView.text != self.text {
            uiView.text = self.text
        }
        if uiView.window != nil, !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        }
        UITextViewWrapper.recalculateHeight(view: uiView, result: $calculatedHeight)
    }
    
    private static func recalculateHeight(view: UIView, result: Binding<CGFloat>) {
        let newSize = view.sizeThatFits(CGSize(width: view.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
        if result.wrappedValue != newSize.height {
            DispatchQueue.main.async {
                result.wrappedValue = newSize.height // call in next render cycle.
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text, height: $calculatedHeight, onDone: onDone)
    }
    
    final class Coordinator: NSObject, UITextViewDelegate {
        var text: Binding<String>
        var calculatedHeight: Binding<CGFloat>
        var onDone: (() -> Void)?
        
        init(text: Binding<String>, height: Binding<CGFloat>, onDone: (() -> Void)? = nil) {
            self.text = text
            self.calculatedHeight = height
            self.onDone = onDone
        }
        
        func textViewDidChange(_ uiView: UITextView) {
            text.wrappedValue = uiView.text
            UITextViewWrapper.recalculateHeight(view: uiView, result: calculatedHeight)
        }
        
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if let onDone = self.onDone, text == "\n" {
                textView.resignFirstResponder()
                onDone()
                return false
            }
            return true
        }
    }
    
}

// MARK: - Selection Menus View

struct MenuContentView: View {
    @Binding var itemSelection  : [(label  : String, selected  : Bool)]
    
    func setAll(selected: Bool) {
        for idx in 0 ..< itemSelection.count {
            itemSelection[idx].selected = selected
        }
    }
    
    var body: some View {
        // filtre des séries à (dé)sélectionner
        VStack {
            // Barre de titre
            HStack {
                Button(
                    action: {
                        self.setAll(selected: true)
                    },
                    label: {
                        HStack {
                            Text("Tout").font(.callout)
                            Image(systemName: "checkmark.square")
                        }
                    }).capsuleButtonStyle()
                Spacer()
                Button(
                    action: {
                        self.setAll(selected: false)
                    },
                    label: {
                        HStack {
                            Text("Rien").font(.callout)
                            Image(systemName: "square")
                        }
                    }).capsuleButtonStyle()
            }.padding(.horizontal)
            // menu
            List (0 ..< itemSelection.count) { idx in
                HStack {
                    Text(self.itemSelection[idx].label).font(.caption)
                    Spacer()
                    Image(systemName: self.itemSelection[idx].selected ? "checkmark.square" : "square")
                }
                .onTapGesture {
                    self.itemSelection[idx].selected.toggle()
                }
            }
            .listStyle(GroupedListStyle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Tests & Previews

struct HelperViews_Previews: PreviewProvider {
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
                ProgressBar(value             : 5,
                            minValue          : 0,
                            maxValue          : 10,
                            backgroundEnabled : true,
                            labelsEnabled     : true,
                            backgroundColor   : .secondary,
                            foregroundColor   : .blue)
                    .previewLayout(PreviewLayout.fixed(width: 400, height: 100))
                    .padding()
                    .previewDisplayName("ProgressBar")
                ProgressCircle(value             : 85.0,
                               minValue          : 50.0,
                               maxValue          : 100.0,
                               backgroundEnabled : false,
                               backgroundColor   : .gray,
                               foregroundColor   : .blue,
                               lineWidth         : 10)
                    .previewLayout(PreviewLayout.fixed(width: 100, height: 100))
                    .padding()
                    .previewDisplayName("ProgressCircle")
                ActivityIndicator(shouldAnimate: .constant(true))
                    .previewLayout(PreviewLayout.fixed(width: 100, height: 100))
                    .padding()
                    .previewDisplayName("ActivityIndicator")
                ActivityIndicatorView(isVisible: .constant(true), type: .flickeringDots)
                    .frame(width: 50, height: 50)
                    .previewLayout(PreviewLayout.fixed(width: 100, height: 100))
                    .foregroundColor(.blue)
                    .previewDisplayName("ActivityIndicatorView")
                MultilineTextField("Type here",
                                   text: .constant("content"),
                                   onCommit: { })
                    .previewLayout(PreviewLayout.fixed(width: 400, height: 100))
                    .padding()
                    .previewDisplayName("MultilineTextField")
            }
            Group {
                MenuContentView(itemSelection: .constant(itemSelection))
                    .previewLayout(PreviewLayout.fixed(width: 250, height: 250))
                    .padding()
                    .previewDisplayName("MenuContentView")
                Toggle(isOn: .constant(true), label: { Text("Toggle") })
                    .toggleStyle(CheckboxToggleStyle(size:.large))
                    .previewLayout(PreviewLayout.fixed(width: 250, height: 50))
                    .padding()
                    .previewDisplayName("CheckboxToggleStyle")
           }
        }
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


// MARK: - Library Modifiers

struct ButtonModifiers_Library: LibraryContentProvider {
    @LibraryContentBuilder
    func modifiers(base: Button<ContentView>) -> [LibraryItem] {
        LibraryItem (base.roundedRectButtonStyle(color: .blue, width: 200),
                     title: "Rounded Rect Button",
                     category: .control,
                     matchingSignature: "roundrectbutton")
        LibraryItem (base.capsuleButtonStyle(color: Color("buttonBackgroundColor")),
                     title: "Capsule Rect Button",
                     category: .control,
                     matchingSignature: "capsulebutton")
    }
}

struct ToggleModifiers_Library: LibraryContentProvider {
    @LibraryContentBuilder
    func modifiers(base: Toggle<ContentView>) -> [LibraryItem] {
        LibraryItem (base.toggleStyle(CheckboxToggleStyle(size:.large)),
                     title: "Toggle Check Box",
                     category: .control,
                     matchingSignature: "checkbox")
    }
}
