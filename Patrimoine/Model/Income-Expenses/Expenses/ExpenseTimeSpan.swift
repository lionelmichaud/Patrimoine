//
//  ExpenseTimeSpan.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 29/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Elongation temporelle du poste de dépense

enum ExpenseTimeSpan: PickableIdentifiableEnum, Hashable {
    
    case permanent
    case periodic (from: DateBoundary, period: Int, to: DateBoundary)
    case starting (from: DateBoundary)
    case ending   (to:   DateBoundary)
    case spanning (from: DateBoundary, to: DateBoundary)
    case exceptional (inYear: Int)
    
    // MARK: - Static properties

    static var allCases: [ExpenseTimeSpan] {
        return [.permanent,
                .periodic (from: DateBoundary(), period: 1, to: DateBoundary()),
                .starting (from: DateBoundary()),
                .ending   (to:   DateBoundary()),
                .spanning (from: DateBoundary(), to: DateBoundary()),
                .exceptional (inYear: 0)]
    }
    
    @available(*, unavailable)
    case all
    
    // MARK: - Computed properties

    var rawValue: Int {
        switch self {
            case .permanent:
                return 1
            case .periodic(_, _, _):
                return 2
            case .starting (_):
                return 3
            case .ending (_):
                return 4
            case .spanning(_, _):
                return 5
            case .exceptional (_):
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
            case .periodic(_, _, _):
                return "Periodique"
            case .starting (_):
                return "Depuis..."
            case .ending (_):
                return "Jusqu'à..."
            case .spanning(_, _):
                return "De...à..."
            case .exceptional (_):
                return "Ponctuelle"
        }
    }
    
    // MARK: - Methods

    func contains (_ year: Int) -> Bool {
        switch self {
            case .permanent:
                return true
            
            case .periodic (let from, let period, let to):
                return (from.year...to.year).contains {
                    let includesYear = $0 == year
                    return includesYear && (($0 - from.year) % period == 0)
            }
            
            case .starting (let from):
                return year >= from.year
            
            case .ending (let to):
                return year <= to.year
            
            case .spanning (let from, let to):
                return (from.year...to.year).contains(year)
            
            case .exceptional(let inYear):
                return year == inYear
        }
    }
    
    var firstYear: Int { // computed
        switch self {
            case .permanent:
                return Date.now.year
            case .periodic(let from, period: _, to: _):
                return from.year
            case .starting(let from):
                return from.year
            case .ending(to: _):
                return Date.now.year
            case .spanning(let from, to: _):
                return from.year
            case .exceptional(let inYear):
                return inYear
        }
    }
    
    var lastYear: Int { // computed
        switch self {
            case .permanent:
                return Date.now.year + 100
            case .periodic(from: _, period: _, to: let to):
                return to.year
            case .starting(from: _):
                return Date.now.year + 100
            case .ending(let to):
                return to.year
            case .spanning(from: _, to: let to):
                return to.year
            case .exceptional(inYear: let inYear):
                return inYear
        }
    }
    
    var isValid: Bool {
        switch self {
            case .permanent:
                return true
            case .periodic(let from, _, let to):
                return from.year <= to.year
            case .starting(from: _):
                return true
            case .ending(to: _):
                return true
            case .spanning(let from, let to):
                return from.year <= to.year
            case .exceptional(inYear: _):
            return true
        }
    }
}

// MARK: - Extension: Codable

extension ExpenseTimeSpan: Codable {
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
        
        throw ExpenseTimeSpanError.decoding("Error decoding 'ExpenseTimeSpan' ! \(dump(container))")
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

extension ExpenseTimeSpan: CustomStringConvertible{
    public var description: String{
        get{
            switch self {
                case .permanent:
                    return "permanent"
                case .periodic (let from, let period, let to):
                    return "periodic - from \(from) every \(period) years - ending in \(to)"
                case .starting (let from):
                    return "starting from \(from)"
                case .ending (let to):
                    return "ending in \(to.year) on event: \(String(describing: to.event))"
                case .spanning (let from, let to):
                    return "starting from \(from) - ending in \(to)"
                case .exceptional(let inYear):
                    return "in \(inYear)"
            }
        }
    }
}

