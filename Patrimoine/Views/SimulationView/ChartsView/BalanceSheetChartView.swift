//
//  BalanceSheetChartView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 12/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import os
import SwiftUI
import Charts // https://github.com/danielgindi/Charts.git
import Disk // https://github.com/saoudrizwan/Disk.git

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "UI.BalanceSheetChartView")

// MARK: - Balance Sheet Charts Views

/// Vue globale du bilan: Actif / Passif / Net
struct BalanceSheetGlobalChartView: View {
    @EnvironmentObject var simulation: Simulation
    @State private var showInfoPopover = false
    let popOverTitle   = "Contenu du graphique:"
    let popOverMessage =
        """
        Evolution dans le temps des valeurs de l'ensemble des biens (actif et passif).
        détenus par l'ensemble des membres de la famille.

        Evolution du solde net.
        """
    
    var body: some View {
        VStack {
            BalanceSheetLineChartView(socialAccounts: $simulation.socialAccounts,
                                      title         : simulation.title)
                .padding(.trailing, 4)
        }
        .navigationTitle("Bilan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // sauvergarder l'image dans l'album photo
            ToolbarItem(placement: .automatic) {
                Button(action: BalanceSheetLineChartView.saveImage,
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

/// Vue détaillée du bilan: Actif / Passif / Tout
struct BalanceSheetDetailedChartView: View {
    @EnvironmentObject var family     : Family
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState
    @State private var menuIsPresented = false
    let menuWidth: CGFloat = 200
    @State private var showInfoPopover = false
    let popOverTitle   = "Contenu du graphique:"
    let popOverMessage =
        """
        Evolution dans le temps des valeurs de l'ensemble des biens (actif et passif) détenus
        par l'ensemble des membres de la famille ou par un individu en particulier.

        Détail par catégorie d'actif / passif.
        Utiliser la loupe 🔍 pour filtrer les catégories d'actif / passif.

        Lorsqu'un seul individu est sélectionné, les actifs sont évalués selon une méthode
        et selon un filtre définis dans les préférences ⚙️.

        Evolution du solde net.
        """

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                /// zone de graphique
                VStack {
                    // sélecteur: Membre de la famille / Tous
                    Picker(selection: self.$uiState.bsChartState.nameSelection, label: Text("Personne")) {
                        ForEach(family.members.sorted(by: < )) { person in
                            PersonNameRow(member: person)
                        }
                        Text(AppSettings.shared.allPersonsLabel)
                            .tag(AppSettings.shared.allPersonsLabel)
                    }
                    .padding(.horizontal)
                    .pickerStyle(SegmentedPickerStyle())
                    
                    // sélecteur: Actif / Passif / Tout
                    CasePicker(pickedCase: self.$uiState.bsChartState.combination, label: "")
                        .padding(.horizontal)
                        .pickerStyle(SegmentedPickerStyle())
                    
                    // graphique
                    BalanceSheetStackedBarChartView(for           : self.uiState.bsChartState.nameSelection,
                                                    socialAccounts: self.$simulation.socialAccounts,
                                                    title         : self.simulation.title,
                                                    combination   : self.uiState.bsChartState.combination,
                                                    itemSelection : self.uiState.bsChartState.itemSelection)
                        .padding(.trailing, 4)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .offset(x: self.menuIsPresented ? self.menuWidth : 0)
                
                /// slide out menu de filtrage des séries à afficher
                if self.menuIsPresented {
                    MenuContentView(itemSelection: self.$uiState.bsChartState.itemSelection)
                        .frame(width: self.menuWidth)
                        .transition(.move(edge: .leading))
                }
            }
        }
        .navigationTitle("Bilan détaillé")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            //  menu slideover de filtrage
            ToolbarItem(placement: .navigation) {
                Button(action: { withAnimation { self.menuIsPresented.toggle() } },
                       label: {
                        if self.uiState.bsChartState.itemSelection.allCategoriesSelected() {
                            Image(systemName: "magnifyingglass.circle")
                        } else {
                            Image(systemName: "magnifyingglass.circle.fill")
                        }
                       })//.capsuleButtonStyle()
            }
            // sauvergarder l'image dans l'album photo
            ToolbarItem(placement: .automatic) {
                Button(action: BalanceSheetStackedBarChartView.saveImage,
                       label : { Image(systemName: "camera.circle") })
            }
            // afficher info-bulle
            ToolbarItem(placement: .automatic) {
                Button(action: { self.showInfoPopover = true },
                       label : {
                        Image(systemName: "info.circle")//.font(.largeTitle)
                       })
                    .popover(isPresented: $showInfoPopover) {
                        PopOverContentView(title       : popOverTitle,
                                           description : popOverMessage)
                    }
            }
        }
    }
}

// MARK: - Wrappers de UIView

/// Wrapper de LineChartView
struct BalanceSheetLineChartView: UIViewRepresentable {
    @Binding var socialAccounts: SocialAccounts
    var title                   : String
    static var titleStatic      : String = "image"
    static var uiView           : LineChartView?
    static var snapshotNb       : Int = 0

    internal init(socialAccounts : Binding<SocialAccounts>, title: String) {
        BalanceSheetLineChartView.titleStatic = title
        self.title            = title
        self._socialAccounts  = socialAccounts
    }

    /// Sauvegarde de l'image en fichier  et dans l'album photo au format .PNG
    static func saveImage() {
        guard BalanceSheetLineChartView.uiView != nil else {
            #if DEBUG
            print("error: nothing to save")
            #endif
            return
        }
        // construire l'image
        guard let image = BalanceSheetLineChartView.uiView!.getChartImage(transparent: false) else {
            #if DEBUG
            print("error: nothing to save")
            #endif
            return
        }

        // sauvegarder l'image dans l'album photo
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)

        // sauvegarder l'image dans le répertoire documents/image
        let fileName = "Bilan-" + String(BalanceSheetLineChartView.snapshotNb) + ".png"
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
        BalanceSheetLineChartView.snapshotNb += 1
    }
    
    func makeUIView(context: Context) -> LineChartView {
        // créer et configurer un nouveau graphique
        let chartView = LineChartView(title               : "Actif/Passif",
                                      smallLegend         : false,
                                      axisFormatterChoice : .largeValue(appendix: "€", min3Digit: true))
        
        // créer les DataSet: LineChartDataSets
        let dataSets = socialAccounts.getBalanceSheetLineChartDataSets()
        
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
        BalanceSheetLineChartView.uiView = chartView
        return chartView
    }
    
    func updateUIView(_ uiView: LineChartView, context: Context) {
    }
}

/// Wrapper de BarChartView
struct BalanceSheetStackedBarChartView: UIViewRepresentable {
    
