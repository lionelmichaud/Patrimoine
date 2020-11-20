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

// MARK: - Extension de SocialAccounts pour graphiques FISCALITE

extension SocialAccounts {
    
    // MARK: - Génération de graphiques - Synthèse - FISCALITE
    
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
        
        let set1 = LineChartDataSet(entries: yVals1,
                                    label: "Revenus",
                                    color: #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1))
        let set2 = LineChartDataSet(entries: yVals2,
                                    label: "IRPP",
                                    color: #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1))
        
        // ajouter les dataSet au dataSets
        var dataSets = [LineChartDataSet]()
        dataSets.append(set1)
        dataSets.append(set2)
        
        return dataSets
    }
    
    /// Dessiner un graphe à lignes : taux d'imposition marginal + taux d'imposition moyen
    /// - Returns: tableau de LineChartDataSet
    func getIrppCoefLineChartDataSets() -> [LineChartDataSet]? {
        // si la table est vide alors quitter
        guard !cashFlowArray.isEmpty else { return nil }
        
        //: ### ChartDataEntry
        var yVals1 = [ChartDataEntry]()
        var yVals2 = [ChartDataEntry]()
        // revenu imposable
        yVals1 = cashFlowArray.map { cfLine in // pour chaque année
            ChartDataEntry(x: cfLine.year.double(), y: cfLine.taxes.irpp.averageRate)
        }
        // irpp
        yVals2 = cashFlowArray.map { cfLine in // pour chaque année
            ChartDataEntry(x: cfLine.year.double(), y: cfLine.taxes.irpp.marginalRate)
        }
        
        let set1 = LineChartDataSet(entries: yVals1,
                                    label: "Taux Moyen",
                                    color: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
        let set2 = LineChartDataSet(entries: yVals2,
                                    label: "Taux Marginal",
                                    color: #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1))
        
        // ajouter les dataSet au dataSets
        var dataSets = [LineChartDataSet]()
        dataSets.append(set1)
        dataSets.append(set2)
        
        return dataSets
    }

}
