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
    @EnvironmentObject var member: Person
    
    class ViewModel: ObservableObject {
        @Published var steps      : [AnyView]                        = []
        @Published var indicators : [StepperIndicationType<AnyView>] = []
        @Published var pitStops   : [PitStopStep]                    = []
    }
    
    @ObservedObject var viewModel = ViewModel()
    
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
                        .spacing(50) // sets the spacingg to value specified.
                        .padding(.leading, 20)
                }
            }
        }
        .padding(.vertical, 20)
        .navigationBarTitle("Ligne de vie de \(member.displayName)", displayMode: .inline)
    }
    
    init(withInitialValueFrom member: Person) {
        let radius: CGFloat = 45
        
        viewModel.steps.append(TextView(text:member.birthDate.stringShortDayMonth + ": Naissance", font: .system(size: 14, weight: .semibold)).padding(.leading).eraseToAnyView())
        viewModel.indicators.append(StepperIndicationType.custom(NumberedCircleView(text: String(member.birthDate.year), width: radius).eraseToAnyView()))
        viewModel.pitStops.append(PitStopStep(view: TextView(text:"Revenu d'activité professionnelle").eraseToAnyView(), lineOptions: PitStopLineOptions.custom(1, Colors.teal.rawValue)))
        
        switch member {
            case is Adult:
                let adult = member as! Adult
                // cessation d'activité
                viewModel.steps.append(TextView(text: adult.dateOfRetirement.stringShortDayMonth + ": Cessation d'activité à l'age de \(adult.age(atDate: adult.dateOfRetirement).year!) ans \(adult.age(atDate: adult.dateOfRetirement).month!) mois",
                                                font: .system(size: 14, weight: .semibold)).padding(.leading).eraseToAnyView())
                viewModel.indicators.append(StepperIndicationType.custom(NumberedCircleView(text: String(adult.dateOfRetirement.year), width: radius).eraseToAnyView()))
                viewModel.pitStops.append(PitStopStep(view: TextView(text:"Aucun revenu").eraseToAnyView(), lineOptions: PitStopLineOptions.custom(1, Colors.teal.rawValue)))
                // période d'allocation chomage éventuelle
                if adult.hasUnemployementAllocationPeriod {
                    if adult.dateOfStartOfAllocationReduction != nil {
                        viewModel.steps.append(TextView(text: adult.dateOfStartOfAllocationReduction!.stringShortDayMonth + ": Début de réduction de l'allocation chômage à l'age de \(adult.age(atDate: adult.dateOfStartOfAllocationReduction!).year!) ans \(adult.age(atDate: adult.dateOfStartOfAllocationReduction!).month!) mois",
                                                        font: .system(size: 14, weight: .semibold)).padding(.leading).eraseToAnyView())
                        viewModel.indicators.append(StepperIndicationType.custom(NumberedCircleView(text: String(adult.dateOfStartOfAllocationReduction!.year), width: radius).eraseToAnyView()))
                        viewModel.pitStops.append(PitStopStep(view: TextView(text:"Allocation chômage").eraseToAnyView(), lineOptions: PitStopLineOptions.custom(1, Colors.teal.rawValue)))
                    }
                    viewModel.steps.append(TextView(text: adult.dateOfEndOfUnemployementAllocation!.stringShortDayMonth + ": Fin de période d'allocation chômage à l'age de \(adult.age(atDate: adult.dateOfEndOfUnemployementAllocation!).year!) ans \(adult.age(atDate: adult.dateOfEndOfUnemployementAllocation!).month!) mois",
                                                    font: .system(size: 14, weight: .semibold)).padding(.leading).eraseToAnyView())
                    viewModel.indicators.append(StepperIndicationType.custom(NumberedCircleView(text: String(adult.dateOfEndOfUnemployementAllocation!.year), width: radius).eraseToAnyView()))
                    viewModel.pitStops.append(PitStopStep(view: TextView(text:"Allocation chômage").eraseToAnyView(), lineOptions: PitStopLineOptions.custom(1, Colors.teal.rawValue)))
                }
                // liquidation de pension complémentaire
                viewModel.steps.append(TextView(text: adult.dateOfAgircPensionLiquid.stringShortDayMonth + ": Liquidation de la pension complémentaire à l'age de \(adult.ageOfAgircPensionLiquidComp.year!) ans \(adult.ageOfAgircPensionLiquidComp.month!) mois",
                                                font: .system(size: 14, weight: .semibold)).padding(.leading).eraseToAnyView())
                viewModel.indicators.append(StepperIndicationType.custom(NumberedCircleView(text: String(adult.dateOfAgircPensionLiquid.year), width: radius).eraseToAnyView()))
                viewModel.pitStops.append(PitStopStep(view: TextView(text:"Pension complémentaire").eraseToAnyView(), lineOptions: PitStopLineOptions.custom(1, Colors.teal.rawValue)))
                // liquidation de pension de base
                viewModel.steps.append(TextView(text: adult.dateOfPensionLiquid.stringShortDayMonth + ": Liquidation de la pension de base à l'age de \(adult.ageOfPensionLiquidComp.year!) ans \(adult.ageOfPensionLiquidComp.month!) mois",
                                                font: .system(size: 14, weight: .semibold)).padding(.leading).eraseToAnyView())
                viewModel.indicators.append(StepperIndicationType.custom(NumberedCircleView(text: String(adult.dateOfPensionLiquid.year), width: radius).eraseToAnyView()))
                viewModel.pitStops.append(PitStopStep(view: TextView(text:"Pension du régime général et complémentaire").eraseToAnyView(), lineOptions: PitStopLineOptions.custom(1, Colors.teal.rawValue)))
                // début de la dépendance
                if adult.nbOfYearOfDependency != 0 {
                viewModel.steps.append(TextView(text: "Entrée dans la dépendance pour une période de \(adult.nbOfYearOfDependency) ans à l'age de \(adult.ageOfDependency) ans",
                                                font: .system(size: 14, weight: .semibold)).padding(.leading).eraseToAnyView())
                viewModel.indicators.append(StepperIndicationType.custom(NumberedCircleView(text: String(adult.yearOfDependency), width: radius).eraseToAnyView()))
                viewModel.pitStops.append(PitStopStep(view: TextView(text:"Pension du régime général et complémentaire").eraseToAnyView(), lineOptions: PitStopLineOptions.custom(1, Colors.teal.rawValue)))
                }
            
            case is Child:
                let child = member as! Child
                // Début des études supérieures
                viewModel.steps.append(TextView(text: child.dateOfUniversity.stringShortDayMonth + ": Début des études supérieures", font: .system(size: 14, weight: .semibold)).padding(.leading).eraseToAnyView())
                viewModel.indicators.append(StepperIndicationType.custom(NumberedCircleView(text: String(child.dateOfUniversity.year), width: radius).eraseToAnyView()))
                viewModel.pitStops.append(PitStopStep(view: TextView(text:"Dépenses plus élevées à la charge des parents").eraseToAnyView(), lineOptions: PitStopLineOptions.custom(1, Colors.teal.rawValue)))
                // indépendance financière
                viewModel.steps.append(TextView(text: child.dateOfIndependence.stringShortDayMonth + ": Indépendance financière", font: .system(size: 14, weight: .semibold)).padding(.leading).eraseToAnyView())
                viewModel.indicators.append(StepperIndicationType.custom(NumberedCircleView(text: String(child.dateOfIndependence.year), width: radius).eraseToAnyView()))
                viewModel.pitStops.append(PitStopStep(view: TextView(text:"les dépenses ne sont plus à la charge des parents").eraseToAnyView(), lineOptions: PitStopLineOptions.custom(1, Colors.teal.rawValue)))

            default:
                ()
        }
        viewModel.steps.append(TextView(text:"Décès à l'age de \(member.ageOfDeath) ans",
                                        font: .system(size: 14, weight: .semibold)).padding(.leading).eraseToAnyView())
        viewModel.indicators.append(StepperIndicationType.custom(NumberedCircleView(text: String(member.yearOfDeath), width: radius).eraseToAnyView()))
        //viewModel.pitStops.append(PitStopStep(view: TextView(text:"Pension du régime général").eraseToAnyView(), lineOptions: PitStopLineOptions.custom(1, Colors.teal.rawValue)))
    }
}

