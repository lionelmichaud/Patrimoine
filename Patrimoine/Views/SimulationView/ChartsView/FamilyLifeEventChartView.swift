//
//  FamilyLifeEventChartView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 14/04/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import Charts // https://github.com/danielgindi/Charts.git

// MARK: - Wrappers de UIView

/// Wrapper de HorizontalBarChartView
struct FamilyLifeEventChartView: UIViewRepresentable {
    @EnvironmentObject var family : Family
    let endDate: Double

    static let ColorsTable: [NSUIColor] = [UIColor(white: 1, alpha: 0), #colorLiteral(red: 0.9686274529, green: 0.78039217, blue: 0.3450980484, alpha: 1)]
    
    /// Créer le dataset du graphique
    /// - Returns: dataset
    func getFamilyLifeEventDataSet(formatter    : NamedValueFormatter,
                                   baloonMarker : ExpenseMarkerView) -> [BarChartDataSet] {
        var dataSets = [BarChartDataSet]()
        
        let familyDatedLifeEvents = family.familyDatedLifeEvents
        
        // mettre à jour les noms des membres de la famille dans le formatteur de l'axe X (vertical ici)
        formatter.names = family.membersName

        // mettre à jour les valeurs des dépenses dans le formatteur de bulle d'info
//        baloonMarker.amounts = namedValuedTimeFrameTable.map { (_, value, _, _, _) in
//            value
//        }
//        baloonMarker.prop = namedValuedTimeFrameTable.map { (_, _, prop, _, _) in
//            prop
//        }
        //        baloonMarker.firstYearDuration = namedValuedTimeFrameTable.map { (_, _, _, _, firstYearDuration) in
        //            firstYearDuration
        //        }
        
        // générer une série pour chaque événement de vie
        LifeEvent.allCases.forEach { event in // pour chaque type d'événement
            // construire la série de points: date = f(nom)
            var dataEntries = [BarChartDataEntry]()
            for idx in formatter.names.startIndex..<formatter.names.endIndex { // pour chaque personne
                let name = formatter.names[idx]
                let date = familyDatedLifeEvents[name]?[event] ?? 0
                dataEntries.append(BarChartDataEntry(x: idx.double(), y: date.double()))
            }
            // créer le DataSet
            let dataSet = BarChartDataSet(entries: dataEntries, label: event.displayString)
            dataSet.colors = [#colorLiteral(red        : 0.4666666687, green        : 0.7647058964, blue        : 0.2666666806, alpha        : 1)]
            dataSet.drawIconsEnabled = false
            // ajouter les dataSet au dataSets
            dataSets.append(dataSet)
        }
        
        //dataSet.colors           = ExpenseSummaryChartView.ColorsTable

        return dataSets
    }
    
    func drawExpenseDataChart() -> HorizontalBarChartView {
        let chartView = HorizontalBarChartView()
        
        //: ### General
        chartView.pinchZoomEnabled          = true
        chartView.doubleTapToZoomEnabled    = true
        chartView.dragEnabled               = true
        chartView.drawGridBackgroundEnabled = true
        chartView.gridBackgroundColor       = ChartThemes.LightChartColors.gridBackgroundColor
        chartView.backgroundColor           = ChartThemes.DarkChartColors.backgroundColor
        chartView.borderColor               = ChartThemes.DarkChartColors.borderColor
        chartView.borderLineWidth           = 1.0
        chartView.drawBordersEnabled        = false
        chartView.drawValueAboveBarEnabled  = false
        chartView.drawBarShadowEnabled      = false
        chartView.fitBars                   = true
        chartView.highlightFullBarEnabled   = false
        //chartView.maxVisibleCount = 60
        
        //: ### xAxis value formatter
        let xAxisValueFormatter = NamedValueFormatter()
        
        //: ### xAxis
        let xAxis = chartView.xAxis
        xAxis.drawAxisLineEnabled  = true
        xAxis.labelPosition        = .bottom
        xAxis.labelFont            = ChartThemes.ChartDefaults.smallLabelFont
        xAxis.labelTextColor       = ChartThemes.DarkChartColors.labelTextColor
        xAxis.granularityEnabled   = false
        xAxis.granularity          = 1
        xAxis.labelCount           = 200
        xAxis.drawGridLinesEnabled = false
        xAxis.drawAxisLineEnabled  = true
        xAxis.valueFormatter       = xAxisValueFormatter
        //xAxis.wordWrapEnabled      = true
        //xAxis.wordWrapWidthPercent = 0.5
        //xAxis.axisMinimum         = 0
        
        //: ### LeftAxis
        let leftAxis = chartView.leftAxis
        leftAxis.enabled              = true
        leftAxis.drawAxisLineEnabled  = true
        leftAxis.drawGridLinesEnabled = true
        leftAxis.labelFont            = ChartThemes.ChartDefaults.smallLabelFont
        leftAxis.labelTextColor       = ChartThemes.DarkChartColors.labelTextColor
        leftAxis.granularityEnabled   = true // autoriser la réducion du nombre de label
        leftAxis.granularity          = 1    // à utiliser sans dépasser .labelCount
        leftAxis.labelCount           = 15   // nombre maxi
        leftAxis.axisMinimum          = Date.now.year.double()
        leftAxis.axisMaximum          = endDate
        
        //: ### RightAxis
        let rightAxis = chartView.rightAxis
        rightAxis.enabled              = false
        rightAxis.drawAxisLineEnabled  = true
        rightAxis.drawGridLinesEnabled = false
        leftAxis.labelFont             = ChartThemes.ChartDefaults.smallLabelFont
        leftAxis.labelTextColor        = ChartThemes.DarkChartColors.labelTextColor
        rightAxis.granularityEnabled   = true // autoriser la réducion du nombre de label
        rightAxis.granularity          = 1    // à utiliser sans dépasser .labelCount
        rightAxis.labelCount           = 15   // nombre maxi
        rightAxis.axisMinimum          = Date.now.year.double()
        rightAxis.axisMaximum          = endDate
        
        //: ### Legend
        let legend = chartView.legend
        legend.enabled             = true
        legend.font                = ChartThemes.ChartDefaults.smallLegendFont
        legend.textColor           = ChartThemes.DarkChartColors.legendColor
        legend.form                = .square
        legend.formSize            = 8
        legend.drawInside          = false
        legend.horizontalAlignment = .left
        legend.verticalAlignment   = .bottom
        legend.orientation         = .horizontal
        legend.xEntrySpace         = 4
        
        //: ## bulle d'info
        let marker = ExpenseMarkerView(color              : ChartThemes.BallonColors.color,
                                       font               : ChartThemes.ChartDefaults.baloonfont,
                                       textColor          : ChartThemes.BallonColors.textColor,
                                       insets             : UIEdgeInsets(top: 8, left: 8, bottom: 20, right: 8),
                                       xAxisValueFormatter: chartView.xAxis.valueFormatter!,
                                       yAxisValueFormatter: chartView.leftAxis.valueFormatter!)
        marker.chartView = chartView
        marker.minimumSize = CGSize(width: 80, height: 40)
        chartView.marker = marker
        
        chartView.fitBars = true
        
        //: ### BarChartData
        let dataSets = getFamilyLifeEventDataSet(formatter    : xAxisValueFormatter,
                                                 baloonMarker : marker)
        
        // ajouter le dataset au graphique
        let data = BarChartData(dataSets: dataSets)
        data.setValueTextColor(ChartThemes.LightChartColors.valueColor)
        data.setValueFont(ChartThemes.ChartDefaults.valueFont)
        let groupSpace = 0.2
        let barSpace = 0.1
        let barWidth = 0.1
        // (0.2 + 0.03) * 4 + 0.08 = 1.00 -> interval per "group"

        data.barWidth = barWidth
        data.groupBars(fromX: 0, groupSpace: groupSpace, barSpace: barSpace)
        
        // ajouter le dataset au graphique
        chartView.data = data
        
        return chartView
    }
    
    func makeUIView(context: Context) -> HorizontalBarChartView {
        drawExpenseDataChart()
    }
    
    func updateUIView(_ uiView: HorizontalBarChartView, context: Context) {
        uiView.clear()
        //: ### BarChartData
        let dataSets = getFamilyLifeEventDataSet(formatter    : uiView.xAxis.valueFormatter as! NamedValueFormatter,
                                                 baloonMarker : uiView.marker as! ExpenseMarkerView)
        
        // ajouter le dataset au graphique
        let data = BarChartData(dataSets: dataSets)
        data.setValueTextColor(ChartThemes.LightChartColors.valueColor)
        data.setValueFont(ChartThemes.ChartDefaults.valueFont)
        let groupSpace = 0.2
        let barSpace = 0.1
        let barWidth = 0.1
        // (0.2 + 0.03) * 4 + 0.08 = 1.00 -> interval per "group"
        
        data.barWidth = barWidth
        data.groupBars(fromX: -1, groupSpace: groupSpace, barSpace: barSpace)

        // mettre à joure en fonction de la position du slider de plage de temps à afficher
        uiView.leftAxis.axisMaximum  = endDate
        uiView.rightAxis.axisMaximum = endDate
        
        // ajouter le dataset au graphique
        uiView.data = data
        
        uiView.data?.notifyDataChanged()
        uiView.notifyDataSetChanged()
    }
}

//struct FamilyLifeEventChartView_Previews: PreviewProvider {
//    static var family     = Family()
//    static var uiState    = UIState()
//
//    static var previews: some View {
//        FamilyLifeEventChartView()
//            .environmentObject(family)
//            .environmentObject(uiState)
//    }
//}
