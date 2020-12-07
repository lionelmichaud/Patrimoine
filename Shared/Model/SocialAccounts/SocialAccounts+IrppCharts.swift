//
//  SocialAccounts+FiscCharts.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/11/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import os
import CoreGraphics
#if canImport(UIKit)
import UIKit
#endif
import Charts // https://github.com/danielgindi/Charts.git

fileprivate let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.SocialAccounts+FiscCharts")

// MARK: - Extension de SocialAccounts pour graphiques FISCALITE IRPP

extension SocialAccounts {
    
    // MARK: - Génération de graphiques - Synthèse - FISCALITE IRPP
    
    /// Dessiner un graphe à lignes : revenu imposable + irpp
    /// - Returns: tableau de LineChartDataSet
    func getIrppLineChartDataSets() -> [LineChartDataSet]? {
        // si la table est vide alors quitter
        guard !cashFlowArray.isEmpty else { return nil }
        
        //: ### ChartDataEntry
        var yVals1 = [ChartDataEntry]()
        var yVals2 = [ChartDataEntry]()
        // revenu imposable
        yVals1 = cashFlowArray.map { cfLine in // pour chaque année
            ChartDataEntry(x: cfLine.year.double(), y: cfLine.taxes.irpp.amount / cfLine.taxes.irpp.averageRate)
        }
        // irpp
        yVals2 = cashFlowArray.map { cfLine in // pour chaque année
            ChartDataEntry(x: cfLine.year.double(), y: cfLine.taxes.irpp.amount)
        }
        
        let set1 = LineChartDataSet(entries : yVals1,
                                    label   : "Revenu Imposable",
                                    color   : #colorLiteral(red   : 0.2392156869, green   : 0.6745098233, blue   : 0.9686274529, alpha   : 1))
        let set2 = LineChartDataSet(entries : yVals2,
                                    label   : "IRPP",
                                    color   : #colorLiteral(red   : 1, green   : 0.1491314173, blue   : 0, alpha   : 1))
        
        // ajouter les dataSet au dataSets
        var dataSets = [LineChartDataSet]()
        dataSets.append(set1)
        dataSets.append(set2)
        
        return dataSets
    }
    
    /// Dessiner un graphe à lignes : taux d'imposition marginal + taux d'imposition moyen
    /// - Returns: tableau de LineChartDataSet
    func getIrppRatesfLineChartDataSets() -> [LineChartDataSet]? {
        // si la table est vide alors quitter
        guard !cashFlowArray.isEmpty else { return nil }
        
        //: ### ChartDataEntry
        var yVals1 = [ChartDataEntry]()
        var yVals2 = [ChartDataEntry]()
        // taux moyen
        yVals1 = cashFlowArray.map { cfLine in // pour chaque année
            ChartDataEntry(x: cfLine.year.double(), y: cfLine.taxes.irpp.averageRate)
        }
        // taux marginal
        yVals2 = cashFlowArray.map { cfLine in // pour chaque année
            ChartDataEntry(x: cfLine.year.double(), y: cfLine.taxes.irpp.marginalRate)
        }
        
        let set1 = LineChartDataSet(entries: yVals1,
                                    label: "Taux Moyen",
                                    color: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
        set1.axisDependency = .left
        set1.lineWidth      = 3.0
        let set2 = LineChartDataSet(entries: yVals2,
                                    label: "Taux Marginal",
                                    color: #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1))
        set2.axisDependency = .left
        set2.lineWidth      = 3.0

        // ajouter les dataSet au dataSets
        var dataSets = [LineChartDataSet]()
        dataSets.append(set1)
        dataSets.append(set2)
        
        return dataSets
    }

    /// Dessiner un graphe à barres : quotient familial
    /// - Returns: tableau de BarChartDataSet
    func getfamilyQotientBarChartDataSets() -> [BarChartDataSet]? {
        // si la table est vide alors quitter
        guard !cashFlowArray.isEmpty else { return nil }
        
        //: ### ChartDataEntry
        // revenu imposable
        let yVals1 = cashFlowArray.map { cfLine in // pour chaque année
            BarChartDataEntry(x: cfLine.year.double(), y: cfLine.taxes.irpp.familyQuotient)
        }
        
        let set1 = BarChartDataSet(entries : yVals1,
                                   label   : "Quotient Familial")
        set1.setColor(#colorLiteral(red: 0.5058823824, green: 0.3372549117, blue: 0.06666667014, alpha: 1))
        set1.axisDependency    = .right
        set1.drawValuesEnabled = false

        // ajouter les dataSet au dataSets
        var dataSets = [BarChartDataSet]()
        dataSets.append(set1)
        
        return dataSets
    }
    
    enum IrppEnum: Int, PickableEnum {
        case bareme
        case withChildren
        case withoutChildren
        
        var id: Int {
            return self.rawValue
        }
        
        var pickerString: String {
            switch self {
                case .bareme:
                    return "Barême"
                case .withChildren:
                    return "Quotient Familial \n avec Enfants"
                case .withoutChildren:
                    return "Quotient Familial \n sans Enfant"
            }
        }
    }
    
    /// Dessiner un graphe à barres verticales : imposition par tranche de taux d'imposition
    /// - Returns: tableau de BarChartDataSet
    func getSlicedIrppBarChartDataSets(for year   : Int,
                                       maxCumulatedSlices: inout Double,
                                       nbAdults   : Int,
                                       nbChildren : Int) -> BarChartDataSet? {
        // si la table est vide alors quitter
        guard !cashFlowArray.isEmpty else { return nil }
        // si l'année n'existe pas dans le tableau de cash flow
        guard let cfLine = cashFlowArray.yearCashFlow(for: year) else { return nil }
        
        let slicedIrpp = Fiscal.model.incomeTaxes.slicedIrpp(taxableIncome : cfLine.taxes.irpp.amount / cfLine.taxes.irpp.averageRate,
                                                             nbAdults      : nbAdults,
                                                             nbChildren    : nbChildren)
        maxCumulatedSlices = 0.0
        let bars = IrppEnum.allCases.map { (xLabel) -> BarChartDataEntry in
            var yVals = [Double]()
            switch xLabel {
                case .bareme:
                    yVals = slicedIrpp.map { // pour chaque tranche = série
                        $0.size
                    }
                case .withChildren:
                    yVals = slicedIrpp.map { // pour chaque tranche = série
                        $0.sizeithChildren
                    }
                case .withoutChildren:
                    yVals = slicedIrpp.map { // pour chaque tranche = série
                        maxCumulatedSlices += $0.sizeithoutChildren
                        return $0.sizeithoutChildren
                    }
            }
            return BarChartDataEntry(x       : Double(xLabel.id),
                                     yValues : yVals)
        }
        let set = BarChartDataSet(entries: bars, label: "Tranches par taux d'imposition")
        set.colors = slicedIrpp.map { // pour chaque tranche
            ChartThemes.taxRateColor(rate: $0.rate)
        }
        set.stackLabels = slicedIrpp.map { // pour chaque tranche
            ($0.rate * 100.0).percentString() + " %"
        }
        return set
    }
    
}
