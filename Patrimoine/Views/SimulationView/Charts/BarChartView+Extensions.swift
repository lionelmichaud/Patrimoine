//
//  BarChartView+Extensions.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif
import Charts // https://github.com/danielgindi/Charts.git

// MARK: - Extension de BarChartView pour customizer la configuration des Graph de l'appli
extension BarChartView {
    
    /// Création d'un BarChartView avec une présentation customisée
    /// - Parameter title: Titre du graphique
    convenience init (title: String) {
        self.init()
        
        //: ### General
        self.pinchZoomEnabled          = true
        self.doubleTapToZoomEnabled    = true
        self.dragEnabled               = true
        self.drawGridBackgroundEnabled = true
        self.backgroundColor           = ChartThemes.DarkChartColors.backgroundColor
        self.borderColor               = ChartThemes.DarkChartColors.borderColor
        self.borderLineWidth           = 1.0
        self.drawBordersEnabled        = true
        self.drawValueAboveBarEnabled  = false
        self.drawBarShadowEnabled      = false
        self.fitBars                   = true
        self.highlightFullBarEnabled   = false
        self.gridBackgroundColor       = NSUIColor.black
        
        //: ### xAxis
        let xAxis = self.xAxis
        xAxis.enabled                   = true
        xAxis.drawLabelsEnabled         = true
        xAxis.labelFont                 = ChartThemes.ChartDefaults.labelFont
        xAxis.labelTextColor            = ChartThemes.DarkChartColors.labelTextColor
        xAxis.labelPosition             = .bottom // .insideChart
        xAxis.labelRotationAngle        = -90
        xAxis.granularityEnabled        = true
        xAxis.granularity               = 1
        xAxis.labelCount                = 200
        xAxis.drawGridLinesEnabled      = true
        xAxis.drawAxisLineEnabled       = true
        
        //: ### RightAxis
        let rightAxis = self.rightAxis
        rightAxis.enabled = false
        
        //: ### LeftAxis
        let leftAxis = self.leftAxis
        leftAxis.enabled              = true
        leftAxis.labelFont            = ChartThemes.ChartDefaults.labelFont
        leftAxis.labelTextColor       = ChartThemes.DarkChartColors.labelTextColor
        leftAxis.valueFormatter       = KiloEuroFormatter()
        leftAxis.drawGridLinesEnabled = true
        leftAxis.drawZeroLineEnabled  = false
        
        //: ### Legend
        let legend = self.legend
        legend.enabled             = true
        legend.font                = ChartThemes.ChartDefaults.legendFont
        legend.textColor           = ChartThemes.DarkChartColors.legendColor
        legend.form                = .square
        legend.drawInside          = false
        legend.orientation         = .horizontal
        legend.verticalAlignment   = .bottom
        legend.horizontalAlignment = .left
        
        //: ### Description
        self.chartDescription?.text = title
        self.chartDescription?.enabled = true
        
        // bulle d'info
        let marker = DateValueMarkerView(color               : ChartThemes.BallonColors.color,
                                         font                : ChartThemes.ChartDefaults.baloonfont,
                                         textColor           : ChartThemes.BallonColors.textColor,
                                         insets              : UIEdgeInsets(top: 8, left: 8, bottom: 20, right: 8),
                                         xAxisValueFormatter : self.xAxis.valueFormatter!,
                                         yAxisValueFormatter : self.leftAxis.valueFormatter!)
        marker.chartView   = self
        marker.minimumSize = CGSize(width : 80, height : 40)
        self.marker   = marker
    }
}
