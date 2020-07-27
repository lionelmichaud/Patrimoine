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
public enum WorkIncomeType: PickableIdentifiableEnum {
    case salary (brutSalary: Double, taxableSalary: Double, netSalary: Double, fromDate: Date, healthInsurance: Double)
    case turnOver (BNC: Double, incomeLossInsurance: Double)
    
    @available(*, unavailable)
    case all
    
    public static var allCases: [WorkIncomeType] {
        return [.salary(brutSalary: 0, taxableSalary: 0, netSalary: 0, fromDate: Date.now, healthInsurance: 0), .turnOver(BNC: 0, incomeLossInsurance: 0)]
    }
    
    public static var salaryId: Int {
        WorkIncomeType.salary(brutSalary      : 0,
                                  taxableSalary   : 0,
                                  netSalary       : 0,
                                  fromDate        : Date.now,
                                  healthInsurance : 0).id
    }
    
    public static var turnOverId: Int {
        WorkIncomeType.turnOver(BNC: 0, incomeLossInsurance: 0).id
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

extension WorkIncomeType: Codable {
    // coding keys
    private enum CodingKeys: String, CodingKey {
        case salary_brutSalary, salary_taxableSalary, salary_netSalary, salary_fromDate, salary_healthInsurance
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
        if let salary_brutSalary = try? values.decode(Double.self, forKey: .salary_brutSalary) {
            if let salary_taxableSalary = try? values.decode(Double.self, forKey: .salary_taxableSalary) {
                if let salary_netSalary = try? values.decode(Double.self, forKey: .salary_netSalary) {
                    if let salary_fromDate = try? values.decode(Date.self, forKey: .salary_fromDate) {
                        if let salary_healthInsurance = try? values.decode(Double.self, forKey: .salary_healthInsurance) {
                            self = .salary(brutSalary      : salary_brutSalary,
                                           taxableSalary   : salary_taxableSalary,
                                           netSalary       : salary_netSalary,
                                           fromDate        : salary_fromDate,
                                           healthInsurance : salary_healthInsurance)
                                return
                            } else {
                                throw PersonalIncomeTypeCodingError.decoding("Error while decoding '.salary_healthInsurance' ! \(dump("values"))")
                            }
                        } else {
                            throw PersonalIncomeTypeCodingError.decoding("Error while decoding '.salary_fromDate' ! \(dump("values"))")
                        }
                }  else {
                    throw PersonalIncomeTypeCodingError.decoding("Error while decoding '.salary_netSalary' ! \(dump("values"))")
                }
            }  else {
                throw PersonalIncomeTypeCodingError.decoding("Error while decoding '.salary_taxableSalary' ! \(dump("values"))")
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
            case .salary (let brutSalary, let taxableSalary, let netSalary, let fromDate, let healthInsurance):
                try container.encode(brutSalary, forKey: .salary_brutSalary)
                try container.encode(taxableSalary, forKey: .salary_taxableSalary)
                try container.encode(netSalary, forKey: .salary_netSalary)
                try container.encode(fromDate, forKey: .salary_fromDate)
                try container.encode(healthInsurance, forKey: .salary_healthInsurance)
            case .turnOver (let BNC, let incomeLossInsurance):
                try container.encode(BNC, forKey: .turnOver_BNC)
                try container.encode(incomeLossInsurance, forKey: .turnOver_incomeLossInsurance)
        }
    }
}

