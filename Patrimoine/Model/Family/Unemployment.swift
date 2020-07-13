//
//  Unemployment.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 13/07/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

struct Unemployment: Codable {
    
    // nested types
    
    struct Model: Codable {
        var indemniteLicenciement : IndemniteLicenciement
        var allocationChomage     : AllocationChomage
    }
    
    static var model: Model =
        Bundle.main.decode(Model.self,
                           from                 : "AllocChomageModel.json",
                           dateDecodingStrategy : .iso8601,
                           keyDecodingStrategy  : .useDefaultKeys)
}

// MARK: - Indeminité de licenciement
// https://www.juritravail.com/Actualite/respecter-salaire-minimum/Id/221441
// https://www.service-public.fr/particuliers/vosdroits/F408
struct IndemniteLicenciement: Codable {
    
    enum CauseLicenciement {
        case planSauvegardeEmploi, ruptureConventionnelleCollective, ruptureConventionnelleIndividuelle, licenciement
    }

    // nested types
    
    struct SliceBase: Codable {
        var nbYears : Int // nb d'année d'ancienneté dans l'entreprise
        var coef    : Double // nb de mois de salaire par année d'ancienneté
    }
    
    struct SliceCorrectionAnciennete: Codable {
        var anciennete : Int // nb d'année d'ancienneté dans l'entreprise
        var majoration : Double // %
        var min        : Int // nb de mois de salaire minimum
        var max        : Int // nb de mois de salaire maximum
    }
    
    struct SliceCorrection: Codable {
        var age                      : Int
        var correctionAncienneteGrid : [SliceCorrectionAnciennete] // nb d'année d'ancienneté dans l'entreprise
    }
    
    struct IrppDiscount: Codable {
        var multipleOfLegalIndemnite: Double = 1.0 // multiple de l'indemnité légale ou conventionnelle
        var multipleOfLastSalaryBrut: Double = 2.0 // multiple du derneir salaire annuel brut
        var multipleOfIndemnite: Double = 0.5// multiple du montant de l'indemnité perçue
        var maxDiscount : Double = 246_816 // €
        
    }
    struct Model: Codable {
        let legalGrid         : [SliceBase]
        let metallurgieGrid   : [SliceBase]
        let correctionAgeGrid : [SliceCorrection]
        let irppDiscount      : IrppDiscount
    }
    
    // properties
    
    var model: Model
    
    // methods
    

}

// MARK: - Allocation chomage
// https://www.cadremploi.fr/editorial/conseils/droit-du-travail/detail/article/demission-legitime-et-allocations-chomage.html

struct AllocationChomage: Codable {

    // nested types
    
    struct DurationSlice: Codable {
        var fromAge             : Int
        var maxDuration         : Int // nb de mois d'indemnisation
        var reduction           : Double // % de dégressivité
        var reductionAfter      : Int // nd de mois d'indemnisation avant dégressivité
        var reductionSeuilAlloc : Double // € d'allocation min pour dégressivité
    }
    
    struct AmountModel: Codable {
        let case1Rate          : Double = 40.4 // % du salaire journalier de référence
        let case1Fix           : Double = 12.0 // € par jour
        let case2Rate          : Double = 57.0 // % du salaire journalier de référence
        let minAllocation      : Double = 29.26 // € par jour
        let maxAllocationPcent : Double = 75.0 // % du salaire journalier de référence
        let maxAllocationEuro  : Double = 253.14 // en €
    }
    
    struct Model: Codable {
        let durationGrid : [DurationSlice]
        let amountModel  : AmountModel
    }
    
    // properties
    
    var model: Model
    
    // methods
    
    /// Durée d'indemnisation en mois
    /// - Parameter age: age au moment du licenciement
    /// - Returns: durée d'indemnisation en mois
    func durationInMonth(age: Int) -> Int {
        guard let slice = model.durationGrid.last(where: { $0.fromAge <= age }) else {
            fatalError()
        }
        return slice.maxDuration
    }
    
    /// Réduction de l'allocation journalière
    /// - Parameters:
    ///   - age: age au moment du licenciement
    ///   - daylyAlloc: allocation journalière
    /// - Returns: Coefficient de réduction de l'allocation journalière et durée de carence avant réduction
    func reduction(age: Int, daylyAlloc: Double) ->
        (percentReduc: Double, afterMonth: Int, reducedDailyAlloc: Double) {
        guard let slice = model.durationGrid.last(where: { $0.fromAge <= age }) else {
            fatalError()
        }
        // réduction application seulement au-dessus d'un certain seuil d'allocation
        if daylyAlloc >= slice.reductionSeuilAlloc {
            return (percentReduc      : slice.reduction,
                    afterMonth        : slice.reductionAfter,
                    reducedDailyAlloc : daylyAlloc * (1.0 - slice.reduction))
        } else {
            return (percentReduc      : 0.0,
                    afterMonth        : slice.reductionAfter,
                    reducedDailyAlloc : daylyAlloc)
        }
    }
    
    func daylyAllocBeforeReduction(SJR: Double) -> (brut: Double, net: Double) {
        // brute avant charges sociales
        let alloc1  = SJR * model.amountModel.case1Rate + model.amountModel.case1Fix
        let alloc2  = SJR * model.amountModel.case2Rate
        let alloc   = max(alloc1, alloc2)
        let plafond = max(SJR * model.amountModel.maxAllocationPcent,
                          model.amountModel.maxAllocationEuro)
        let brut = alloc.clamp(low  : model.amountModel.minAllocation,
                               high : plafond)

        // nette de charges sociales
        let net = Fiscal.model.socialTaxesOnAllocationChomage.net(brut : brut,
                                                                  SJR  : SJR)
        return (brut: brut, net: net)
    }
}
