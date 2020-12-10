//
//  SocialAccounts+Charts.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 11/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import os
import CoreGraphics
#if canImport(UIKit)
import UIKit
#endif
import Charts // https://github.com/danielgindi/Charts.git

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.SocialAccounts+BsCharts")

// MARK: - Extension de SocialAccounts pour graphiques BALANCE SHEET

extension SocialAccounts {
        
    // MARK: - Nested types
    
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
    
    // MARK: - Génération de graphiques - Synthèse - BALANCE SHEET
    
    /// Dessiner un graphe à lignes : passif + actif + net
    /// - Returns: UIView
    func getBalanceSheetLineChartDataSets() -> [LineChartDataSet]? {
        // si la table est vide alors quitter
        guard !balanceArray.isEmpty else { return nil }
        
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
            ChartDataEntry(x: $0.year.double(), y: $0.netAssets)
        }
        
        let set1 = LineChartDataSet(entries: yVals1,
                                    label: "Actif",
                                    color: #colorLiteral(red        : 0.4666666687, green        : 0.7647058964, blue        : 0.2666666806, alpha        : 1))
        let set2 = LineChartDataSet(entries: yVals2,
                                    label: "Passif",
                                    color: #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1))
        let set3 = LineChartDataSet(entries: yVals3,
                                    label: "Net",
                                    color: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))

        // ajouter les dataSet au dataSets
        var dataSets = [LineChartDataSet]()
        dataSets.append(set1)
        dataSets.append(set2)
        dataSets.append(set3)
        
        return dataSets
    }
    
    // MARK: - Génération de graphiques - Détail par catégories - BALANCE SHEET
    
    /// Construction de la légende du graphique
    /// - Parameter combination: sélection de la catégories de séries à afficher
    /// - Returns: tableau des libéllés des sries des catégories sélectionnées
    func getBalanceSheetLegend(_ combination: AssetLiabilitiesCombination = .both)
    -> ItemSelectionList {
        let firstLine   = balanceArray.first!
        switch combination {
            case .assets:
                return firstLine.assets.summary.namedValues.map({($0.name, true)}) // sélectionné par défaut
            case .liabilities:
                return firstLine.liabilities.summary.namedValues.map({($0.name, true)}) // sélectionné par défaut
            case .both:
                return getBalanceSheetLegend(.assets) + getBalanceSheetLegend(.liabilities)
        }
    }
    
    /// Créer le DataSet pour former un un graphe barre empilées : passif / actif / net
    /// - Parameters:
    ///   - combination: passif / actif / tout
    ///   - itemSelectionList: séries sélectionnées pour être affichées
    /// - Returns: DataSet
    func getBalanceSheetStackedBarChartDataSet(
        combination      : AssetLiabilitiesCombination = .both,
        itemSelectionList: ItemSelectionList) -> BarChartDataSet? {
        
        // si la table est vide alors quitter
        guard !balanceArray.isEmpty else { return nil }
        
        let firstLine   = balanceArray.first!
        var dataEntries = [ChartDataEntry]()
        let dataSet : BarChartDataSet
        
        switch combination {
            case .assets:
                dataEntries += balanceArray.map { // pour chaque année
                    BarChartDataEntry(x       : $0.year.double(),
                                      yValues : $0.assets.summaryFiltredValues(with: itemSelectionList))
                }
                let labels = firstLine.assets.summaryFiltredNames(with : itemSelectionList)
                dataSet = BarChartDataSet(entries: dataEntries,
                                          label: (labels.count == 1 ? labels.first : nil))
                dataSet.stackLabels = labels
                dataSet.colors      = ChartThemes.positiveColors(number: dataSet.stackLabels.count)
                
            case .liabilities:
                dataEntries += balanceArray.map { // pour chaque année
                    BarChartDataEntry(x       : $0.year.double(),
                                      yValues : $0.liabilities.summaryFiltredValues(with: itemSelectionList))
                }
                let labels = firstLine.liabilities.summaryFiltredNames(with : itemSelectionList)
                dataSet = BarChartDataSet(entries: dataEntries,
                                          label: (labels.count == 1 ? labels.first : nil))
                dataSet.stackLabels = labels
                dataSet.colors      = ChartThemes.negativeColors(number: dataSet.stackLabels.count)
                
            case .both:
                dataEntries += balanceArray.map {
                    BarChartDataEntry(x       : $0.year.double(),
                                      yValues : $0.assets.summaryFiltredValues(with: itemSelectionList) +
                                        $0.liabilities.summaryFiltredValues(with: itemSelectionList))
                }
                let labels = firstLine.assets.summaryFiltredNames(with : itemSelectionList) +
                    firstLine.liabilities.summaryFiltredNames(with : itemSelectionList)
                dataSet = BarChartDataSet(entries: dataEntries,
                                          label: (labels.count == 1 ? labels.first : nil))
                dataSet.stackLabels = firstLine.assets.summaryFiltredNames(with : itemSelectionList)
                let numberPositive = dataSet.stackLabels.count
                dataSet.stackLabels += firstLine.liabilities.summaryFiltredNames(with : itemSelectionList)
                dataSet.colors = ChartThemes.positiveNegativeColors(numberPositive: numberPositive,
                                                                    numberNegative: dataSet.stackLabels.count - numberPositive)
        }
        
        return dataSet
    }
    
