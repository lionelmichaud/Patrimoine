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
    func getCashFlowLineChartDataSets() -> [LineChartDataSet]? {
        // si la table est vide alors quitter
        guard !cashFlowArray.isEmpty else { return nil }
                
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
        
        let set1 = LineChartDataSet(entries: yVals1,
                                    label: "Revenus",
                                    color: #colorLiteral(red        : 0.4666666687, green        : 0.7647058964, blue        : 0.2666666806, alpha        : 1))
        let set2 = LineChartDataSet(entries: yVals2,
                                    label: "Dépenses",
                                    color: #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1))
        let set3 = LineChartDataSet(entries: yVals3,
                                    label: "Solde Net",
                                    color: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
        
        // ajouter les dataSet au dataSets
        var dataSets = [LineChartDataSet]()
        dataSets.append(set1)
        dataSets.append(set2)
        dataSets.append(set3)
        
        return dataSets
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
        
        if firstLine.revenues.summary.namedValues.first(where: { $0.name == categoryName } ) != nil {
            /// rechercher la catégorie dans les revenus
            // customLog.log(level: .info, "Catégorie trouvée dans Revenues : \(found.name)")
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
            
        } else if firstLine.sciCashFlowLine.summary.namedValues.first(where: { $0.name == categoryName } ) != nil {
            /// rechercher la catégorie dans les revenus de la SCI
            // customLog.log(level: .info, "Catégorie trouvée dans sciCashFlowLine : \(found.name)")
            let labelsInCategory = firstLine.sciCashFlowLine.namesFlatArray
            print("  legende : ", labelsInCategory)
            
            // valeurs des dettes
            dataEntries = cashFlowArray.map { // pour chaque année
                let y = $0.sciCashFlowLine.valuesFlatArray
                return BarChartDataEntry(x       : $0.year.double(),
                                         yValues : y)
            }
            dataSet = BarChartDataSet(entries : dataEntries,
                                      label   : (labelsInCategory.count == 1 ? labelsInCategory.first : nil))
            dataSet.stackLabels = labelsInCategory
            dataSet.colors      = ChartThemes.positiveColors(number : dataSet.stackLabels.count)
            
        } else if firstLine.taxes.summary.namedValues.first(where: { $0.name == categoryName } ) != nil {
            /// rechercher les valeurs des taxes
            // customLog.log(level: .info, "Catégorie trouvée dans taxes : \(found.name)")
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
            // customLog.log(level: .info, "Catégorie trouvée dans lifeExpenses : \(categoryName)")
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
            // customLog.log(level: .info, "Catégorie trouvée dans debtPayements : \(categoryName)")
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
            // customLog.log(level: .info, "Catégorie trouvée dans investPayements : \(categoryName)")
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

