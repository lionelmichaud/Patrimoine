//
//  InvestmentType.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Type d'investissement
enum InvestementType: PickableIdentifiableEnum {
    case lifeInsurance (periodicSocialTaxes: Bool)
    case pea
    case other
    
    static var allCases: [InvestementType] {
        return [.lifeInsurance (periodicSocialTaxes: true), .pea, .other]
    }
    
    @available(*, unavailable)
    case all
    
    var rawValue: Int {
        rawValueGeneric(of: self)
    }
    
    var id: Int {
        return self.rawValue
    }
    
    var pickerString: String {
        switch self {
            case .lifeInsurance:
                return "Assurance Vie"
            case .pea:
                return "PEA"
            case .other:
                return "Autre"
        }
    }
}

extension InvestementType: Codable {
    // coding keys
    private enum CodingKeys: String, CodingKey {
        case lifeInsurance_taxes, PEA, other
    }
    // error type
    enum InvestementTypeCodingError: Error {
        case decoding(String)
    }
    // decode
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        // decode .lifeInsurance
        if let value = try? values.decode(Bool.self, forKey: .lifeInsurance_taxes) {
            self = .lifeInsurance(periodicSocialTaxes: value)
            return
        }
        
        // decode .PEA
        if (try? values.decode(Bool.self, forKey: .PEA)) != nil {
            self = .pea
            return
        }
        
        // decode .other
        if (try? values.decode(Bool.self, forKey: .other)) != nil {
            self = .other
            return
        }
        
        throw InvestementTypeCodingError.decoding("Error decoding 'InvestementType' ! \(dump(values))")
    }
    // encode
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
            case .lifeInsurance (let periodicSocialTaxes):
                try container.encode(periodicSocialTaxes, forKey: .lifeInsurance_taxes)
            case .pea:
                try container.encode(true, forKey: .PEA)
            case .other:
                try container.encode(true, forKey: .other)
        }
    }
}
