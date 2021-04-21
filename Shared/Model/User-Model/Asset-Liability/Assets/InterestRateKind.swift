//
//  InvestmentRate.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 14/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Type d'investissement

enum InterestRateKind {
    case contractualRate (fixedRate: Double)
    case marketRate (stockRatio: Double)
    
    // properties
    
    static var allCases: [InterestRateKind] {
        return [.contractualRate(fixedRate: 0.0),
                .marketRate(stockRatio: 0.0)]
    }
    
    @available(*, unavailable)
    case all
    
    var rawValue: Int {
        rawValueGeneric(of: self)
    }
}

// MARK: - Extensions

extension InterestRateKind: PickableIdentifiableEnum {
    var id: Int {
        return self.rawValue
    }
    
    var pickerString: String {
        switch self {
            case .contractualRate:
                return "Taux Contractuel"
                
            case .marketRate:
                return "Taux de Marché"
        }
    }

}

extension InterestRateKind: CustomStringConvertible {
    var description: String {
        switch self {
            case .contractualRate(let fixedRate):
                return "Taux Contractuel = \(fixedRate) %"
                
            case .marketRate(let stockRatio):
                return "Taux de Marché avec \(stockRatio) % d'actions et \(100 - stockRatio) % d'obligations"
        }
    }
}

extension InterestRateKind: Codable {
    // coding keys
    private enum CodingKeys: String, CodingKey {
        case contractualRate_fixedRate, marketRate_stockRatio
    }
    // error type
    enum InterestRateTypeCodingError: Error {
        case decoding(String)
    }
    // decode
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        // decode .contractualRate
        if let value = try? values.decode(Double.self, forKey: .contractualRate_fixedRate) {
            self = .contractualRate(fixedRate: value)
            return
        }
        
        // decode .marketRate
        if let value = try? values.decode(Double.self, forKey: .marketRate_stockRatio) {
            self = .marketRate(stockRatio: value)
            return
        }

        throw InterestRateTypeCodingError.decoding("Error decoding 'InterestRateType' ! \(dump(values))")
    }
    // encode
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
            case .contractualRate (let fixedRate):
                try container.encode(fixedRate, forKey: .contractualRate_fixedRate)
            case .marketRate (let stockRatio):
                try container.encode(stockRatio, forKey: .marketRate_stockRatio)
        }
    }
}
