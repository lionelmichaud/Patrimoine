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
    @State private var minX  : Double = 0.0
    @State private var maxX  : Double = 10.0
    @State private var alpha : Double = 2.0
    @State private var beta  : Double = 2.0
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
                               step              : 0.1,
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
                               step              : 0.1,
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
                               step              : 0.1,
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
                               step              : 0.1,
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

    /// fonction gamma
//    let yVals1 = functionSampler(minX: minX, maxX: maxX, nbSamples: nbSamples, f: tgamma).map {
    //        ChartDataEntry(x: $0.x, y: $0.y)
    //    }

    /// générateur de nombre aléatoire suivant une distribution Beta
    var betaGenerator = BetaRG(minX  : minX,
                               maxX  : maxX,
                               alpha : alpha,
                               beta  : beta)
    
    /// PDF de la distribution Beta(alpha,beta)
    let yVals1 = functionSampler(minX      : minX,
                                 maxX      : maxX,
                                 nbSamples : nbSamples,
                                 f         : betaGenerator.pdf).map {
                                    ChartDataEntry(x: $0.x, y: $0.y)
                                 }
    
    /// CDF de la distribution Beta(alpha,beta)
    var yVals2 = [ChartDataEntry]()
    let betaCdfCurve = betaGenerator.cdfCurve(length: nbSamples)
    betaCdfCurve.forEach { point in
        yVals2.append(ChartDataEntry(x: point.x, y: point.y))
    }

    /// Histogramme des tirages aléatoires
    var yVals3 = [ChartDataEntry]()
    let nbRandomSamples = 10000
    let sequence = betaGenerator.sequence(of: nbRandomSamples)
    var histogram = Histogram(Xmin: minX, Xmax: maxX, bucketNb: 100)
    sequence.forEach {
        histogram.record($0)
    }
    histogram.xCountsNormalized.forEach {
        yVals3.append(ChartDataEntry(x: $0.x, y: Double($0.n)))
    }

    let set1 = LineChartDataSet(entries: yVals1,
                                label: "PDF de Beta (\(alpha), \(beta))",
                                color: #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1))
    let set2 = LineChartDataSet(entries: yVals2,
                                label: "CDF de Beta (\(alpha), \(beta))",
                                color: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
    let set3 = LineChartDataSet(entries: yVals3,
                                label: "Histogramme des tirages aléatoires",
                                color: #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1))


//    let betaDistrib = BetaDistribution(minX  : minX,
//                                       maxX  : maxX,
//                                       alpha : alpha,
//                                       beta  : beta)
//
//    /// pdf de la distribution Beta(alpha,beta)
//    let yVals2 = functionSampler(minX      : minX,
//                                 maxX      : maxX,
//                                 nbSamples : nbSamples,
//                                 f         : betaDistrib.pdf).map {
//                                    ChartDataEntry(x: $0.x, y: $0.y)
//                                 }
    
//    /// cdf de la distribution Beta(alpha,beta)
//    var yVals3 = [ChartDataEntry]()
//    let betaCdfCurve = betaDistrib.cdfCurve(length: nbSamples)
//    betaCdfCurve.forEach { point in
//        yVals3.append(ChartDataEntry(x: point.x, y: point.y))
//    }
//
//    let set1 = LineChartDataSet(entries: yVals1,
//                                label: "Gamma function",
//                                color: #colorLiteral(red        : 0.4666666687, green        : 0.7647058964, blue        : 0.2666666806, alpha        : 1))
//    let set2 = LineChartDataSet(entries: yVals2,
//                                label: "PDF de Beta (\(alpha), \(beta))",
//                                color: #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1))
//    let set3 = LineChartDataSet(entries: yVals3,
//                                label: "CDF de Beta (\(alpha), \(beta))",
//                                color: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
//
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
