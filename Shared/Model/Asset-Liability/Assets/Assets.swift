//
//  Assets.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 09/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Actifs de la famille

//typealias Assets = DictionaryOfItemArray<AssetsCategory,

struct Assets {
    // MARK: - Static Methods
    
    /// Définir le mode de simulation à utiliser pour tous les calculs futurs
    /// - Parameter simulationMode: mode de simulation à utiliser
    static func setSimulationMode(to simulationMode : SimulationModeEnum) {
        // injecter l'inflation dans les Types d'investissements procurant
        // un rendement non réévalué de l'inflation chaque année
        SCPI.simulationMode                = simulationMode
        PeriodicInvestement.simulationMode = simulationMode
        FreeInvestement.simulationMode     = simulationMode
        // on suppose que les loyers des biens immobiliers physiques sont réévalués de l'inflation
        // on suppose que les valeurs de vente des biens immobiliers physiques et papier sont réévalués de l'inflation
        RealEstateAsset.simulationMode     = simulationMode
        // on suppose que les salaires et les chiffres d'affaires sont réévalués de l'inflation
    }
    
    // MARK: - Properties
    
    var periodicInvests : PeriodicInvestementArray
    var freeInvests     : FreeInvestmentArray
    var realEstates     : RealEstateArray
    var scpis           : ScpiArray // SCPI hors de la SCI
    var sci             : SCI

    // MARK: - Initializers
    
    internal init(family: Family?) {
        self.periodicInvests = PeriodicInvestementArray()
        self.freeInvests     = FreeInvestmentArray()
        self.realEstates     = RealEstateArray(family: family)
        self.scpis           = ScpiArray() // SCPI hors dscpis
        self.sci             = SCI()
    }
    
    // MARK: - Methods
    
    func value(atEndOf year: Int) -> Double {
        var sum = realEstates.value(atEndOf: year)
        sum += scpis.value(atEndOf: year)
        sum += periodicInvests.value(atEndOf: year)
        sum += freeInvests.value(atEndOf: year)
        sum += sci.scpis.value(atEndOf: year)
        return sum
    }
    
    func valueOfRealEstateAssets(atEndOf year: Int) -> Double {
        realEstates.value(atEndOf: year) +
            scpis.value(atEndOf: year) +
            sci.scpis.value(atEndOf: year)
    }
    
    func valueOfInhabitedRealEstateAssets(atEndOf year: Int) -> Double {
        return realEstates.items.reduce(.zero, {result, element in
            element.isInhabited(during: year) ?
                result + element.value(atEndOf: year) :
                result
        })
        
    }
}
