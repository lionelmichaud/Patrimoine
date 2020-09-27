//
//  CashFlowChartView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 16/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import os
import SwiftUI
import Charts // https://github.com/danielgindi/Charts.git
import Disk // https://github.com/saoudrizwan/Disk.git

fileprivate let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "UI.CashFlowChartView")

// MARK: - Cash Flow Charts Views

/// Vue globale du cash flow: Revenus / Dépenses / Net
struct CashFlowGlobalChartView: View {
    @EnvironmentObject var simulation: Simulation
    
    var body: some View {
        VStack {
            CashFlowLineChartView(socialAccounts : $simulation.socialAccounts,
                                  title          : simulation.title)
                .padding(.trailing, 4)
        }
        .navigationTitle("Cash Flow")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button(action: saveImage,
                                             label : {
                                                HStack {
                                                    Image(systemName: "square.and.arrow.down")
                                                    Text("Image")
                                                }
                                             }).capsuleButtonStyle()
        )
    }
    
    func saveImage() {
        CashFlowLineChartView.saveImage()
    }
}

/// Vue détaillée du cash flow: Revenus / Dépenses / Net
struct CashFlowDetailedChartView: View {
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState
    @State private var menuIsPresented = false
    let menuWidth: CGFloat = 200
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                /// zone de graphique
                VStack {
                    // sélecteur: Actif / Passif / Tout
                    CasePicker(pickedCase: self.$uiState.cfChartState.combination, label: "")
                        .padding(.horizontal)
                        .pickerStyle(SegmentedPickerStyle())
                    // graphique
                    CashFlowStackedBarChartView(socialAccounts: self.$simulation.socialAccounts,
                                                title         : self.simulation.title,
                                                combination   : self.uiState.cfChartState.combination,
                                                itemSelection : self.uiState.cfChartState.itemSelection)
                        .padding(.trailing, 4)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .offset(x: self.menuIsPresented ? self.menuWidth : 0)
                
                /// slide out menu de filtrage des séries à afficher
                if self.menuIsPresented {
                    MenuContentView(itemSelection: self.$uiState.cfChartState.itemSelection)
                        .frame(width: self.menuWidth)
                        .transition(.move(edge: .leading))
                }
            }
        }
        .navigationTitle("Cash Flow")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            leading: Button(
                action: {
                    withAnimation { self.menuIsPresented.toggle() }
                },
                label : {
                    HStack {
                        Image(systemName: self.uiState.cfChartState.itemSelection.allCategoriesSelected() ?
                                "line.horizontal.3.decrease.circle" : "line.horizontal.3.decrease.circle.fill")
                        Text("Filtrer")
                    }
                } ).capsuleButtonStyle(),
            trailing: Button(
                action: saveImage,
                label : {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Image")
                    }
                } ).capsuleButtonStyle()
        )
    }
    
    func saveImage() {
        CashFlowStackedBarChartView.saveImage()
    }
}

// MARK: - Wrappers de UIView

/// Wrapper de LineChartView
struct CashFlowLineChartView: UIViewRepresentable {
    @Binding var socialAccounts : SocialAccounts
    var title                   : String
    static var titleStatic      : String = "image"
    static var uiView           : LineChartView?
    static var snapshotNb       : Int = 0

    internal init(socialAccounts : Binding<SocialAccounts>, title: String) {
        CashFlowLineChartView.titleStatic = title
        self.title            = title
        self._socialAccounts  = socialAccounts
    }
    
    /// Sauvegarde de l'image en fichier  et dans l'album photo au format .PNG
    static func saveImage() {
        guard CashFlowLineChartView.uiView != nil else {
            #if DEBUG
            print("error: nothing to save")
            #endif
           return
        }
        // construire l'image
        guard let image = CashFlowLineChartView.uiView!.getChartImage(transparent: false) else {
            #if DEBUG
            print("error: nothing to save")
            #endif
            return
        }

        // sauvegarder l'image dans l'album photo
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)

        // sauvegarder l'image dans le répertoire documents/image
        let fileName = "CashFlow-" + String(CashFlowLineChartView.snapshotNb) + ".png"
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
        CashFlowLineChartView.snapshotNb += 1
    }
    
    func makeUIView(context: Context) -> LineChartView {
        // créer et configurer un nouveau graphique
        let chartView = LineChartView(title: "Revenu / Dépense")
        
        // créer les DataSet: LineChartDataSets
        let dataSets = socialAccounts.getCashFlowLineChartDataSets()
        
        // ajouter les DataSet au Chartdata
        let data = LineChartData(dataSets: dataSets)
        data.setValueTextColor(ChartThemes.DarkChartColors.valueColor)
        data.setValueFont(NSUIFont(name: "HelveticaNeue-Light", size: CGFloat(12.0))!)
        data.setValueFormatter(DefaultValueFormatter(formatter: valueKiloFormatter))
        
        // ajouter le Chartdata au ChartView
        chartView.data = data
        //chartView.data?.notifyDataChanged()
        //chartView.notifyDataSetChanged()
        
        // animer la transition
        chartView.animate(yAxisDuration: 0.5, easingOption: .linear)
        
        // mémoriser la référence de la vue pour sauvegarde d'image ultérieure
        CashFlowLineChartView.uiView = chartView
        return chartView
    }
    
    func updateUIView(_ uiView: LineChartView, context: Context) {
    }
}

