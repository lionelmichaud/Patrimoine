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

fileprivate let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.SocialAccounts+CfCharts")

// MARK: - Extension de SocialAccounts pour graphiques CASH FLOW

extension SocialAccounts {
    
    // MARK: - Nested types
    
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
    
    // MARK: - Génération de graphiques - Synthèse - CASH FLOW
    
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
    
    // MARK: - Génération de graphiques - Détail par catégories - CASH FLOW
    
    /// Construction de la légende du graphique
    /// - Parameter combination: sélection de la catégories de séries à afficher
    /// - Returns: tableau des libéllés des sries des catégories sélectionnées
    func getCashFlowLegend(_ combination: CashCombination = .both)
    -> ItemSelectionList {
        let firstLine   = cashFlowArray.first!
        switch combination {
            case .revenues:
                // libellés des revenus famille + revenus SCI
                let revenuesLegend = firstLine.revenues.summary.namedValues.map({($0.name, true)})
                // Résumé seulement
                let sciLegend      = firstLine.sciCashFlowLine.summary.namedValues.map({($0.name, true)})
                return revenuesLegend + sciLegend
                
            case .expenses:
                // à plat
                let taxesLegend    = firstLine.taxes.summary.namedValues.map({($0.name, true)})
                // Résumé seulement
                let expenseLegend  = firstLine.lifeExpenses.summary.namedValues.map({($0.name, true)})
                // Résumé seulement
                let debtsLegend    = firstLine.debtPayements.summary.namedValues.map({($0.name, true)})
                // Résumé seulement
                let investsLegend  = firstLine.investPayements.summary.namedValues.map({($0.name, true)})
                return expenseLegend + taxesLegend + debtsLegend + investsLegend
                
            case .both:
                return getCashFlowLegend(.revenues) + getCashFlowLegend(.expenses)
        }
    }
    
    /// Créer le DataSet pour former un un graphe barre empilées : revenus / dépenses / tout
    /// - Parameters:
    ///   - combination: revenus / dépenses / tout
    ///   - itemSelectionList: séries sélectionnées pour être affichées
    /// - Returns: DataSet
    func getCashFlowStackedBarChartDataSet(
        combination      : CashCombination = .both,
        itemSelectionList: ItemSelectionList) -> BarChartDataSet? {
        
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
                    let yRevenues = $0.revenues.summaryFiltredValues(with: itemSelectionList)
                    let ySCI      = $0.sciCashFlowLine.summaryFiltredValues(with: itemSelectionList)
                    return BarChartDataEntry(x       : $0.year.double(),
                                             yValues : yRevenues + ySCI)
                }
                let labelRevenues = firstLine.revenues.summaryFiltredNames(with: itemSelectionList)
                let labelSCI      = firstLine.sciCashFlowLine.summaryFiltredNames(with: itemSelectionList)
                let labels        = labelRevenues + labelSCI
                dataSet = BarChartDataSet(entries : dataEntries,
                                          label   : (labels.count == 1 ? labels.first : nil))
                // légendes des revenus
                dataSet.stackLabels = labels
                dataSet.colors      = ChartThemes.positiveColors(number: dataSet.stackLabels.count)
                
            case .expenses:
                // valeurs des taxes + valeurs des dépenses + valeurs des dettes
                dataEntries = cashFlowArray.map { // pour chaque année
                    let yExpenses = -$0.lifeExpenses.summaryFiltredValues(with: itemSelectionList)
                    let yTaxes    = -$0.taxes.summaryFiltredValues(with: itemSelectionList)
                    let yDebt     = -$0.debtPayements.summaryFiltredValues(with: itemSelectionList)
                    let yInvest   = -$0.investPayements.summaryFiltredValues(with: itemSelectionList)
                    return BarChartDataEntry(x       : $0.year.double(),
                                             yValues : yExpenses + yTaxes + yDebt + yInvest)
                }
                let labelExpenses = firstLine.lifeExpenses.summaryFiltredNames(with: itemSelectionList)
                let labelTaxes    = firstLine.taxes.summaryFiltredNames(with: itemSelectionList)
                let labelDebt     = firstLine.debtPayements.summaryFiltredNames(with: itemSelectionList)
                let labelInvest   = firstLine.investPayements.summaryFiltredNames(with: itemSelectionList)
                let labels        = labelExpenses + labelTaxes + labelDebt + labelInvest
                dataSet = BarChartDataSet(entries : dataEntries,
                                          label   : (labels.count == 1 ? labels.first : nil))
                // légendes des dépenses
                dataSet.stackLabels = labels
                dataSet.colors = ChartThemes.negativeColors(number: dataSet.stackLabels.count)
                
