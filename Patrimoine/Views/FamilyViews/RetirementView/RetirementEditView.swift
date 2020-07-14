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
            // régime complémentaire
            RegimeAgircEditView(personViewModel : personViewModel,
                                  adultViewModel  : adultViewModel)
            // régime général
            RegimeGeneralEditView(personViewModel : personViewModel,
                                adultViewModel  : adultViewModel)
        }
    }
}

// MARK: - Saisie de la situation - Régime complémentaire

struct RegimeAgircEditView: View {
    @ObservedObject var personViewModel : PersonViewModel
    @ObservedObject var adultViewModel  : AdultViewModel

    var body: some View {
        Section(header: Text("RETRAITE - Régime complémentaire")) {
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
            RegimeAgircSituationEditView(lastKnownAgircSituation: $adultViewModel.lastKnownAgircSituation)
        }
    }
}

struct RegimeAgircSituationEditView : View {
    @Binding var lastKnownAgircSituation: RegimeAgircSituation
    
    var body: some View {
        Group {
            IntegerEditView(label   : "Date de la dernière situation connue",
                            integer : $lastKnownAgircSituation.atEndOf)
            IntegerEditView(label   : "Nombre de points total acquis",
                            integer : $lastKnownAgircSituation.nbPoints)
            IntegerEditView(label   : "Nombre de points acquis par an",
                            integer : $lastKnownAgircSituation.pointsParAn)
        }
    }
}

// MARK: - Saisie de la situation - Régime général

struct RegimeGeneralEditView: View {
    @ObservedObject var personViewModel : PersonViewModel
    @ObservedObject var adultViewModel  : AdultViewModel

    var body: some View {
        Section(header: Text("RETRAITE - Régime général")) {
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
        }
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


struct RetirementEditView_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            RetirementEditView(personViewModel: PersonViewModel(), adultViewModel: AdultViewModel())
        }
    }
}