struct ExampleView6: View {
    
    let indicators = [
        StepperIndicationType<AnyView>.custom(NumberedCircleView(text: "2024", width: 40).eraseToAnyView()),
        StepperIndicationType.custom(CircledIconView(image: Image("like"),
                                                     width: 40,
                                                     strokeColor: Color(UIColor(red: 26/255, green: 188/255, blue: 156/255, alpha: 1.0)))
                            .eraseToAnyView()),
        StepperIndicationType.custom(CircledIconView(image: Image("flag"),
                                                     width: 40,
                                                     strokeColor: Color.red)
                            .eraseToAnyView()),
        StepperIndicationType.custom(CircledIconView(image: Image("book"),
                                                     width: 40,
                                                     strokeColor: Colors.gray(.darkSilver).rawValue)
                            .eraseToAnyView())]
    
    let steps = [TextView(text:"Question", font: .system(size: 14, weight: .semibold)),
                TextView(text:"Expected Answer", font: .system(size: 14, weight: .semibold)),
                TextView(text:"Red Flags", font: .system(size: 14, weight: .semibold)),
                TextView(text:"Further Reading", font: .system(size: 14, weight: .semibold))]
    
    let pitStops = [PitStopStep(view: TextView(text:PitStopText.p1).eraseToAnyView(), lineOptions: PitStopLineOptions.custom(1, Colors.teal.rawValue)),
                    PitStopStep(view: TextView(text:PitStopText.p2).eraseToAnyView(),
                                    lineOptions: PitStopLineOptions.custom(1, Color(UIColor(red: 26/255, green: 188/255, blue: 156/255, alpha: 1.0)))),
                    PitStopStep(view: TextView(text:PitStopText.p3).eraseToAnyView(), lineOptions: PitStopLineOptions.custom(1, Color.red)),
                    PitStopStep(view: FurtherReadingView().eraseToAnyView(), lineOptions: PitStopLineOptions.custom(1, Colors.gray(.darkSilver).rawValue))]
    
    var body: some View {
        //ScrollView(Axis.Set.vertical, showsIndicators: false) {
        VStack {
            StepperView()
                .addSteps(steps)
                .indicators(indicators)
                .addPitStops(pitStops)
                //.spacing(100) // sets the spacingg to value specified.
                .autoSpacing(true) // auto calculates spacing between steps based on the content.
        }
       // }
    }
}

struct FurtherReadingView:View {
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Button("Github - StepperView") {
                UIApplication.shared.open(URL(string:"https://github.com/badrinathvm/StepperView")!)
            }
        }
    }
}

struct PitStopText {
    static var p1 = "What are Step Indicators ?"
    static var p2 = "Step indicators are used to."
    static var p3 = "Even though some languages."
}

struct PersonLifeLineView_Previews: PreviewProvider {
    static var family  = Family()
    static var aMember = family.members.first!
    
    static var previews: some View {
        PersonLifeLineView(withInitialValueFrom: aMember)
            .environmentObject(aMember)
    }
}