            case .both:
                // valeurs des revenus + valeurs des revenus de la SCI + valeurs des taxes + valeurs des dépenses + valeurs des dettes
                dataEntries = cashFlowArray.map {
                    let yRevenues = $0.revenues.summaryFiltredValues(with: itemSelectionList)
                    let ySCI      = $0.sciCashFlowLine.summaryFiltredValues(with: itemSelectionList)
                    let yExpenses = -$0.lifeExpenses.summaryFiltredValues(with: itemSelectionList)
                    let yTaxes    = -$0.taxes.summaryFiltredValues(with: itemSelectionList)
                    let yDebt     = -$0.debtPayements.summaryFiltredValues(with: itemSelectionList)
                    let yInvest   = -$0.investPayements.summaryFiltredValues(with: itemSelectionList)
                    return BarChartDataEntry(x       : $0.year.double(),
                                             yValues : yRevenues + ySCI + yExpenses + yTaxes + yDebt + yInvest)
                }
                let labelRevenues   = firstLine.revenues.summaryFiltredNames(with: itemSelectionList)
                let labelSCI        = firstLine.sciCashFlowLine.summaryFiltredNames(with: itemSelectionList)
                let labelsPositive  = labelRevenues + labelSCI
                let numberPositive  = labelsPositive.count
                
                let labelExpenses   = firstLine.lifeExpenses.summaryFiltredNames(with: itemSelectionList)
                let labelTaxes      = firstLine.taxes.summaryFiltredNames(with: itemSelectionList)
                let labelDebt       = firstLine.debtPayements.summaryFiltredNames(with: itemSelectionList)
                let labelInvest     = firstLine.investPayements.summaryFiltredNames(with: itemSelectionList)
                let labelsNegative  = labelExpenses + labelTaxes + labelDebt + labelInvest
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
    
    // MARK: - Génération de graphiques - Détail d'une seule catégorie - CASH FLOW
    
