//
//  Income.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Revenus du travail
/// revenus du travail
public enum PersonalIncomeType: PickableIdentifiableEnum {
    case salary (netSalary: Double, healthInsurance: Double)
    case turnOver (BNC: Double, incomeLossInsurance: Double)
    
    @available(*, unavailable)
    case all
    
    public static var allCases: [PersonalIncomeType] {
        return [.salary(netSalary: 0,healthInsurance: 0), .turnOver(BNC: 0, incomeLossInsurance: 0)]
    }
    
    public var rawValue: Int {
        rawValueGeneric(of: self)
//        if Mirror(reflecting: self).children.count != 0 {
//            // le swich case possède des valeurs
//            let selfCaseName = Mirror(reflecting: self).children.first!.label!
//
//            return PersonalIncomeType.allCases.firstIndex(where: { swichCase in
//                let switchingCaseName = Mirror(reflecting: swichCase).children.first!.label!
//                return switchingCaseName == selfCaseName
//            })!
//        } else {
//            return PersonalIncomeType.allCases.firstIndex(where: { swichCase in
//                return swichCase == self
//            })!
//        }
    }
    
    public var id: Int {
        return self.rawValue
    }
    
    var displayString: String {
        pickerString
    }
    
    var pickerString: String {
        switch self {
            case .salary:
                return "Salaire"
            case .turnOver:
                return "Chiffre d'affaire"
        }
    }
}

extension PersonalIncomeType: Codable {
    // coding keys
    private enum CodingKeys: String, CodingKey {
        case salary_netSalary, salary_healthInsurance
        case turnOver_BNC, turnOver_incomeLossInsurance
    }
    // error type
    enum PersonalIncomeTypeCodingError: Error {
        case decoding(String)
    }
    // decode
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        // decode .salary
        if let value1 = try? values.decode(Double.self, forKey: .salary_netSalary) {
            if let value2 = try? values.decode(Double.self, forKey: .salary_healthInsurance) {
                self = .salary(netSalary: value1, healthInsurance: value2)
                return
            } else {
                throw PersonalIncomeTypeCodingError.decoding("Error while decoding '.salary_healthInsurance' ! \(dump("values"))")
            }
        }
        
        // decode .turnOver
        if let value1 = try? values.decode(Double.self, forKey: .turnOver_BNC) {
            if let value2 = try? values.decode(Double.self, forKey: .turnOver_incomeLossInsurance) {
                self = .turnOver(BNC: value1, incomeLossInsurance: value2)
                return
            } else {
                throw PersonalIncomeTypeCodingError.decoding("Error while decoding '.turnOver_incomeLossInsurance' ! \(dump("values"))")
            }
        }
        
        throw PersonalIncomeTypeCodingError.decoding("Whoops! \(dump(values))")
    }
    // encode
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
            case .salary (let netSalary, let healthInsurance):
                try container.encode(netSalary, forKey: .salary_netSalary)
                try container.encode(healthInsurance, forKey: .salary_healthInsurance)
            case .turnOver (let BNC, let incomeLossInsurance):
                try container.encode(BNC, forKey: .turnOver_BNC)
                try container.encode(incomeLossInsurance, forKey: .turnOver_incomeLossInsurance)
        }
    }
    
}

