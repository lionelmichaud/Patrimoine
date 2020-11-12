//
//  TimeSpanEditView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 02/06/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

// MARK: - View Model for DateBoundary

class TimeSpanViewModel: ObservableObject {
    
    // MARK: - Properties
    
    @Published var caseIndex : Int
    @Published var period    : Int
    @Published var inYear    : Int
    @Published var fromVM    : DateBoundaryViewModel?
    @Published var toVM      : DateBoundaryViewModel?
    
    // MARK: - Computed Properties
    
    // construire l'objet de type DateBoundary correspondant au ViewModel
    var timeSpan: LifeExpenseTimeSpan {
        switch caseIndex {
            case LifeExpenseTimeSpan.permanent.id:
                return .permanent
                
            case LifeExpenseTimeSpan.periodic(from: DateBoundary.empty, period: 0, to: DateBoundary.empty).id:
                return .periodic(from   : fromVM!.dateBoundary,
                                 period : self.period,
                                 to     : toVM!.dateBoundary)
                
            case LifeExpenseTimeSpan.starting(from: DateBoundary.empty).id:
                return .starting(from: fromVM!.dateBoundary)
                
            case LifeExpenseTimeSpan.ending(to: DateBoundary.empty).id:
                return .ending(to: toVM!.dateBoundary)
                
            case LifeExpenseTimeSpan.spanning(from: DateBoundary.empty, to: DateBoundary.empty).id:
                return .spanning(from : fromVM!.dateBoundary,
                                 to   : toVM!.dateBoundary)
                
            case LifeExpenseTimeSpan.exceptional(inYear:0).id:
                return .exceptional(inYear: self.inYear)
                
            default:
                fatalError("LifeExpenseTimeSpan : Case out of bound")
        }
    }

        // MARK: -  Initializers of ViewModel from Model
    
    init(from timeSpan: LifeExpenseTimeSpan) {
        self.caseIndex = timeSpan.id
        switch timeSpan {
            case .exceptional(let inYear):
                self.inYear = inYear
            default:
                self.inYear = Date.now.year
        }
        switch timeSpan {
            case .periodic(_, let period, _):
                self.period = period
            default:
                self.period = 1
        }
        switch timeSpan {
            case .starting (let from),
                 .periodic(let from , _ , _),
                 .spanning(let from , _):
                self.fromVM = DateBoundaryViewModel(from: from)
            default:
                self.fromVM = nil
        }
        switch timeSpan {
            case .ending (let to),
                 .periodic(_ , _ , let to),
                 .spanning(_ , let to):
                self.toVM = DateBoundaryViewModel(from: to)
            default:
                self.toVM = nil
        }
    }
}

struct TimeSpanEditView: View {
    
    static let defaultToEvent   : LifeEvent = .deces
    static let defaultFromEvent : LifeEvent = .cessationActivite

    // MARK: - Properties
    
    @Binding var timeSpan       : LifeExpenseTimeSpan
    @StateObject var timeSpanVM : TimeSpanViewModel

