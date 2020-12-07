//
//  FiscalSliceView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 21/11/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import os
import SwiftUI
import Charts // https://github.com/danielgindi/Charts.git
import Disk // https://github.com/saoudrizwan/Disk.git

fileprivate let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "UI.FiscalSliceView")

// MARK: - Décompositon de l'impôt par tranche Charts Views

struct IrppSliceView: View {
    @EnvironmentObject var simulation: Simulation
    @EnvironmentObject var family    : Family
    @EnvironmentObject var uiState   : UIState

    var body: some View {
        VStack {
            HStack {
                Text("Evaluation en ") + Text(String(Int(uiState.fiscalChartState.evalDate)))
                Slider(value : $uiState.fiscalChartState.evalDate,
                       in    : (simulation.socialAccounts.cashFlowArray.first?.year.double())! ... (simulation.socialAccounts.cashFlowArray.last?.year.double())! - 1,
                       step  : 1,
                       onEditingChanged: {_ in
                       })
                Text(String(simulation.socialAccounts.cashFlowArray.last!.year - 1))
            }
            .padding(.horizontal)
            IrppSlicesStackedBarChartView(family         : family,
                                          socialAccounts : $simulation.socialAccounts,
                                          evalYear       : uiState.fiscalChartState.evalDate,
                                          title          : simulation.title)
        }
        .padding(.trailing, 4)
        .navigationTitle("Décomposition par tranche d'imposition")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button(action: saveImages,
                                             label : {
                                                HStack {
                                                    Image(systemName: "square.and.arrow.up")
                                                    Text("Image")
                                                }
                                             }).capsuleButtonStyle()
        )
    }
    
    func saveImages() {
        IrppSlicesStackedBarChartView.saveImage()
    }
}

/// Wrapper de BarChartView
struct IrppSlicesStackedBarChartView: UIViewRepresentable {
    
    // type properties
    
    static var titleStatic      : String = "image"
    static var uiView           : BarChartView?
    static var snapshotNb       : Int = 0
    
    // properties
    
    @Binding var socialAccounts : SocialAccounts
    var family                  : Family
    var title                   : String
    var evalYear                : Double
    
    // initializers
    
    internal init(family         : Family,
                  socialAccounts : Binding<SocialAccounts>,
                  evalYear       : Double,
                  title          : String) {
        IrppSlicesStackedBarChartView.titleStatic = title
        self.title                                = title
        self.family                               = family
        self.evalYear                             = evalYear
        self._socialAccounts                      = socialAccounts
    }
    
    // type methods
    
    /// Sauvegarde de l'image en fichier  et dans l'album photo au format .PNG
    static func saveImage() {
        guard IrppSlicesStackedBarChartView.uiView != nil else {
            #if DEBUG
            print("error: nothing to save")
            #endif
            return
        }
        // construire l'image
        guard let image = IrppSlicesStackedBarChartView.uiView!.getChartImage(transparent: false) else {
            #if DEBUG
            print("error: nothing to save")
            #endif
            return
        }
        
        // sauvegarder l'image dans l'album photo
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        // sauvegarder l'image dans le répertoire documents/image
        let fileName = "IRPP-Tranches-" + String(IrppSlicesStackedBarChartView.snapshotNb) + ".png"
        do {
            try Disk.save(image, to: .documents, as: AppSettings.imagePath(titleStatic) + fileName)
            // impression debug
            #if DEBUG
            Swift.print("saving image to file: ", AppSettings.imagePath(titleStatic) + fileName)
            #endif
        }
        catch let error as NSError {
            fatalError("""
                Domain         : \(error.domain)
                Code           : \(error.code)
                Description    : \(error.localizedDescription)
                Failure Reason : \(error.localizedFailureReason ?? "")
                Suggestions    : \(error.localizedRecoverySuggestion ?? "")
                """)
        }
        IrppSlicesStackedBarChartView.snapshotNb += 1
    }
    
    // methods
    
    /// Création de la vue du Graphique
    /// - Parameter context:
    /// - Returns: Graphique View
    func makeUIView(context: Context) -> BarChartView {
        // créer et configurer un nouveau bar graphique
        let chartView = BarChartView(title               : "Répartition de l'Impôt",
                                     smallLegend         : false,
                                     axisFormatterChoice : .largeValue(appendix: "€", min3Digit: true))
        
        // créer le DataSet: BarChartDataSet
        let year = Int(evalYear)
        var maxCumulatedSlices: Double = 0.0
        let dataSet = socialAccounts.getSlicedIrppBarChartDataSets(for                : year,
                                                                   maxCumulatedSlices : &maxCumulatedSlices,
                                                                   nbAdults           : family.nbOfAdultAlive(atEndOf: year),
                                                                   nbChildren         : family.nbOfFiscalChildren(during: year))
        
        // ajouter les DataSet au Chartdata
        let data = BarChartData(dataSet: dataSet)
        data.setValueTextColor(ChartThemes.DarkChartColors.valueColor)
        data.setValueFont(UIFont(name:"HelveticaNeue-Light", size:12)!)
        data.setValueFormatter(DefaultValueFormatter(formatter: valueKiloFormatter))
        
        // ajouter le Chartdata au ChartView
        chartView.data = data
        chartView.leftAxis.axisMinimum     = 0
        chartView.leftAxis.axisMaximum     = maxCumulatedSlices * 2
        chartView.xAxis.labelRotationAngle = 0
        chartView.xAxis.valueFormatter     = IrppValueFormatter()
        chartView.xAxis.labelFont          = ChartThemes.ChartDefaults.largeLegendFont

        // animer la transition
        chartView.animate(yAxisDuration: 0.5, easingOption: .linear)
        
        // mémoriser la référence de la vue pour sauvegarde d'image ultérieure
        IrppSlicesStackedBarChartView.uiView = chartView
        return chartView
    }
    
    /// Mise à jour de la vue du Graphique
    /// - Parameters:
    ///   - uiView: Graphique View
    ///   - context:
    func updateUIView(_ uiView: BarChartView, context: Context) {
        uiView.clear()

        // créer le DataSet: BarChartDataSet
        let year = Int(evalYear)
        var maxCumulatedSlices: Double = 0.0
        let dataSet = socialAccounts.getSlicedIrppBarChartDataSets(for                : year,
                                                                   maxCumulatedSlices : &maxCumulatedSlices,
                                                                   nbAdults           : family.nbOfAdultAlive(atEndOf: year),
                                                                   nbChildren         : family.nbOfFiscalChildren(during: year))
        
        // ajouter les DataSet au Chartdata
        let data = BarChartData(dataSet: dataSet)
        data.setValueTextColor(ChartThemes.DarkChartColors.valueColor)
        data.setValueFont(UIFont(name:"HelveticaNeue-Light", size:12)!)
        data.setValueFormatter(DefaultValueFormatter(formatter: valueKiloFormatter))
        
        // ajouter le dataset au graphique
        uiView.data = data
        uiView.leftAxis.axisMaximum = maxCumulatedSlices * 2

        uiView.data?.notifyDataChanged()
        uiView.notifyDataSetChanged()
    }
}
