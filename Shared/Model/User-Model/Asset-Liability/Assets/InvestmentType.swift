//
//  InvestmentType.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Type d'investissement

enum InvestementType {
    case lifeInsurance (periodicSocialTaxes: Bool = true,
                        clause: LifeInsuranceClause = LifeInsuranceClause())
    case pea
    case other
    
    static var allCases: [InvestementType] {
        return [.lifeInsurance(), .pea, .other]
    }
    
    @available(*, unavailable)
    case all
    
    var rawValue: Int {
        rawValueGeneric(of: self)
    }
}

// MARK: - Extensions

extension InvestementType: CustomStringConvertible {
    var description: String {
        switch self {
            case .lifeInsurance(let periodicSocialTaxes, let clause):
                return
                    """
                    TYPE D'INVESTISSEMENT:
                      Assurance Vie:
                      - Prélèvement périodique des contributions sociales: \(periodicSocialTaxes)
                      - \(clause)
                    """
                
            case .pea:
                return
                    """
                    TYPE D'INVESTISSEMENT:
                      PEA

                    """
                
            case .other:
                return
                    """
                    TYPE D'INVESTISSEMENT:
                      Autre

                    """
        }
    }
}

extension InvestementType: PickableIdentifiableEnum {
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
        case lifeInsurance_taxes, lifeInsurance_clause, PEA, other
    }
    
    // error type
    enum InvestementTypeCodingError: Error {
        case decoding(String)
    }
    
    // decode
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        // decode .lifeInsurance
        if let valueTaxes = try? values.decode(Bool.self, forKey: .lifeInsurance_taxes) {
            if let valueClause = try? values.decode(LifeInsuranceClause.self, forKey: .lifeInsurance_clause) {
                self = .lifeInsurance(periodicSocialTaxes: valueTaxes, clause: valueClause)
            return
            }
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
            case .lifeInsurance (let periodicSocialTaxes, let clause):
                try container.encode(periodicSocialTaxes, forKey: .lifeInsurance_taxes)
                try container.encode(clause, forKey: .lifeInsurance_clause)
            case .pea:
                try container.encode(true, forKey: .PEA)
            case .other:
                try container.encode(true, forKey: .other)
        }
    }
}
