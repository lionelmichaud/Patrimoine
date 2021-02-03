//
//  LifeExpenseTimeSpan.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 29/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import os

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.TimeSpan")

// MARK: - Elongation temporelle du poste de dépense

enum TimeSpan: PickableIdentifiableEnum, Hashable {
    // les années de début et de fin sont inclues
    case permanent
    case periodic (from: DateBoundary, period: Int, to: DateBoundary)
    case starting (from: DateBoundary)
    case ending   (to:   DateBoundary)
    case spanning (from: DateBoundary, to: DateBoundary)
    case exceptional (inYear: Int)
    
    // MARK: - Static properties

    static var allCases: [TimeSpan] {
        return [.permanent,
                .periodic (from: DateBoundary.empty, period: 1, to: DateBoundary.empty),
                .starting (from: DateBoundary.empty),
                .ending   (to:   DateBoundary.empty),
                .spanning (from: DateBoundary.empty, to: DateBoundary.empty),
                .exceptional (inYear: 0)]
    }
    
    // MARK: - Computed properties

    var rawValue: Int {
        switch self {
            case .permanent:
                return 1
            case .periodic:
                return 2
            case .starting:
                return 3
            case .ending:
                return 4
            case .spanning:
                return 5
            case .exceptional:
                return 6
        }
    }
    
    var id: Int {
        return self.rawValue
    }
    
    var pickerString: String {
        switch self {
            case .permanent:
                return "Permanent"
            case .periodic:
                return "Periodique"
            case .starting:
                return "Depuis..."
            case .ending:
                return "Jusqu'à..."
            case .spanning:
                return "De...à..."
            case .exceptional:
                return "Ponctuelle"
        }
    }
    
    // MARK: - Methods

    func contains (_ year: Int) -> Bool { // swiftlint:disable:this cyclomatic_complexity
        switch self {
            case .permanent:
                return true
            
            case .periodic (let from, let period, let to):
                guard to.year != nil && from.year != nil else {
                    customLog.log(level: .info, "contains: to.year = nil or from.year = nil")
                    return false
                }
                guard from.year! <= to.year! else {
//                    customLog.log(level: .info, "contains: from.year \(from.year!) > to.year \(to.year!)")
                    return false
                }
                return (from.year!...to.year!).contains {
                    let includesYear = $0 == year
                    return includesYear && (($0 - from.year!) % period == 0)
            }
            
            case .starting (let from):
                guard from.year != nil else {
                    customLog.log(level: .info, "contains: from.year = nil")
                    return false
                }
                return year >= from.year!
            
            case .ending (let to):
                guard to.year != nil else {
                    customLog.log(level: .info, "contains: to.year = nil")
                    return false
                }
                return year <= to.year!
            
            case .spanning (let from, let to):
                guard to.year != nil && from.year != nil else {
                    customLog.log(level: .info, "contains: to.year = nil or from.year = nil")
                    return false
                }
                if from.year! > to.year! { return false }
                return (from.year!...to.year!).contains(year)
            
            case .exceptional(let inYear):
                return year == inYear
        }
    }
    
    var firstYear: Int? { // computed
        switch self {
            case .permanent:
                return Date.now.year
                
            case .ending(let to):
                guard to.year != nil else {
                    customLog.log(level: .info, "contains: to.year = nil")
                    return nil
                }
                return min(Date.now.year, to.year!)
                
            case .periodic(let from, period: _, to: _),
                 .starting(let from),
                 .spanning(let from, to: _):
                return from.year
                
            case .exceptional(let inYear):
                return inYear
        }
    }
    
    var lastYear: Int? { // computed
        switch self {
            case .permanent:
                return Date.now.year + 100
            case .periodic(from: _, period: _, to: let to),
                 .spanning(from: _,            to: let to),
                 .ending(let to):
                return to.year
            case .starting(let from):
                guard from.year != nil else {
                    customLog.log(level: .info, "contains: from.year = nil")
                    return nil
                }
                return Date.now.year + 100
            case .exceptional(inYear: let inYear):
                return inYear
        }
    }
    
    var isValid: Bool {
        switch self {
            case .permanent:
                return true
            case .periodic(let from, _, let to),
                 .spanning(let from,    let to):
                guard let fromYear = from.year, let toYear = to.year else { return false }
                return fromYear <= toYear
            case .starting(from: _):
                return true
            case .ending(to: _):
                return true
            case .exceptional(inYear: _):
            return true
        }
    }
}

// MARK: - Extension: Codable

extension TimeSpan: Codable {
    // coding keys
    private enum CodingKeys: String, CodingKey {
        case permanent, periodic_from, periodic_to, periodic_period, spanning_from, spanning_to
        case starting_from, ending_to, exceptional_in
    }
    // error type
    enum ExpenseTimeSpanError: Error {
        case decoding(String)
    }
    
    // MARK: - Decoding

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // decode .permanent
        if (try? container.decode(Bool.self, forKey: .permanent)) != nil {
            self = .permanent
            return
        }
        
        // decode .periodic
        if let from = try? container.decode(DateBoundary.self, forKey: .periodic_from) {
            if let to = try? container.decode(DateBoundary.self, forKey: .periodic_to) {
                if let period = try? container.decode(Int.self, forKey: .periodic_period) {
                    self = .periodic(from: from, period: period, to: to)
                    return
                }
            }
        }
        
        // decode .spanning
        if let from = try? container.decode(DateBoundary.self, forKey: .spanning_from) {
            if let to = try? container.decode(DateBoundary.self, forKey: .spanning_to) {
                self = .spanning(from: from, to: to)
                return
            }
        }
        
        // decode .starting
        if let from = try? container.decode(DateBoundary.self, forKey: .starting_from) {
            self = .starting (from: from)
            return
        }
        
        // decode .ending
        if let to = try? container.decode(DateBoundary.self, forKey: .ending_to) {
            self = .ending (to: to)
            return
        }
        
        // decode .exceptional
        if let inYear = try? container.decode(Int.self, forKey: .exceptional_in) {
            self = .exceptional (inYear: inYear)
            return
        }
        
        throw ExpenseTimeSpanError.decoding("Error decoding 'LifeExpenseTimeSpan' ! \(dump(container))")
    }

    // MARK: - Coding

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
            case .permanent:
                try container.encode(true, forKey: .permanent)
            
            case .starting (let from):
                try container.encode(from, forKey: .starting_from)
            
            case .ending (let to):
                try container.encode(to, forKey: .ending_to)

            case .exceptional (let inYear):
                try container.encode(inYear, forKey: .exceptional_in)
            
            case .spanning (let from, let to):
                try container.encode(from, forKey: .spanning_from)
                try container.encode(to, forKey: .spanning_to)
            
            case .periodic (let from, let period, let to):
                try container.encode(from, forKey: .periodic_from)
                try container.encode(to, forKey: .periodic_to)
                try container.encode(period, forKey: .periodic_period)
        }
    }
}

// MARK: - Extension: Description

extension TimeSpan: CustomStringConvertible {
    public var description: String {
        switch self {
            case .permanent:
                return "permanent"
            case .periodic (let from, let period, let to):
                return "periodic - from \(from) every \(period) years - ending in \(to)"
            case .starting (let from):
                return "starting from \(from)"
            case .ending (let to):
                return "ending in \(to.year ?? -1) on event: \(String(describing: to.event))"
            case .spanning (let from, let to):
                return "starting from \(from) - ending in \(to)"
            case .exceptional(let inYear):
                return "in \(inYear)"
        }
    }
}
