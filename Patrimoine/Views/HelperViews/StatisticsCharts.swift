//
//  StatisticsCharts.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 27/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import Charts // https://github.com/danielgindi/Charts.git

struct StatisticsChartsView: View {
    @State private var minX  : Double = 0.1
    @State private var maxX  : Double = 10.0
    @State private var alpha : Double = 1.0
    @State private var beta  : Double = 5.0
    let minmin =  0.0
    let maxmax = 10.0
    let delta  =  0.1
    
    var body: some View {
        VStack {
            HStack {
                VStack {
                    HStack {
                        Text("\(minX, specifier: "%.1f") [")
                            .frame(width: 70)
                        Slider(value             : $minX,
                               in                : minmin...maxmax,
                               onEditingChanged  : { _ in maxX = max(minX+delta, maxX) },
                               minimumValueLabel : Text("\(minmin, specifier: "%.1f")"),
                               maximumValueLabel : Text("\(maxmax, specifier: "%.1f")"),
                               label             : {Text("Minimum")})
                    }
                    .padding(.horizontal)
                    HStack {
                        Text("\(maxX, specifier: "%.1f") ]")
                            .frame(width: 70)
                        Slider(value             : $maxX,
                               in                : minmin...maxmax,
                               onEditingChanged  : { _ in minX = min(minX, maxX-delta) },
                               minimumValueLabel : Text("\(minmin, specifier: "%.1f")"),
                               maximumValueLabel : Text("\(maxmax, specifier: "%.1f")"),
                               label             : {Text("Maximum")})
                    }
                    .padding(.horizontal)
                }
                VStack {
                    HStack {
                        Text("\(alpha, specifier: "%.1f") alpha")
                            .frame(width: 70)
                        Slider(value             : $alpha,
                               in                : 0...10,
                               minimumValueLabel : Text("\(0.0, specifier: "%.1f")"),
                               maximumValueLabel : Text("\(10.0, specifier: "%.1f")"),
                               label             : {Text("alpha")})
                    }
                    .padding(.horizontal)
                    HStack {
                        Text("\(beta, specifier: "%.1f") beta")
                            .frame(width: 70)
                        Slider(value             : $beta,
                               in                : 0...10,
                               minimumValueLabel : Text("\(0.0, specifier: "%.1f")"),
                               maximumValueLabel : Text("\(10.0, specifier: "%.1f")"),
                               label             : {Text("beta")})
                    }
                    .padding(.horizontal)
                }
            }
            BetaGammaChartView(minX  : $minX,  maxX : $maxX,
                               alpha : $alpha, beta : $beta)
        }
        .navigationTitle("Beta distribution")
        .navigationBarTitleDisplayMode(.inline)

    }
}

struct BetaGammaChartView : UIViewRepresentable {
    @Binding var minX : Double
    @Binding var maxX : Double
    @Binding var alpha: Double
    @Binding var beta : Double
    
    func makeUIView(context: Context) -> LineChartView {
        // créer et configurer un nouveau graphique
        let chartView = LineChartView(title               : "Beta distribution",
                                      axisFormatterChoice : .none)
        
        // créer les DataSet: LineChartDataSets
        let dataSets = getBetaGammaLineChartDataSets(minX : minX,  maxX: maxX,
                                                     alpha: alpha, beta: beta)
        
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
        BalanceSheetLineChartView.uiView = chartView
        return chartView
    }
    
    func updateUIView(_ uiView: LineChartView, context: Context) {
        guard maxX > minX else { return }
        uiView.clear()
        //uiView.data?.clearValues()
        
        // créer les DataSet: LineChartDataSets
        let dataSets = getBetaGammaLineChartDataSets(minX : minX,  maxX: maxX,
                                                     alpha: alpha, beta: beta)
        
        // ajouter les DataSet au Chartdata
        let data = LineChartData(dataSets: dataSets)
        data.setValueTextColor(ChartThemes.DarkChartColors.valueColor)
        data.setValueFont(NSUIFont(name: "HelveticaNeue-Light", size: CGFloat(12.0))!)
        
        // ajouter le Chartdata au ChartView
        uiView.data = data
        
        uiView.data?.notifyDataChanged()
        uiView.notifyDataSetChanged()
    }
}

func getBetaGammaLineChartDataSets(minX : Double,
                                   maxX : Double,
                                   alpha: Double,
                                   beta : Double) -> [LineChartDataSet]? {
    
    let nbSamples = 100
    
    //: ### ChartDataEntry
    var yVals1 = [ChartDataEntry]()
    var yVals2 = [ChartDataEntry]()
    var yVals3 = [ChartDataEntry]()
    
    /// fonction gamma
    yVals1 = functionSampler(minX: minX, maxX: maxX, nbSamples: nbSamples, f: tgamma).map {
        ChartDataEntry(x: $0.x, y: $0.y)
    }
    
    /// distribution Beta(2,2)
    let alpha1 = 2.0
    let beta1  = 2.0
    let betaDistrib1 = BetaDistribution(minX  : 0.0,
                                        maxX  : maxX,
                                        alpha : alpha1,
                                        beta  : beta1)
    yVals2 = functionSampler(minX: minX, maxX: maxX, nbSamples: nbSamples, f: betaDistrib1.pdf).map {
        ChartDataEntry(x: $0.x, y: $0.y)
    }
    
    /// distribution Beta(alpha,beta)
    let alpha2 = alpha
    let beta2  = beta
    let betaDistrib2 = BetaDistribution(minX  : 0.0,
                                        maxX  : maxX,
                                        alpha : alpha2,
                                        beta  : beta2)
    yVals3 = functionSampler(minX: minX, maxX: maxX, nbSamples: nbSamples, f: betaDistrib2.pdf).map {
        ChartDataEntry(x: $0.x, y: $0.y)
    }
    
    let set1 = LineChartDataSet(entries: yVals1,
                                label: "Gamma function",
                                color: #colorLiteral(red        : 0.4666666687, green        : 0.7647058964, blue        : 0.2666666806, alpha        : 1))
    let set2 = LineChartDataSet(entries: yVals2,
                                label: "Beta distribution (\(alpha1), \(beta1))",
                                color: #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1))
    let set3 = LineChartDataSet(entries: yVals3,
                                label: "Beta distribution (\(alpha2), \(beta2))",
                                color: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
    
    // ajouter les dataSet au dataSets
    var dataSets = [LineChartDataSet]()
    dataSets.append(set1)
    dataSets.append(set2)
    dataSets.append(set3)
    
    return dataSets
}

func functionSampler (minX: Double, maxX: Double, nbSamples: Int, f: (Double) -> Double) -> [(x: Double, y: Double)] {
    var xy = [(x: Double, y: Double)]()
    for i in 1...nbSamples {
        let x :Double = min(minX + (maxX - minX) / nbSamples.double() * i.double(), maxX)
        xy.append((x, f(x)))
    }
    return xy
}

struct StatisticsChartsView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsChartsView()
    }
}
