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
    
    var name       : String = ""
    var perCategory: [TaxeCategory: NamedValueTable] = [:]
    var familyQuotient: Double = 0.0

    init() { }
}
