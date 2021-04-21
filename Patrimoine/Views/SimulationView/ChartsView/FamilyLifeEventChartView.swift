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
    let endDate: Int

    static let shape: [LifeEvent:ScatterChartDataSet.Shape] =
        [.debutEtude         :.chevronUp,
         .independance       :.chevronDown,
         .cessationActivite  :.triangle,
         .liquidationPension :.square,
         .dependence         :.circle,
         .deces              :.x]
    static let colorsTable: [LifeEvent:NSUIColor] =
        [.debutEtude         : #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1),
         .independance       : #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1),
         .cessationActivite  : #colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1),
         .liquidationPension : #colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1),
         .dependence         : #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1),
         .deces              : #colorLiteral(red     : 1, green     : 0.1474981606, blue     : 0, alpha     : 1)]

    /// Créer le dataset du graphique
    /// - Returns: dataset
    func getFamilyLifeEventDataSet() -> [ScatterChartDataSet] {
        var dataSets = [ScatterChartDataSet]()
        let names    = family.membersName

        func i(_ name: String) -> Int {
            names.firstIndex(of: name) ?? -2
        }

        func nameIndex(_ year            : Int,
                       _ eventNamesYears : [(name : String, year : Int?)]) -> Double {
            for element in eventNamesYears where element.year == year {
                return i(element.name).double()
            }
            return -1
        }
        
        // générer une série pour chaque événement de vie
        LifeEvent.allCases.forEach { event in // pour chaque type d'événement
            // construire la série de points: rang(nom) = f(année)
            var dataEntries = [ChartDataEntry]()
            let eventNamesYears = family.members.map {
                ($0.displayName, $0.yearOf(event: event))
            }
            for year in Date.now.year ... endDate {
                dataEntries.append(ChartDataEntry(x: year.double(),
                                                  y: nameIndex(year, eventNamesYears)))
            }
            // créer le DataSet
            let dataSet = ScatterChartDataSet(entries: dataEntries, label: event.displayString)
            dataSet.setColor(FamilyLifeEventChartView.colorsTable[event] ?? #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
            dataSet.setScatterShape(FamilyLifeEventChartView.shape[event] ?? .x)
            dataSet.drawIconsEnabled = false
            // ajouter les dataSet au dataSets
            dataSets.append(dataSet)
        }
        
        //dataSet.colors = ExpenseSummaryChartView.ColorsTable

        return dataSets
    }
    
    func drawExpenseDataChart() -> ScatterChartView {
        let chartView = ScatterChartView(title               : "Evénements",
                                         smallLegend         : true,
                                         axisFormatterChoice : .name(names: family.membersName))

        chartView.leftAxis.axisMinimum = -0.5
        chartView.leftAxis.axisMaximum = family.members.count.double() - 0.5

        //: ### BarChartData
        let dataSets = getFamilyLifeEventDataSet()
        
        // ajouter le dataset au graphique
        let data = ScatterChartData(dataSets: dataSets)
        data.setValueTextColor(ChartThemes.LightChartColors.valueColor)
        data.setValueFont(ChartThemes.ChartDefaults.valueFont)

        // ajouter le dataset au graphique
        chartView.data = data
        
        return chartView
    }
    
    func makeUIView(context: Context) -> ScatterChartView {
        drawExpenseDataChart()
    }
    
    func updateUIView(_ uiView: ScatterChartView, context: Context) {
        uiView.clear()
        //: ### BarChartData
        let dataSets = getFamilyLifeEventDataSet()
        
        // ajouter le dataset au graphique
        let data = ScatterChartData(dataSets: dataSets)
        data.setValueTextColor(ChartThemes.LightChartColors.valueColor)
        data.setValueFont(ChartThemes.ChartDefaults.valueFont)

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
