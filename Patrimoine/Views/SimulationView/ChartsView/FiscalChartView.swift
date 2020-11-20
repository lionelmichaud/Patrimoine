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

fileprivate let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "UI.FiscalChartView")

// MARK: - Fiscalité Charts Views

/// Vue globale du cash flow: Revenus / Dépenses / Net
struct FiscalChartView: View {
    @EnvironmentObject var simulation: Simulation
    
    var body: some View {
        VStack {
            IrppParamLineChartView(socialAccounts : $simulation.socialAccounts,
                              title               : simulation.title)
            IrppLineChartView(socialAccounts      : $simulation.socialAccounts,
                                  title           : simulation.title)
        }
        .padding(.trailing, 4)
        .navigationTitle("Fiscalité")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button(action: saveImage,
                                             label : {
                                                HStack {
                                                    Image(systemName: "square.and.arrow.up")
                                                    Text("Image")
                                                }
                                             }).capsuleButtonStyle()
        )
    }
    
    func saveImage() {
        IrppParamLineChartView.saveImage()
    }
}

/// Wrapper de LineChartView
struct IrppParamLineChartView: UIViewRepresentable {
    @Binding var socialAccounts : SocialAccounts
    var title                   : String
    static var titleStatic      : String = "image"
    static var uiView           : LineChartView?
    static var snapshotNb       : Int = 0
    
    internal init(socialAccounts : Binding<SocialAccounts>, title: String) {
        IrppParamLineChartView.titleStatic = title
        self.title                    = title
        self._socialAccounts          = socialAccounts
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
        let fileName = "Fiscalité-" + String(IrppParamLineChartView.snapshotNb) + ".png"
        do {
            try Disk.save(image, to: .documents, as: Config.imagePath(titleStatic) + fileName)
            // impression debug
            #if DEBUG
            Swift.print("saving image to file: ", Config.imagePath(titleStatic) + fileName)
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
        IrppParamLineChartView.snapshotNb += 1
    }
    
    func makeUIView(context: Context) -> LineChartView {
        // créer et configurer un nouveau graphique
        let chartView = LineChartView(title               : "Paramètres Imposition",
                                      axisFormatterChoice : .percent)
        
        // créer les DataSet: LineChartDataSets
        let dataSets = socialAccounts.getIrppCoefLineChartDataSets()
        
        // ajouter les DataSet au Chartdata
        let data = LineChartData(dataSets: dataSets)
        data.setValueTextColor(ChartThemes.DarkChartColors.valueColor)
        data.setValueFont(NSUIFont(name: "HelveticaNeue-Light", size: CGFloat(12.0))!)
        data.setValueFormatter(DefaultValueFormatter(formatter: decimalX100IntegerFormatter))
        
        // ajouter le Chartdata au ChartView
        chartView.data = data
        
        // animer la transition
        chartView.animate(yAxisDuration: 0.5, easingOption: .linear)
        
        // mémoriser la référence de la vue pour sauvegarde d'image ultérieure
        IrppParamLineChartView.uiView = chartView
        return chartView
    }
    
    func updateUIView(_ uiView: LineChartView, context: Context) {
    }
}

/// Wrapper de LineChartView
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
        let fileName = "Fiscalité-" + String(IrppLineChartView.snapshotNb) + ".png"
        do {
            try Disk.save(image, to: .documents, as: Config.imagePath(titleStatic) + fileName)
            // impression debug
            #if DEBUG
            Swift.print("saving image to file: ", Config.imagePath(titleStatic) + fileName)
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
        IrppLineChartView.snapshotNb += 1
    }
    
    func makeUIView(context: Context) -> LineChartView {
        // créer et configurer un nouveau graphique
        let chartView = LineChartView(title               : "Imposition",
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

