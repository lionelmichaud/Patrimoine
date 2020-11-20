//
//  Graphs.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 10/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import Charts // https://github.com/danielgindi/Charts.git

// MARK: - Themes graphiques

struct ChartThemes {
    struct BallonColors { // UIColor
        static let color     = #colorLiteral(red: 0.5704585314, green: 0.5704723597, blue: 0.5704649091, alpha: 1)
        static let textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    }
    
    struct DarkChartColors { // UIColor
        static let labelTextColor  = #colorLiteral(red                        : 1, green                        : 1, blue                        : 1, alpha                        : 1)
        static let backgroundColor = #colorLiteral(red : 0, green : 0, blue : 0, alpha : 1)
        static let borderColor     = #colorLiteral(red : 0, green : 0, blue : 0, alpha : 1)
        static let legendColor     = #colorLiteral(red : 1, green : 1, blue : 1, alpha : 1)
        static let valueColor      = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    }
    
    struct LightChartColors { // UIColor
        static let gridColor           = #colorLiteral(red          : 0.6000000238, green          : 0.6000000238, blue          : 0.6000000238, alpha          : 1)
        static let gridBackgroundColor = #colorLiteral(red: 0.9171036869, green: 0.9171036869, blue: 0.9171036869, alpha: 1)
        static let backgroundColor     = #colorLiteral(red     : 1, green     : 1, blue     : 1, alpha     : 1)
        static let borderColor         = #colorLiteral(red         : 1, green         : 1, blue         : 1, alpha         : 1)
        static let valueColor          = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    }
    
    struct ChartDefaults {
        static let labelFont       : UIFont = .systemFont(ofSize: 12)
        static let smallLegendFont : UIFont = .systemFont(ofSize: 11)
        static let largeLegendFont : UIFont = .systemFont(ofSize: 13)
        static let baloonfont      : UIFont = .systemFont(ofSize: 13)
        static let valueFont       : UIFont = .systemFont(ofSize: 14)
    }
    
    static let positiveColorsTable: [NSUIColor] = [#colorLiteral(red: 0.1294117719, green: 0.2156862766, blue: 0.06666667014, alpha: 1),#colorLiteral(red: 0.1960784346, green: 0.3411764801, blue: 0.1019607857, alpha: 1),#colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1),#colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1),#colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1),#colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1),#colorLiteral(red: 0.721568644, green: 0.8862745166, blue: 0.5921568871, alpha: 1),#colorLiteral(red: 0.05882352963, green: 0.180392161, blue: 0.2470588237, alpha: 1),#colorLiteral(red: 0.1019607857, green: 0.2784313858, blue: 0.400000006, alpha: 1),#colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1),#colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1),#colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1),#colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1),#colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1),#colorLiteral(red: 0.06274510175, green: 0, blue: 0.1921568662, alpha: 1),#colorLiteral(red: 0.1215686277, green: 0.01176470611, blue: 0.4235294163, alpha: 1),#colorLiteral(red: 0.1215686277, green: 0.01176470611, blue: 0.4235294163, alpha: 1),#colorLiteral(red: 0.1764705926, green: 0.01176470611, blue: 0.5607843399, alpha: 1),#colorLiteral(red: 0.2196078449, green: 0.007843137719, blue: 0.8549019694, alpha: 1),#colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1),#colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1),#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1),#colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1),#colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1),#colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1),#colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1),#colorLiteral(red: 0.1686089337, green: 0.1686392725, blue: 0.1686022878, alpha: 1),#colorLiteral(red: 0.7254902124, green: 0.4784313738, blue: 0.09803921729, alpha: 1),#colorLiteral(red: 0.5058823824, green: 0.3372549117, blue: 0.06666667014, alpha: 1),#colorLiteral(red: 0.3098039329, green: 0.2039215714, blue: 0.03921568766, alpha: 1),#colorLiteral(red: 0.2554336918, green: 0.1694213438, blue: 0.0335564099, alpha: 1),#colorLiteral(red: 0.1294117719, green: 0.2156862766, blue: 0.06666667014, alpha: 1),#colorLiteral(red: 0.1960784346, green: 0.3411764801, blue: 0.1019607857, alpha: 1),#colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1),#colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1),#colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1),#colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1),#colorLiteral(red: 0.721568644, green: 0.8862745166, blue: 0.5921568871, alpha: 1)]
    
    static let negativeColorsTable: [NSUIColor] = [#colorLiteral(red: 0.3176470697, green: 0.07450980693, blue: 0.02745098062, alpha: 1),#colorLiteral(red: 0.521568656, green: 0.1098039225, blue: 0.05098039284, alpha: 1),#colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1),#colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1),#colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1),#colorLiteral(red: 0.5058823824, green: 0.3372549117, blue: 0.06666667014, alpha: 1),#colorLiteral(red: 0.7254902124, green: 0.4784313738, blue: 0.09803921729, alpha: 1),#colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1),#colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1),#colorLiteral(red: 0.2196078449, green: 0.007843137719, blue: 0.8549019694, alpha: 1),#colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1),#colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1)]
    
    static func positiveColors (number: Int) -> [NSUIColor] {
        var colorTable = [NSUIColor]()
        if number == 0 {
            return [positiveColorsTable[0]]
        } else {
            for i in 0...number-1 {
                colorTable.append(positiveColorsTable[i % positiveColorsTable.count])
            }
        }
        return colorTable
    }
    
    static func negativeColors (number: Int) -> [NSUIColor] {
        var colorTable = [NSUIColor]()
        if number == 0 {
            return [negativeColorsTable[0]]
        } else {
            for i in 0...number-1 {
                colorTable.append(negativeColorsTable[i % negativeColorsTable.count])
            }
        }
        return colorTable
    }
    
    static func positiveNegativeColors (numberPositive: Int, numberNegative: Int) -> [NSUIColor] {
        var colorTable = [NSUIColor]()
        if numberPositive == 0 && numberNegative == 0 {
            return [positiveColorsTable[0]]
        } else {
            if numberPositive != 0 {
                for i in 0...numberPositive-1 {
                    colorTable.append(positiveColorsTable[i % positiveColorsTable.count])
                }
            }
            if numberNegative != 0 {
                for i in 0...numberNegative-1 {
                    colorTable.append(negativeColorsTable[i % negativeColorsTable.count])
                }
            }
        }
        return colorTable
    }
}

struct ListTheme {
    struct ListRowTheme {
        let indent          : CGFloat
        let labelFontSize   : CGFloat
        let valueFontSize   : CGFloat
        let opacity         : Double
    }
    
    static let rowsBaseColor = Color("listRowBaseColor")
    static var listTheme: [ListRowTheme] = [
        // 0
        ListRowTheme(indent          : 0,
                     labelFontSize   : 17,
                     valueFontSize   : 17,
                     opacity         : 1.0),
        // 1
        ListRowTheme(indent          : 0,
                     labelFontSize   : 16,
                     valueFontSize   : 16,
                     opacity         : 0.5),
        // 2
        ListRowTheme(indent          : 0,
                     labelFontSize   : 15,
                     valueFontSize   : 15,
                     opacity         : 0.25),
        // 3
        ListRowTheme(indent          : 0,
                     labelFontSize   : 14,
                     valueFontSize   : 14,
                     opacity         : 0.0)
    ]
    static subscript(idx: Int) -> ListRowTheme {
            ListTheme.listTheme[idx]
    }
}
