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
        self.periodicInvests = PeriodicInvestementArray(family: family)
        self.freeInvests     = FreeInvestmentArray(family: family)
        self.realEstates     = RealEstateArray(family: family)
        self.scpis           = ScpiArray(family: family) // SCPI hors dscpis
        self.sci             = SCI(family: family)
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
    
    /// Valeur nette taxable à l'IFI du patrimoine immobilier de la famille
    ///  - Note:
    ///  Pour l'IFI:
    ///
    ///  Foyer taxable:
    ///  - adultes + enfants non indépendants
    ///
    ///  Patrimoine taxable à l'IFI =
    ///  - tous les actifs immobiliers dont un propriétaire ou usufruitier
    ///  est un membre du foyer taxable
    ///
    ///  Valeur retenue:
    ///  - actif détenu en pleine-propriété: valeur de la part détenue en PP
    ///  - actif détenu en usufuit : valeur de la part détenue en PP
    ///  - la résidence principale faire l’objet d’une décote de 30 %
    ///  - les immeubles que vous donnez en location peuvent faire l’objet d’une décote de 10 % à 30 % environ
    ///  - en indivision : dans ce cas, ils sont imposables à hauteur de votre quote-part minorée d’une décote de l’ordre de 30 % pour tenir compte des contraintes liées à l’indivision)
    ///
    /// - Parameters:
    ///   - year: année d'évaluation
    ///   - evaluationMethod: méthode d'évaluation de la valeure des bien
    ///   - Returns: assiette nette IFI
    func valueOfRealEstateAssets(atEndOf year     : Int,
                                 evaluationMethod : EvaluationMethod) -> Double {
        switch evaluationMethod {
            case .ifi, .isf :
                /// on prend la valeure IFI des biens immobiliers
                /// pour: adultes + enfants non indépendants
                guard let family = Patrimoin.family else {return 0.0}
                
                var cumulatedvalue: Double = 0.0
                
                for member in family.members {
                    var toBeConsidered : Bool
                    
                    if (member is Adult) {
                        toBeConsidered = true
                    } else if (member is Child) {
                        let child = member as! Child
                        toBeConsidered = !child.isIndependant(during: year)
                    } else {
                        toBeConsidered = false
                    }
                    
                    if toBeConsidered {
                        cumulatedvalue +=
                            realEstates.ownedValue(by               : member.displayName,
                                                   atEndOf          : year,
                                                   evaluationMethod : evaluationMethod) +
                            scpis.ownedValue(by               : member.displayName,
                                             atEndOf          : year,
                                             evaluationMethod : evaluationMethod) +
                            sci.scpis.ownedValue(by               : member.displayName,
                                                 atEndOf          : year,
                                                 evaluationMethod : evaluationMethod)
                    }
                }
                return cumulatedvalue

            default:
                /// on prend la valeure totale de tous les biens immobiliers
                return
                    realEstates.value(atEndOf: year) +
                    scpis.value(atEndOf: year) +
                    sci.scpis.value(atEndOf: year)
        }
    }
    
    /// Calcule l'actif  taxable à la succession d'une personne
    /// - Note: [Reference](https://www.service-public.fr/particuliers/vosdroits/F14198)
    /// - Parameters:
    ///   - year: année d'évaluation
    ///   - thisPerson: personne dont on calcule la succession
    /// - Returns: actif taxable à la succession
    func taxableInheritanceValue(of decedent  : Person,
                                 atEndOf year : Int) -> Double {
        return 0
    }
}
