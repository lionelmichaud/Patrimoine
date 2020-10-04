//
//  MarkerView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 13/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import Charts // https://github.com/danielgindi/Charts.git
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Etiquette pour diagramme  en radar

/// Etiquette pour diagramme  en radar
class RadarMarkerView: MarkerView {
    @IBOutlet var label: UILabel!
    
    public override func awakeFromNib() {
        self.offset.x = -self.frame.size.width / 2.0
        self.offset.y = -self.frame.size.height - 7.0
    }
    
    public override func refreshContent(entry: ChartDataEntry, highlight: Highlight) {
        label.text = String.init(format: "%d %%", Int(round(entry.y)))
        layoutIfNeeded()
    }
}

// MARK: - Bulle d'info pour diagramme (générique)

/// Bulle d'info pour diagramme (générique)
open class BalloonMarker: MarkerImage
{
    open var color: UIColor
    open var arrowSize = CGSize(width: 15, height: 11)
    open var font: UIFont
    open var textColor: UIColor
    open var insets: UIEdgeInsets
    open var minimumSize = CGSize()
    
    fileprivate var label: String?
    fileprivate var _labelSize: CGSize = CGSize()
    fileprivate var _paragraphStyle: NSMutableParagraphStyle?
    fileprivate var _drawAttributes = [NSAttributedString.Key : Any]()
    
    public init(color: UIColor, font: UIFont, textColor: UIColor, insets: UIEdgeInsets)
    {
        self.color = color
        self.font = font
        self.textColor = textColor
        self.insets = insets
        
        _paragraphStyle = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
        _paragraphStyle?.alignment = .center
        super.init()
    }
    
    open override func offsetForDrawing(atPoint point: CGPoint) -> CGPoint
    {
        var offset = self.offset
        var size = self.size
        
        if size.width == 0.0 && image != nil
        {
            size.width = image!.size.width
        }
        if size.height == 0.0 && image != nil
        {
            size.height = image!.size.height
        }
        
        let width = size.width
        let height = size.height
        let padding: CGFloat = 8.0
        
        var origin = point
        origin.x -= width / 2
        origin.y -= height
        
        if origin.x + offset.x < 0.0
        {
            offset.x = -origin.x + padding
        }
        else if let chart = chartView,
            origin.x + width + offset.x > chart.bounds.size.width
        {
            offset.x = chart.bounds.size.width - origin.x - width - padding
        }
        
        if origin.y + offset.y < 0
        {
            offset.y = height + padding;
        }
        else if let chart = chartView,
            origin.y + height + offset.y > chart.bounds.size.height
        {
            offset.y = chart.bounds.size.height - origin.y - height - padding
        }
        
        return offset
    }
    
