//
//  PensionTaxes.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 12/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Charges sociales sur pensions de retraite
/// https://www.service-public.fr/particuliers/vosdroits/F2971
/// Charges sociales sur pensions de retraite
struct PensionTaxesModel: Codable {
    
    // MARK: - Nested types

    enum ModelError: Error {
        case outOfBounds
    }
    
    struct Model: BundleCodable, Versionable {
        static var defaultFileName : String = "PensionTaxesModel.json"
        var version           : Version
        let rebate            : Double // 10.0 // %
        let minRebate         : Double // 393   // € par déclarant
        let maxRebate         : Double // 3_850 // € par foyer fiscal
        let CSGdeductible     : Double // 5.9 // %
        let CRDS              : Double // 0.5 // % https://www.agirc-arrco.fr/fileadmin/agircarrco/documents/Doc_specif_page/prelevements_sociaux_bareme.pdf
        let CSG               : Double // 8.3 // % https://www.agirc-arrco.fr/fileadmin/agircarrco/documents/Doc_specif_page/prelevements_sociaux_bareme.pdf
        let additionalContrib : Double // 0.3 // % https://www.agirc-arrco.fr/fileadmin/agircarrco/documents/Doc_specif_page/prelevements_sociaux_bareme.pdf
        let healthInsurance   : Double // 1.0 // % https://www.agirc-arrco.fr/particuliers/vivre-retraite/prelevements-sociaux-prelevement-source/
        var totalRegimeGeneral: Double {
            CRDS + CSG + additionalContrib // %
        }
        var totalRegimeAgirc: Double {
            CRDS + CSG + additionalContrib + healthInsurance // %
        }
    }
    
    // MARK: - Properties

    var model: Model
    
    // MARK: - Methods

    /// pension du régime général nette de charges sociales
    /// - Parameter brut: pension brute du régéme général
    /// - Note:
    ///   - [régime Général](https://www.lafinancepourtous.com/pratique/retraite/preparer-son-depart-a-la-retraite/le-montant-de-la-retraite-du-brut-au-net/)
    ///   - [tout régime](https://www.toutsurmesfinances.com/impots/csg-des-retraites.html#CSG_non_deductible_ou_deductible_la_CSG_sur_les_retraites_est-elle_imposable)
    func netRegimeGeneral(_ brut: Double) -> Double {
        guard brut >= 0.0 else {
            return 0.0
        }
        return brut * (1.0 - model.totalRegimeGeneral / 100.0)
    }
    
    /// pension du régime complémentaire nette de charges sociales
    /// - Parameter brut: pension brute du régéme complémentaire
    /// - Note:
    ///   - [régime AGIRC-ARCCO](https://www.agirc-arrco.fr/particuliers/vivre-retraite/prelevements-sociaux-prelevement-source/)
    ///   - [tout régime](https://www.toutsurmesfinances.com/impots/csg-des-retraites.html#CSG_non_deductible_ou_deductible_la_CSG_sur_les_retraites_est-elle_imposable)
    func netRegimeAgirc(_ brut: Double) -> Double {
        guard brut >= 0.0 else {
            return 0.0
        }
        return brut * (1.0 - model.totalRegimeAgirc / 100.0)
    }
    
    /// charges sociales sur une pension brute du régime général
    /// - Parameter brut: pension brute du régime général
    func socialTaxesRegimeGeneral(_ brut: Double) -> Double {
        guard brut >= 0.0 else {
            return 0.0
        }
        return brut * model.totalRegimeGeneral / 100.0
    }
    
    /// charges sociales sur une pension brute du régime général
    /// - Parameter brut: pension brute du régime général
    func socialTaxesRegimeAgirc(_ brut: Double) -> Double {
        guard brut >= 0.0 else {
            return 0.0
        }
        return brut * model.totalRegimeAgirc / 100.0
    }
    
    /// Calcule la pension taxable à l'IRPP en applicant un abattement plafonné.
    /// Cet abattement est similaire à celui de 10% sur les salaires mais avec un plafond différent
    /// - Parameter net: pension nette de charges sociales
    /// - Returns: pension taxable à l'IRPP
    /// - Warning: une partie de la CSG est imposable donc la base tacable n'est pas la pension nette de charge
    ///             mais la pension nette de charge + la CSG non déductible.
    /// - Note:
    ///   - [tout régime](https://www.francetransactions.com/impots/taux-de-csg-deductibles-comment-ca-marche.html)
    ///   - [tout régime](https://www.la-retraite-en-clair.fr/organiser-depart-retraite/comprendre-pension-retraite/impots-retraite)
    func taxable(brut: Double, net: Double) throws -> Double {
        guard brut >= 0.0 else {
            return 0.0
        }
        guard net >= 0.0 else {
            throw ModelError.outOfBounds
        }
        let base   = net + csgNonDeductibleDeIrpp(brut)
        // TODO: - il faudrait prendre en compte que le rabais maxi est par foyer et non pas par personne
        let rebate = (base * model.rebate / 100.0).clamp(low: model.minRebate, high: model.maxRebate)
        return zeroOrPositive(base - rebate)
    }
    
    // TODO: - Prendre en compte la CSG déductible du salaire imposable
    /// Calcule le montant de CSG NON déductible du revenu imposable
    /// - Parameter brut: pension brute
    /// - Returns: fraction de la pension NON déductible du revenu imposable
    /// - Note:
    ///   - [reference](https://www.l-expert-comptable.com/a/532523-csg-deductible-en-2018.html)
    ///   - [tout régime](https://www.toutsurmesfinances.com/impots/csg-des-retraites.html#CSG_non_deductible_ou_deductible_la_CSG_sur_les_retraites_est-elle_imposable)
    func csgNonDeductibleDeIrpp(_ brut: Double) -> Double {
        guard brut >= 0.0 else {
            return 0.0
        }
        return brut * (model.CSG - model.CSGdeductible) / 100.0
    }
}
