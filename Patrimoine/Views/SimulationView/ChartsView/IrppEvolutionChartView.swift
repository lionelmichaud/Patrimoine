//
//  FiscalChartView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/11/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import os
import SwiftUI
import Charts // https://github.com/danielgindi/Charts.git
import Disk // https://github.com/saoudrizwan/Disk.git

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "UI.IrppEvolutionChartView")

// MARK: - Evolution de la Fiscalité dans le temps Charts Views

struct IrppEvolutionChartView: View {
    @EnvironmentObject var simulation: Simulation
    @State private var showInfoPopover = false
    let popOverTitle   = "Contenu du graphique:"
    let popOverMessage =
        """
        Evolution dans le temps des taux d'imposition sur le revenu (IRPP).

        Evolution du revenu imposable à l'IRRP et du montant de l'IRPP.
        """

    var body: some View {
        VStack {
            IrppParamLineChartView(socialAccounts : $simulation.socialAccounts,
                                   title          : simulation.title)
            IrppLineChartView(socialAccounts : $simulation.socialAccounts,
                              title          : simulation.title)
        }
        .padding(.trailing, 4)
        .navigationTitle("Evolution de la Fiscalité")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // sauvergarder l'image dans l'album photo
            ToolbarItem(placement: .automatic) {
                Button(action: saveImages,
                       label : { Image(systemName: "camera.circle") })
            }
            // afficher info-bulle
            ToolbarItem(placement: .automatic) {
                Button(action: { self.showInfoPopover = true },
                       label : {
                        Image(systemName: "info.circle")
                       })
                    .popover(isPresented: $showInfoPopover) {
                        PopOverContentView(title       : popOverTitle,
                                           description : popOverMessage)
                    }
            }
        }
    }
    
    func saveImages() {
        IrppParamLineChartView.saveImage()
        IrppLineChartView.saveImage()
    }
}

/// Wrapper de CombinedChartView: EVOLUTION dans le temps des Taux d'imposition et du Quotient familial
struct IrppParamLineChartView: UIViewRepresentable {
    @Binding var socialAccounts : SocialAccounts
    var title                   : String
    static var titleStatic      : String = "image"
    static var uiView           : CombinedChartView?
    static var snapshotNb       : Int = 0
    
    internal init(socialAccounts : Binding<SocialAccounts>, title: String) {
        IrppParamLineChartView.titleStatic = title
        self.title                         = title
        self._socialAccounts               = socialAccounts
    }
    
    /// Sauvegarde de l'image en fichier  et dans l'album photo au format .PNG
    static func saveImage() {
        guard IrppParamLineChartView.uiView != nil else {
            #if DEBUG
            print("error: nothing to save")
            #endif
            return
        }
        // construire l'image
        guard let image = IrppParamLineChartView.uiView!.getChartImage(transparent: false) else {
            #if DEBUG
            print("error: nothing to save")
            #endif
            return
        }
        
        // sauvegarder l'image dans l'album photo
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        // sauvegarder l'image dans le répertoire documents/image
        let fileName = "IRPP-Taux-" + String(IrppParamLineChartView.snapshotNb) + ".png"
        do {
            try Disk.save(image, to: .documents, as: AppSettings.imagePath(titleStatic) + fileName)
            // impression debug
            #if DEBUG
            Swift.print("saving image to file: ", AppSettings.imagePath(titleStatic) + fileName)
            #endif
        } catch let error as NSError {
            fatalError("""
                Domain         : \(error.domain)
                Code           : \(error.code)
                Description    : \(error.localizedDescription)
                Failure Reason : \(error.localizedFailureReason ?? "")
                Suggestions    : \(error.localizedRecoverySuggestion ?? "")
                """)
        }
        IrppParamLineChartView.snapshotNb += 1
    }
    