    open override func draw(context: CGContext, point: CGPoint)
    {
        guard let label = label else { return }
        
        let offset = self.offsetForDrawing(atPoint: point)
        let size = self.size
        
        var rect = CGRect(
            origin: CGPoint(
                x: point.x + offset.x,
                y: point.y + offset.y),
            size: size)
        rect.origin.x -= size.width / 2.0
        rect.origin.y -= size.height
        
        context.saveGState()
        
        context.setFillColor(color.cgColor)
        
        if offset.y > 0
        {
            context.beginPath()
            context.move(to: CGPoint(
                x: rect.origin.x,
                y: rect.origin.y + arrowSize.height))
            context.addLine(to: CGPoint(
                x: rect.origin.x + (rect.size.width - arrowSize.width) / 2.0,
                y: rect.origin.y + arrowSize.height))
            //arrow vertex
            context.addLine(to: CGPoint(
                x: point.x,
                y: point.y))
            context.addLine(to: CGPoint(
                x: rect.origin.x + (rect.size.width + arrowSize.width) / 2.0,
                y: rect.origin.y + arrowSize.height))
            context.addLine(to: CGPoint(
                x: rect.origin.x + rect.size.width,
                y: rect.origin.y + arrowSize.height))
            context.addLine(to: CGPoint(
                x: rect.origin.x + rect.size.width,
                y: rect.origin.y + rect.size.height))
            context.addLine(to: CGPoint(
                x: rect.origin.x,
                y: rect.origin.y + rect.size.height))
            context.addLine(to: CGPoint(
                x: rect.origin.x,
                y: rect.origin.y + arrowSize.height))
            context.fillPath()
        }
        else
        {
            context.beginPath()
            context.move(to: CGPoint(
                x: rect.origin.x,
                y: rect.origin.y))
            context.addLine(to: CGPoint(
                x: rect.origin.x + rect.size.width,
                y: rect.origin.y))
            context.addLine(to: CGPoint(
                x: rect.origin.x + rect.size.width,
                y: rect.origin.y + rect.size.height - arrowSize.height))
            context.addLine(to: CGPoint(
                x: rect.origin.x + (rect.size.width + arrowSize.width) / 2.0,
                y: rect.origin.y + rect.size.height - arrowSize.height))
            //arrow vertex
            context.addLine(to: CGPoint(
                x: point.x,
                y: point.y))
            context.addLine(to: CGPoint(
                x: rect.origin.x + (rect.size.width - arrowSize.width) / 2.0,
                y: rect.origin.y + rect.size.height - arrowSize.height))
            context.addLine(to: CGPoint(
                x: rect.origin.x,
                y: rect.origin.y + rect.size.height - arrowSize.height))
            context.addLine(to: CGPoint(
                x: rect.origin.x,
                y: rect.origin.y))
            context.fillPath()
        }
        
        if offset.y > 0 {
            rect.origin.y += self.insets.top + arrowSize.height
        } else {
            rect.origin.y += self.insets.top
        }
        
        rect.size.height -= self.insets.top + self.insets.bottom
        
        UIGraphicsPushContext(context)
        
        label.draw(in: rect, withAttributes: _drawAttributes)
        
        UIGraphicsPopContext()
        
        context.restoreGState()
    }
    
    open override func refreshContent(entry: ChartDataEntry, highlight: Highlight)
    {
        setLabel(String(entry.y))
    }
    
    open func setLabel(_ newLabel: String)
    {
        label = newLabel
        
        _drawAttributes.removeAll()
        _drawAttributes[.font] = self.font
        _drawAttributes[.paragraphStyle] = _paragraphStyle
        _drawAttributes[.foregroundColor] = self.textColor
        
        _labelSize = label?.size(withAttributes: _drawAttributes) ?? CGSize.zero
        
        var size = CGSize()
        size.width = _labelSize.width + self.insets.left + self.insets.right
        size.height = _labelSize.height + self.insets.top + self.insets.bottom
        size.width = max(minimumSize.width, size.width)
        size.height = max(minimumSize.height, size.height)
        self.size = size
    }
}

// MARK: - Bulle d'info pour diagramme en X-Y

/// Bulle d'info pour diagramme en en X-Y
class XYMarkerViewSpecial: BalloonMarker {
    public var xAxisValueFormatter: IAxisValueFormatter
    fileprivate var yFormatter = NumberFormatter()
    
    public init(color               : UIColor,
                font                : UIFont,
                textColor           : UIColor,
                insets              : UIEdgeInsets,
                xAxisValueFormatter : IAxisValueFormatter) {
        self.xAxisValueFormatter = xAxisValueFormatter
        yFormatter.minimumFractionDigits = 1
        yFormatter.maximumFractionDigits = 1
        super.init(color: color, font: font, textColor: textColor, insets: insets)
    }
    
    public override func refreshContent(entry: ChartDataEntry, highlight: Highlight) {
        let string = "x: "
            + xAxisValueFormatter.stringForValue(entry.x, axis: XAxis())
            + ", y: "
            + yFormatter.string(from: NSNumber(floatLiteral: entry.y))!
        setLabel(string)
    }
}

/// Bulle d'info pour diagramme en en X-Y
class XYMarkerView: BalloonMarker {
    public var xAxisValueFormatter: IAxisValueFormatter
    public var yAxisValueFormatter: IAxisValueFormatter
    
    public init(color               : UIColor,
                font                : UIFont,
                textColor           : UIColor,
                insets              : UIEdgeInsets,
                xAxisValueFormatter : IAxisValueFormatter,
                yAxisValueFormatter : IAxisValueFormatter) {
        self.xAxisValueFormatter = xAxisValueFormatter
        self.yAxisValueFormatter = yAxisValueFormatter
        super.init(color: color, font: font, textColor: textColor, insets: insets)
    }
    
