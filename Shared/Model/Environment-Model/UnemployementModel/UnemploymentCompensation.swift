//
//  UnemploymentCompensation.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 16/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation
import os

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.UnemploymentCompensation")

// MARK: - Modèle d'Allocation chomage
// https://www.service-public.fr/particuliers/vosdroits/F14860
// https://www.unedic.org/indemnisation/vos-questions-sur-indemnisation-assurance-chomage/pendant-combien-de-temps-puis-je-etre-indemnisee
// https://www.unedic.org/indemnisation/vos-questions-sur-indemnisation-assurance-chomage/comment-est-calculee-mon-allocation-chomage
// https://www.legisocial.fr/actualites-sociales/1097-le-nouveau-regime-differe-specifique-dindemnisation-pole-emploi-est-en-vigueur.html
// https://www.cadremploi.fr/editorial/conseils/droit-du-travail/detail/article/demission-legitime-et-allocations-chomage.html
// https://www.cadremploi.fr/editorial/conseils/droit-du-travail/detail/article/ce-que-les-cadres-doivent-savoir-sur-la-nouvelle-convention-dassurance-chomage0.html
// https://www.cadremploi.fr/editorial/conseils/droit-du-travail/detail/article/allocations-chomage-combien-toucheriez-vous.html

struct UnemploymentCompensation: Codable {
    
    // MARK: - Nested types

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
        let minAllocationEuro  : Double // 29.26 // € par jour
        let maxAllocationPcent : Double // 75.0 // % du salaire journalier de référence
        let maxAllocationEuro  : Double // 253.14 // en €
    }
    
    struct Model: BundleCodable, Versionable {
        static var defaultFileName: String = "UnemploymentCompensationModel.json"
        
        var version      : Version
        let durationGrid : [DurationSlice]
        let delayModel   : DelayModel
        let amountModel  : AmountModel
    }
    
    // MARK: - Static Properties

    private static var fiscalModel: Fiscal.Model = Fiscal.model

    // MARK: - Properties

    var model: Model
    
    // MARK: - Static Methods

    static func setFiscalModel(_ model: Fiscal.Model) {
        fiscalModel = model
    }

    // MARK: - Methods

    /// Durée d'indemnisation en mois
    /// - Parameter age: age au moment du licenciement
    /// - Returns: durée d'indemnisation en mois
    func durationInMonth(age: Int) -> Int? {
        model.durationGrid.last(\.maxDuration, where: \.fromAge, <=, age)
    }
    
    /// Différé spécifique d'indemnisation (ne réduit pas la durée totale d'indemnisation)
    /// - Returns: durée en nombre de jours du Différé spécifique d'indemnisation
    /// - Parameters:
    ///   - SJR: Salaire Journalier de Référence
    ///   - compensationSupralegal: indemnités de rupture de contrat en plus des indemnités d'origine légale
    ///   - causeOfUnemployement: cause de la cessation d'activité
    /// - Returns: Différé spécifique d'indemnisation en jours
    /// - Note: Lorsque vous percevez des indemnités de rupture de contrat en plus des indemnités d'origine légale,
    ///           un différé spécifique d'indemnisation est appliqué sur ces sommes.
    ///           - Ne diminue pas la durée totale d'indemnisation.
    ///           - Repousse uniquement le point de départ.
    ///  - [village-justice.com](https://www.village-justice.com/articles/differe-indemnisation-les-regles-avant-apres-reforme,34272.html)
    func differeSpecifique(compensationSupralegal : Double,
                           causeOfUnemployement   : Unemployment.Cause) -> Int {
        let delay = (compensationSupralegal / model.delayModel.ratioDiffereSpecifique).rounded(.down)
        // plafonnemment différent selon la cause de licenciement
        let plafond = (causeOfUnemployement == .planSauvegardeEmploi) ?
            model.delayModel.maxDiffereSpecifiqueLicenciementEco :
            model.delayModel.maxDiffereSpecifique
        return min(Int(delay), plafond)
    }
    
    /// Calcul de la durée en mois de la période avant réduction de l'allocation journalière
    /// - Parameters:
    ///   - age: age au moment du licenciement
    ///   - SJR: Salaire Journalier de Référence
    /// - Returns: Période avant réduction de l'allocation journalière en mois
    ///            Retourne `nil` s'il n'y aura jamais de réduction
    /// - Note: La période commence au premier jour d'indemnisation
    func reductionAfter(age: Int, SJR: Double) -> Int? {
        guard let slice = model.durationGrid.last(where: \.fromAge, <=, age) else {
            customLog.log(level: .error, "reduction:slice = nil")
            fatalError("reduction:slice = nil")
        }
        // réduction application seulement au-dessus d'un certain seuil d'allocation
        let daylyAlloc = daylyAllocBeforeReduction(SJR: SJR).brut
        if daylyAlloc >= slice.reductionSeuilAlloc && slice.reduction != 0 {
            return slice.reductionAfter
        } else {
            return nil
        }
    }
    
    /// Calcul des Durée et Coefficient de réduction de l'allocation journalière
    /// - Parameters:
    ///   - age: age au moment du licenciement
    ///   - daylyAlloc: allocation journalière
    /// - Returns: Coefficient de réduction de l'allocation journalière et durée de carence avant réduction
    ///            `afterMonth` = `nil` s'il n'y aura jamais de réduction
    /// - Note: La période commence au premier jour d'indemnisation
    func reduction(age: Int, daylyAlloc: Double) ->
    (percentReduc : Double,
     afterMonth   : Int?) {
        guard let slice = model.durationGrid.last(where: \.fromAge, <=, age) else {
            customLog.log(level: .error, "reduction:slice = nil")
            fatalError("reduction:slice = nil")
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
    
    /// Calcul l'allocation de recherche d'emploi (ARE) avant son éventuelle réduction
    /// - Parameters:
    ///   - SJR: Salaire Journalier de Référence
    /// - Returns: Allocation de recherche d'emploi (ARE) avant son éventuelle réduction
    /// - Note: [unedic.org](https://www.unedic.org/indemnisation/vos-questions-sur-indemnisation-assurance-chomage/comment-est-calculee-mon-allocation-chomage)
    func daylyAllocBeforeReduction(SJR: Double)
    -> (brut: Double,
        net : Double) {
        
        // brute avant charges sociales
        //  1er mode de calcul
        let alloc1  = SJR * model.amountModel.case1Rate / 100.0 + model.amountModel.case1Fix
        //  2nd mode de calcul
        let alloc2  = SJR * model.amountModel.case2Rate / 100.0
        //  on retient le meilleur des deux
        let alloc   = max(alloc1, alloc2)
        let plafond = min(SJR * model.amountModel.maxAllocationPcent / 100.0,
                          model.amountModel.maxAllocationEuro)
        let brut    = alloc.clamp(low  : model.amountModel.minAllocationEuro,
                                  high : plafond)
        
        // nette de charges sociales
        let net = try! UnemploymentCompensation.fiscalModel.allocationChomageTaxes.net(
            brut : brut,
            SJR  : SJR)
        return (brut : brut,
                net  : net)
    }
}
