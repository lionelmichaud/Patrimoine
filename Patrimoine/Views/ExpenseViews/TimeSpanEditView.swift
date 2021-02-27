//
//  TimeSpanEditView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 02/06/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

// MARK: - View Model for LifeExpenseTimeSpan

struct TimeSpanViewModel: Equatable {
    
    // MARK: - Properties
    
    var caseIndex : Int
    var period    : Int
    var inYear    : Int
    var fromVM    : DateBoundaryViewModel?
    var toVM      : DateBoundaryViewModel?
    
    // MARK: - Computed Properties
    
    // construire l'objet de type LifeExpenseTimeSpan correspondant au ViewModel
    var timeSpan: TimeSpan {
        switch caseIndex {
            case TimeSpan.permanent.id:
                return .permanent
                
            case TimeSpan.periodic(from: DateBoundary.empty, period: 0, to: DateBoundary.empty).id:
                return .periodic(from   : fromVM!.dateBoundary,
                                 period : self.period,
                                 to     : toVM!.dateBoundary)
                
            case TimeSpan.starting(from: DateBoundary.empty).id:
                return .starting(from: fromVM!.dateBoundary)
                
            case TimeSpan.ending(to: DateBoundary.empty).id:
                return .ending(to: toVM!.dateBoundary)
                
            case TimeSpan.spanning(from: DateBoundary.empty, to: DateBoundary.empty).id:
                return .spanning(from : fromVM!.dateBoundary,
                                 to   : toVM!.dateBoundary)
                
            case TimeSpan.exceptional(inYear:0).id:
                return .exceptional(inYear: self.inYear)
                
            default:
                fatalError("LifeExpenseTimeSpan : Case out of bound")
        }
    }
    
    // MARK: - Initializers of ViewModel from Model
    
    internal init(from timeSpan: TimeSpan) {
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
                 .periodic(let from, _, _),
                 .spanning(let from, _):
                self.fromVM = DateBoundaryViewModel(from: from)
            default:
                self.fromVM = nil
        }
        switch timeSpan {
            case .ending (let to),
                 .periodic(_, _, let to),
                 .spanning(_, let to):
                self.toVM = DateBoundaryViewModel(from: to)
            default:
                self.toVM = nil
        }
    }
    
    internal init() {
        self = TimeSpanViewModel(from: .permanent)
    }
}

// MARK: - View

struct TimeSpanEditView: View {
    
    // MARK: - Properties
    
    @Binding var timeSpanVM : TimeSpanViewModel
    
    // MARK: - Computed Properties
    
    var body: some View {
        Group {
            Section(header: Text("PLAGE DE TEMPS")) {
                // choisir le type de TimeFrame pour la dépense
                CaseWithAssociatedValuePicker<TimeSpan>(caseIndex: $timeSpanVM.caseIndex, label: "")
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: timeSpanVM.caseIndex, perform: updateLifeExpenseTimeSpanEnum)
            }
            // en fonction du type choisi
            if timeSpanVM.caseIndex == TimeSpan.ending(to: DateBoundary.empty).id {
                // TimeSpan = .ending
                BoundaryEditView(label    : "Fin (exclue)",
                                 boundary : $timeSpanVM.toVM)
                
            } else if timeSpanVM.caseIndex == TimeSpan.starting(from: DateBoundary.empty).id {
                // TimeSpan = .starting
                BoundaryEditView(label    : "Début",
                                 boundary : $timeSpanVM.fromVM)
                
            } else if timeSpanVM.caseIndex == TimeSpan.spanning(from: DateBoundary.empty,
                                                                           to: DateBoundary.empty).id {
                // TimeSpan = .spanning
                BoundaryEditView(label    : "Début",
                                 boundary : $timeSpanVM.fromVM)
                BoundaryEditView(label    : "Fin (exclue)",
                                 boundary : $timeSpanVM.toVM)
                
            } else if timeSpanVM.caseIndex == TimeSpan.periodic(from: DateBoundary.empty,
                                                                           period: 0,
                                                                           to: DateBoundary.empty).id {
                // TimeSpan = .periodic
                BoundaryEditView(label    : "Début",
                                 boundary : $timeSpanVM.fromVM)
                BoundaryEditView(label     : "Fin (exclue)",
                                 boundary : $timeSpanVM.toVM)
                Section(header: Text("Période")) {
                    Stepper(value: $timeSpanVM.period, in: 0...100, step: 1, label: {
                        HStack {
                            Text("Période")
                            Spacer()
                            Text("\(timeSpanVM.period) ans").foregroundColor(.secondary)
                        }
                    })
                }
                
            } else if timeSpanVM.caseIndex == TimeSpan.exceptional(inYear: 0).id {
                // TimeSpan = .exceptional
                IntegerEditView(label: "Durant l'année", integer: $timeSpanVM.inYear)
            }
        }
    }
    
    // MARK: - Methods
    
    func updateLifeExpenseTimeSpanEnum(id: Int) {
        switch id {
            case TimeSpan.permanent.id:
                ()
                
            case TimeSpan.periodic(from: DateBoundary.empty, period: 0, to: DateBoundary.empty).id:
                self.timeSpanVM.fromVM = DateBoundaryViewModel(from: DateBoundary(fixedYear: Date.now.year))
                self.timeSpanVM.toVM = DateBoundaryViewModel(from: DateBoundary(fixedYear: Date.now.year))
                
            case TimeSpan.starting(from: DateBoundary.empty).id:
                self.timeSpanVM.fromVM = DateBoundaryViewModel(from: DateBoundary(fixedYear: Date.now.year))
                
            case TimeSpan.ending(to: DateBoundary.empty).id:
                self.timeSpanVM.toVM = DateBoundaryViewModel(from: DateBoundary(fixedYear: Date.now.year))
                
            case TimeSpan.spanning(from: DateBoundary.empty, to: DateBoundary.empty).id:
                self.timeSpanVM.fromVM = DateBoundaryViewModel(from: DateBoundary(fixedYear: Date.now.year))
                self.timeSpanVM.toVM = DateBoundaryViewModel(from: DateBoundary(fixedYear: Date.now.year))
                
            case TimeSpan.exceptional(inYear:0).id:
                self.timeSpanVM.inYear = Date.now.year
                
            default:
                ()
        }
    }
    
}

struct TimeSpanEditView_Previews: PreviewProvider {
    static var previews: some View {
        TimeSpanEditView(
            timeSpanVM: .constant(TimeSpanViewModel(from: TimeSpan.permanent))
        )
            .previewLayout(PreviewLayout.sizeThatFits)
            .padding([.bottom, .top])
            .previewDisplayName("TimeSpanEditView")
    }
}