    func makeUIView(context: Context) -> CombinedChartView {
        // créer et configurer un nouveau graphique
        let chartView = CombinedChartView(title                   : "Paramètres Imposition",
                                          smallLegend             : false,
                                          leftAxisFormatterChoice : .percent)
        
        // LIGNES
        // créer les DataSet : LineChartDataSets
        let lineDataSets = socialAccounts.getIrppRatesfLineChartDataSets()
        // ajouter les DataSet au ChartData
        let lineChartData = LineChartData(dataSets: lineDataSets)
        lineChartData.setValueTextColor(ChartThemes.DarkChartColors.valueColor)
        lineChartData.setValueFont(NSUIFont(name: "HelveticaNeue-Light", size: CGFloat(12.0))!)
        lineChartData.setValueFormatter(DefaultValueFormatter(formatter: decimalX100IntegerFormatter))
        
        // BARRES
        // créer les DataSet : BarChartDataSets
        let barDataSets = socialAccounts.getfamilyQotientBarChartDataSets()
        // ajouter les DataSet au ChartData
        let barChartData = BarChartData(dataSets: barDataSets)
        barChartData.setValueTextColor(ChartThemes.DarkChartColors.valueColor)
        barChartData.setValueFont(NSUIFont(name: "HelveticaNeue-Light", size: CGFloat(12.0))!)
        barChartData.setValueFormatter(DefaultValueFormatter(formatter: decimalFormatter))
        
        // combiner les ChartData
        let data = CombinedChartData()
        data.lineData = lineChartData
        data.barData  = barChartData
//        data.bubbleData = generateBubbleData()
//        data.scatterData = generateScatterData()
//        data.candleData = generateCandleData()
        
        // ajouter le Chartdata au ChartView
        chartView.data = data
        
        // animer la transition
        chartView.animate(yAxisDuration: 0.5, easingOption: .linear)
        
        // mémoriser la référence de la vue pour sauvegarde d'image ultérieure
        IrppParamLineChartView.uiView = chartView
        return chartView
    }
    
    func updateUIView(_ uiView: CombinedChartView, context: Context) {
    }
}

/// Wrapper de LineChartView: EVOLUTION dans le temps de l'IRPP
struct IrppLineChartView: UIViewRepresentable {
    @Binding var socialAccounts : SocialAccounts
    var title                   : String
    static var titleStatic      : String = "image"
    static var uiView           : LineChartView?
    static var snapshotNb       : Int = 0
    
    internal init(socialAccounts : Binding<SocialAccounts>, title: String) {
        IrppLineChartView.titleStatic = title
        self.title                    = title
        self._socialAccounts          = socialAccounts
    }
    
    /// Sauvegarde de l'image en fichier  et dans l'album photo au format .PNG
    static func saveImage() {
        guard IrppLineChartView.uiView != nil else {
            #if DEBUG
            print("error: nothing to save")
            #endif
            return
        }
        // construire l'image
        guard let image = IrppLineChartView.uiView!.getChartImage(transparent: false) else {
            #if DEBUG
            print("error: nothing to save")
            #endif
            return
        }
        
        // sauvegarder l'image dans l'album photo
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        // sauvegarder l'image dans le répertoire documents/image
        let fileName = "IRPP-Evolution-" + String(IrppLineChartView.snapshotNb) + ".png"
        do {
            try Disk.save(image, to: .documents, as: AppSettings.imagePath(titleStatic) + fileName)
            // impression debug
            #if DEBUG
            Swift.print("saving image to file: ", AppSettings.imagePath(titleStatic) + fileName)
            #endif
        } catch let error as NSError {
            fatalError("""
                Domain         : \(error.domain)
                Code           : \(error.code)
                Description    : \(error.localizedDescription)
                Failure Reason : \(error.localizedFailureReason ?? "")
                Suggestions    : \(error.localizedRecoverySuggestion ?? "")
                """)
        }
        IrppLineChartView.snapshotNb += 1
    }
    
    func makeUIView(context: Context) -> LineChartView {
        // créer et configurer un nouveau graphique
        let chartView = LineChartView(title               : "Imposition",
                                      smallLegend         : false,
                                      axisFormatterChoice : .largeValue(appendix: "€", min3Digit: true))
        
        // créer les DataSet: LineChartDataSets
        let dataSets = socialAccounts.getIrppLineChartDataSets()
        
        // ajouter les DataSet au Chartdata
        let data = LineChartData(dataSets: dataSets)
        data.setValueTextColor(ChartThemes.DarkChartColors.valueColor)
        data.setValueFont(NSUIFont(name: "HelveticaNeue-Light", size: CGFloat(12.0))!)
        data.setValueFormatter(DefaultValueFormatter(formatter: valueKiloFormatter))
        
        // ajouter le Chartdata au ChartView
        chartView.data = data
        
        // animer la transition
        chartView.animate(yAxisDuration: 0.5, easingOption: .linear)
        
        // mémoriser la référence de la vue pour sauvegarde d'image ultérieure
        IrppLineChartView.uiView = chartView
        return chartView
    }
    
    func updateUIView(_ uiView: LineChartView, context: Context) {
    }
}