    // MARK: - Génération de graphiques - Détail d'une seule catégorie - CASH FLOW
    
    /// Créer le DataSet pour former un un graphe barre empilées : une seule catégorie
    /// - Parameters:
    ///   - categoryName: nom de la catégories
    /// - Returns: DataSet
    func getBalanceSheetCategoryStackedBarChartDataSet(categoryName: String) -> BarChartDataSet? {
        
        // si la table est vide alors quitter
        guard !balanceArray.isEmpty else {
            return nil
        }
        
        let firstLine   = balanceArray.first!
        var dataEntries = [ChartDataEntry]()
        let dataSet : BarChartDataSet
        
        if firstLine.assets.summary.namedValues.first(where: { $0.name == categoryName }) != nil {
            /// rechercher les valeurs des actifs
            // customLog.log(level: .info, "Catégorie trouvée dans assets : \(found.name)")
            guard let category = AssetsCategory.category(of: categoryName) else {
                return BarChartDataSet()
            }
//            print("  nom : \(category)")
            guard let labelsInCategory = firstLine.assets.namesArray(category) else {
                return BarChartDataSet()
            }
//            print("  legende : ", labelsInCategory)
            
            // valeurs des revenus de la catégorie
            dataEntries = balanceArray.map { // pour chaque année
                let y = $0.assets.valuesArray(category)
                return BarChartDataEntry(x       : $0.year.double(),
                                         yValues : y!)
            }
            dataSet = BarChartDataSet(entries : dataEntries,
                                      label   : (labelsInCategory.count == 1 ? labelsInCategory.first : nil))
            dataSet.stackLabels = labelsInCategory
            dataSet.colors      = ChartThemes.positiveColors(number : dataSet.stackLabels.count)
            
        } else if firstLine.liabilities.summary.namedValues.first(where: { $0.name == categoryName }) != nil {
            /// rechercher les valeurs des passifs
            // customLog.log(level: .info, "Catégorie trouvée dans liabilities : \(found.name)")
            guard let category = LiabilitiesCategory.category(of: categoryName) else {
                return BarChartDataSet()
            }
//            print("  nom : \(category)")
            guard let labelsInCategory = firstLine.liabilities.namesArray(category) else {
                return BarChartDataSet()
            }
//            print("  legende : ", labelsInCategory)
            
            // valeurs des revenus de la catégorie
            dataEntries = balanceArray.map { // pour chaque année
                let y = $0.liabilities.valuesArray(category)
                return BarChartDataEntry(x       : $0.year.double(),
                                         yValues : y!)
            }
            dataSet = BarChartDataSet(entries : dataEntries,
                                      label   : (labelsInCategory.count == 1 ? labelsInCategory.first : nil))
            dataSet.stackLabels = labelsInCategory
            dataSet.colors      = ChartThemes.positiveColors(number : dataSet.stackLabels.count)

        } else {
            customLog.log(level: .error, "Catégorie \(categoryName) NON trouvée dans balanceArray.first!")
            assert(true, "Catégorie \(categoryName) NON trouvée dans balanceArray.first!")
            dataSet = BarChartDataSet()
        }
        
        return dataSet
    }

    /// unused
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
        xAxis.labelFont               = ChartThemes.ChartDefaults.smallLabelFont
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
        leftAxis.labelFont            = ChartThemes.ChartDefaults.smallLabelFont
        leftAxis.labelTextColor       = #colorLiteral(red     : 0.215686274509804, green     : 0.709803921568627, blue     : 0.898039215686275, alpha     : 1.0)
        leftAxis.valueFormatter       = Kilo€Formatter()
        leftAxis.drawGridLinesEnabled = true
        leftAxis.drawZeroLineEnabled  = false
        
        //: ### Legend
        let legend = chartView.legend
        legend.font                = ChartThemes.ChartDefaults.smallLegendFont
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
    
}
