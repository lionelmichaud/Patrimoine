//
//  Coordinator.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 02/05/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

struct Coordinator {
    static let shared = Coordinator()

    init() {
        let fiscalModel = Fiscal.model
        LayoffCompensation.setFiscalModel(fiscalModel)
        UnemploymentCompensation.setFiscalModel(fiscalModel)
    }
}
