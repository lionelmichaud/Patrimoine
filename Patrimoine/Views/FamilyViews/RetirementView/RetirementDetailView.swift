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
        struct General {
            var sam              : Double = 0
            var tauxDePension    : Double = 0
            var dureeDeReference : Int    = 0
            var dureeAssurance   : Int    = 0
            var dateTauxPlein    : Date?
            var ageTauxPlein     : DateComponents?
            var nbTrimestreDecote: Int    = 0
            var pensionBrute     : Double = 0
            var pensionNette     : Double = 0
        }
        struct Agirc {
            var projectedNbOfPoints : Int    = 0
            var valeurDuPoint       : Double = 0
            var coefMinoration      : Double = 0
            var pensionBrute        : Double = 0
            var pensionNette        : Double = 0
        }
        // régime général
        @Published var general = General()
        // régime complémentaire
        @Published var agirc = Agirc()
    }
    
    // MARK: - Properties
    
    @EnvironmentObject var member: Person
    @ObservedObject var viewModel = ViewModel()
    
    var body: some View {
        Form {
            AmountView(label: "Pension annuelle brute", amount: viewModel.general.pensionBrute + viewModel.agirc.pensionBrute)
            AmountView(label: "Pension annuelle nette", amount: viewModel.general.pensionNette + viewModel.agirc.pensionNette, weight: .bold)
            Section(header: Text("REGIME GENERAL").font(.subheadline)) {
                AmountView(label: "Salaire annuel moyen", amount: viewModel.general.sam, comment: "SAM")
                AgeDateView(label: "Date du taux plein")
                IntegerView(label: "Nombre de trimestres de décote", integer: viewModel.general.nbTrimestreDecote)
                PercentView(label: "Taux de réversion", percent: viewModel.general.tauxDePension, comment: "Trev")
                IntegerView(label: "Durée d'assurance (trimestres)", integer: viewModel.general.dureeAssurance, comment: "Da")
                IntegerView(label: "Durée de référence (trimestres)", integer: viewModel.general.dureeDeReference, comment: "Dr")
                AmountView(label: "Pension annuelle brute", amount: viewModel.general.pensionBrute, comment: "Brut = SAM x Trev x Da/Dr")
                AmountView(label: "Pension annuelle nette", amount: viewModel.general.pensionNette, weight: .bold, comment: "Net = Brut - Prélev sociaux")
            }
            Section(header: Text("REGIME COMPLEMENTAIRE").font(.subheadline)) {
                IntegerView(label: "Nombre de points", integer: viewModel.agirc.projectedNbOfPoints, comment: "Npt")
                AmountView(label: "Valeur de 1000 points", amount: viewModel.agirc.valeurDuPoint * 1000, comment: "Vpt")
                PercentView(label: "Coeficient de minoration", percent: viewModel.agirc.coefMinoration, comment: "Cm")
                AmountView(label: "Pension annuelle brute", amount: viewModel.agirc.pensionBrute, comment: "Brut = Npt x Vpt x Cm")
                AmountView(label: "Pension annuelle nette", amount: viewModel.agirc.pensionNette, weight: .bold, comment: "Net = Brut - Prélev sociaux")
            }
        }
        .navigationBarTitle("Retraite de \(member.displayName)", displayMode: .inline)
        .onAppear(perform: onAppear)
    }
    
    // MARK: - Methods
    
    func AgeDateView(label: String) -> some View {
        return HStack {
            Text(label)
            Spacer()
            if viewModel.general.dateTauxPlein == nil || viewModel.general.ageTauxPlein == nil {
                EmptyView()
            } else {
                Text(mediumDateFormatter.string(from: viewModel.general.dateTauxPlein!) + " à l'age de \(viewModel.general.ageTauxPlein!.year!) ans \(viewModel.general.ageTauxPlein!.month!) mois")
            }
        }
    }
    
    func onAppear() {
        // régime général
        let adult = member as! Adult
        guard let nbTrimestreDecote =
            Pension.model.regimeGeneral.nbTrimestreDecote(birthDate           : member.birthDate,
                                                          lastKnownSituation  : adult.lastKnownPensionSituation,
                                                          dateOfPensionLiquid : adult.dateOfPensionLiquid) else {
             return
        }
        guard let (tauxDePension, dureeDeReference, dureeAssurance, pensionBrute, pensionNette) =
            Pension.model.regimeGeneral.pensionWithDetail(birthDate               : member.birthDate,
                                                          dateOfRetirement        : adult.dateOfRetirement,
                                                          dateOfEndOfUnemployAlloc: adult.dateOfEndOfUnemployementAllocation,
                                                          dateOfPensionLiquid     : adult.dateOfPensionLiquid,
                                                          lastKnownSituation      : adult.lastKnownPensionSituation) else {
            return
        }
        viewModel.general.dateTauxPlein     =
            Pension.model.regimeGeneral.dateTauxPlein(birthDate          : member.birthDate,
                                                      lastKnownSituation : (member as! Adult).lastKnownPensionSituation)
        if viewModel.general.dateTauxPlein != nil {
            viewModel.general.ageTauxPlein  = member.age(atDate: viewModel.general.dateTauxPlein!)
        }
        viewModel.general.sam               = (member as! Adult).lastKnownPensionSituation.sam
        viewModel.general.tauxDePension     = tauxDePension / 100
        viewModel.general.nbTrimestreDecote = nbTrimestreDecote
        viewModel.general.dureeDeReference  = dureeDeReference
        viewModel.general.dureeAssurance    = dureeAssurance
        viewModel.general.pensionBrute      = pensionBrute
        viewModel.general.pensionNette      = pensionNette
        
        // régime complémentaire
        guard let (coefMinoration, projectedNbOfPoints, pensionBruteAgirc, pensionNetteAgirc) =
            Pension.model.regimeAgirc.pension(lastAgircKnownSituation : adult.lastKnownAgircPensionSituation,
                                              birthDate               : member.birthDate,
                                              lastKnownSituation      : adult.lastKnownPensionSituation,
                                              dateOfRetirement        : adult.dateOfRetirement,
                                              dateOfEndOfUnemployAlloc: adult.dateOfEndOfUnemployementAllocation,
                                              dateOfPensionLiquid     : adult.dateOfPensionLiquid,
                                              ageOfPensionLiquidComp  : adult.ageOfAgircPensionLiquidComp) else { return }
        viewModel.agirc.projectedNbOfPoints = projectedNbOfPoints
        viewModel.agirc.valeurDuPoint       = Pension.model.regimeAgirc.model.valeurDuPoint
        viewModel.agirc.coefMinoration      = coefMinoration
        viewModel.agirc.pensionBrute        = pensionBruteAgirc
        viewModel.agirc.pensionNette        = pensionNetteAgirc
    }
}

struct RetirementDetailView_Previews: PreviewProvider {
    static var family  = Family()
    
    static var previews: some View {
        let aMember = family.members.first!
        
        return RetirementDetailView().environmentObject(aMember)
        
    }
}