/// Wrapper de BarChartView
struct CashFlowStackedBarChartView: UIViewRepresentable {
    
    // type properties
    
    static var titleStatic      : String = "image"
    static var uiView           : BarChartView?
    static var snapshotNb       : Int = 0
    
    // properties
    
    @Binding var socialAccounts : SocialAccounts
    var title                   : String
    var combination             : SocialAccounts.CashCombination
    var itemSelectionList       : ItemSelectionList

    // initializers
    
    internal init(socialAccounts : Binding<SocialAccounts>,
                  title          : String,
                  combination    : SocialAccounts.CashCombination,
                  itemSelection  : ItemSelectionList) {
        CashFlowStackedBarChartView.titleStatic = title
        self.title             = title
        self.combination       = combination
        self.itemSelectionList = itemSelection
        self._socialAccounts   = socialAccounts
    }
    
    // type methods
    
    /// Sauvegarde de l'image en fichier  et dans l'album photo au format .PNG
    static func saveImage() {
        guard CashFlowStackedBarChartView.uiView != nil else {
            #if DEBUG
            print("error: nothing to save")
            #endif
            return
        }
        // construire l'image
        guard let image = CashFlowStackedBarChartView.uiView!.getChartImage(transparent: false) else {
            #if DEBUG
            print("error: nothing to save")
            #endif
            return
        }

        // sauvegarder l'image dans l'album photo
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)

        // sauvegarder l'image dans le répertoire documents/image
        let fileName = "CashFlow-detailed-" + String(CashFlowStackedBarChartView.snapshotNb) + ".png"
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
        CashFlowStackedBarChartView.snapshotNb += 1
    }
    
    // methods
    
   /// Création de la vue du Graphique
    /// - Parameter context:
    /// - Returns: Graphique View
    func makeUIView(context: Context) -> BarChartView {
        // créer et configurer un nouveau bar graph
        let chartView = BarChartView(title: "Revenus / Dépenses")

        //: ### BarChartData
        let dataSet = socialAccounts.getCashFlowStackedBarChartDataSet(
            combination      : combination,
            itemSelectionList: itemSelectionList)
        
        // ajouter les data au graphique
        let data = BarChartData(dataSet: dataSet)
        //data.addDataSet(dataSet)
        data.setValueTextColor(ChartThemes.DarkChartColors.valueColor)
        data.setValueFont(NSUIFont(name: "HelveticaNeue-Light", size: CGFloat(12.0))!)
        data.setValueFormatter(DefaultValueFormatter(formatter: valueKiloFormatter))
        
        // ajouter le dataset au graphique
        chartView.data = data
        
        chartView.animate(yAxisDuration: 0.5, easingOption: .linear)
        CashFlowStackedBarChartView.uiView = chartView
        return chartView
    }
    
    /// Mise à jour de la vue du Graphique
    /// - Parameters:
    ///   - uiView: Graphique View
    ///   - context:
    func updateUIView(_ uiView: BarChartView, context: Context) {
        uiView.clear()
        //uiView.data?.clearValues()
        
        //: ### BarChartData
        let aDataSet : BarChartDataSet?
        if itemSelectionList.onlyOneCategorySelected() {
            // il y a un seule catégorie de sélectionnée, afficher le détail
            if let categoryName = itemSelectionList.firstCategorySelected() {
                aDataSet = socialAccounts.getCashFlowCategoryStackedBarChartDataSet(categoryName: categoryName)
            } else {
                customLog.log(level: .error,
                              "CashFlowStackedBarChartView : aDataSet = nil => graphique vide")
                aDataSet = nil
            }
        } else {
            // il y a plusieurs catégories sélectionnées, afficher le graphe résumé par catégorie
            aDataSet = socialAccounts.getCashFlowStackedBarChartDataSet(
                combination       : combination,
                itemSelectionList : itemSelectionList)
        }
        
        // ajouter les data au graphique
        let data = BarChartData(dataSet: ((aDataSet == nil ? BarChartDataSet() : aDataSet)!))
        data.setValueTextColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
        data.setValueFont(NSUIFont(name: "HelveticaNeue-Light", size: CGFloat(12.0))!)
        data.setValueFormatter(DefaultValueFormatter(formatter: valueKiloFormatter))
        
        // ajouter le dataset au graphique
        uiView.data = data
        
        uiView.data?.notifyDataChanged()
        uiView.notifyDataSetChanged()
    }
}


struct CashFlowChartView_Previews: PreviewProvider {
    static var simulation = Simulation()
    
    static var previews: some View {
        NavigationView {
            CashFlowGlobalChartView()
                .environmentObject(simulation)
        }
    }
}
