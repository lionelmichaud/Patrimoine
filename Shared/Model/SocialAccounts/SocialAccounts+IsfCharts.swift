//
//  SocialAccounts+IsfCharts.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 06/12/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import os
import CoreGraphics
#if canImport(UIKit)
import UIKit
#endif
import Charts // https://github.com/danielgindi/Charts.git

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.SocialAccounts+FiscCharts")

// MARK: - Extension de SocialAccounts pour graphiques FISCALITE ISF

extension SocialAccounts {
    
    // MARK: - Génération de graphiques - Synthèse - FISCALITE ISF
    
    /// Dessiner un graphe à lignes : revenu imposable + isf
    /// - Returns: tableau de LineChartDataSet
    func getIsfLineChartDataSets() -> [LineChartDataSet]? {
        // si la table est vide alors quitter
        guard !cashFlowArray.isEmpty else { return nil }
        
        // : ### ChartDataEntry
        var yVals1 = [ChartDataEntry]()
        var yVals2 = [ChartDataEntry]()
        // revenu imposable
        yVals1 = cashFlowArray.map { cfLine in // pour chaque année
            ChartDataEntry(x: cfLine.year.double(), y: cfLine.taxes.isf.taxable)
        }
        // isf
        yVals2 = cashFlowArray.map { cfLine in // pour chaque année
            ChartDataEntry(x: cfLine.year.double(), y: cfLine.taxes.isf.amount)
        }
        
        let set1 = LineChartDataSet(entries : yVals1,
                                    label   : "Patrimoine Imposable",
                                    color   : #colorLiteral(red   : 0.2392156869, green   : 0.6745098233, blue   : 0.9686274529, alpha   : 1))
        set1.axisDependency = .left

        let set2 = LineChartDataSet(entries : yVals2,
                                    label   : "ISF",
                                    color   : #colorLiteral(red   : 1, green   : 0.1491314173, blue   : 0, alpha   : 1))
        set2.axisDependency = .right

        // ajouter les dataSet au dataSets
        var dataSets = [LineChartDataSet]()
        dataSets.append(set1)
        dataSets.append(set2)
        
        return dataSets
    }
}