    /// Créer le DataSet pour former un un graphe barre empilées : une seule catégorie
    /// - Parameters:
    ///   - categoryName: nom de la catégories
    /// - Returns: DataSet
    func getCashFlowCategoryStackedBarChartDataSet(categoryName: String) -> BarChartDataSet? {
        
        // si la table est vide alors quitter
        guard !cashFlowArray.isEmpty else {
            return nil
        }
        
        let firstLine   = cashFlowArray.first!
        var dataEntries = [ChartDataEntry]()
        let dataSet : BarChartDataSet
        
        if let found = firstLine.revenues.summary.namedValues.first(where: { $0.name == categoryName } ) {
            /// rechercher la catégorie dans les revenus
            customLog.log(level: .info, "Catégorie trouvée dans Revenues : \(found.name)")
            guard let category = RevenueCategory.category(of: categoryName) else {
                return BarChartDataSet()
            }
            // print("  nom : \(category)")
            guard let labelsInCategory = firstLine.revenues.perCategory[category]?.credits.namesArray else {
                return BarChartDataSet()
            }
            // print("  legende : ", labelsInCategory)
            
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
            
        } else if let found = firstLine.sciCashFlowLine.summary.namedValues.first(where: { $0.name == categoryName } ) {
            /// rechercher la catégorie dans les revenus de la SCI
            customLog.log(level: .info, "Catégorie trouvée dans sciCashFlowLine : \(found.name)")
            var labelsInRevenus = firstLine.sciCashFlowLine.revenues.sciDividends.namesArray
            labelsInRevenus = labelsInRevenus.map {$0 + "(Revenu)"}
            var labelsInSales = firstLine.sciCashFlowLine.revenues.scpiSale.namesArray
            labelsInSales = labelsInSales.map {$0 + "(Vente)"}
            var labelsInCategory = labelsInRevenus + labelsInSales
            // ajouter l'IS de la SCI
            labelsInCategory.append("IS")
            print("  legende : ", labelsInCategory)
            
            // valeurs des dettes
            dataEntries = cashFlowArray.map { // pour chaque année
                var y = $0.sciCashFlowLine.revenues.sciDividends.valuesArray
                y += $0.sciCashFlowLine.revenues.scpiSale.valuesArray
                y.append(-$0.sciCashFlowLine.IS)
                return BarChartDataEntry(x       : $0.year.double(),
                                         yValues : y)
            }
            dataSet = BarChartDataSet(entries : dataEntries,
                                      label   : (labelsInCategory.count == 1 ? labelsInCategory.first : nil))
            dataSet.stackLabels = labelsInCategory
            dataSet.colors      = ChartThemes.positiveColors(number : dataSet.stackLabels.count)
            
        } else if let found = firstLine.taxes.summary.namedValues.first(where: { $0.name == categoryName } ) {
            /// rechercher les valeurs des taxes
            customLog.log(level: .info, "Catégorie trouvée dans taxes : \(found.name)")
            guard let category = TaxeCategory.category(of: categoryName) else {
                return BarChartDataSet()
            }
            print("  nom : \(category)")
            guard let labelsInCategory = firstLine.taxes.perCategory[category]?.namesArray else {
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
            
        } else if categoryName == firstLine.lifeExpenses.summary.name {
            /// rechercher les valeurs des dépenses
            customLog.log(level: .info, "Catégorie trouvée dans lifeExpenses : \(categoryName)")
            let labelsInCategory = firstLine.lifeExpenses.namedValueTable.namesArray
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
            
        } else if categoryName == firstLine.debtPayements.summary.name {
            /// rechercher les valeurs des debtPayements
            customLog.log(level: .info, "Catégorie trouvée dans debtPayements : \(categoryName)")
            let labelsInCategory = firstLine.debtPayements.namedValueTable.namesArray
            print("  legende : ", labelsInCategory)
            
            // valeurs des dettes
            dataEntries = cashFlowArray.map { // pour chaque année
                let y = $0.debtPayements.namedValueTable.valuesArray
                return BarChartDataEntry(x       : $0.year.double(),
                                         yValues : -y)
            }
            
            dataSet = BarChartDataSet(entries : dataEntries,
                                      label   : (labelsInCategory.count == 1 ? labelsInCategory.first : nil))
            dataSet.stackLabels = labelsInCategory
            dataSet.colors      = ChartThemes.negativeColors(number : dataSet.stackLabels.count)
            
        } else if categoryName == firstLine.investPayements.summary.name {
            /// rechercher les valeurs des investPayements
            customLog.log(level: .info, "Catégorie trouvée dans investPayements : \(categoryName)")
            let labelsInCategory = firstLine.investPayements.namedValueTable.namesArray
            print("  legende : ", labelsInCategory)
            
            // valeurs des investissements
            dataEntries = cashFlowArray.map { // pour chaque année
                let y = $0.investPayements.namedValueTable.valuesArray
                return BarChartDataEntry(x       : $0.year.double(),
                                         yValues : -y)
            }
            
            dataSet = BarChartDataSet(entries : dataEntries,
                                      label   : (labelsInCategory.count == 1 ? labelsInCategory.first : nil))
            dataSet.stackLabels = labelsInCategory
            dataSet.colors      = ChartThemes.negativeColors(number : dataSet.stackLabels.count)
            
        } else {
            customLog.log(level: .error, "Catégorie \(categoryName) NON trouvée dans cashFlowArray.first!")
            dataSet = BarChartDataSet()
        }
        
        return dataSet
    }
}