    // type properties
    
    static var titleStatic      : String = "image"
    static var uiView           : BarChartView?
    static var snapshotNb       : Int = 0

    // properties
    
    @Binding var socialAccounts : SocialAccounts
    var title                   : String
    var combination             : SocialAccounts.AssetLiabilitiesCombination
    var personSelection         : String
    var itemSelectionList       : ItemSelectionList

    // initializers
    
    internal init(for thisName   : String,
                  socialAccounts : Binding<SocialAccounts>,
                  title          : String,
                  combination    : SocialAccounts.AssetLiabilitiesCombination,
                  itemSelection  : ItemSelectionList) {
        BalanceSheetStackedBarChartView.titleStatic = title
        self.title             = title
        self.combination       = combination
        self.personSelection   = thisName
        self.itemSelectionList = itemSelection
        self._socialAccounts   = socialAccounts
    }
    
    // type methods
    
    /// Sauvegarde de l'image en fichier  et dans l'album photo au format .PNG
    static func saveImage() {
        guard BalanceSheetStackedBarChartView.uiView != nil else {
            #if DEBUG
            print("error: nothing to save")
            #endif
            return
        }
        // construire l'image
        guard let image = BalanceSheetStackedBarChartView.uiView!.getChartImage(transparent: false) else {
            #if DEBUG
            print("error: nothing to save")
            #endif
            return
        }

        // sauvegarder l'image dans l'album photo
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)

        // sauvegarder l'image dans le répertoire documents/image
        let fileName = "Bilan-detailed-" + String(BalanceSheetStackedBarChartView.snapshotNb) + ".png"
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
        BalanceSheetStackedBarChartView.snapshotNb += 1
    }
    
    // methods
    
    /// Création de la vue du Graphique
    /// - Parameter context:
    /// - Returns: Graphique View
    func makeUIView(context: Context) -> BarChartView {
        // créer et configurer un nouveau bar graphique
        let chartView = BarChartView(title               : "Actif / Passif",
                                     axisFormatterChoice : .largeValue(appendix: "€", min3Digit: true))
        
        // créer le DataSet: BarChartDataSet
        let dataSet = socialAccounts.getBalanceSheetStackedBarChartDataSet(
            personSelection   : personSelection,
            combination       : combination,
            itemSelectionList : itemSelectionList)
        
        // ajouter les DataSet au Chartdata
        let data = BarChartData(dataSet: dataSet)
        data.setValueTextColor(ChartThemes.DarkChartColors.valueColor)
        data.setValueFont(UIFont(name:"HelveticaNeue-Light", size:12)!)
        data.setValueFormatter(DefaultValueFormatter(formatter: valueKiloFormatter))
        
        // ajouter le Chartdata au ChartView
        chartView.data = data
//        chartView.gridBackgroundColor = NSUIColor.black // NSUIColor(red: 240/255.0, green: 240/255.0, blue: 240/255.0, alpha: 1.0) UIColor(red: 230/255, green: 126/255, blue: 34/255, alpha: 1)
        
        // animer la transition
        chartView.animate(yAxisDuration: 0.5, easingOption: .linear)
        
        // mémoriser la référence de la vue pour sauvegarde d'image ultérieure
        BalanceSheetStackedBarChartView.uiView = chartView
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
                aDataSet = socialAccounts.getBalanceSheetCategoryStackedBarChartDataSet(
                    personSelection : personSelection,
                    categoryName    : categoryName)
            } else {
                customLog.log(level : .error,
                              "getBalanceSheetCategoryStackedBarChartDataSet : aDataSet = nil => graphique vide")
                aDataSet = nil
            }
        } else {
            // il y a plusieurs catégories sélectionnées, afficher le graphe résumé par catégorie
            aDataSet = socialAccounts.getBalanceSheetStackedBarChartDataSet(
                personSelection   : personSelection,
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

// MARK: - Preview

struct BalanceSheetChartView_Previews: PreviewProvider {
    static var simulation = Simulation()
    
    static var previews: some View {
        NavigationView {
            BalanceSheetGlobalChartView()
                .environmentObject(simulation)
            BalanceSheetDetailedChartView()
                .environmentObject(simulation)
        }
    }
}
