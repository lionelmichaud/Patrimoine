//
//  RetirementDetailView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 25/06/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct RetirementDetailView: View {
    
    // MARK: - View Model
    
    class ViewModel: ObservableObject {
        let sam: Double = 50_000
        let lastKnownSituation = (atEndOf: 2018, nbTrimestreAcquis: 135)
        @Published var tauxDePension    : Double = 0
        @Published var dureeDeReference : Int    = 0
        @Published var dureeAssurance   : Int    = 0
        @Published var dateTauxPlein    : Date?
        @Published var nbTrimestreDecote: Int    = 0
        @Published var pensionBrute     : Double = 0
        @Published var pensionNette     : Double = 0
    }
    
    // MARK: - Properties
    
    @EnvironmentObject var member: Person
    @ObservedObject var viewModel = ViewModel()
    
    var body: some View {
        Form {
            Section(header: Text("REGIME GENERAL").font(.subheadline)) {
                AmountView(label: "Salaire annuel moyen", amount: viewModel.sam, comment: "SAM")
                AgeDateView(label: "Age du taux plein")
                IntegerView(label: "Nombre de trimestres de décote", integer: viewModel.nbTrimestreDecote)
                PercentView(label: "Taux de réversion", percent: viewModel.tauxDePension, comment: "Trev")
                IntegerView(label: "Durée d'assurance (trimestres)", integer: viewModel.dureeAssurance, comment: "Da")
                IntegerView(label: "Durée de référence (trimestres)", integer: viewModel.dureeDeReference, comment: "Dr")
                AmountView(label: "Pension annuelle brute", amount: viewModel.pensionBrute, comment: "Brut = SAM x Trev x Da/Dr")
                AmountView(label: "Pension annuelle nette", amount: viewModel.pensionNette, weight: .bold, comment: "Net = Brut - Prélev sociaux")
            }
            Section(header: Text("REGIME COMPLEMENTAIRE").font(.subheadline)) {
                EmptyView()
            }
        }
        .navigationBarTitle("Retraite", displayMode: .inline)
        .onAppear(perform: compute)
    }
    
    // MARK: - Methods
    
    func AgeDateView(label: String) -> some View {
        return HStack {
            Text(label)
            Spacer()
            if viewModel.dateTauxPlein == nil {
                EmptyView()
            } else {
                Text(mediumDateFormatter.string(from: viewModel.dateTauxPlein!))
            }
        }
    }
    
    func compute() {
        guard let nbTrimestreDecote =
            Pension.model.regimeGeneral.nbTrimestreDecote(birthDate            : member.birthDate,
                                                          lastKnownSituation   : viewModel.lastKnownSituation,
                                                          dateOfRetirementComp : (member as! Adult).dateOfPensionLiquidComp) else {
                                                            return
        }
        guard let (tauxDePension, dureeDeReference, dureeAssurance, pensionBrute, pensionNette) =
            Pension.model.regimeGeneral.pensionWithDetail(sam: viewModel.sam,
                                                          birthDate: member.birthDate,
                                                          dateOfRetirementComp: (member as! Adult).dateOfPensionLiquidComp,
                                                          lastKnownSituation: viewModel.lastKnownSituation) else {
            return
        }
        viewModel.tauxDePension     = tauxDePension / 100
        viewModel.nbTrimestreDecote = nbTrimestreDecote
        viewModel.dureeDeReference  = dureeDeReference
        viewModel.dureeAssurance    = dureeAssurance
        viewModel.pensionBrute      = pensionBrute
        viewModel.pensionNette      = pensionNette
        viewModel.dateTauxPlein     =
            Pension.model.regimeGeneral.dateTauxPlein(birthDate: member.birthDate,
                                                      lastKnownSituation: viewModel.lastKnownSituation)
    }
}

struct RetirementDetailView_Previews: PreviewProvider {
    static var family  = Family()
    
    static var previews: some View {
        let aMember = family.members.first!
        
        return RetirementDetailView().environmentObject(aMember)
        
    }
}
