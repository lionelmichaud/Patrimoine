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
        ()
        // on suppose que les valeurs de vente des biens immobiliers physiques et papier sont réévalués de l'inflation
        () // RealEstateAsset.simulationMode     = simulationMode
        // on suppose que les salaires et les chiffres d'affaires sont réévalués de l'inflation
        ()
    }
    
    // MARK: - Properties
    
    var periodicInvests : PeriodicInvestementArray
    var freeInvests     : FreeInvestmentArray
    var realEstates     : RealEstateArray
    var scpis           : ScpiArray // SCPI hors de la SCI
    var sci             : SCI
    
    // MARK: - Initializers
    
    /// Charger les actifs stockés en fichier JSON
    /// - Parameter family: famille à laquelle associer le patrimoine
    /// - Note: family est utilisée pour injecter dans chaque actif un délégué family.ageOf
    ///         permettant de calculer les valeurs respectives des Usufruits et Nu-Propriétés
    internal init(family: Family?) {
        self.periodicInvests = PeriodicInvestementArray(family: family)
        self.freeInvests     = FreeInvestmentArray(family: family)
        self.realEstates     = RealEstateArray(family: family)
        self.scpis           = ScpiArray(family: family) // SCPI hors de la SCI
        self.sci             = SCI(family: family)

        // initialiser le vetcuer d'état de chaque FreeInvestement à la date courante
        resetFreeInvestementCurrentValue()
    }
    
    // MARK: - Methods
    
    /// Réinitialiser les valeurs courantes des investissements libres
    /// - Warning:
    ///   - Doit être appelée après le chargement d'un objet FreeInvestement depuis le fichier JSON
    ///   - Doit être appelée après toute simulation ayant affectée le Patrimoine (succession)
    mutating func resetFreeInvestementCurrentValue() {
        for idx in 0..<freeInvests.items.count {
            freeInvests[idx].resetCurrentState()
        }
//        var investements = [FreeInvestement]()
//        freeInvests.items.forEach {
//            var invest = $0
//            invest.resetCurrentState()
//            investements.append(invest)
//        }
//        freeInvests.items = investements
    }
    
    /// Recharger depuis les fichiers pour repartir d'une situation initiale
    /// - Note: Doit être appelé avant de lancer un nouveau run de simulation
    ///         susceptible de modifier le patrimoin en cours de simulation (tel que
    ///         les propriétaire des biens à l'issue des successions.
    mutating func reLoad() {
        periodicInvests = PeriodicInvestementArray(family: Patrimoin.family)
        freeInvests     = FreeInvestmentArray(family: Patrimoin.family)
        realEstates     = RealEstateArray(family: Patrimoin.family)
        scpis           = ScpiArray(family: Patrimoin.family) // SCPI hors de la SCI
        sci             = SCI(family: Patrimoin.family)
        
        // initialiser le vetcuer d'état de chaque FreeInvestement à la date courante
        resetFreeInvestementCurrentValue()
    }
    
    func value(atEndOf year: Int) -> Double {
        var sum = realEstates.value(atEndOf: year)
        sum += scpis.value(atEndOf: year)
        sum += periodicInvests.value(atEndOf: year)
        sum += freeInvests.value(atEndOf: year)
        sum += sci.scpis.value(atEndOf: year)
        return sum
    }
    
    /// Calls the given closure on each element in the sequence in the same order as a for-in loop
    func forEachOwnable(_ body: (Ownable) throws -> Void) rethrows {
        try periodicInvests.items.forEach(body)
        try freeInvests.items.forEach(body)
        try realEstates.items.forEach(body)
        try scpis.items.forEach(body)
        try sci.forEachOwnable(body)
    }

    /// Transférer la propriété d'un bien d'un défunt vers ses héritiers en fonction de l'option
    ///  fiscale du conjoint survivant éventuel
    /// - Parameters:
    ///   - decedentName: défunt
    ///   - chidrenNames: noms des enfants héritiers survivant éventuels
    ///   - spouseName: nom du conjoint survivant éventuel
    ///   - spouseFiscalOption: option fiscale du conjoint survivant éventuel
    mutating func transferOwnershipOfDecedent(decedentName       : String,
                                              chidrenNames       : [String]?,
                                              spouseName         : String?,
                                              spouseFiscalOption : InheritanceDonation.FiscalOption?) {
        for idx in 0..<periodicInvests.items.count {
            switch periodicInvests.items[idx].type {
                case .lifeInsurance:
                    // régles de transmission particulières pour l'Assurance Vie
                    // TODO: - ne transférer que ce qui n'est pas de l'assurance vie, sinon utiliser d'autres règles de transmission
                    ()
                    
                default:
                    periodicInvests.items[idx].ownership.transferOwnershipOfDecedent(decedentName       : decedentName,
                                                                                     chidrenNames       : chidrenNames,
                                                                                     spouseName         : spouseName,
                                                                                     spouseFiscalOption : spouseFiscalOption)
            }
        }
        for idx in 0..<freeInvests.items.count {
            switch freeInvests.items[idx].type {
                case .lifeInsurance:
                    // régles de transmission particulières pour l'Assurance Vie
                    // TODO: - ne transférer que ce qui n'est pas de l'assurance vie, sinon utiliser d'autres règles de transmission
                    ()
                    
                default:
                    freeInvests.items[idx].ownership.transferOwnershipOfDecedent(decedentName       : decedentName,
                                                                                 chidrenNames       : chidrenNames,
                                                                                 spouseName         : spouseName,
                                                                                 spouseFiscalOption : spouseFiscalOption)
            }
        }
        for idx in 0..<realEstates.items.count {
            realEstates.items[idx].ownership.transferOwnershipOfDecedent(decedentName       : decedentName,
                                                                         chidrenNames       : chidrenNames,
                                                                         spouseName         : spouseName,
                                                                         spouseFiscalOption : spouseFiscalOption)
        }
        for idx in 0..<scpis.items.count {
            scpis.items[idx].ownership.transferOwnershipOfDecedent(decedentName       : decedentName,
                                                                   chidrenNames       : chidrenNames,
                                                                   spouseName         : spouseName,
                                                                   spouseFiscalOption : spouseFiscalOption)
        }
        sci.transferOwnershipOfDecedent(decedentName       : decedentName,
                                        chidrenNames       : chidrenNames,
                                        spouseName         : spouseName,
                                        spouseFiscalOption : spouseFiscalOption)
    }
    
    /// Calcule  la valeur nette taxable du patrimoine immobilier de la famille selon la méthode de calcul choisie
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
    ///   - Returns: assiette nette fiscale calculée selon la méthode choisie
    func realEstateValue(atEndOf year     : Int,
                         evaluationMethod : EvaluationMethod) -> Double {
        switch evaluationMethod {
            case .ifi, .isf :
                /// on prend la valeure IFI des biens immobiliers
                /// pour: le foyer fiscal
                return FiscalHousehold.value(atEndOf: year) { name in
                    realEstates.ownedValue(by               : name,
                                           atEndOf          : year,
                                           evaluationMethod : evaluationMethod) +
                        scpis.ownedValue(by               : name,
                                         atEndOf          : year,
                                         evaluationMethod : evaluationMethod) +
                        sci.scpis.ownedValue(by               : name,
                                             atEndOf          : year,
                                             evaluationMethod : evaluationMethod)
                }

            default:
                /// on prend la valeure totale de tous les biens immobiliers
                return
                    realEstates.value(atEndOf: year) +
                    scpis.value(atEndOf: year) +
                    sci.scpis.value(atEndOf: year)
        }
    }
    
    /// Calcule l'actif taxable à la succession d'une personne
    /// - Note: [Reference](https://www.service-public.fr/particuliers/vosdroits/F14198)
    /// - Parameters:
    ///   - year: année d'évaluation
    ///   - decedent: personne dont on calcule la succession
    /// - Returns: actif taxable à la succession
    func taxableInheritanceValue(of decedent  : Person,
                                 atEndOf year : Int) -> Double {
        return
            realEstates.ownedValue(by               : decedent.displayName,
                                   atEndOf          : year,
                                   evaluationMethod : .inheritance) +
            scpis.ownedValue(by               : decedent.displayName,
                             atEndOf          : year,
                             evaluationMethod : .inheritance) +
            sci.scpis.ownedValue(by               : decedent.displayName,
                                 atEndOf          : year,
                                 evaluationMethod : .inheritance) +
            periodicInvests.ownedValue(by               : decedent.displayName,
                                       atEndOf          : year,
                                       evaluationMethod : .inheritance) +
            freeInvests.ownedValue(by               : decedent.displayName,
                                   atEndOf          : year,
                                   evaluationMethod : .inheritance)
    }
}