    var body: some View {
        Group {
            Section(header: Text("PLAGE DE TEMPS")) {
                // choisir le type de TimeFrame pour la dépense
                CaseWithAssociatedValuePicker<LifeExpenseTimeSpan>(caseIndex: $timeSpanVM.caseIndex, label: "")
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: timeSpanVM.caseIndex, perform: updateLifeExpenseTimeSpanEnum)
            }
            // en fonction du type choisi
            if timeSpanVM.caseIndex == LifeExpenseTimeSpan.ending (to: DateBoundary.empty).id {
                // TimeSpan = .ending
                BoundaryEditView(label    : "Fin",
                                 boundary : $timeSpanVM.toVM)
                
            } else if timeSpanVM.caseIndex == LifeExpenseTimeSpan.starting(from: DateBoundary.empty).id {
                // TimeSpan = .starting
                BoundaryEditView(label    : "Début",
                                 boundary : $timeSpanVM.fromVM)
                
            } else if timeSpanVM.caseIndex == LifeExpenseTimeSpan.spanning(from: DateBoundary.empty,
                                                                           to: DateBoundary.empty).id {
                // TimeSpan = .spanning
                BoundaryEditView(label    : "Début",
                                 boundary : $timeSpanVM.fromVM)
                BoundaryEditView(label    : "Fin",
                                 boundary : $timeSpanVM.toVM)
                
            } else if timeSpanVM.caseIndex == LifeExpenseTimeSpan.periodic(from: DateBoundary.empty,
                                                                           period: 0,
                                                                           to: DateBoundary.empty).id {
                // TimeSpan = .periodic
                BoundaryEditView(label    : "Début",
                                 boundary : $timeSpanVM.fromVM)
                BoundaryEditView(label     : "Fin",
                                 boundary : $timeSpanVM.toVM)
                Section(header: Text("Période")) {
                    Stepper(value: $timeSpanVM.period, in: 0...100, step: 1, label: {
                        HStack {
                            Text("Période")
                            Spacer()
                            Text("\(timeSpanVM.period) ans").foregroundColor(.secondary)
                        }
                    })
//                    .onChange(of: timeSpanVM.period, perform: updatePeriod)
                }
                
            } else if timeSpanVM.caseIndex == LifeExpenseTimeSpan.exceptional(inYear: 0).id {
                // TimeSpan = .exceptional
                IntegerEditView(label: "Durant l'année", integer: $timeSpanVM.inYear)
//                    .onChange(of: timeSpanVM.inYear, perform: updateExceptionalYear)
            }
        }
    }
    
    // MARK: - Initializers
    
    init(timeSpan : Binding<LifeExpenseTimeSpan>) {
        _timeSpan   = timeSpan
        _timeSpanVM = StateObject(wrappedValue : TimeSpanViewModel(from : timeSpan.wrappedValue))
    }
    
    // MARK: - Methods
    
    func updateLifeExpenseTimeSpanEnum(id: Int) {
        switch id {
            case LifeExpenseTimeSpan.permanent.id:
                ()

            case LifeExpenseTimeSpan.periodic(from: DateBoundary.empty, period: 0, to: DateBoundary.empty).id:
                self.timeSpanVM.fromVM = DateBoundaryViewModel(from: DateBoundary(year: Date.now.year))
                self.timeSpanVM.toVM = DateBoundaryViewModel(from: DateBoundary(year: Date.now.year))

            case LifeExpenseTimeSpan.starting(from: DateBoundary.empty).id:
                self.timeSpanVM.fromVM = DateBoundaryViewModel(from: DateBoundary(year: Date.now.year))

            case LifeExpenseTimeSpan.ending(to: DateBoundary.empty).id:
                self.timeSpanVM.toVM = DateBoundaryViewModel(from: DateBoundary(year: Date.now.year))

            case LifeExpenseTimeSpan.spanning(from: DateBoundary.empty, to: DateBoundary.empty).id:
                self.timeSpanVM.fromVM = DateBoundaryViewModel(from: DateBoundary(year: Date.now.year))
                self.timeSpanVM.toVM = DateBoundaryViewModel(from: DateBoundary(year: Date.now.year))

            case LifeExpenseTimeSpan.exceptional(inYear:0).id:
                self.timeSpanVM.inYear = Date.now.year

            default:
                ()
        }
    }
    
    func updateExceptionalYear(year: Int) {
        self.timeSpan = .exceptional(inYear: year)
    }
    
    func updatePeriod(period: Int) {
        switch self.timeSpan {
            case .periodic(let from, _, let to):
                self.timeSpan = .periodic(from: from, period: period, to: to)
            default:
                fatalError("LifeExpenseTimeSpan : Case out of bound")
        }
    }
    
}

struct TimeSpanEditView_Previews: PreviewProvider {
    static var previews: some View {
        TimeSpanEditView(timeSpan: .constant(LifeExpenseTimeSpan.spanning(from: DateBoundary(year: 2020),
                                                                          to  : DateBoundary(year: 2022))))
            .previewLayout(PreviewLayout.sizeThatFits)
            .padding([.bottom, .top])
            .previewDisplayName("TimeSpanEditView")
    }
}

