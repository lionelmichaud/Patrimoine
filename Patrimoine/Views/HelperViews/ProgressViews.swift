//
//  ProgressViews.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 13/12/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import ActivityIndicatorView // https://github.com/exyte/ActivityIndicatorView.git

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
        self.maxValue          = max(minValue+0.01, maxValue)
        self.backgroundEnabled = backgroundEnabled
        self.labelsEnabled     = labelsEnabled
        self.backgroundColor   = backgroundColor
        self.foregroundColor   = foregroundColor
        self.formater          = formater
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
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
                HStack {
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
        self.maxValue          = max(minValue+0.01, maxValue)
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

// MARK: - Tests & Previews

struct ProgressViews_Previews: PreviewProvider {
    static let itemSelection = [(label: "item 1", selected: true),
                                (label: "item 2", selected: true)]
    
    static var previews: some View {
        Group {
            Group {
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
            }
        }
    }
}
