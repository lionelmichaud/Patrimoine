//
//  Taxes.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - SINGLETON: Modèle fiscal
struct Fiscal {
    
    // MARK: - Nested types

    struct Model: BundleCodable {
        
        // MARK: - Static Properties
        
        static var defaultFileName   : String = "FiscalModelConfig.json"
        
        // MARK: - Properties
        
        var PASS                     : Double // Plafond Annuel de la Sécurité Sociale en €
        // impôts
        var incomeTaxes              : IncomeTaxesModel
        var isf                      : IsfModel
        var estateCapitalGainIrpp    : RealEstateCapitalGainIrppModel
        // charges sociales
        var estateCapitalGainTaxes   : RealEstateCapitalGainTaxesModel
        var pensionTaxes             : PensionTaxesModel
        var financialRevenuTaxes     : FinancialRevenuTaxesModel
        var turnoverTaxes            : TurnoverTaxesModel
        var allocationChomageTaxes   : AllocationChomageTaxesModel
        var layOffTaxes              : LayOffTaxes
        var lifeInsuranceTaxes       : LifeInsuranceTaxes
        var companyProfitTaxes       : CompanyProfitTaxesModel
        // autres
        var demembrement             : DemembrementModel
        var inheritanceDonation      : InheritanceDonation
        var lifeInsuranceInheritance : LifeInsuranceInheritance
        
        /// Initialise le modèle après l'avoir chargé à partir d'un fichier JSON du Bundle Main
        func initialized() -> Model {
            var model = self
            do {
                try model.incomeTaxes.initialize()
            } catch {
                fatalError("Failed to initialize Fiscal.model.incomeTaxes\n" + convertErrorToString(error))
            }
            do {
                try model.isf.initialize()
            } catch {
                fatalError("Failed to initialize Fiscal.model.isf\n" + convertErrorToString(error))
            }
            do {
                try model.inheritanceDonation.initialize()
            } catch {
                fatalError("Failed to initialize Fiscal.model.inheritanceDonation\n" + convertErrorToString(error))
            }
            do {
                try model.lifeInsuranceInheritance.initialize()
            } catch {
                fatalError("Failed to initialize Fiscal.model.lifeInsuranceInheritance\n" + convertErrorToString(error))
            }
            return model
        }
    }
    
    // MARK: - Static Properties

    static var model: Model = Model().initialized()

    // MARK: - Initializer
    
    private init() {
    }
}
