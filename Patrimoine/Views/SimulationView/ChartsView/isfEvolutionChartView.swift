//
//  isfEvolutionChartView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 06/12/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import os
import SwiftUI
import Charts // https://github.com/danielgindi/Charts.git
import Disk // https://github.com/saoudrizwan/Disk.git

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "UI.IsfEvolutionChartView")

// MARK: - Evolution de la Fiscalité dans le temps Charts Views

struct IsfEvolutionChartView: View {
    @EnvironmentObject var simulation: Simulation
    @State private var showInfoPopover = false
    let popOverTitle   = "Contenu du graphique:"
    let popOverMessage =
        """
        Evolution dans le temps du montant de l'ISF dû.
        """

    var body: some View {
        IsfLineChartView(socialAccounts : $simulation.socialAccounts,
                         title          : simulation.title)
            .padding(.trailing, 4)
            .navigationTitle("Evolution de la Fiscalité")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // sauvergarder l'image dans l'album photo
                ToolbarItem(placement: .automatic) {
                    Button(action: IsfLineChartView.saveImage,
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
}

/// Wrapper de LineChartView: EVOLUTION dans le temps de l'ISF
struct IsfLineChartView: UIViewRepresentable {
    @Binding var socialAccounts : SocialAccounts
    var title                   : String
    static var titleStatic      : String = "image"
    static var uiView           : LineChartView?
    static var snapshotNb       : Int = 0
    
    internal init(socialAccounts : Binding<SocialAccounts>, title: String) {
        IsfLineChartView.titleStatic = title
        self.title                   = title
        self._socialAccounts         = socialAccounts
    }
    
    /// Sauvegarde de l'image en fichier  et dans l'album photo au format .PNG
    static func saveImage() {
        guard IsfLineChartView.uiView != nil else {
            #if DEBUG
            print("error: nothing to save")
            #endif
            return
        }
        // construire l'image
        guard let image = IsfLineChartView.uiView!.getChartImage(transparent: false) else {
            #if DEBUG
            print("error: nothing to save")
            #endif
            return
        }
        
        // sauvegarder l'image dans l'album photo
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        // sauvegarder l'image dans le répertoire documents/image
        let fileName = "IRPP-Evolution-" + String(IsfLineChartView.snapshotNb) + ".png"
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
        IsfLineChartView.snapshotNb += 1
    }
    
    func makeUIView(context: Context) -> LineChartView {
        // créer et configurer un nouveau graphique
        let chartView = LineChartView(title               : "Imposition sur la Fortune",
                                      smallLegend         : false,
                                      axisFormatterChoice : .largeValue(appendix: "€", min3Digit: true))
        
        // créer les DataSet: LineChartDataSets
        let dataSets = socialAccounts.getIsfLineChartDataSets()
        
        // ajouter les DataSet au Chartdata
        let data = LineChartData(dataSets: dataSets)
        data.setValueTextColor(ChartThemes.DarkChartColors.valueColor)
        data.setValueFont(NSUIFont(name: "HelveticaNeue-Light", size: CGFloat(12.0))!)
        data.setValueFormatter(DefaultValueFormatter(formatter: valueKiloFormatter))
        
        // ajouter le Chartdata au ChartView
        chartView.data = data
        chartView.rightAxis.axisMinimum = 0.0
        chartView.rightAxis.enabled = true

        // animer la transition
        chartView.animate(yAxisDuration: 0.5, easingOption: .linear)
        
        // mémoriser la référence de la vue pour sauvegarde d'image ultérieure
        IsfLineChartView.uiView = chartView
        return chartView
    }
    
    func updateUIView(_ uiView: LineChartView, context: Context) {
    }
}
