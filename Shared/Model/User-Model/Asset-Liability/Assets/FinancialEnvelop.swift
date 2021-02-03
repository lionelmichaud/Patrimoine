//
//  FinancialEnvelop.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 15/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: Protocol d'enveloppe financière

protocol FinancialEnvelop: Ownable {
    var type            : InvestementType { get set }
    var isLifeInsurance : Bool { get }
    var clause          : LifeInsuranceClause? { get }
}

extension FinancialEnvelop {
    var isLifeInsurance: Bool {
        switch type {
        case .lifeInsurance:
            return true
        case .other, .pea:
            return false
        }
    }
    var clause: LifeInsuranceClause? {
        switch type {
        case .lifeInsurance(_, let clause):
            return clause
        case .other, .pea:
            return nil
        }
    }
}
