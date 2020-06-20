//
//  Assets.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 09/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

struct Assets {
    var periodicInvests = PeriodicInvestmentArray()
    var freeInvests     = FreeInvestmentArray()
    var realEstates     = RealEstateArray()
    var scpis           = ScpiArray() // SCPI hors de la SCI
    var sci             = SCI()
    
    func value(atEndOf year: Int) -> Double {
        var sum = realEstates.value(atEndOf: year)
        sum += scpis.value(atEndOf: year)
        sum += periodicInvests.value(atEndOf: year)
        sum += freeInvests.value(atEndOf: year)
        sum += sci.scpis.value(atEndOf: year)
        return sum
    }
}
