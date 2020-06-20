//
//  ExpenseSummaryView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 01/06/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import Charts // https://github.com/danielgindi/Charts.git

struct ExpenseSummaryView: View {
    @EnvironmentObject var family  : Family
    @EnvironmentObject var uiState : UIState
    let minDate = Date.now.year
    let maxDate = Date.now.year + 40
    
    var body: some View {
        VStack {
            // évaluation annuelle des dépenses
            HStack {
                Text("Evaluation en ") + Text(String(Int(uiState.expenseViewState.evalDate)))
                Slider(value : $uiState.expenseViewState.evalDate,
                       in    : minDate.double() ... maxDate.double(),
                       step  : 1,
                       onEditingChanged: {_ in
                })
                Text(self.family.expenses.value(atEndOf: Int(self.uiState.expenseViewState.evalDate)).euroString)
            }
            // graphique
            .padding(.horizontal)
            ExpenseSummaryChartView(endDate  : uiState.expenseViewState.endDate,
                                    evalDate : uiState.expenseViewState.evalDate)
                .padding()
                .navigationBarTitle(Text("Résumé"), displayMode: .inline)
            // paramétrage du graphique
            HStack {
                Text(String(minDate))
                Slider(value : $uiState.expenseViewState.endDate,
                       in    : minDate.double() ... maxDate.double(),
                       step  : 5,
                       onEditingChanged: {
                        print("\($0)")
                })
                Text(String(Int(uiState.expenseViewState.endDate)))
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}

// MARK: - Wrappers de UIView

/// Wrapper de HorizontalBarChartView
struct ExpenseSummaryChartView: UIViewRepresentable {
    @EnvironmentObject var family : Family
    let endDate  : Double
    let evalDate : Double


    static let ColorsTable: [NSUIColor] = [UIColor(white: 1, alpha: 0),#colorLiteral(red: 0.9686274529, green: 0.78039217, blue: 0.3450980484, alpha: 1)]
    
    /// Créer le dataset du graphique
    /// - Returns: dataset
    func getExpenseDataSet(formatter    : ExpenseCateroryValueFormatter,
                           baloonMarker : ExpenseMarkerView) -> BarChartDataSet {
        var dataEntries = [ChartDataEntry]()
        let dataSet : BarChartDataSet
        
        // pour chaque categorie de dépense
        //for _ in ExpenseCategory.allCases {
        // pour chaque dépense
        //  chercher le nom de la dépense
        //  chercher la position de la dépense dans le tableau des dépense
        //  chercher les dates de début et de fin
        let namedValuedTimeFrameTable = family.expenses.namedValuedTimeFrameTable()
        
        // mettre à jour les noms des dépenses dans le formatteur de l'axe X
        formatter.names = namedValuedTimeFrameTable.map { (name, value, prop, idx, firstYearDuration) in
            name
        }
        
        // mettre à jour les valeurs des dépenses dans le formatteur de bulle d'info
        baloonMarker.amounts = namedValuedTimeFrameTable.map { (name, value, prop, idx, firstYearDuration) in
            value
        }
        baloonMarker.prop = namedValuedTimeFrameTable.map { (name, value, prop, idx, firstYearDuration) in
            prop
        }
       baloonMarker.firstYearDuration = namedValuedTimeFrameTable.map { (name, value, prop, idx, firstYearDuration) in
            firstYearDuration
        }

        // générer les 2 séries pour chaque dépense
        dataEntries += namedValuedTimeFrameTable.map { (name, value, prop, idx, firstYearDuration) in
            BarChartDataEntry(x       : idx.double(),
                              yValues : firstYearDuration.map{$0.double()})
        }
        
        //}
        dataSet = BarChartDataSet(entries : dataEntries)
        dataSet.colors           = ExpenseSummaryChartView.ColorsTable
        dataSet.drawIconsEnabled = false
        
        return dataSet
    }
    
    func drawExpenseDataChart() -> HorizontalBarChartView {
        let chartView = HorizontalBarChartView()
        
        //: ### General
        chartView.pinchZoomEnabled          = true
        chartView.doubleTapToZoomEnabled    = true
        chartView.dragEnabled               = true
        chartView.drawGridBackgroundEnabled = true
        chartView.gridBackgroundColor       = ChartThemes.LightChartColors.gridBackgroundColor
        chartView.backgroundColor           = ChartThemes.LightChartColors.backgroundColor
        chartView.borderColor               = ChartThemes.LightChartColors.borderColor
        chartView.borderLineWidth           = 1.0
        chartView.drawBordersEnabled        = false
        chartView.drawValueAboveBarEnabled  = false
        chartView.drawBarShadowEnabled      = false
        chartView.fitBars                   = true
        chartView.highlightFullBarEnabled   = false
        //chartView.maxVisibleCount = 60
        
        //: ### xAxis value formatter
        let xAxisValueFormatter = ExpenseCateroryValueFormatter()

        //: ### xAxis
        let xAxis = chartView.xAxis
        xAxis.drawAxisLineEnabled  = true
        xAxis.labelPosition        = .bottom
        xAxis.labelFont            = ChartThemes.ChartDefaults.labelFont
        xAxis.granularityEnabled   = false
        xAxis.granularity          = 1
        xAxis.labelCount           = 200
        xAxis.drawGridLinesEnabled = false
        xAxis.drawAxisLineEnabled  = true
        xAxis.valueFormatter       = xAxisValueFormatter
        //xAxis.wordWrapEnabled      = true
        //xAxis.wordWrapWidthPercent = 0.5
        //xAxis.axisMinimum         = 0
        
        //: ### LeftAxis
        let leftAxis = chartView.leftAxis
        leftAxis.enabled              = true
        leftAxis.drawAxisLineEnabled  = true
        leftAxis.drawGridLinesEnabled = true
        leftAxis.gridColor            = ChartThemes.LightChartColors.gridColor
        leftAxis.labelFont            = ChartThemes.ChartDefaults.labelFont
        leftAxis.granularityEnabled   = true // autoriser la réducion du nombre de label
        leftAxis.granularity          = 1    // à utiliser sans dépasser .labelCount
        leftAxis.labelCount           = 15   // nombre maxi
        leftAxis.axisMinimum          = Date.now.year.double()
        leftAxis.axisMaximum          = endDate
        
        //: ### RightAxis
        let rightAxis = chartView.rightAxis
        rightAxis.enabled              = true
        rightAxis.drawAxisLineEnabled  = true
        rightAxis.drawGridLinesEnabled = false
        rightAxis.labelFont            = ChartThemes.ChartDefaults.labelFont
        rightAxis.granularityEnabled   = true // autoriser la réducion du nombre de label
        rightAxis.granularity          = 1    // à utiliser sans dépasser .labelCount
        rightAxis.labelCount           = 15   // nombre maxi
        rightAxis.axisMinimum          = Date.now.year.double()
        rightAxis.axisMaximum          = endDate
        
        //: ### Legend
        let legend = chartView.legend
        legend.enabled             = false
        legend.font                = ChartThemes.ChartDefaults.legendFont
        legend.form                = .square
        legend.formSize            = 8
        legend.drawInside          = false
        legend.horizontalAlignment = .left
        legend.verticalAlignment   = .bottom
        legend.orientation         = .horizontal
        legend.xEntrySpace         = 4
        
        //: ## bulle d'info
        let marker = ExpenseMarkerView(color              : ChartThemes.BallonColors.color,
                                       font               : ChartThemes.ChartDefaults.baloonfont,
                                       textColor          : ChartThemes.BallonColors.textColor,
                                       insets             : UIEdgeInsets(top: 8, left: 8, bottom: 20, right: 8),
                                       xAxisValueFormatter: chartView.xAxis.valueFormatter!,
                                       yAxisValueFormatter: chartView.leftAxis.valueFormatter!)
        marker.chartView = chartView
        marker.minimumSize = CGSize(width: 80, height: 40)
        chartView.marker = marker

        
        chartView.fitBars = true
        
        //: ### BarChartData
        let dataSet = getExpenseDataSet(formatter: xAxisValueFormatter,
                                        baloonMarker: marker)
        
        // ajouter le dataset au graphique
        let data = BarChartData(dataSet: dataSet)
        
        data.setValueTextColor(ChartThemes.LightChartColors.valueColor)
        data.setValueFont(ChartThemes.ChartDefaults.valueFont)
        data.barWidth = 0.5
        
        chartView.data = data
        //chartView.animate(xAxisDuration: 1.0)
        
        return chartView
    }
    
    func makeUIView(context: Context) -> HorizontalBarChartView {
        drawExpenseDataChart() 
    }
    
    func updateUIView(_ uiView: HorizontalBarChartView, context: Context) {
        uiView.clear()
        //: ### BarChartData
        let dataSet = getExpenseDataSet(formatter    : uiView.xAxis.valueFormatter as! ExpenseCateroryValueFormatter,
                                        baloonMarker : uiView.marker as! ExpenseMarkerView)
        
        // ajouter le dataset au graphique
        let data = BarChartData(dataSet: dataSet)
        
        data.setValueTextColor(ChartThemes.LightChartColors.valueColor)
        data.setValueFont(ChartThemes.ChartDefaults.valueFont)
        data.barWidth = 0.5

        // mettre à joure en fonction de la position du slider de plage de temps à afficher
        uiView.leftAxis.axisMaximum  = endDate
        uiView.rightAxis.axisMaximum = endDate
        
        // mettre à joure en fonction de la position du slider de date d'évaluation
        let ll1 = ChartLimitLine(limit: evalDate+0.5, label: "date d'évaluation")
        ll1.lineWidth = 2
        ll1.lineDashLengths = [10, 10]
        ll1.labelPosition = .bottomRight
        ll1.valueFont = .systemFont(ofSize: 10)
        uiView.leftAxis.removeAllLimitLines()
        uiView.leftAxis.addLimitLine(ll1)

        uiView.data = data
        uiView.data?.notifyDataChanged()
        uiView.notifyDataSetChanged()
    }
}

struct ExpenseSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        ExpenseSummaryView()
    }
}
