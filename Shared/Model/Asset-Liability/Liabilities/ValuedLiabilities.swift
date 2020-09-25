//
//  ValuedLiabilities.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 25/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - agrégat des Passifs

struct ValuedLiabilities: DictionaryOfNamedValueTable {
    
    // MARK: - Properties
    
    var name       : String = ""
    var perCategory: [LiabilitiesCategory: NamedValueTable] = [:]
    
    init() { }
}