    public override func refreshContent(entry: ChartDataEntry, highlight: Highlight) {
        let string = "x: "
            + xAxisValueFormatter.stringForValue(entry.x, axis: XAxis())
            + ", y: "
            + yAxisValueFormatter.stringForValue(entry.y, axis: YAxis())
        setLabel(string)
    }
}

// MARK: - Bulle d'info pour diagramme en barre: Date + Valeur en Y

/// Bulle d'info: Date + Valeur en Y
class DateValueMarkerView: BalloonMarker {
    public var xAxisValueFormatter: IAxisValueFormatter
    public var yAxisValueFormatter: IAxisValueFormatter
    
    public init(color               : UIColor,
                font                : UIFont,
                textColor           : UIColor,
                insets              : UIEdgeInsets,
                xAxisValueFormatter : IAxisValueFormatter,
                yAxisValueFormatter : IAxisValueFormatter) {
        self.xAxisValueFormatter = xAxisValueFormatter
        self.yAxisValueFormatter = yAxisValueFormatter
        super.init(color: color, font: font, textColor: textColor, insets: insets)
    }
    
    public override func refreshContent(entry: ChartDataEntry, highlight: Highlight) {
        var string = ""
        
        if let e = entry as? BarChartDataEntry {
            guard let _ = e.yValues, highlight.stackIndex < e.yValues!.count else {
                setLabel("?")
                return
            }
            if highlight.stackIndex == -1 {
                string += xAxisValueFormatter.stringForValue(e.x, axis: XAxis())
            } else {
                string += xAxisValueFormatter.stringForValue(e.x, axis: XAxis())
                    + ", " + yAxisValueFormatter.stringForValue(e.yValues?[highlight.stackIndex] ?? 0, axis: YAxis())
                if let set = self.chartView?.data?.dataSets[highlight.dataSetIndex] as? BarChartDataSet {
                    string += ", \n" + set.stackLabels[highlight.stackIndex]
                }
            }
            //guard let s = self.chartView?.data?.dataSets[highlight.dataSetIndex].stackLabels[highlight.stackIndex] else { return }
        } else {
            string += xAxisValueFormatter.stringForValue(entry.x, axis: XAxis())
                + ", "//Charts.BarLineScatterCandleBubbleChartData    Charts.BarLineScatterCandleBubbleChartData
                + yAxisValueFormatter.stringForValue(entry.y, axis: YAxis())
        }
        setLabel(string)
    }
}

// MARK: - Bulle d'info pour diagramme en barre: Date + Valeur en Y

/// Bulle d'info pour une dépense
class ExpenseMarkerView: BalloonMarker {
    var xAxisValueFormatter: IAxisValueFormatter
    var yAxisValueFormatter: IAxisValueFormatter
    var amounts           = [Double]()
    var prop              = [Bool]()
    var firstYearDuration = [[Int]]()
    
    public init(color               : UIColor,
                font                : UIFont,
                textColor           : UIColor,
                insets              : UIEdgeInsets,
                xAxisValueFormatter : IAxisValueFormatter,
                yAxisValueFormatter : IAxisValueFormatter) {
        self.xAxisValueFormatter = xAxisValueFormatter
        self.yAxisValueFormatter = yAxisValueFormatter
        super.init(color: color, font: font, textColor: textColor, insets: insets)
    }
    
    public override func refreshContent(entry: ChartDataEntry, highlight: Highlight) {
        var string = ""
        
        if let e = entry as? BarChartDataEntry {
            guard let _ = e.yValues, highlight.stackIndex < e.yValues!.count else {
                setLabel("?")
                return
            }
            
            let value        = amounts[Int(e.x)]
            let proportional = prop[Int(e.x)]
            let firstYear    = firstYearDuration[Int(e.x)][0]
            let lastYear     = firstYear + firstYearDuration[Int(e.x)][1] - 1

            string += xAxisValueFormatter.stringForValue(e.x, axis: XAxis()) + "\n" +
                String(firstYear) + " à " + String(lastYear) + "\n" +
                value.euroString + (proportional ? " (X)" : "")
            //guard let s = self.chartView?.data?.dataSets[highlight.dataSetIndex].stackLabels[highlight.stackIndex] else { return }
        } else {
            string += xAxisValueFormatter.stringForValue(entry.x, axis: XAxis())
        }
        setLabel(string)
    }
}

