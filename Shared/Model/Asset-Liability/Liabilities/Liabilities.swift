//
//  Liabilities.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 09/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

struct Liabilities {
    var debts = DebtArray()
    var loans = LoanArray()
    
    func value(atEndOf year: Int) -> Double {
        loans.items.sumOfValues(atEndOf: year) +
            debts.items.sumOfValues(atEndOf: year)
    }
    
    func valueOfDebts(atEndOf year: Int) -> Double {
        debts.items.sumOfValues(atEndOf: year)
    }
    
    func valueOfLoans(atEndOf year: Int) -> Double {
        loans.items.sumOfValues(atEndOf: year)
    }
}
