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
        var indemniteLicenciement : LayoffCompensation
        var allocationChomage     : UnemploymentCompensation
    }
    
    // properties
    
    static var model: Model =
        Bundle.main.decode(Model.self,
                           from                 : "UnemploymentModelConfig.json",
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
// https://www.service-public.fr/particuliers/vosdroits/F987
struct LayoffCompensation: Codable {
    
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
        var multipleOfConventionalCompensation : Double = 1.0 // multiple de l'indemnité légale ou conventionnelle
        var multipleOfLastSalaryBrut           : Double = 2.0 // multiple du derneir salaire annuel brut
        var multipleOfActualCompensation       : Double = 0.5// multiple du montant de l'indemnité perçue
        var maxDiscount                        : Double = 246_816 // €
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
    func layoffCompensationInMonth(nbYearsSeniority years : Int,
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
    
    /// Calcul du nombre de mois de salaire de l'indemnité de licenciement selon le Code du Travail (Légal)
    /// - Parameter nbYearsSeniority: nombre d'année d'ancienneté au moment du licenciement
    /// - Returns: nombre de mois de salaire de l'indemnité de licenciement selon le Code du Travail (Légal)
    func layoffCompensationLegalInMonth(nbYearsSeniority years : Int) -> Double {
        layoffCompensationInMonth(nbYearsSeniority: years,
                                  grid: model.legalGrid)
    }
    
    /// Calcul du nombre de mois de salaire de l'indemnité de licenciement selon la Convention de la Métalurgie
    /// - Parameters:
    ///   - age: age au moment du licenciement
    ///   - nbYearsSeniority: nombre d'année d'ancienneté au moment du licenciement
    /// - Returns: nombre de mois de salaire de l'indemnité de licenciement selon la Convention de la Métalurgie
    func layoffCompensationConventionInMonth(age                    : Int,
                                             nbYearsSeniority years : Int) -> Double {
        let allocLegale      = layoffCompensationInMonth(nbYearsSeniority: years,
                                                         grid: model.legalGrid)
        var allocMetallurgie = layoffCompensationInMonth(nbYearsSeniority: years,
                                                         grid: model.metallurgieGrid)
        // majoration fonction de l'age
        guard let sliceAge = model.correctionAgeGrid.last(where: { $0.age <= age }) else {
            fatalError()
        }
        // majoration fonction de l'ancienneté
        guard let slice2 = sliceAge.correctionAncienneteGrid.last(where: { $0.anciennete <= years }) else {
            fatalError()
        }
        // application de la majoration
        allocMetallurgie *= (1 + slice2.majoration / 100)
        
        // seuillage
        allocMetallurgie = allocMetallurgie.clamp(low  : slice2.min.double(),
                                                  high : slice2.max.double())
        
        return max(allocMetallurgie, allocLegale)
    }
    
    /// Calcul de l'indemnité de licenciement selon le Code du travail (Légale)
    /// - Parameters:
    ///   - yearlyWorkIncomeBrut: dernier salaire annuel brut
    ///   - nbYearsSeniority: nombre d'année d'ancienneté au moment du licenciement
    /// - Returns: montant de l'indemnité de licenciement selon le Code du travail (Légale)
    func layoffCompensationLegal(yearlyWorkIncomeBrut   : Double,
                                 nbYearsSeniority years : Int) -> Double {
        let nbMonth = layoffCompensationLegalInMonth(nbYearsSeniority : years)
        // indemnité brute légale basée sur le dernier salaire brut
        return nbMonth * yearlyWorkIncomeBrut / 12.0
    }

    /// Calcul de l'indemnité de licenciement selon la Convention de la Métalurgie ou Supra-convention
    /// - Parameters:
    ///   - actualCompensationBrut: indemnité licenciement brute si > convention collective
    ///   - causeOfRetirement: cause de la cessation d'activité
    ///   - yearlyWorkIncomeBrut: dernier salaire annuel brut
    ///   - age: age au moment du licenciement
    ///   - nbYearsSeniority: nombre d'année d'ancienneté au moment du licenciement
    /// - Returns: montant de l'indemnité de licenciement selon la Convention de la Métalurgie ou Supra-convention
    func layoffCompensation(actualCompensationBrut : Double? = nil,
                            causeOfRetirement      : Unemployment.Cause,
                            yearlyWorkIncomeBrut   : Double,
                            age                    : Int,
                            nbYearsSeniority years : Int)
    -> (nbMonth : Double,
        brut    : Double,
        net     : Double,
        taxable : Double) {
        
        var taxable      : Double
        var irppDiscount : Double
        let nbMonth = layoffCompensationConventionInMonth(age              : age,
                                                          nbYearsSeniority : years)
        // indemnité brute conventionnelle basée sur le dernier salaire brut
        let brutConventionnel = nbMonth * yearlyWorkIncomeBrut / 12.0
        // indemnité réelle perçue (peut être plus élevée que l'indemnité conventionnelle)
        let brutReel          = actualCompensationBrut ?? brutConventionnel
        
        // fraction de l'indemnité taxable à l'IRPP
        switch causeOfRetirement {
            case .planSauvegardeEmploi, .ruptureConventionnelleCollective :
                // exonération totale de l'IRPP
                irppDiscount = brutReel
                
            case .licenciement, .ruptureConventionnelleIndividuelle :
                // Exonération partielle de l'IRPP :
                // 1 x le montant de l'indemnité légale ou conventionnelle
                let discount1 = model.irppDiscount.multipleOfConventionalCompensation * brutConventionnel
                // 2 x le montant de la rémunération brute annuelle que vous avez perçue l'année précédant votre licenciement
                var discount2 = model.irppDiscount.multipleOfLastSalaryBrut * yearlyWorkIncomeBrut
                discount2 = min(discount2, model.irppDiscount.maxDiscount)
                // 0,5 x le montant de l'indemnité perçue
                // TODO: - prendre en compte le fait que l'indemnité réelle peut être supérieure à l'indemnité conventionnelle
                var discount3 = model.irppDiscount.multipleOfActualCompensation * brutReel
                discount3 = min(discount3, model.irppDiscount.maxDiscount)
                // maximum des 3
                irppDiscount = max(discount1, discount2, discount3)
                irppDiscount = min(irppDiscount, brutReel)
                
            case .demission :
                // pas d'exonération de l'IRPP
                irppDiscount = 0
        }
        taxable = brutReel - irppDiscount
        
        // indemnité nette de charges sociales
        let net = Fiscal.model.layOffTaxes.net(compensationConventional : brutConventionnel,
                                               compensationBrut         : brutReel,
                                               compensationTaxable      : &taxable,
                                               irppDiscount             : irppDiscount)
        return (nbMonth : nbMonth,
                brut    : brutReel,
                net     : net,
                taxable : taxable)
    }
}

// MARK: - Allocation chomage
// https://www.service-public.fr/particuliers/vosdroits/F14860
// https://www.unedic.org/indemnisation/vos-questions-sur-indemnisation-assurance-chomage/pendant-combien-de-temps-puis-je-etre-indemnisee
// https://www.unedic.org/indemnisation/vos-questions-sur-indemnisation-assurance-chomage/comment-est-calculee-mon-allocation-chomage
// https://www.legisocial.fr/actualites-sociales/1097-le-nouveau-regime-differe-specifique-dindemnisation-pole-emploi-est-en-vigueur.html
// https://www.cadremploi.fr/editorial/conseils/droit-du-travail/detail/article/demission-legitime-et-allocations-chomage.html
// https://www.cadremploi.fr/editorial/conseils/droit-du-travail/detail/article/ce-que-les-cadres-doivent-savoir-sur-la-nouvelle-convention-dassurance-chomage0.html
// https://www.cadremploi.fr/editorial/conseils/droit-du-travail/detail/article/allocations-chomage-combien-toucheriez-vous.html

struct UnemploymentCompensation: Codable {
    
    // nested types
    
    struct DurationSlice: Codable {
        let fromAge             : Int
        let maxDuration         : Int // nb de mois d'indemnisation
        let reduction           : Double // % de dégressivité après le délai de reductionAfter
        let reductionAfter      : Int // nd de mois d'indemnisation avant dégressivité
        let reductionSeuilAlloc : Double // € d'allocation SJR min pour se voir appliqué la dégressivité
    }
    
    struct DelayModel: Codable {
        let delaiAttente                        : Int // 7 // L'ARE ne peut pas être versée avant la fin d'un délai d'attente, fixé à 7 jours
        let ratioDiffereSpecifique              : Double // 94,4 // nombre de jours obtenu en divisant le montant de l'indemnité prise en compte par 94,4
        let maxDiffereSpecifique                : Int // 150 // le différé ne doit pas dépasser 150 jours calendaires (5 mois)
        let maxDiffereSpecifiqueLicenciementEco : Int // 75 // ou, en cas de licenciement pour motif économique, 75 jours calendaires.
    }
    
    struct AmountModel: Codable {
        let case1Rate          : Double // 40.4 // % du salaire journalier de référence
        let case1Fix           : Double // 12.0 // € par jour
        let case2Rate          : Double // 57.0 // % du salaire journalier de référence
        let minAllocation      : Double // 29.26 // € par jour
        let maxAllocationPcent : Double // 75.0 // % du salaire journalier de référence
        let maxAllocationEuro  : Double // 253.14 // en €
    }
    
    struct Model: Codable {
        let durationGrid : [DurationSlice]
        let delayModel   : DelayModel
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
    
    /// Différé spécifique d'indemnisation (ne réduit pas la durée totale d'indemnisation)
    /// - Returns: durée en nombre de jours du Différé spécifique d'indemnisation
    /// - Parameters:
    ///   - SJR: Salaire Journalier de Référence
    ///   - compensationSupralegal: indemnités de rupture de contrat en plus des indemnités d'origine légale
    ///   - causeOfRetirement: cause de la cessation d'activité
    /// - Returns: Différé spécifique d'indemnisation en jours
    /// - Note: Lorsque vous percevez des indemnités de rupture de contrat en plus des indemnités d'origine légale,
    ///           un différé spécifique d'indemnisation est appliqué sur ces sommes.
    ///           - Ne diminue pas la durée totale d'indemnisation.
    ///           - Repousse uniquement le point de départ.
    func differeSpecifique(SJR                    : Double,
                           compensationSupralegal : Double,
                           causeOfRetirement      : Unemployment.Cause) -> Int {
        let delay = (compensationSupralegal / model.delayModel.ratioDiffereSpecifique).rounded(.up)
        print("delay = \(delay)")
        // plafonnemment différent selon la cause de licenciement
        let plafond = causeOfRetirement == .planSauvegardeEmploi ? model.delayModel.maxDiffereSpecifiqueLicenciementEco : model.delayModel.maxDiffereSpecifique
        print("plafon = \(plafond)")
        print("retenu = \(min(Int(delay), plafond))")
        return min(Int(delay), plafond)
    }
    
    /// Période avant réduction de l'allocation journalière
    /// - Parameters:
    ///   - age: age au moment du licenciement
    ///   - SJR: Salaire Journalier de Référence
    /// - Returns: Période avant réduction de l'allocation journalière en mois
    func reductionAfter(age: Int, SJR: Double) -> Int? {
        guard let slice = model.durationGrid.last(where: { $0.fromAge <= age }) else {
            fatalError()
        }
        // réduction application seulement au-dessus d'un certain seuil d'allocation
        let daylyAlloc = daylyAllocBeforeReduction(SJR: SJR).brut
        if daylyAlloc >= slice.reductionSeuilAlloc && slice.reduction != 0 {
            return slice.reductionAfter
        } else {
            return nil
        }
    }
    
    /// Coefficient de réduction de l'allocation journalière
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
    
    func daylyAllocBeforeReduction(SJR: Double)
    -> (brut: Double,
        net : Double) {
        
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
