//
//  AdultDetailView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 11/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

// MARK: - MemberDetailView / AdultDetailView

struct AdultDetailView: View {
    var body: some View {
        Group {
            /// Section: scénario
            ScenarioSectionView()
            
            /// Section: revenus
            RevenuSectionView()
            
            /// Section: succession
            InheritanceSectionView()
        }
    }
}

// MARK: - MemberDetailView / AdultDetailView / ScenarioSectionView

private struct ScenarioSectionView: View {
    @EnvironmentObject var member : Person
    
    var body: some View {
        let adult = member as! Adult
        return Section {
            DisclosureGroup(
                content: {
                    LabeledText(label: "Age de décès estimé",
                                text : "\(member.ageOfDeath) ans en \(String(member.yearOfDeath))")
                    LabeledText(label: "Cessation d'activité",
                                text : "\(adult.age(atDate: adult.dateOfRetirement).year!) ans \(adult.age(atDate: adult.dateOfRetirement).month!) mois au \(mediumDateFormatter.string(from: adult.dateOfRetirement))")
                    LabeledText(label: "Cause",
                                text : adult.causeOfRetirement.displayString)
                        .padding(.leading)
                    if adult.hasUnemployementAllocationPeriod {
                        if let date = adult.dateOfStartOfUnemployementAllocation {
                            LabeledText(label: "Début de la période d'allocation chômage",
                                        text : "\(adult.age(atDate: date).year!) ans \(adult.age(atDate: date).month!) mois au \(mediumDateFormatter.string(from: date))")
                                .padding(.leading)
                        }
                        if let date = adult.dateOfStartOfAllocationReduction {
                            LabeledText(label: "Début de la période de réduction d'allocation chômage",
                                        text : "\(adult.age(atDate: date).year!) ans \(adult.age(atDate: date).month!) mois au \(mediumDateFormatter.string(from: date))")
                                .padding(.leading)
                        }
                        if let date = adult.dateOfEndOfUnemployementAllocation {
                            LabeledText(label: "Fin de la période d'allocation chômage",
                                        text : "\(adult.age(atDate: date).year!) ans \(adult.age(atDate: date).month!) mois au \(mediumDateFormatter.string(from: date))")
                                .padding(.leading)
                        }
                    }
                    LabeledText(label: "Liquidation de pension - régime complém.",
                                text : "\(adult.ageOfAgircPensionLiquidComp.year!) ans \(adult.ageOfAgircPensionLiquidComp.month!) mois fin \(monthMediumFormatter.string(from: adult.dateOfAgircPensionLiquid)) \(String(adult.dateOfAgircPensionLiquid.year))")
                    LabeledText(label: "Liquidation de pension - régime général",
                                text : "\(adult.ageOfPensionLiquidComp.year!) ans \(adult.ageOfPensionLiquidComp.month!) mois fin \(monthMediumFormatter.string(from: adult.dateOfPensionLiquid)) \(String(adult.dateOfPensionLiquid.year))")
                    HStack {
                        Text("Dépendance")
                        Spacer()
                        if adult.nbOfYearOfDependency == 0 {
                            Text("aucune")
                        } else {
                            Text("\(adult.nbOfYearOfDependency) ans à partir de \(String(adult.yearOfDependency))")
                        }
                    }
                    NavigationLink(destination: PersonLifeLineView(from: self.member)) {
                        Text("Ligne de vie").foregroundColor(.blue)
                    }
                },
                label: {
                    Text("SCENARIO DE VIE").font(.headline)
                })
        }
    }
}

// MARK: - MemberDetailView / AdultDetailView / RevenuSectionView

private struct RevenuSectionView: View {
    
    // MARK: - View Model
    
    struct ViewModel {
        var unemployementAllocation          : (brut: Double, net: Double)?
        var income                           : WorkIncomeType?
        var pension                          = BrutNetTaxable(brut: 0.0, net: 0.0, taxable: 0.0)
        var hasUnemployementAllocationPeriod = false
        var revenueBrut                      = 0.0
        var revenueNet                       = 0.0
        var revenueTaxable                   = 0.0
        var revenueLiving                    = 0.0
        var fromDate                         = ""
        var insurance                        = 0.0
        
        // MARK: - Initializers
        
        init() {
        }
        
