//
//  RetirementEditView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 10/07/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

// MARK: - Saisie pension retraite
struct RetirementEditView: View {
    @ObservedObject var personViewModel : PersonViewModel
    @ObservedObject var adultViewModel  : AdultViewModel

    var body : some View {
        Group {
            // régime général
            RegimeGeneralEditView(personViewModel : personViewModel,
                                  adultViewModel  : adultViewModel)
            // régime complémentaire
            RegimeAgircEditView(personViewModel : personViewModel,
                                adultViewModel  : adultViewModel)
        }
    }
}

// MARK: - Saisie de la situation - Régime général
struct RegimeGeneralEditView: View {
    @ObservedObject var personViewModel : PersonViewModel
    @ObservedObject var adultViewModel  : AdultViewModel

    var body: some View {
        Section(header: Text("Régime complémentaire").padding(.leading)) {
            HStack {
                Stepper(value: $adultViewModel.ageAgircPension, in: Pension.model.regimeAgirc.model.ageMinimum ... Pension.model.regimeGeneral.ageTauxPleinLegal(birthYear: personViewModel.birthDate.year)!) {
                    HStack {
                        Text("Age de liquidation")
                        Spacer()
                        Text("\(adultViewModel.ageAgircPension) ans").foregroundColor(.secondary)
                    }
                }
                Stepper(value: $adultViewModel.trimAgircPension, in: 0...4) {
                    Text("\(adultViewModel.trimAgircPension * 3) mois").foregroundColor(.secondary)
                }
                .frame(width: 160)
            }
        }.padding(.leading)
    }
}

struct RegimeGeneralSituationEditView : View {
    @Binding var lastKnownPensionSituation: RegimeGeneralSituation
    
    var body: some View {
        Group {
            AmountEditView(label  : "Salaire annuel moyen",
                           amount : $lastKnownPensionSituation.sam)
            IntegerEditView(label   : "Date de la dernière situation connue",
                            integer : $lastKnownPensionSituation.atEndOf)
            IntegerEditView(label   : "Nombre de trimestre acquis",
                            integer : $lastKnownPensionSituation.nbTrimestreAcquis)
        }
    }
}

// MARK: - Saisie de la situation - Régime complémentaire
struct RegimeAgircEditView: View {
    @ObservedObject var personViewModel : PersonViewModel
    @ObservedObject var adultViewModel  : AdultViewModel

    var body: some View {
        Section(header: Text("Régime général").padding(.leading)) {
            // régime complémentaire
            HStack {
                Stepper(value: $adultViewModel.agePension, in: Pension.model.regimeGeneral.model.ageMinimumLegal ... Pension.model.regimeGeneral.ageTauxPleinLegal(birthYear: personViewModel.birthDate.year)!) {
                    HStack {
                        Text("Age de liquidation")
                        Spacer()
                        Text("\(adultViewModel.agePension) ans").foregroundColor(.secondary)
                    }
                }
                Stepper(value: $adultViewModel.trimPension, in: 0...4) {
                    Text("\(adultViewModel.trimPension * 3) mois").foregroundColor(.secondary)
                }
                .frame(width: 160)
            }
            RegimeGeneralSituationEditView(lastKnownPensionSituation: $adultViewModel.lastKnownPensionSituation)
        }.padding(.leading)
    }
}


struct RetirementEditView_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            RetirementEditView(personViewModel: PersonViewModel(), adultViewModel: AdultViewModel())
        }
    }
}
