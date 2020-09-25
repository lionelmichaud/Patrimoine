//
//  ValuedAssets.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 22/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - agrégat des Actifs

struct ValuedAssets: DictionaryOfNamedValueTable {
    
    // MARK: - Properties
    
    var name       : String = ""
    var perCategory: [AssetsCategory: NamedValueTable] = [:]

    init() { }
}