        init(from adult: Adult) {
            hasUnemployementAllocationPeriod = adult.hasUnemployementAllocationPeriod
            unemployementAllocation          = adult.unemployementAllocation
            pension                          = adult.pension
            income                           = adult.workIncome
            switch income {
                case let .salary(_, _, _, fromDate1, healthInsurance):
                    revenueBrut    = adult.workBrutIncome
                    revenueTaxable = adult.workTaxableIncome
                    revenueLiving  = adult.workLivingIncome
                    revenueNet     = adult.workNetIncome
                    fromDate       = fromDate1.stringMediumDate
                    insurance      = healthInsurance
                case let .turnOver(_, incomeLossInsurance):
                    revenueBrut    = adult.workBrutIncome
                    revenueTaxable = adult.workTaxableIncome
                    revenueLiving  = adult.workLivingIncome
                    revenueNet     = adult.workNetIncome
                    insurance      = incomeLossInsurance
                case .none: // nil
                    revenueBrut    = 0
                    revenueTaxable = 0
                    revenueLiving  = 0
                    revenueNet     = 0
                    insurance      = 0
            }
        }
    }
    
    // MARK: - Properties
    
    @EnvironmentObject var member : Person
    @State var viewModel = ViewModel()
    
    var body: some View {
        Section {
            DisclosureGroup(
                content: {
                    if viewModel.income?.pickerString == "Salaire" {
                        AmountView(label  : "Salaire brut", amount : viewModel.revenueBrut)
                        AmountView(label  : "Salaire net de feuille de paye", amount : viewModel.revenueNet)
                        AmountView(label  : "Coût de la mutuelle (protec. sup.)", amount : viewModel.insurance)
                        AmountView(label  : "Salaire net moins mutuelle facultative (à vivre)", amount : viewModel.revenueLiving)
                        AmountView(label  : "Salaire imposable (après abattement)", amount : viewModel.revenueTaxable)
                        HStack {
                            Text("Date d'embauche")
                            Spacer()
                            Text(viewModel.fromDate)
                        }
                    } else {
                        AmountView(label  : "BNC", amount : viewModel.revenueBrut)
                        AmountView(label  : "BNC net de charges sociales", amount : viewModel.revenueNet)
                        AmountView(label  : "Coût des assurances", amount : viewModel.insurance)
                        AmountView(label  : "BNC net de charges sociales et d'assurances (à vivre)", amount : viewModel.revenueLiving)
                        AmountView(label  : "BNC imposable (après abattement)", amount : viewModel.revenueTaxable)
                        
                    }
                    // allocation chomage
                    if viewModel.hasUnemployementAllocationPeriod {
                        NavigationLink(destination: UnemployementDetailView().environmentObject(self.member)) {
                            AmountView(label  : "Allocation chômage annuelle nette",
                                       amount : viewModel.unemployementAllocation!.net)
                                .foregroundColor(.blue)
                        }
                    }
                    // pension de retraite
                    NavigationLink(destination: RetirementDetailView().environmentObject(self.member)) {
                        AmountView(label  : "Pension de retraite annuelle nette",
                                   amount : viewModel.pension.net)
                            .foregroundColor(.blue)
                    }
                },
                label: {
                    Text("REVENUS").font(.headline)
                })
        }
        .onAppear(perform: onAppear)
    }
    
    // MARK: - Methods
    
    func onAppear() {
        let adult = member as! Adult
        viewModel = ViewModel(from: adult)
    }
}

// MARK: - MemberDetailView / AdultDetailView / InheritanceSectionView

private struct InheritanceSectionView: View {
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var member     : Person
    
    var body: some View {
        if member is Adult {
            Section {
                DisclosureGroup(
                    content: {
                        if let adult = member as? Adult {
                            LabeledText(label: "Option fiscale retenue en cas d'héritage",
                                        text : adult.fiscalOption.displayString)
                        }
                        AmountView(label : "A la date d'aujourd'hui",
                                   amount: patrimoine.taxableInheritanceValue(of: member, atEndOf: Date.now.year),
                                   comment: "masse successorale en cas de décès")
                        AmountView(label : "A l'âge de décès estimé \(member.ageOfDeath) ans en \(String(member.yearOfDeath))",
                                   amount: patrimoine.taxableInheritanceValue(of: member, atEndOf: member.yearOfDeath),
                                   comment: "masse successorale en cas de décès")
                    },
                    label: {
                        Text("SUCCESSION").font(.headline)
                    })
            }
        }
    }
}
