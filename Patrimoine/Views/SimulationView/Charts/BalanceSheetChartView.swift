//
//  BalanceSheetChartView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 12/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import Charts // https://github.com/danielgindi/Charts.git
import Disk // https://github.com/saoudrizwan/Disk.git

// MARK: - Balance Sheet Charts Views

/// Vue globale du bilan: Actif / Passif / Net
struct BalanceSheetGlobalChartView: View {
    @EnvironmentObject var simulation: Simulation
    
    var body: some View {
        VStack {
            BalanceSheetLineChartView(socialAccounts: $simulation.socialAccounts,
                                      title         : simulation.title)
                .padding(.trailing, 4)
        }
        .navigationTitle("Bilan")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button(action: saveImage,
                                             label : { Text("Sauver image") }))
    }
    
    func saveImage() {
        BalanceSheetLineChartView.saveImage()
    }
}

/// Vue détaillée du bilan: Actif / Passif / Tout
struct BalanceSheetDetailedChartView: View {
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
                    CasePicker(pickedCase: self.$uiState.bsChartState.combination, label: "")
                        .padding(.horizontal)
                        .pickerStyle(SegmentedPickerStyle())
                    // graphique
                    BalanceSheetStackedBarChartView(socialAccounts: self.$simulation.socialAccounts,
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
        .navigationTitle("Bilan")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            leading: Button(
                action: {
                    withAnimation { self.menuIsPresented.toggle() }
                },
                label: {
                    HStack {
                        Image(systemName: "line.horizontal.3.decrease.circle")
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
        BalanceSheetStackedBarChartView.saveImage()
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
        guard let image = BalanceSheetLineChartView.uiView!.getChartImage(transparent: false) else { return }

        // sauvegarder l'image dans l'album photo
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)

        // sauvegarder l'image dans le répertoire documents/image
        let fileName = "Bilan-" + String(BalanceSheetLineChartView.snapshotNb) + ".png"
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
        BalanceSheetLineChartView.snapshotNb += 1
    }
    
    func makeUIView(context: Context) -> LineChartView {
        let view = socialAccounts.drawBalanceSheetLineChart()
        BalanceSheetLineChartView.uiView = view
        return view
    }
    
    func updateUIView(_ uiView: LineChartView, context: Context) {
    }
}

/// Wrapper de BarChartView
struct BalanceSheetStackedBarChartView: UIViewRepresentable {
    @Binding var socialAccounts : SocialAccounts
    var title                   : String
    var combination             : SocialAccounts.AssetLiabilitiesCombination
    var itemSelection           : [(label: String, selected: Bool)]
    static var titleStatic      : String = "image"
    static var uiView           : BarChartView?
    static var snapshotNb       : Int = 0

    internal init(socialAccounts : Binding<SocialAccounts>,
                  title          : String,
                  combination    : SocialAccounts.AssetLiabilitiesCombination,
                  itemSelection  : [(label: String, selected: Bool)]) {
        BalanceSheetStackedBarChartView.titleStatic = title
        self.title           = title
        self.combination     = combination
        self.itemSelection   = itemSelection
        self._socialAccounts = socialAccounts
    }
    
    /// Sauvegarde de l'image en fichier  et dans l'album photo au format .PNG
    static func saveImage() {
        guard BalanceSheetStackedBarChartView.uiView != nil else {
            #if DEBUG
            print("error: nothing to save")
            #endif
            return
        }
        // construire l'image
        guard let image = BalanceSheetStackedBarChartView.uiView!.getChartImage(transparent: false) else { return }

        // sauvegarder l'image dans l'album photo
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)

        // sauvegarder l'image dans le répertoire documents/image
        let fileName = "Bilan-detailed-" + String(BalanceSheetStackedBarChartView.snapshotNb) + ".png"
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
        BalanceSheetStackedBarChartView.snapshotNb += 1
    }
    
    func makeUIView(context: Context) -> BarChartView {
        let view = socialAccounts.drawBalanceSheetStackedBarChart(combination  : combination,
                                                       itemSelection: itemSelection)
        BalanceSheetStackedBarChartView.uiView = view
        return view
    }
    
    func updateUIView(_ uiView: BarChartView, context: Context) {
        uiView.clear()
        //uiView.data?.clearValues()
        let dataSet = socialAccounts.getBalanceSheetStackedBarChartDataSet(combination  : combination,
                                                                           itemSelection: itemSelection)
        let data = BarChartData(dataSet: dataSet)
        data.setValueTextColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
        data.setValueFont(NSUIFont(name: "HelveticaNeue-Light", size: CGFloat(12.0))!)
        data.setValueFormatter(DefaultValueFormatter(formatter: valueKiloFormatter))
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
