//
//  PersonLifeLineView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 12/07/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import StepperView

struct PersonLifeLineView: View {
   
    class ViewModel: ObservableObject {
        @Published var personName : String = ""
        @Published var steps      : [AnyView]                        = []
        @Published var indicators : [StepperIndicationType<AnyView>] = []
        @Published var pitStops   : [PitStopStep]                    = []
        let spacing  : CGFloat = 40
        let radius   : CGFloat = 45
        let fontSize : CGFloat = 14

        init(from member: Person) {
            personName = member.displayName
            steps.append(TextView(text:member.birthDate.stringShortDayMonth + ": Naissance", font: .system(size: fontSize, weight: .semibold)).padding(.leading).eraseToAnyView())
            indicators.append(StepperIndicationType.custom(NumberedCircleView(text: String(member.birthDate.year), width: radius).eraseToAnyView()))
            pitStops.append(PitStopStep(view: TextView(text:"Revenu d'activité professionnelle").eraseToAnyView(), lineOptions: PitStopLineOptions.custom(1, Colors.teal.rawValue)))
            
            switch member {
                case is Adult:
                    let adult = member as! Adult
                    // cessation d'activité
                    steps.append(TextView(text: adult.dateOfRetirement.stringShortDayMonth + ": Cessation d'activité (\(adult.causeOfRetirement.displayString)) à l'age de \(adult.age(atDate: adult.dateOfRetirement).year!) ans \(adult.age(atDate: adult.dateOfRetirement).month!) mois",
                                                    font: .system(size: fontSize, weight: .semibold)).padding(.leading).eraseToAnyView())
                    indicators.append(StepperIndicationType.custom(NumberedCircleView(text: String(adult.dateOfRetirement.year), width: radius).eraseToAnyView()))
                    pitStops.append(PitStopStep(view: TextView(text:"Aucun revenu").eraseToAnyView(), lineOptions: PitStopLineOptions.custom(1, Colors.teal.rawValue)))
                    // période d'allocation chomage éventuelle
                    if adult.hasUnemployementAllocationPeriod {
                        if let date = adult.dateOfStartOfUnemployementAllocation {
                            steps.append(TextView(text: date.stringShortDayMonth + ": Début de la période d'allocation chômage à l'age de \(adult.age(atDate: date).year!) ans \(adult.age(atDate: date).month!) mois",
                                                  font: .system(size: fontSize, weight: .semibold)).padding(.leading).eraseToAnyView())
                            indicators.append(StepperIndicationType.custom(NumberedCircleView(text: String(date.year), width: radius).eraseToAnyView()))
                            pitStops.append(PitStopStep(view: TextView(text:"Allocation chômage").eraseToAnyView(), lineOptions: PitStopLineOptions.custom(1, Colors.teal.rawValue)))
                        }
                        if let date = adult.dateOfStartOfAllocationReduction {
                            steps.append(TextView(text: date.stringShortDayMonth + ": Début de réduction de l'allocation chômage à l'age de \(adult.age(atDate: date).year!) ans \(adult.age(atDate: date).month!) mois",
                                                  font: .system(size: fontSize, weight: .semibold)).padding(.leading).eraseToAnyView())
                            indicators.append(StepperIndicationType.custom(NumberedCircleView(text: String(date.year), width: radius).eraseToAnyView()))
                            pitStops.append(PitStopStep(view: TextView(text:"Allocation chômage").eraseToAnyView(), lineOptions: PitStopLineOptions.custom(1, Colors.teal.rawValue)))
                        }
                        if let date = adult.dateOfEndOfUnemployementAllocation {
                            steps.append(TextView(text: date.stringShortDayMonth + ": Fin de période d'allocation chômage à l'age de \(adult.age(atDate: date).year!) ans \(adult.age(atDate: date).month!) mois",
                                                  font: .system(size: fontSize, weight: .semibold)).padding(.leading).eraseToAnyView())
                            indicators.append(StepperIndicationType.custom(NumberedCircleView(text: String(date.year), width: radius).eraseToAnyView()))
                            pitStops.append(PitStopStep(view: TextView(text:"Allocation chômage").eraseToAnyView(), lineOptions: PitStopLineOptions.custom(1, Colors.teal.rawValue)))
                        }
                    }
                    // liquidation de pension complémentaire
                    steps.append(TextView(text: adult.dateOfAgircPensionLiquid.stringShortDayMonth + ": Liquidation de la pension complémentaire à l'age de \(adult.ageOfAgircPensionLiquidComp.year!) ans \(adult.ageOfAgircPensionLiquidComp.month!) mois",
                                          font: .system(size: fontSize, weight: .semibold)).padding(.leading).eraseToAnyView())
                    indicators.append(StepperIndicationType.custom(NumberedCircleView(text: String(adult.dateOfAgircPensionLiquid.year), width: radius).eraseToAnyView()))
                    pitStops.append(PitStopStep(view: TextView(text:"Pension complémentaire").eraseToAnyView(), lineOptions: PitStopLineOptions.custom(1, Colors.teal.rawValue)))
                    // liquidation de pension de base
                    steps.append(TextView(text: adult.dateOfPensionLiquid.stringShortDayMonth + ": Liquidation de la pension de base à l'age de \(adult.ageOfPensionLiquidComp.year!) ans \(adult.ageOfPensionLiquidComp.month!) mois",
                                                    font: .system(size: fontSize, weight: .semibold)).padding(.leading).eraseToAnyView())
                    indicators.append(StepperIndicationType.custom(NumberedCircleView(text: String(adult.dateOfPensionLiquid.year), width: radius).eraseToAnyView()))
                    pitStops.append(PitStopStep(view: TextView(text:"Pension du régime général et complémentaire").eraseToAnyView(), lineOptions: PitStopLineOptions.custom(1, Colors.teal.rawValue)))
                    // début de la dépendance
                    if adult.nbOfYearOfDependency != 0 {
                        steps.append(TextView(text: "Entrée dans la dépendance pour une période de \(adult.nbOfYearOfDependency) ans à l'age de \(adult.ageOfDependency) ans",
                                                        font: .system(size: fontSize, weight: .semibold)).padding(.leading).eraseToAnyView())
                        indicators.append(StepperIndicationType.custom(NumberedCircleView(text: String(adult.yearOfDependency), width: radius).eraseToAnyView()))
                        pitStops.append(PitStopStep(view: TextView(text:"Pension du régime général et complémentaire").eraseToAnyView(), lineOptions: PitStopLineOptions.custom(1, Colors.teal.rawValue)))
                    }
                    
                case is Child:
                    let child = member as! Child
                    // Début des études supérieures
                    steps.append(TextView(text: child.dateOfUniversity.stringShortDayMonth + ": Début des études supérieures", font: .system(size: fontSize, weight: .semibold)).padding(.leading).eraseToAnyView())
                    indicators.append(StepperIndicationType.custom(NumberedCircleView(text: String(child.dateOfUniversity.year), width: radius).eraseToAnyView()))
                    pitStops.append(PitStopStep(view: TextView(text:"Dépenses plus élevées à la charge des parents").eraseToAnyView(), lineOptions: PitStopLineOptions.custom(1, Colors.teal.rawValue)))
                    // indépendance financière
                    steps.append(TextView(text: child.dateOfIndependence.stringShortDayMonth + ": Indépendance financière", font: .system(size: fontSize, weight: .semibold)).padding(.leading).eraseToAnyView())
                    indicators.append(StepperIndicationType.custom(NumberedCircleView(text: String(child.dateOfIndependence.year), width: radius).eraseToAnyView()))
                    pitStops.append(PitStopStep(view: TextView(text:"les dépenses ne sont plus à la charge des parents").eraseToAnyView(), lineOptions: PitStopLineOptions.custom(1, Colors.teal.rawValue)))
                    
                default:
                    ()
            }
            steps.append(TextView(text:"Décès à l'age de \(member.ageOfDeath) ans",
                                            font: .system(size: fontSize, weight: .semibold)).padding(.leading).eraseToAnyView())
            indicators.append(StepperIndicationType.custom(NumberedCircleView(text: String(member.yearOfDeath), width: radius).eraseToAnyView()))
            //pitStops.append(PitStopStep(view: TextView(text:"Pension du régime général").eraseToAnyView(), lineOptions: PitStopLineOptions.custom(1, Colors.teal.rawValue)))
        }
    }
    
    @StateObject var viewModel: ViewModel
    
    var body: some View {
        VStack(spacing: 5) {
            ScrollView(Axis.Set.vertical, showsIndicators: false) {
                HStack {
                    StepperView()
                        .addSteps(viewModel.steps)
                        .indicators(viewModel.indicators)
                        //.addPitStops(viewModel.pitStops)
                        .lineOptions(StepperLineOptions.custom(1, Colors.blue(.teal).rawValue))
                        //.autoSpacing(true) // auto calculates spacing between steps based on the content.
                        .spacing(viewModel.spacing) // sets the spacingg to value specified.
                        .padding(.leading, 20)
                }
            }
        }
        .padding(.vertical, 20)
        .navigationTitle("Ligne de vie de \(viewModel.personName)")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    init(from member: Person) {
        // initialize ViewModel
        _viewModel = StateObject(wrappedValue: ViewModel(from: member))
    }
}

struct PersonLifeLineView_Previews: PreviewProvider {
    static var family  = Family()
    static var aMember = family.members.first!
    
    static var previews: some View {
        PersonLifeLineView(from: aMember)
            .environmentObject(aMember)
    }
}
