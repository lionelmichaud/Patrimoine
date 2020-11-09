//
//  TimeSpanEditView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 02/06/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct TimeSpanEditView: View {
    
    static let defaultToEvent: LifeEvent = .deces
    static let defaultFromEvent  : LifeEvent = .cessationActivite

    // MARK: - Properties
    
    @Binding var timeSpan : LifeExpenseTimeSpan
    
    @State private var isLinkedToFromEvent : Bool
    @State private var isLinkedToToEvent   : Bool
    @State private var fromEvent     : LifeEvent
    @State private var toEvent       : LifeEvent
    @State private var fromName      : String
    @State private var toName        : String
    @State private var fromYear      : Int
    @State private var toYear        : Int
    @State private var period        : Int
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
                                 event    : $toEvent,
                                 isLinked : $isLinkedToToEvent,
                                 year     : $toYear,
                                 name     : $toName)
                
            } else if caseIndex == LifeExpenseTimeSpan.starting(from: DateBoundary()).id {
                // TimeSpan = .starting
                BoundaryEditView(label    : "Début",
                                 event    : $fromEvent,
                                 isLinked : $isLinkedToFromEvent,
                                 year     : $fromYear,
                                 name     : $fromName)
                
            } else if caseIndex == LifeExpenseTimeSpan.spanning(from: DateBoundary(), to: DateBoundary()).id {
                // TimeSpan = .spanning
                BoundaryEditView(label    : "Début",
                                 event    : $fromEvent,
                                 isLinked : $isLinkedToFromEvent,
                                 year     : $fromYear,
                                 name     : $fromName)
                BoundaryEditView(label    : "Fin",
                                 event    : $toEvent,
                                 isLinked : $isLinkedToToEvent,
                                 year     : $toYear,
                                 name     : $toName)
                
            } else if caseIndex == LifeExpenseTimeSpan.periodic(from: DateBoundary(), period: 0, to: DateBoundary()).id {
                // TimeSpan = .periodic
                BoundaryEditView(label    : "Début",
                                 event    : $fromEvent,
                                 isLinked : $isLinkedToFromEvent,
                                 year     : $fromYear,
                                 name     : $fromName)
                BoundaryEditView(label    : "Fin",
                                 event    : $toEvent,
                                 isLinked : $isLinkedToToEvent,
                                 year     : $toYear,
                                 name     : $toName)
                Section(header: Text("Période")) {
                    Stepper(value: $period, in: 0...100, step: 1, label: {
                        HStack {
                            Text("Période")
                            Spacer()
                            Text("\(period) ans").foregroundColor(.secondary)
                        }
                    })
                    .onChange(of: period, perform: updatePeriod)
                }
                
            } else if caseIndex == LifeExpenseTimeSpan.exceptional(inYear: 0).id {
                // TimeSpan = .exceptional
                IntegerEditView(label: "Durant l'année", integer: $exceptionYear)
                    .onChange(of: exceptionYear, perform: updateExceptionalYear)
            }
        }
        .onChange(of: toYear,   perform: updateToYear)
        .onChange(of: fromYear, perform: updateFromYear)
        .onChange(of: toName,   perform: updateToName)
        .onChange(of: fromName, perform: updateFromName)
        .onChange(of: toEvent,   perform: updateToEvent)
        .onChange(of: fromEvent, perform: updateFromEvent)
        .onChange(of: isLinkedToToEvent,   perform: updateLinkedToToEvent)
        .onChange(of: isLinkedToFromEvent, perform: updateLinkedToFromEvent)
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
        switch timeSpan.wrappedValue {
            case .periodic(_, let period, _):
                _period = State(initialValue: period)
            default:
                _period = State(initialValue: 1)
        }
        switch timeSpan.wrappedValue {
            case .ending (let to),
                 .periodic(_ , _ , let to),
                 .spanning(_ , let to):
                _toYear  = State(initialValue: to.year)
                _toName  = State(initialValue: to.name) // default value should never be used
                _toEvent = State(initialValue: to.event ?? TimeSpanEditView.defaultToEvent) // default value should never be used
                _isLinkedToToEvent = State(initialValue: to.event != nil)
            default:
                // nout used anyway
                _toYear  = State(initialValue: Date.now.year)
                _toName  = State(initialValue: "")
                _toEvent = State(initialValue: TimeSpanEditView.defaultToEvent)
                _isLinkedToToEvent = State(initialValue: false)
        }
        switch timeSpan.wrappedValue {
            case .starting (let from),
                 .periodic(let from , _ , _),
                 .spanning(let from , _):
                _fromYear  = State(initialValue: from.year)
                _fromName  = State(initialValue: from.name)
                _fromEvent = State(initialValue: from.event ?? TimeSpanEditView.defaultFromEvent) // default value should never be used
                _isLinkedToFromEvent = State(initialValue: from.event != nil)
            default:
                // nout used anyway
                _fromYear  = State(initialValue: Date.now.year)
                _fromName  = State(initialValue: "")
                _fromEvent = State(initialValue: TimeSpanEditView.defaultFromEvent)
                _isLinkedToFromEvent = State(initialValue: false)
        }
    }
    
    // MARK: - Methods
    
    func updateLifeExpenseTimeSpanEnum(id: Int) {
        switch id {
            case LifeExpenseTimeSpan.permanent.id:
                self.timeSpan = .permanent
                
            case LifeExpenseTimeSpan.periodic(from: DateBoundary(), period: 0, to: DateBoundary()).id:
                self.timeSpan = .periodic(from   : DateBoundary(year: self.fromYear),
                                          period : self.period,
                                          to     : DateBoundary(year: self.toYear))
                
            case LifeExpenseTimeSpan.starting(from: DateBoundary()).id:
                self.timeSpan = .starting(from: DateBoundary(year: self.fromYear))
                
            case LifeExpenseTimeSpan.ending(to: DateBoundary()).id:
                self.timeSpan = .ending(to: DateBoundary(year: self.toYear))
                
            case LifeExpenseTimeSpan.spanning(from: DateBoundary(), to: DateBoundary()).id:
                self.timeSpan = .spanning(from : DateBoundary(year: self.fromYear),
                                          to   : DateBoundary(year: self.toYear))
                
            case LifeExpenseTimeSpan.exceptional(inYear:0).id:
                self.timeSpan = .exceptional(inYear: self.exceptionYear)
                
            default:
                fatalError("LifeExpenseTimeSpan : Case out of bound")
        }
    }
    
    func updateExceptionalYear(year: Int) {
        self.timeSpan = .exceptional(inYear: year)
    }
    
    func updateToYear(year: Int) {
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
    }
    
    func updateFromYear(year: Int) {
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
    }
    
    func updatePeriod(period: Int) {
        switch self.timeSpan {
            case .periodic(let from, _, let to):
                self.timeSpan = .periodic(from: from, period: period, to: to)
            default:
                fatalError("LifeExpenseTimeSpan : Case out of bound")
        }
    }
    
    func updateToName(name: String) {
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
    }
    
    func updateFromName(name: String) {
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
    }
    
    func updateToEvent(event: LifeEvent) {
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
    }
    
    func updateFromEvent(event: LifeEvent) {
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
    }
    
    func updateLinkedToToEvent(isLinked: Bool) {
        // affecter une valeur par défaut au LifeEvent ou supprimer le lien vers le LifeEvent
        let boundary = DateBoundary(
            event: (isLinked ? TimeSpanEditView.defaultToEvent : nil))
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
    }
    
    func updateLinkedToFromEvent(isLinked: Bool) {
        // affecter une valeur par défaut au LifeEvent ou supprimer le lien vers le LifeEvent
        let boundary = DateBoundary(
            event: (isLinked ? TimeSpanEditView.defaultFromEvent : nil))
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

