//
//  TimeSpanEditView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 02/06/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct TimeSpanEditView: View {
    
    // MARK: - Properties
    
    @Binding var timeSpan : LifeExpenseTimeSpan
    let defaultToEvent    : LifeEvent = .deces
    let defaultFromEvent  : LifeEvent = .cessationActivite
    
    var bindingIsLinkedToFromEvent : Binding<Bool> {
        return Binding<Bool> (
            get: {
                switch self.timeSpan {
                    case .starting (let from),
                         .periodic(let from , _ , _),
                         .spanning(let from , _):
                        return from.event != nil
                    default:
                        // nout used anyway
                        return false
                }
            },
            set: { isLinked in
                // affecter une valeur par défaut au LifeEvent ou supprimer le lien vers le LifeEvent
                let boundary = DateBoundary(
                    event: (isLinked ? self.defaultFromEvent : nil))
                switch self.timeSpan {
                    case .starting (_):
                        self.timeSpan = .starting(from: boundary)
                    case .periodic(_, let period, let to):
                        self.timeSpan = .periodic(from: boundary, period: period, to: to)
                    case .spanning(_, let to):
                        self.timeSpan = .spanning(from: boundary, to: to)
                    default:
                        // should never be called
                        fatalError("LifeExpenseTimeSpan : Case out of bound")
                }
            })
    }
    var bindingIsLinkedToToEvent : Binding<Bool> {
        return Binding<Bool> (
            get: {
                switch self.timeSpan {
                    case .ending (let to),
                         .periodic(_ , _ , let to),
                         .spanning(_ , let to):
                        return to.event != nil
                    default:
                        // nout used anyway
                        return false
                }
            },
            set: { isLinked in
                // affecter une valeur par défaut au LifeEvent ou supprimer le lien vers le LifeEvent
                let boundary = DateBoundary(
                    event: (isLinked ? self.defaultFromEvent : nil))
                switch self.timeSpan {
                    case .ending (_):
                        self.timeSpan = .ending(to: boundary)
                    case .periodic(let from, let period, _):
                        self.timeSpan = .periodic(from: from, period: period, to: boundary)
                    case .spanning(let from, _):
                        self.timeSpan = .spanning(from: from, to: boundary)
                    default:
                        // should never be called
                        fatalError("LifeExpenseTimeSpan : Case out of bound")
                }
            })
    }
    
    var bindingFromEvent : Binding<LifeEvent> {
        return Binding<LifeEvent> (
            get: {
                switch self.timeSpan {
                    case .starting (let from),
                         .periodic(let from , _ , _),
                         .spanning(let from , _):
                        return from.event ?? self.defaultFromEvent // default value should never be used
                    default:
                        // nout used anyway
                        return self.defaultFromEvent
                }
            },
            set: { event in
                let boundary = DateBoundary(event: event)
                switch self.timeSpan {
                    case .starting ( _):
                        self.timeSpan  = .starting(from: boundary)
                    case .periodic( _, let period, let to):
                        self.timeSpan  = .periodic(from: boundary, period: period, to: to)
                    case .spanning( _, let to):
                        self.timeSpan  = .spanning(from: boundary, to: to)
                    default:
                        // should never be called
                        fatalError("LifeExpenseTimeSpan : Case out of bound")
                }
            } )
    }
    var bindingToEvent : Binding<LifeEvent> {
        return Binding<LifeEvent> (
            get: {
                switch self.timeSpan {
                    case .ending (let to),
                         .periodic(_ , _ , let to),
                         .spanning(_ , let to):
                        return to.event ?? self.defaultToEvent // default value should never be used
                    default:
                        // nout used anyway
                        return self.defaultToEvent
                }
            },
            set: { event in
                let boundary = DateBoundary(event: event)
                switch self.timeSpan {
                    case .ending (_):
                        self.timeSpan  = .ending(to : boundary)
                    case .periodic(let from, let period, _):
                        self.timeSpan  = .periodic(from: from, period: period, to: boundary)
                    case .spanning(let from, _):
                        self.timeSpan  = .spanning(from: from, to: boundary)
                    default:
                        // should never be called
                        fatalError("LifeExpenseTimeSpan : Case out of bound")
                }
            } )
    }
    
    var bindingNameFrom: Binding<String> {
        return Binding<String> (
            get: {
                switch self.timeSpan {
                    case .starting (let from),
                         .periodic(let from , _ , _),
                         .spanning(let from , _):
                        return from.name
                    default:
                        // nout used anyway
                        return ""
                }
            },
            set: { name in
                switch self.timeSpan {
                    case .starting (let from):
                        var boundary   = from
                        boundary.name = name // modifier le nom associé à l'événement
                        self.timeSpan  = .starting(from: boundary)
                    case .periodic(let from, let period, let to):
                        var boundary   = from
                        boundary.name = name // modifier le nom associé à l'événement
                        self.timeSpan  = .periodic(from: boundary, period: period, to: to)
                    case .spanning(let from, let to):
                        var boundary   = from
                        boundary.name = name // modifier le nom associé à l'événement
                        self.timeSpan  = .spanning(from: boundary, to: to)
                    default:
                        // should never be called
                        fatalError("LifeExpenseTimeSpan : Case out of bound")
                }
            } )
    }
    var bindingNameTo: Binding<String> {
        return Binding<String> (
            get: {
                switch self.timeSpan {
                    case .ending (let to),
                         .periodic(_ , _ , let to),
                         .spanning(_ , let to):
                        return to.name // default value should never be used
                    default:
                        // nout used anyway
                        return ""
                }
            },
            set: { name in
                switch self.timeSpan {
                    case .ending (let to):
                        var boundary   = to
                        boundary.name = name // modifier le nom associé à l'événement
                        self.timeSpan = .ending(to: boundary)
                    case .periodic(let from, let period, let to):
                        var boundary   = to
                        boundary.name = name // modifier le nom associé à l'événement
                        self.timeSpan = .periodic(from: from, period: period, to: boundary)
                    case .spanning(let from, let to):
                        var boundary   = to
                        boundary.name = name // modifier le nom associé à l'événement
                        self.timeSpan = .spanning(from: from, to: boundary)
                    default:
                        fatalError("LifeExpenseTimeSpan : Case out of bound")
                }
            })
    }
    
    var bindingFrom : Binding<Int> {
        return Binding<Int> (
            get: {
                switch self.timeSpan {
                    case .periodic(let from, _ , _),
                         .starting(let from),
                         .spanning(let from, _):
                        return from.year
                    default:
                        return Date.now.year
                }
            },
            set: { year in
                switch self.timeSpan {
                    case .periodic(let from, let period, let to):
                        var boundary  = from
                        boundary.fixedYear = year // modifier l'année
                        self.timeSpan = .periodic(from: boundary, period: period, to: to)
                    case .starting(let from):
                        var boundary  = from
                        boundary.fixedYear = year // modifier l'année
                        self.timeSpan = .starting(from: boundary)
                    case .spanning(let from, to: let to):
                        var boundary  = from
                        boundary.fixedYear = year // modifier l'année
                        self.timeSpan = .spanning(from: boundary, to: to)
                    default:
                        fatalError("LifeExpenseTimeSpan : Case out of bound")
                }
            })
    }
    var bindingTo : Binding<Int> {
        return Binding<Int> (
            get: {
                switch self.timeSpan {
                    case .ending (let to),
                         .periodic(_ , _ , let to),
                         .spanning(_ , let to):
                        return to.year
                    default:
                        return Date.now.year
                }
            },
            set: { year in
                switch self.timeSpan {
                    case .ending (let to):
                        var boundary   = to
                        boundary.fixedYear = year // modifier l'année
                        self.timeSpan = .ending(to: boundary)
                    case .periodic(let from, let period, let to):
                        var boundary   = to
                        boundary.fixedYear = year // modifier l'année
                        self.timeSpan = .periodic(from: from, period: period, to: boundary)
                    case .spanning(let from, let to):
                        var boundary   = to
                        boundary.fixedYear = year // modifier l'année
                        self.timeSpan = .spanning(from: from, to: boundary)
                    default:
                        fatalError("LifeExpenseTimeSpan : Case out of bound")
                }
            })
    }
    
    
    var bindingPeriod : Binding<Int> {
        return Binding<Int> (
            get: {
                switch self.timeSpan {
                    case .periodic(_, let period, _):
                        return period
                    default:
                        return 1
                }
            },
            set: {
                switch self.timeSpan {
                    case .periodic(let from, _, let to):
                        self.timeSpan = .periodic(from: from, period: $0, to: to)
                    default:
                        fatalError("LifeExpenseTimeSpan : Case out of bound")
                }
            })
    }
    
    @State private var exceptionYear : Int
    @State private var caseIndex     : Int
    
    var body: some View {
        Group {
            Section(header: Text("PLAGE DE TEMPS")) {
                // choisir le type de TimeFrame pour la dépense
                CaseWithAssociatedValuePicker<LifeExpenseTimeSpan>(caseIndex: $caseIndex, label: "")
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: caseIndex, perform: updateLifeExpenseTimeSpanEnum)
            }
            // en fonction du type choisi
            if caseIndex == LifeExpenseTimeSpan.ending (to: DateBoundary()).id {
                // TimeSpan = .ending
                BoundaryEditView(label    : "Fin",
                                 event    : bindingToEvent,
                                 isLinked : bindingIsLinkedToToEvent,
                                 year     : bindingTo,
                                 name     : bindingNameTo)
                
            } else if caseIndex == LifeExpenseTimeSpan.starting(from: DateBoundary()).id {
                // TimeSpan = .starting
                BoundaryEditView(label    : "Début",
                                 event    : bindingFromEvent,
                                 isLinked : bindingIsLinkedToFromEvent,
                                 year     : bindingFrom,
                                 name     : bindingNameFrom)
                
            } else if caseIndex == LifeExpenseTimeSpan.spanning(from: DateBoundary(), to: DateBoundary()).id {
                // TimeSpan = .spanning
                BoundaryEditView(label    : "Début",
                                 event    : bindingFromEvent,
                                 isLinked : bindingIsLinkedToFromEvent,
                                 year     : bindingFrom,
                                 name     : bindingNameFrom)
                BoundaryEditView(label    : "Fin",
                                 event    : bindingToEvent,
                                 isLinked : bindingIsLinkedToToEvent,
                                 year     : bindingTo,
                                 name     : bindingNameTo)
                
            } else if caseIndex == LifeExpenseTimeSpan.periodic(from: DateBoundary(), period: 0, to: DateBoundary()).id {
                // TimeSpan = .periodic
                BoundaryEditView(label    : "Début",
                                 event    : bindingFromEvent,
                                 isLinked : bindingIsLinkedToFromEvent,
                                 year     : bindingFrom,
                                 name     : bindingNameFrom)
                BoundaryEditView(label    : "Fin",
                                 event    : bindingToEvent,
                                 isLinked : bindingIsLinkedToToEvent,
                                 year     : bindingTo,
                                 name     : bindingNameTo)
                Section(header: Text("Période")) {
                    Stepper(value: bindingPeriod, in: 0...100, step: 1, label: {
                        HStack {
                            Text("Période")
                            Spacer()
                            Text("\(bindingPeriod.wrappedValue) ans").foregroundColor(.secondary)
                        }
                    })
                }
                
            } else if caseIndex == LifeExpenseTimeSpan.exceptional(inYear: 0).id {
                // TimeSpan = .exceptional
                IntegerEditView(label: "Durant l'année", integer: $exceptionYear)
                    .onChange(of: exceptionYear, perform: updateExceptionalYear)
            }
        }
    }
    
    // MARK: - Initializers
    
    init(timeSpan : Binding<LifeExpenseTimeSpan>) {
        _timeSpan = timeSpan
        _caseIndex = State(initialValue: timeSpan.wrappedValue.id)
        switch timeSpan.wrappedValue {
            case .exceptional(let inYear):
                _exceptionYear = State(initialValue: inYear)
            default:
                _exceptionYear = State(initialValue: Date.now.year)
        }
    }
    
    // MARK: - Methods
    
    func updateLifeExpenseTimeSpanEnum(id: Int) {
        switch id {
            case LifeExpenseTimeSpan.permanent.id:
                self.timeSpan = .permanent
                
            case LifeExpenseTimeSpan.periodic(from: DateBoundary(), period: 0, to: DateBoundary()).id:
                self.timeSpan = .periodic(from   : DateBoundary(year: self.bindingFrom.wrappedValue),
                                          period : self.bindingPeriod.wrappedValue,
                                          to     : DateBoundary(year: self.bindingTo.wrappedValue))
                
            case LifeExpenseTimeSpan.starting(from: DateBoundary()).id:
                self.timeSpan = .starting(from: DateBoundary(year: self.bindingFrom.wrappedValue))
                
            case LifeExpenseTimeSpan.ending(to: DateBoundary()).id:
                self.timeSpan = .ending(to: DateBoundary(year: self.bindingTo.wrappedValue))
                
            case LifeExpenseTimeSpan.spanning(from: DateBoundary(), to: DateBoundary()).id:
                self.timeSpan = .spanning(from : DateBoundary(year: self.bindingFrom.wrappedValue),
                                          to   : DateBoundary(year: self.bindingTo.wrappedValue))
                
            case LifeExpenseTimeSpan.exceptional(inYear:0).id:
                self.timeSpan = .exceptional(inYear: self.exceptionYear)
                
            default:
                fatalError("LifeExpenseTimeSpan : Case out of bound")
        }
    }
    
    func updateExceptionalYear(year: Int) {
        self.timeSpan = .exceptional(inYear: year)
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

