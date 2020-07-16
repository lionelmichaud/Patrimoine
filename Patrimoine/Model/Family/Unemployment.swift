//
//  Unemployment.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 13/07/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Modèle de Chomage
struct Unemployment: Codable {
    
    // nested types
    
    enum Cause: String, PickableEnum, Codable, Hashable {
        case demission                          = "Démission"
        case licenciement                       = "Licenciement"
        case ruptureConventionnelleIndividuelle = "Rupture individuelle"
        case ruptureConventionnelleCollective   = "Rupture collective"
        case planSauvegardeEmploi               = "PSE"

        // methods
        
        var pickerString: String {
            return self.rawValue
        }
    }
    
    struct Model: Codable {
        var indemniteLicenciement : IndemniteLicenciement
        var allocationChomage     : AllocationChomage
    }
    
    // properties
    
    static var model: Model =
        Bundle.main.decode(Model.self,
                           from                 : "AllocChomageModel.json",
                           dateDecodingStrategy : .iso8601,
                           keyDecodingStrategy  : .useDefaultKeys)
    // methods
    
    /// Indique si la personne à droit à une allocation et une indemnité
    /// - Parameter cause: cause de la cessation d'activité
    /// - Returns: vrai si a droit
    static func canReceiveAllocation(for cause: Cause) -> Bool {
        cause != .demission
    }
}

// MARK: - Indeminité de licenciement
// https://www.juritravail.com/Actualite/respecter-salaire-minimum/Id/221441
// https://www.service-public.fr/particuliers/vosdroits/F408
struct IndemniteLicenciement: Codable {
    
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
        var correctionAncienneteGrid : [SliceCorrectionAnciennete]
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
    
    /// Calcul du nombre de mois de salaire de l'indemnité de licenciement pour une grille donnée
    /// - Parameters:
    ///   - nbYearsSeniority: nombre d'année d'ancienneté au moment du licenciement
    ///   - grid: grille à utiliser
    /// - Returns: nombre de mois de salaire de l'indemnité de licenciement selon la grille
    func compensationDuration(nbYearsSeniority years : Int,
                              grid                   : [SliceBase]) -> Double {
        var decompte = years
        let nbMonth: Double = grid.reduce(0.0) { m, slice in
            guard decompte > 0 else { return m }
            // nombre de mois dans la tranche
            let nbMonth = min(decompte, slice.nbYears)
            decompte -= nbMonth
            // application du facteur
            let increment = nbMonth.double() * slice.coef
            // ajout de l'incrément
            return m + increment
        }
        return nbMonth
    }
    
    /// Calcul du nombre de mois de salaire de l'indemnité de licenciement
    /// - Parameters:
    ///   - age: age au moment du licenciement
    ///   - nbYearsSeniority: nombre d'année d'ancienneté au moment du licenciement
    /// - Returns: nombre de mois de salaire de l'indemnité de licenciement
    func compensationDuration(age                    : Int,
                              nbYearsSeniority years : Int) -> Double {
        let allocLegale      = compensationDuration(nbYearsSeniority: years,
                                                    grid: model.legalGrid)
        var allocMetallurgie = compensationDuration(nbYearsSeniority: years,
                                                    grid: model.metallurgieGrid)
        // majoration fonction de l'age
        guard let slice1 = model.correctionAgeGrid.last(where: { $0.age <= age }) else {
            fatalError()
        }
        // majoration fonction de l'ancienneté
        guard let slice2 = slice1.correctionAncienneteGrid.last(where: { $0.anciennete <= years }) else {
            fatalError()
        }
        // application de la majoration
        allocMetallurgie *= (1 + slice2.majoration)
        
        // seuillage
        allocMetallurgie = allocMetallurgie.clamp(low  : slice2.min.double(),
                                                  high : slice2.max.double())
        
        return max(allocMetallurgie, allocLegale)
    }
    
    /// Calcul de l'indemnité de licenciement
    /// - Parameters:
    ///   - yearlyWorkIncome: dernier salaire annuel
    ///   - age: age au moment du licenciement
    ///   - nbYearsSeniority: nombre d'année d'ancienneté au moment du licenciement
    /// - Returns: montant de l'indemnité de licenciement
    func compensation(yearlyWorkIncome       : Double,
                      age                    : Int,
                      nbYearsSeniority years : Int) -> (nbMonth: Double, amount: Double) {
        let nbMonth = compensationDuration(age              : age,
                                           nbYearsSeniority : years)
        return (nbMonth: nbMonth,
                amount : nbMonth / 12.0 * yearlyWorkIncome)
    }
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
    
    /// Période de carence avant réduction de l'allocation journalière
    /// - Parameters:
    ///   - age: age au moment du licenciement
    ///   - SJR: Salaire Journalier de Référence
    /// - Returns: Période de carence avant réduction de l'allocation journalière en mois
    func reductionAfter(age: Int, SJR: Double) -> Int? {
        guard let slice = model.durationGrid.last(where: { $0.fromAge <= age }) else {
            fatalError()
        }
        // réduction application seulement au-dessus d'un certain seuil d'allocation
        let daylyAlloc = daylyAllocBeforeReduction(SJR: SJR).brut
        if daylyAlloc >= slice.reductionSeuilAlloc {
            return slice.reductionAfter
        } else {
            return nil
        }
    }
    
    /// Réduction de l'allocation journalière
    /// - Parameters:
    ///   - age: age au moment du licenciement
    ///   - daylyAlloc: allocation journalière
    /// - Returns: Coefficient de réduction de l'allocation journalière et durée de carence avant réduction
    func reduction(age: Int, daylyAlloc: Double) ->
        (percentReduc: Double, afterMonth: Int?) {
        guard let slice = model.durationGrid.last(where: { $0.fromAge <= age }) else {
            fatalError()
        }
        // réduction application seulement au-dessus d'un certain seuil d'allocation
        if daylyAlloc >= slice.reductionSeuilAlloc && slice.reduction != 0 {
            return (percentReduc : slice.reduction,
                    afterMonth   : slice.reductionAfter)
        } else {
            return (percentReduc : 0.0,
                    afterMonth   : nil)
        }
    }
    
    func daylyAllocBeforeReduction(SJR: Double) -> (brut: Double, net: Double) {
        // brute avant charges sociales
        let alloc1  = SJR * model.amountModel.case1Rate / 100.0 + model.amountModel.case1Fix
        let alloc2  = SJR * model.amountModel.case2Rate / 100.0
        let alloc   = max(alloc1, alloc2)
        let plafond = max(SJR * model.amountModel.maxAllocationPcent / 100.0,
                          model.amountModel.maxAllocationEuro)
        let brut    = alloc.clamp(low  : model.amountModel.minAllocation,
                                  high : plafond)

        // nette de charges sociales
        let net = Fiscal.model.socialTaxesOnAllocationChomage.net(brut : brut,
                                                                  SJR  : SJR)
        return (brut: brut, net: net)
    }
}
