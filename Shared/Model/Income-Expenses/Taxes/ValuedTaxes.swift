//
//  Taxes.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 02/08/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - agrégat des Taxes

struct ValuedTaxes: DictionaryOfNamedValueTable {
    
    // MARK: - Properties
    
    var name        : String                          = ""
    var perCategory : [TaxeCategory: NamedValueTable] = [:]
    var irpp        : IncomeTaxesModel.IRPP
    var isf         : IsfModel.ISF

    init() {
        self.irpp = (amount         : 0,
                     familyQuotient : 0,
                     marginalRate   : 0,
                     averageRate    : 0)
        self.isf = (amount       : 0,
                    taxable      : 0,
                    marginalRate : 0)
    }
}
