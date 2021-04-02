//
//  IncomeCategory.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 27/07/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Catégories de revenus

/// Catégories de revenus
enum RevenueCategory: String, PickableEnum, Codable, Hashable {
    case workIncomes        = "Revenu Travail"
    case pensions           = "Pension"
    case layoffCompensation = "Indemnité de licenciement"
    case unemployAlloc      = "Allocation Chomage"
    case financials         = "Revenu Financier"
    case scpis              = "Revenu SCPI"
    case scpiSale           = "Vente SCPI"
    case realEstateRents    = "Revenu Location"
    case realEstateSale     = "Vente Immeuble"
    
    // properties
    
    var pickerString: String {
        return self.rawValue
    }

    // True si la catégorie de revenus est incorporée un NetCashFlow commun de fin d'année
    // et donc ré-inveti dans un actif sans distinction de son propriétaire
    var isPartOfCashFlow: Bool {
        switch self {
            case .workIncomes, .pensions,
                 .layoffCompensation, .unemployAlloc,
                 .scpis, .realEstateRents:
                return true
            default:
                return false
        }
    }
}
