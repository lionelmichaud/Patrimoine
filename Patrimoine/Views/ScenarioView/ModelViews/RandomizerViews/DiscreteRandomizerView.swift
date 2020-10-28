//
//  DiscreteRandomizerView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 17/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import Charts // https://github.com/danielgindi/Charts.git

struct DiscreteRandomizerView: UIViewRepresentable {
    var randomizer: ModelRandomizer<DiscreteRandomGenerator>
    static var uiView : LineChartView?
    
    func makeUIView(context: Context) -> LineChartView {
        // créer et configurer un nouveau graphique
        let chartView = LineChartView(title               : "Distribution Discrète",
                                      axisFormatterChoice : .none)
        
        // créer les DataSet: LineChartDataSets
        let dataSets = getLineChartDataSets()
        let leftAxis = chartView.leftAxis
        leftAxis.valueFormatter = AxisFormatterChoice.percent.IaxisFormatter()
        
        // ajouter les DataSet au Chartdata
        let data = LineChartData(dataSets: dataSets)
        data.setValueTextColor(ChartThemes.DarkChartColors.valueColor)
        data.setValueFont(NSUIFont(name: "HelveticaNeue-Light", size: CGFloat(12.0))!)
        
        // ajouter le Chartdata au ChartView
        chartView.data = data
        //chartView.data?.notifyDataChanged()
        //chartView.notifyDataSetChanged()
        
        // animer la transition
        chartView.animate(yAxisDuration: 0.5, easingOption: .linear)
        
        // mémoriser la référence de la vue pour sauvegarde d'image ultérieure
        DiscreteChartView.uiView = chartView
        return chartView
    }
    
    func updateUIView(_ uiView: LineChartView, context: Context) {
        uiView.clear()
        //uiView.data?.clearValues()
        
        // créer les DataSet: LineChartDataSets
        let dataSets = getLineChartDataSets()
        
        // ajouter les DataSet au Chartdata
        let data = LineChartData(dataSets: dataSets)
        data.setValueTextColor(ChartThemes.DarkChartColors.valueColor)
        data.setValueFont(NSUIFont(name: "HelveticaNeue-Light", size: CGFloat(12.0))!)
        
        // ajouter le Chartdata au ChartView
        uiView.data = data
        
        uiView.data?.notifyDataChanged()
        uiView.notifyDataSetChanged()
    }
    
    func getLineChartDataSets() -> [LineChartDataSet]? {
        var dataSets = [LineChartDataSet]()

        /// PDF de la distribution Beta(alpha,beta)
        let yVals1 = randomizer.rndGenerator.pdf.map {
                                        ChartDataEntry(x: $0.x, y: $0.y)
                                     }
        let set1 = LineChartDataSet(entries: yVals1,
                                    label: "PDF du modèle",
                                    color: #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1))
        dataSets.append(set1)

        /// CDF de la distribution Beta(alpha,beta)
        var yVals2 = [ChartDataEntry]()
        if let betaCdfCurve = randomizer.rndGenerator.cdfCurve {
            betaCdfCurve.forEach { point in
                yVals2.append(ChartDataEntry(x: point.x, y: point.y))
            }
        }
        let set2 = LineChartDataSet(entries: yVals2,
                                    label: "CDF du modèle",
                                    color: #colorLiteral(red: 0.1960784346, green: 0.3411764801, blue: 0.1019607857, alpha: 1))
        dataSets.append(set2)
        
        if let sequence = randomizer.randomHistory {
            var histogram = Histogram()
            histogram.record(sequence)
            histogram.sort(distributionType : .discrete,
                           openEnds         : false,
                           bucketNb         : 50)
            
            /// PDF des tirages aléatoires
            var yVals3 = [ChartDataEntry]()
            histogram.xPDF.forEach {
                yVals3.append(ChartDataEntry(x: $0.x, y: $0.p))
            }
            let set3 = LineChartDataSet(entries: yVals3,
                                        label: "PDF des tirages aléatoires",
                                        color: #colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1))
            dataSets.append(set3)
            
            /// CDF des tirages aléatoires
            var yVals4 = [ChartDataEntry]()
            histogram.xCDF.forEach {
                yVals4.append(ChartDataEntry(x: $0.x, y: $0.p))
            }
            let set4 = LineChartDataSet(entries: yVals4,
                                        label: "CDF des tirages aléatoires",
                                        color: #colorLiteral(red: 0.721568644, green: 0.8862745166, blue: 0.5921568871, alpha: 1))
            dataSets.append(set4)
        }
        
        return dataSets
    }

}

struct DiscreteRandomizerView_Previews: PreviewProvider {
    static var previews: some View {
        DiscreteRandomizerView(randomizer: HumanLife.model.menLifeEpectation)
    }
}
