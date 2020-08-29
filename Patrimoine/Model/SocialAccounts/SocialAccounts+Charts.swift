//
//  SocialAccounts+Charts.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 11/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import CoreGraphics
#if canImport(UIKit)
import UIKit
#endif
import Charts // https://github.com/danielgindi/Charts.git

extension SocialAccounts {
    
    // nested types
    
    // MARK: -
    
    /// Combinaisons possibles de séries sur le graphique de Bilan
    enum AssetLiabilitiesCombination: Int, PickableEnum {
        case assets
        case liabilities
        case both
        var pickerString: String {
            switch self {
                case .assets:
                    return "Actif"
                case .liabilities:
                    return "Passif"
                case .both:
                    return "Tout"
            }
        }
    }
    
    // MARK: -
    
    /// Combinaisons possibles de séries sur le graphique de CashFlow
    enum CashCombination: Int, PickableEnum {
        case revenues
        case expenses
        case both
        var pickerString: String {
            switch self {
                case .revenues:
                    return "Revenu"
                case .expenses:
                    return "Dépense"
                case .both:
                    return "Tout"
            }
        }
    }
    
    
    // MARK: - Génération de graphiques BILAN
    
    /// Dessiner un graphe à lignes : passif + actif + net
    /// - Returns: UIView
    func drawBalanceSheetLineChart() -> LineChartView {
        let chartView = LineChartView()
        
        // si la table est vide alors quitter
        guard !balanceArray.isEmpty else {
            return chartView
        }
        
        //: ### General
        chartView.pinchZoomEnabled          = true
        chartView.doubleTapToZoomEnabled    = true
        chartView.dragEnabled               = true
        chartView.setScaleEnabled (true)
        chartView.drawGridBackgroundEnabled = false
        chartView.backgroundColor           = ChartThemes.DarkChartColors.backgroundColor
        chartView.borderColor               = ChartThemes.DarkChartColors.borderColor
        chartView.borderLineWidth           = 1.0
        chartView.drawBordersEnabled        = true
        
        //: ### xAxis
        let xAxis = chartView.xAxis
        xAxis.enabled                  = true
        xAxis.drawLabelsEnabled        = true
        xAxis.labelFont                = ChartThemes.ChartDefaults.labelFont
        xAxis.labelTextColor           = ChartThemes.DarkChartColors.labelTextColor
        xAxis.labelPosition            = .bottom // .insideChart
        xAxis.labelRotationAngle       = -90
        xAxis.granularityEnabled       = true
        xAxis.granularity              = 1
        xAxis.labelCount               = 200
        //        xAxis.valueFormatter = IndexAxisValueFormatter(values : months)
        //        xAxis.setLabelCount(months.count, force               : false)
        xAxis.drawGridLinesEnabled     = true
        xAxis.drawAxisLineEnabled      = true
        //        xAxis.axisMinimum    = 0
        
        //: ### LeftAxis
        let leftAxis = chartView.leftAxis
        leftAxis.enabled               = true
        leftAxis.labelFont             = ChartThemes.ChartDefaults.labelFont
        leftAxis.labelTextColor        = ChartThemes.DarkChartColors.labelTextColor
        leftAxis.valueFormatter        = KiloEuroFormatter()
        //        leftAxis.axisMaximum = 200.0
        //        leftAxis.axisMinimum = 0.0
        leftAxis.drawGridLinesEnabled  = true
        leftAxis.drawZeroLineEnabled   = false
        
        //: ### RightAxis
        let rightAxis = chartView.rightAxis
        rightAxis.enabled              = false
        rightAxis.labelFont            = ChartThemes.ChartDefaults.labelFont
        rightAxis.labelTextColor       = #colorLiteral(red     : 1, green     : 0.1474981606, blue     : 0, alpha     : 1)
        rightAxis.axisMaximum          = 900.0
        rightAxis.axisMinimum          = -200.0
        rightAxis.drawGridLinesEnabled = false
        rightAxis.granularityEnabled   = false
        
        //: ### Legend
        let legend = chartView.legend
        legend.font                = ChartThemes.ChartDefaults.legendFont
        legend.textColor           = ChartThemes.DarkChartColors.legendColor
        legend.form                = .square
        legend.drawInside          = false
        legend.orientation         = .horizontal
        legend.verticalAlignment   = .bottom
        legend.horizontalAlignment = .left
        
        //: ### Description
        chartView.chartDescription?.text = "Actif / Passif"
        chartView.chartDescription?.enabled = true
        
        //: ### ChartDataEntry
        var yVals1 = [ChartDataEntry]()
        var yVals2 = [ChartDataEntry]()
        var yVals3 = [ChartDataEntry]()
        
        yVals1 = balanceArray.map {
            ChartDataEntry(x: $0.year.double(), y: $0.assets.total)
        }
        yVals2 = balanceArray.map {
            ChartDataEntry(x: $0.year.double(), y: $0.liabilities.total)
        }
        yVals3 = balanceArray.map {
            ChartDataEntry(x: $0.year.double(), y: $0.net)
        }
        
        var set1 = LineChartDataSet()
        var set2 = LineChartDataSet()
        var set3 = LineChartDataSet()
        
        set1 = LineChartDataSet(entries: yVals1, label: "Actif")
        set1.axisDependency        = .left
        set1.colors                = [#colorLiteral(red        : 0.4666666687, green        : 0.7647058964, blue        : 0.2666666806, alpha        : 1)]
        set1.circleColors          = [#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)]
        set1.lineWidth             = 2.0
        set1.circleRadius          = 3.0
        set1.fillAlpha             = 65 / 255.0
        set1.fillColor             = #colorLiteral(red      : 0.4666666687, green      : 0.7647058964, blue      : 0.2666666806, alpha      : 1)
        set1.highlightColor        = #colorLiteral(red : 0.4666666687, green : 0.7647058964, blue : 0.2666666806, alpha : 1)
        set1.highlightEnabled      = true
        set1.drawCircleHoleEnabled = false
        
        set2 = LineChartDataSet(entries: yVals2, label: "Passif")
        set2.axisDependency        = .left
        set2.colors                = [#colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1)]
        set2.circleColors          = [#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)]
        set2.lineWidth             = 2.0
        set2.circleRadius          = 3.0
        set2.fillAlpha             = 65 / 255.0
        set2.fillColor             = #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1)
        set2.highlightColor        = #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1)
        set2.highlightEnabled      = true
        set2.drawCircleHoleEnabled = false
        
        set3 = LineChartDataSet(entries: yVals3, label: "Net")
        set3.axisDependency        = .left
        set3.colors                = [#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)]
        set3.circleColors          = [#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)]
        set3.lineWidth             = 2.0
        set3.circleRadius          = 3.0
        set3.fillAlpha             = 65 / 255.0
        set3.fillColor             = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        set3.highlightColor        = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        set3.highlightEnabled      = true
        set3.drawCircleHoleEnabled = false
        
        // ajouter les dataSet au dataSets
        var dataSets = [LineChartDataSet]()
        dataSets.append(set1)
        dataSets.append(set2)
        dataSets.append(set3)
        
        //: ### LineChartData
        let data = LineChartData(dataSets: dataSets)
        data.setValueTextColor(ChartThemes.DarkChartColors.valueColor)
        data.setValueFont(NSUIFont(name: "HelveticaNeue-Light", size: CGFloat(12.0))!)
        data.setValueFormatter(DefaultValueFormatter(formatter: valueKiloFormatter))
        
        // ajouter les data au graphique
        chartView.data = data
        //chartView.data?.notifyDataChanged()
        //chartView.notifyDataSetChanged()
        chartView.animate(yAxisDuration: 0.5, easingOption: .linear)
        
        return chartView
    }
    
    func drawBalanceSheetAssetsGroupedBarChart() -> BarChartView {
        let chartView = BarChartView()
        
        // si la table est vide alors quitter
        guard !balanceArray.isEmpty else {
            return chartView
        }
        
        //: ### General
        chartView.pinchZoomEnabled          = false
        chartView.drawBarShadowEnabled      = false
        chartView.doubleTapToZoomEnabled    = false
        chartView.drawGridBackgroundEnabled = true
        chartView.fitBars                   = true
        chartView.backgroundColor           = ChartThemes.DarkChartColors.backgroundColor
        chartView.borderColor               = ChartThemes.DarkChartColors.borderColor
        chartView.borderLineWidth           = 1.0
        chartView.drawBordersEnabled        = true
        
        //: ### xAxis
        let xAxis = chartView.xAxis
        xAxis.enabled                 = true
        xAxis.drawLabelsEnabled       = true
        xAxis.labelFont               = ChartThemes.ChartDefaults.labelFont
        xAxis.labelTextColor          = ChartThemes.DarkChartColors.labelTextColor
        xAxis.labelPosition           = .bottom // .insideChart
        xAxis.centerAxisLabelsEnabled = true
        //xAxis.labelRotationAngle    = -90
        xAxis.granularityEnabled      = true
        xAxis.granularity             = 1
        xAxis.labelCount              = 200
        xAxis.drawGridLinesEnabled    = true
        xAxis.drawAxisLineEnabled     = true
        
        //: ### LeftAxis
        let leftAxis = chartView.leftAxis
        leftAxis.enabled              = true
        leftAxis.labelFont            = ChartThemes.ChartDefaults.labelFont
        leftAxis.labelTextColor       = #colorLiteral(red     : 0.215686274509804, green     : 0.709803921568627, blue     : 0.898039215686275, alpha     : 1.0)
        leftAxis.valueFormatter       = KiloEuroFormatter()
        leftAxis.drawGridLinesEnabled = true
        leftAxis.drawZeroLineEnabled  = false
        
        //: ### Legend
        let legend = chartView.legend
        legend.font                = ChartThemes.ChartDefaults.legendFont
        legend.textColor           = ChartThemes.DarkChartColors.legendColor
        legend.form                = .square
        legend.drawInside          = false
        legend.orientation         = .horizontal
        legend.verticalAlignment   = .bottom
        legend.horizontalAlignment = .left
        
        //: ### Description
        chartView.chartDescription?.text    = "Actifs"
        chartView.chartDescription?.enabled = true
        
        
        //: ### ChartDataEntry
        //        var yVals1 = [ChartDataEntry]()
        //        var yVals2 = [ChartDataEntry]()
        //        var yVals3 = [ChartDataEntry]()
        //
        //        yVals1 = balanceArray.map { ChartDataEntry(x: $0.year.double(), y: $0.assets.total) }
        //        yVals2 = balanceArray.map { ChartDataEntry(x: $0.year.double(), y: $0.liabilities.total) }
        //        yVals3 = balanceArray.map { ChartDataEntry(x: $0.year.double(), y: $0.net) }
        
        
        let xArray = Array(1..<10)
        let ys1 = xArray.map { x in return sin(Double(x) / 2.0 / 3.141 * 1.5) }
        let ys2 = xArray.map { x in return cos(Double(x) / 2.0 / 3.141) }
        
        let yse1 = ys1.enumerated().map { x, y in return BarChartDataEntry(x: Double(x), y: y) }
        let yse2 = ys2.enumerated().map { x, y in return BarChartDataEntry(x: Double(x), y: y) }
        
        let data = BarChartData()
        let ds1 = BarChartDataSet(entries: yse1, label: "Hello")
        ds1.colors = [NSUIColor.red]
        data.addDataSet(ds1)
        
        let ds2 = BarChartDataSet(entries: yse2, label: "World")
        ds2.colors = [NSUIColor.blue]
        data.addDataSet(ds2)
        
        let barWidth = 0.4
        let barSpace = 0.05
        let groupSpace = 0.1
        
        data.barWidth = barWidth
        chartView.xAxis.axisMinimum = Double(xArray[0])
        chartView.xAxis.axisMaximum = Double(xArray[0]) + data.groupWidth(groupSpace: groupSpace, barSpace: barSpace) * Double(xArray.count)
        // (0.4 + 0.05) * 2 (data set count) + 0.1 = 1
        data.groupBars(fromX: Double(xArray[0]), groupSpace: groupSpace, barSpace: barSpace)
        
        chartView.data = data
        
        chartView.gridBackgroundColor = NSUIColor.black // NSUIColor(red: 240/255.0, green: 240/255.0, blue: 240/255.0, alpha: 1.0) UIColor(red: 230/255, green: 126/255, blue: 34/255, alpha: 1)
        
        chartView.animate(xAxisDuration: 2.0, yAxisDuration: 2.0, easingOption: .easeInBounce)
        
        return chartView
    }
    
    /// Construction de la légende du graphique
    /// - Parameter combination: sélection de la catégories de séries à afficher
    /// - Returns: tableau des libéllés des sries des catégories sélectionnées
    func getBalanceSheetLegend(_ combination: AssetLiabilitiesCombination = .both) -> [(label: String, selected: Bool)] {
        let firstLine   = balanceArray.first!
        switch combination {
            case .assets:
                return firstLine.assets.values.map({($0.name, true)})
            case .liabilities:
                return firstLine.liabilities.values.map({($0.name, true)})
            case .both:
                return firstLine.assets.values.map({($0.name, true)}) + firstLine.liabilities.values.map({($0.name, true)})
        }
    }
    
    /// Créer le DataSet pour former un un graphe barre empilées : passif / actif / net
    /// - Parameters:
    ///   - combination: passif / actif / tout
    ///   - itemSelection: séries sélectionnées pour être affichées
    /// - Returns: DataSet
    func getBalanceSheetStackedBarChartDataSet(
        combination  : AssetLiabilitiesCombination = .both,
        itemSelection: [(label: String, selected: Bool)]) -> BarChartDataSet {
        
        let firstLine   = balanceArray.first!
        var dataEntries = [ChartDataEntry]()
        let dataSet : BarChartDataSet
        
        switch combination {
            case .assets:
                dataEntries += balanceArray.map { // pour chaque année
                    BarChartDataEntry(x       : $0.year.double(),
                                      yValues : $0.assets.filtredValues(itemSelection: itemSelection))
                }
                let labels = firstLine.assets.filtredHeaders(itemSelection : itemSelection)
                dataSet = BarChartDataSet(entries: dataEntries,
                                          label: (labels.count == 1 ? labels.first : nil))
                dataSet.stackLabels = labels
                dataSet.colors      = ChartThemes.positiveColors(number: dataSet.stackLabels.count)
                
            case .liabilities:
                dataEntries += balanceArray.map { // pour chaque année
                    BarChartDataEntry(x       : $0.year.double(),
                                      yValues : $0.liabilities.filtredValues(itemSelection: itemSelection))
                }
                let labels = firstLine.liabilities.filtredHeaders(itemSelection : itemSelection)
                dataSet = BarChartDataSet(entries: dataEntries,
                                          label: (labels.count == 1 ? labels.first : nil))
                dataSet.stackLabels = labels
                dataSet.colors      = ChartThemes.negativeColors(number: dataSet.stackLabels.count)
                
            case .both:
                dataEntries += balanceArray.map {
                    BarChartDataEntry(x       : $0.year.double(),
                                      yValues : $0.assets.filtredValues(itemSelection: itemSelection) +
                                        $0.liabilities.filtredValues(itemSelection: itemSelection))
                }
                let labels = firstLine.assets.filtredHeaders(itemSelection : itemSelection) +
                    firstLine.liabilities.filtredHeaders(itemSelection : itemSelection)
                dataSet = BarChartDataSet(entries: dataEntries,
                                          label: (labels.count == 1 ? labels.first : nil))
                dataSet.stackLabels = firstLine.assets.filtredHeaders(itemSelection : itemSelection)
                let numberPositive = dataSet.stackLabels.count
                dataSet.stackLabels += firstLine.liabilities.filtredHeaders(itemSelection : itemSelection)
                dataSet.colors = ChartThemes.positiveNegativeColors(numberPositive: numberPositive,
                                                                    numberNegative: dataSet.stackLabels.count - numberPositive)
        }
        
        return dataSet
    }
    
    /// Dessiner un graphe barre empilées : passif / actif / tout
    /// - Parameters:
    ///   - combination: passif / actif / tout
    ///   - itemSelection: séries sélectionnées pour être affichées
    /// - Returns: UIView
    func drawBalanceSheetStackedBarChart(
        combination  : AssetLiabilitiesCombination = .both,
        itemSelection: [(label: String, selected: Bool)]) -> BarChartView {
        
        let chartView = BarChartView()
        
        // si la table est vide alors quitter
        guard !balanceArray.isEmpty else {
            return chartView
        }
        
        //: ### General
        chartView.pinchZoomEnabled          = true
        chartView.doubleTapToZoomEnabled    = true
        chartView.dragEnabled               = true
        chartView.drawGridBackgroundEnabled = true
        chartView.backgroundColor           = ChartThemes.DarkChartColors.backgroundColor
        chartView.borderColor               = ChartThemes.DarkChartColors.borderColor
        chartView.borderLineWidth           = 1.0
        chartView.drawBordersEnabled        = false
        chartView.drawValueAboveBarEnabled  = false
        chartView.drawBarShadowEnabled      = false
        chartView.fitBars                   = true
        chartView.highlightFullBarEnabled   = false
        
        //: ### xAxis
        let xAxis = chartView.xAxis
        xAxis.enabled                   = true
        xAxis.drawLabelsEnabled         = true
        xAxis.labelFont                 = ChartThemes.ChartDefaults.labelFont
        xAxis.labelTextColor            = ChartThemes.DarkChartColors.labelTextColor
        xAxis.labelPosition             = .bottom // .insideChart
        //xAxis.centerAxisLabelsEnabled = true
        xAxis.labelRotationAngle        = -90
        xAxis.granularityEnabled        = true // autoriser la réducion du nombre de label
        xAxis.granularity               = 1    // à utiliser sans dépasser .labelCount
        xAxis.labelCount                = 200  // nombre maxi
        xAxis.drawGridLinesEnabled      = true
        xAxis.drawAxisLineEnabled       = true
        
        //: ### RightAxis
        let rightAxis = chartView.rightAxis
        rightAxis.enabled = false
        
        //: ### LeftAxis
        let leftAxis = chartView.leftAxis
        leftAxis.enabled              = true
        leftAxis.labelFont            = ChartThemes.ChartDefaults.labelFont
        leftAxis.labelTextColor       = ChartThemes.DarkChartColors.labelTextColor
        leftAxis.valueFormatter       = KiloEuroFormatter()
        leftAxis.drawGridLinesEnabled = true
        leftAxis.drawZeroLineEnabled  = false
        
        //: ### Legend
        let legend = chartView.legend
        legend.enabled             = true
        legend.font                = ChartThemes.ChartDefaults.legendFont
        legend.textColor           = ChartThemes.DarkChartColors.legendColor
        legend.form                = .square
        legend.drawInside          = false
        legend.orientation         = .horizontal
        legend.verticalAlignment   = .bottom
        legend.horizontalAlignment = .left
        
        //: ### Description
        chartView.chartDescription?.text = "Actif / Passif"
        chartView.chartDescription?.enabled = true
        //chartView.chartDescription?.drawInside = false
        
        // bulle d'info
        let marker = DateValueMarkerView(color               : ChartThemes.BallonColors.color,
                                         font                : ChartThemes.ChartDefaults.baloonfont,
                                         textColor           : ChartThemes.BallonColors.textColor,
                                         insets              : UIEdgeInsets(top: 8, left: 8, bottom: 20, right: 8),
                                         xAxisValueFormatter : chartView.xAxis.valueFormatter!,
                                         yAxisValueFormatter : chartView.leftAxis.valueFormatter!)
        marker.chartView   = chartView
        marker.minimumSize = CGSize(width : 80, height : 40)
        chartView.marker   = marker
        
        //: ### BarChartData
        let dataSet = getBalanceSheetStackedBarChartDataSet(combination  : combination,
                                                            itemSelection: itemSelection)
        // ajouter les data au graphique
        let data = BarChartData(dataSet: dataSet)
        //data.addDataSet(dataSet)
        
        data.setValueTextColor(ChartThemes.DarkChartColors.valueColor)
        data.setValueFont(UIFont(name:"HelveticaNeue-Light", size:12)!)
        //data.setValueFont(.systemFont(ofSize: 14, weight: .light))
        data.setValueFormatter(DefaultValueFormatter(formatter: valueKiloFormatter))
        //let barWidth = 0.4
        //data.barWidth = barWidth
        
        // ajouter le dataset au graphique
        chartView.data = data
        chartView.gridBackgroundColor = NSUIColor.black // NSUIColor(red: 240/255.0, green: 240/255.0, blue: 240/255.0, alpha: 1.0) UIColor(red: 230/255, green: 126/255, blue: 34/255, alpha: 1)
        chartView.animate(yAxisDuration: 0.5, easingOption: .linear)
        
        return chartView
    }
    
    // MARK: - Génération de graphiques CASH FLOW
    
    /// Dessiner un graphe à lignes : revenus + dépenses + net
    /// - Returns: UIView
    func drawCashFlowLineChart() -> LineChartView {
        let chartView = LineChartView()
        
        // si la table est vide alors quitter
        guard !cashFlowArray.isEmpty else {
            return chartView
        }
        
        //: ### General
        chartView.pinchZoomEnabled          = true
        chartView.doubleTapToZoomEnabled    = true
        chartView.dragEnabled               = true
        chartView.setScaleEnabled ( true)
        chartView.drawGridBackgroundEnabled = false
        chartView.backgroundColor           = ChartThemes.DarkChartColors.backgroundColor
        chartView.borderColor               = ChartThemes.DarkChartColors.borderColor
        chartView.borderLineWidth           = 1.0
        chartView.drawBordersEnabled        = true
        
        //: ### xAxis
        let xAxis = chartView.xAxis
        xAxis.enabled                  = true
        xAxis.drawLabelsEnabled        = true
        xAxis.labelFont                = ChartThemes.ChartDefaults.labelFont
        xAxis.labelTextColor           = ChartThemes.DarkChartColors.labelTextColor
        xAxis.labelPosition            = .bottom // .insideChart
        xAxis.labelRotationAngle       = -90
        xAxis.granularityEnabled       = true
        xAxis.granularity              = 1
        xAxis.labelCount               = 200
        xAxis.drawGridLinesEnabled     = true
        xAxis.drawAxisLineEnabled      = true
        
        //: ### LeftAxis
        let leftAxis = chartView.leftAxis
        leftAxis.enabled               = true
        leftAxis.labelFont             = ChartThemes.ChartDefaults.labelFont
        leftAxis.labelTextColor        = ChartThemes.DarkChartColors.labelTextColor
        leftAxis.valueFormatter        = KiloEuroFormatter()
        leftAxis.drawGridLinesEnabled  = true
        leftAxis.drawZeroLineEnabled   = false
        
        //: ### RightAxis
        let rightAxis = chartView.rightAxis
        rightAxis.enabled              = false
        rightAxis.labelFont            = ChartThemes.ChartDefaults.labelFont
        rightAxis.labelTextColor       = #colorLiteral(red     : 1, green     : 0.1474981606, blue     : 0, alpha     : 1)
        rightAxis.axisMaximum          = 900.0
        rightAxis.axisMinimum          = -200.0
        rightAxis.drawGridLinesEnabled = false
        rightAxis.granularityEnabled   = false
        
        //: ### Legend
        let legend = chartView.legend
        legend.font                = ChartThemes.ChartDefaults.legendFont
        legend.textColor           = ChartThemes.DarkChartColors.legendColor
        legend.form                = .square
        legend.drawInside          = false
        legend.orientation         = .horizontal
        legend.verticalAlignment   = .bottom
        legend.horizontalAlignment = .left
        
        //: ### Description
        chartView.chartDescription?.text = "Revenu / Dépense"
        chartView.chartDescription?.enabled = true
        
        //: ### ChartDataEntry
        var yVals1 = [ChartDataEntry]()
        var yVals2 = [ChartDataEntry]()
        var yVals3 = [ChartDataEntry]()
        
        yVals1 = cashFlowArray.map {
            ChartDataEntry(x: $0.year.double(), y: $0.sumOfrevenues)
        }
        yVals2 = cashFlowArray.map {
            ChartDataEntry(x: $0.year.double(), y: -$0.sumOfExpenses)
        }
        yVals3 = cashFlowArray.map {
            ChartDataEntry(x: $0.year.double(), y: $0.netCashFlow)
        }
        
        var set1 = LineChartDataSet()
        var set2 = LineChartDataSet()
        var set3 = LineChartDataSet()
        
        set1 = LineChartDataSet(entries: yVals1, label: "Revenus")
        set1.axisDependency        = .left
        set1.colors                = [#colorLiteral(red        : 0.4666666687, green        : 0.7647058964, blue        : 0.2666666806, alpha        : 1)]
        set1.circleColors          = [NSUIColor.white]
        set1.lineWidth             = 2.0
        set1.circleRadius          = 3.0
        set1.fillAlpha             = 65 / 255.0
        set1.fillColor             = #colorLiteral(red      : 0.4666666687, green      : 0.7647058964, blue      : 0.2666666806, alpha      : 1)
        set1.highlightColor        = #colorLiteral(red : 0.4666666687, green : 0.7647058964, blue : 0.2666666806, alpha : 1)
        set1.highlightEnabled      = true
        set1.drawCircleHoleEnabled = false
        
        set2 = LineChartDataSet(entries: yVals2, label: "Dépenses")
        set2.axisDependency        = .left
        set2.colors                = [NSUIColor.red]
        set2.circleColors          = [NSUIColor.white]
        set2.lineWidth             = 2.0
        set2.circleRadius          = 3.0
        set2.fillAlpha             = 65 / 255.0
        set2.fillColor             = NSUIColor.red
        set2.highlightColor        = NSUIColor.red
        set2.highlightEnabled      = true
        set2.drawCircleHoleEnabled = false
        
        set3 = LineChartDataSet(entries: yVals3, label: "Net")
        set3.axisDependency        = .left
        set3.colors                = [NSUIColor.white]
        set3.circleColors          = [NSUIColor.white]
        set3.lineWidth             = 2.0
        set3.circleRadius          = 3.0
        set3.fillAlpha             = 65 / 255.0
        set3.fillColor             = NSUIColor.white
        set3.highlightColor        = NSUIColor.white
        set3.highlightEnabled      = true
        set3.drawCircleHoleEnabled = false
        
        // ajouter les dataSet au dataSets
        var dataSets = [LineChartDataSet]()
        dataSets.append(set1)
        dataSets.append(set2)
        dataSets.append(set3)
        
        //: ### LineChartData
        let data = LineChartData(dataSets: dataSets)
        data.setValueTextColor(ChartThemes.DarkChartColors.valueColor)
        data.setValueFont(NSUIFont(name: "HelveticaNeue-Light", size: CGFloat(12.0))!)
        data.setValueFormatter(DefaultValueFormatter(formatter: valueKiloFormatter))
        
        // ajouter les data au graphique
        chartView.data = data
        
        chartView.animate(yAxisDuration: 0.5, easingOption: .linear)
        
        return chartView
    }
    
    /// Construction de la légende du graphique
    /// - Parameter combination: sélection de la catégories de séries à afficher
    /// - Returns: tableau des libéllés des sries des catégories sélectionnées
    func getCashFlowLegend(_ combination: CashCombination = .both) -> [(label: String, selected: Bool)] {
        let firstLine   = cashFlowArray.first!
        switch combination {
            case .revenues:
                // libellés des revenus famille + revenus SCI
                let revenuesLegend = firstLine.revenues.namedValueTable.values.map({($0.name, true)})
                // Résumé seulement
                let sciLegend      = firstLine.sciCashFlowLine.namedValueTable.values.map({($0.name, true)})
                return revenuesLegend + sciLegend
                
            case .expenses:
                let taxesLegend  = firstLine.taxes.namedValueTable.values.map({($0.name, true)})
                // Résumé seulement
                let expenseLegend  = firstLine.lifeExpenses.summaryValueTable.values.map({($0.name, true)})
                // Résumé seulement
                let debtsLegend  = firstLine.debtPayements.summaryValueTable.values.map({($0.name, true)})
                return expenseLegend + taxesLegend + debtsLegend
                
            case .both:
                let revenuesLegend = firstLine.revenues.namedValueTable.values.map({($0.name, true)})
                // Résumé seulement
                let sciLegend      = firstLine.sciCashFlowLine.namedValueTable.values.map({($0.name, true)})
                let taxesLegend  = firstLine.taxes.namedValueTable.values.map({($0.name, true)})
                // Résumé seulement
                let expenseLegend  = firstLine.lifeExpenses.summaryValueTable.values.map({($0.name, true)})
                // Résumé seulement
                let debtsLegend  = firstLine.debtPayements.summaryValueTable.values.map({($0.name, true)})
                return revenuesLegend + sciLegend + expenseLegend + taxesLegend + debtsLegend
        }
    }
    
    /// Créer le DataSet pour former un un graphe barre empilées : revenus / dépenses / tout
    /// - Parameters:
    ///   - combination: revenus / dépenses / tout
    ///   - itemSelection: séries sélectionnées pour être affichées
    /// - Returns: DataSet
    func getCashFlowStackedBarChartDataSet(
        combination  : CashCombination = .both,
        itemSelection: [(label: String, selected: Bool)]) -> BarChartDataSet? {
        
        // si la table est vide alors quitter
        guard !cashFlowArray.isEmpty else {
            return nil
        }

        let firstLine   = cashFlowArray.first!
        var dataEntries = [ChartDataEntry]()
        let dataSet : BarChartDataSet
        
        switch combination {
            case .revenues:
                // valeurs des revenus + valeurs des revenus de la SCI
                dataEntries = cashFlowArray.map { // pour chaque année
                    let yRevenues = $0.revenues.namedValueTable.filtredValues(itemSelection: itemSelection)
                    let ySCI      = $0.sciCashFlowLine.namedValueTable.filtredValues(itemSelection: itemSelection)
                    return BarChartDataEntry(x       : $0.year.double(),
                                             yValues : yRevenues + ySCI)
                }
                let labelRevenues = firstLine.revenues.namedValueTable.filtredHeaders(itemSelection : itemSelection)
                let labelSCI      = firstLine.sciCashFlowLine.namedValueTable.filtredHeaders(itemSelection : itemSelection)
                let labels        = labelRevenues + labelSCI
                dataSet = BarChartDataSet(entries : dataEntries,
                                          label   : (labels.count == 1 ? labels.first : nil))
                // légendes des revenus
                dataSet.stackLabels = labels
                dataSet.colors      = ChartThemes.positiveColors(number: dataSet.stackLabels.count)
                
            case .expenses:
                // valeurs des taxes + valeurs des dépenses + valeurs des dettes
                dataEntries = cashFlowArray.map { // pour chaque année
                    let yExpenses = -$0.lifeExpenses.summaryValueTable.filtredValues(itemSelection: itemSelection)
                    let yTaxes    = -$0.taxes.namedValueTable.filtredValues(itemSelection: itemSelection)
                    let yDebt     = -$0.debtPayements.summaryValueTable.filtredValues(itemSelection: itemSelection)
                    return BarChartDataEntry(x       : $0.year.double(),
                                             yValues : yExpenses + yTaxes + yDebt)
                }
                let labelExpenses = firstLine.lifeExpenses.summaryValueTable.filtredHeaders(itemSelection: itemSelection)
                let labelTaxes    = firstLine.taxes.namedValueTable.filtredHeaders(itemSelection: itemSelection)
                let labelDebt     = firstLine.debtPayements.summaryValueTable.filtredHeaders(itemSelection: itemSelection)
                let labels        = labelExpenses + labelTaxes + labelDebt
                dataSet = BarChartDataSet(entries : dataEntries,
                                          label   : (labels.count == 1 ? labels.first : nil))
                // légendes des dépenses
                dataSet.stackLabels = labels
                dataSet.colors = ChartThemes.negativeColors(number: dataSet.stackLabels.count)
                
            case .both:
                // valeurs des revenus + valeurs des revenus de la SCI + valeurs des taxes + valeurs des dépenses + valeurs des dettes
                dataEntries = cashFlowArray.map {
                    let yRevenues = $0.revenues.namedValueTable.filtredValues(itemSelection: itemSelection)
                    let ySCI      = $0.sciCashFlowLine.namedValueTable.filtredValues(itemSelection: itemSelection)
                    let yExpenses = -$0.lifeExpenses.summaryValueTable.filtredValues(itemSelection: itemSelection)
                    let yTaxes    = -$0.taxes.namedValueTable.filtredValues(itemSelection: itemSelection)
                    let yDebt     = -$0.debtPayements.summaryValueTable.filtredValues(itemSelection: itemSelection)
                    
                    return BarChartDataEntry(x       : $0.year.double(),
                                             yValues : yRevenues + ySCI + yExpenses + yTaxes + yDebt)
                }
                let labelRevenues   = firstLine.revenues.namedValueTable.filtredHeaders(itemSelection: itemSelection)
                let labelSCI        = firstLine.sciCashFlowLine.namedValueTable.filtredHeaders(itemSelection: itemSelection)
                let labelsPositive  = labelRevenues + labelSCI
                let numberPositive  = labelsPositive.count
                
                let labelExpenses   = firstLine.lifeExpenses.summaryValueTable.filtredHeaders(itemSelection: itemSelection)
                let labelTaxes      = firstLine.taxes.namedValueTable.filtredHeaders(itemSelection: itemSelection)
                let labelDebt       = firstLine.debtPayements.summaryValueTable.filtredHeaders(itemSelection: itemSelection)
                let labelsNegative  = labelExpenses + labelTaxes + labelDebt
                let numberNegative  = labelsNegative.count
                
                let labels         = labelsPositive + labelsNegative
                dataSet = BarChartDataSet(entries : dataEntries,
                                          label   : (labels.count == 1 ? labels.first : nil))
                // légendes des revenus et des dépenses
                dataSet.stackLabels = labels
                dataSet.colors = ChartThemes.positiveNegativeColors (numberPositive: numberPositive,
                                                                     numberNegative: numberNegative)
                
        }
        
        return dataSet
    }
    
    func getCashFlowCategoryStackedBarChartDataSet(categoryName: String) -> BarChartDataSet? {

        // si la table est vide alors quitter
        guard !cashFlowArray.isEmpty else {
            return nil
        }
        
        let firstLine   = cashFlowArray.first!
        var dataEntries = [ChartDataEntry]()
        let dataSet : BarChartDataSet

        if let found = firstLine.revenues.namedValueTable.values.first(where: { $0.name == categoryName } ) {
            /// rechercher la catégorie dans les revenus
            print("revenues : \(found)")
            guard let category = RevenueCategory.category(of: categoryName) else {
                return BarChartDataSet()
            }
            print("  nom : \(category)")
            guard let labelsInCategory = firstLine.revenues.perCategory[category]?.credits.headersArray else {
                return BarChartDataSet()
            }
            print("  legende : ", labelsInCategory)

            // valeurs des revenus de la catégorie
            dataEntries = cashFlowArray.map { // pour chaque année
                let y = $0.revenues.perCategory[category]?.credits.valuesArray
                return BarChartDataEntry(x       : $0.year.double(),
                                         yValues : y!)
            }
            dataSet = BarChartDataSet(entries : dataEntries,
                                      label   : (labelsInCategory.count == 1 ? labelsInCategory.first : nil))
            dataSet.stackLabels = labelsInCategory
            dataSet.colors      = ChartThemes.positiveColors(number : dataSet.stackLabels.count)
            
        } else if let found = firstLine.sciCashFlowLine.namedValueTable.values.first(where: { $0.name == categoryName } ) {
            /// rechercher la catégorie dans les revenus de la SCI
            print("sciCashFlowLine : \(found)")
            dataSet = BarChartDataSet()

        } else if let found = firstLine.taxes.namedValueTable.values.first(where: { $0.name == categoryName } ) {
            /// rechercher les valeurs des taxes
            print("taxes : \(found)")
            guard let category = TaxeCategory.category(of: categoryName) else {
                return BarChartDataSet()
            }
            print("  nom : \(category)")
            guard let labelsInCategory = firstLine.taxes.perCategory[category]?.headersArray else {
                return BarChartDataSet()
            }
            print("  legende : ", labelsInCategory)
            
            // valeurs des revenus de la catégorie
            dataEntries = cashFlowArray.map { // pour chaque année
                let y = $0.taxes.perCategory[category]?.valuesArray
                return BarChartDataEntry(x       : $0.year.double(),
                                         yValues : -y!)
            }
            dataSet = BarChartDataSet(entries : dataEntries,
                                      label   : (labelsInCategory.count == 1 ? labelsInCategory.first : nil))
            dataSet.stackLabels = labelsInCategory
            dataSet.colors      = ChartThemes.negativeColors(number : dataSet.stackLabels.count)
            
        } else if categoryName == firstLine.lifeExpenses.summaryValueTable.name {
            /// rechercher les valeurs des dépenses
            print("expenses : \(categoryName)")
            let labelsInCategory = firstLine.lifeExpenses.namedValueTable.headersArray
            print("  legende : ", labelsInCategory)
            
            // valeurs des dépenses
            dataEntries = cashFlowArray.map { // pour chaque année
                let y = $0.lifeExpenses.namedValueTable.valuesArray
                return BarChartDataEntry(x       : $0.year.double(),
                                         yValues : -y)
            }

            dataSet = BarChartDataSet(entries : dataEntries,
                                      label   : (labelsInCategory.count == 1 ? labelsInCategory.first : nil))
            dataSet.stackLabels = labelsInCategory
            dataSet.colors      = ChartThemes.negativeColors(number : dataSet.stackLabels.count)

        } else {
            dataSet = BarChartDataSet()
        }

        return dataSet
    }
    
}

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
