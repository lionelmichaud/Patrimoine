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
enum RevenueCategory: Int, PickableEnum, Codable, Hashable {
    case workIncomes
    case pensions
    case layoffCompensation
    case unemployAlloc
    case financials
    case scpis
    case realEstateRents
    case scpiSale
    case realEstateSale
    
    // properties
    
    var id: Int {
        return self.rawValue
    }
    var pickerString: String {
        switch self {
            case .workIncomes:
                return "Revenu Travail"
            case .pensions:
                return "Revenu Pension"
            case .layoffCompensation:
                return "Indemnité de licenciement"
            case .unemployAlloc:
                return "Allocation Chomage"
            case .financials:
                return "Revenu Financier"
            case .scpis:
                return "Revenu SCPI"
            case .realEstateRents:
                return "Revenu Location"
            case .scpiSale:
                return "Vente SCPI"
            case .realEstateSale:
                return "Vente Immeuble"
        }
    }
}
