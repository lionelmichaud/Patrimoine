//
//  Taxes.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Modèle fiscal
struct Fiscal: Codable {
    
    // MARK: - Nested types

    struct Model: Codable, Versionable {
        var version                        : Version
        var PASS                           : Double // Plafond Annuel de la Sécurité Sociale en €
        // impôts
        var incomeTaxes                    : IncomeTaxesModel
        var isf                            : IsfModel
        var estateCapitalGainIrpp          : RealEstateCapitalGainIrppModel
        // charges sociales
        var estateCapitalGainTaxes         : RealEstateCapitalGainTaxesModel
        var pensionTaxes                   : PensionTaxesModel
        var financialRevenuTaxes           : FinancialRevenuTaxesModel
        var turnoverTaxes                  : TurnoverTaxesModel
        var allocationChomageTaxes         : AllocationChomageTaxesModel
        var layOffTaxes                    : LayOffTaxes
        var lifeInsuranceTaxes             : LifeInsuranceTaxes
        var companyProfitTaxes             : CompanyProfitTaxesModel
        // autres
        var demembrement                   : DemembrementModel
        var inheritanceDonation            : InheritanceDonation
        var lifeInsuranceInheritance       : LifeInsuranceInheritance
    }
    
    // MARK: - Static Methods

    static func initializedModel() -> Model {
        var model = Bundle.main.decode(Model.self,
                                       from                 : "FiscalModelConfig.json",
                                       dateDecodingStrategy : .iso8601,
                                       keyDecodingStrategy  : .useDefaultKeys)
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
        model.inheritanceDonation.initialize()
        model.lifeInsuranceInheritance.initialize()
        return model
    }
    
    // MARK: - Static Properties

    static var model: Model = Fiscal.initializedModel()
}

// MARK: - Charges sociales sur allocation chomage
struct AllocationChomageTaxesModel: Codable {
    
    // MARK: Nested types
    
    enum ModelError: Error {
        case outOfBounds
    }
    
    struct Model: Codable, Versionable {
        var version       : Version
        let assiette      : Double // 98.5 // % du brut
        let seuilCsgCrds  : Double // 50.0 // €, pas cotisation en deça
        let CRDS          : Double // 0.5 // %
        let CSG           : Double // 6.2 // %
        let retraiteCompl : Double // 3.0 // % du salaire journalier de référence
        let seuilRetCompl : Double // 29.26 // €
    }
    
    // MARK: Properties
    
    var model: Model
    
    // MARK: Methods
    
    /// Allocation chomage journalière nette de charges sociales
    /// - Parameters:
    ///   - brut: allocation chomage journalière brute
    ///   - SJR: Salaire Journilier de Référence
    /// - Returns: allocation chomage journalière nette de charges sociales
    func net(brut: Double, SJR: Double) throws -> Double {
        guard brut >= 0.0 else {
            return 0.0
        }
        let socialTaxe = try socialTaxes(brut: brut, SJR: SJR)
        return brut - socialTaxe
    }
    
    /// Charges sociales sur l'allocation chomage journalière brute
    /// - Parameters:
    ///   - brut: allocation chomage journalière brute
    ///   - SJR: Salaire Journilier de Référence
    /// - Returns: montant des charges sociales
    /// - Note:
    ///   - [exemples de calcul](https://www.unedic.org/indemnisation/fiches-thematiques/retenues-sociales-sur-les-allocations)
    ///   - [pôle emploi](https://www.pole-emploi.fr/candidat/mes-droits-aux-aides-et-allocati/lessentiel-a-savoir-sur-lallocat/quelle-somme-vais-je-recevoir/quelles-retenues-sociales-sont-a.html)
    ///   - [service-public](https://www.service-public.fr/particuliers/vosdroits/F2971)
    func socialTaxes(brut: Double, SJR: Double) throws -> Double {
        guard brut >= 0.0 else {
            return 0.0
        }
        guard SJR >= 0.0 else {
            throw ModelError.outOfBounds
        }
        var cotisation = 0.0
        var brut2: Double
        // 1) cotisation au régime complémentaire de retraite
        let cotRetraiteCompl = SJR * model.retraiteCompl / 100
        if brut - cotRetraiteCompl >= model.seuilRetCompl {
            cotisation += cotRetraiteCompl
            brut2 = brut - cotRetraiteCompl
        } else {
            brut2 = brut
        }
        // 2) CSG et CRDS
        if brut2 >= model.seuilCsgCrds {
            cotisation += model.assiette / 100.0 * brut * (model.CRDS + model.CSG) / 100
        }
        return cotisation
    }
}

// MARK: - Charges sociales sur revenus financiers (dividendes, plus values, loyers...)
struct FinancialRevenuTaxesModel: Codable {
    
    // MARK: Nested types

    struct Model: Codable, Versionable {
        var version      : Version
        let CRDS         : Double // 0.5 // %
        let CSG          : Double // 9.2 // %
        let prelevSocial : Double // 7.5  // %
        var total        : Double {
            CRDS + CSG + prelevSocial // %
        }
    }
    
    // MARK: Properties

    var model: Model
    
    // MARK: Methods

    /// revenus financiers nets de charges sociales
    /// - Parameter brut: revenus financiers bruts
    func net(_ brut: Double) -> Double {
        guard brut >= 0.0 else {
            return 0.0
        }
        return brut - socialTaxes(brut)
    }
    
    /// charges sociales sur les revenus financiers
    /// - Parameter brut: revenus financiers bruts
    func socialTaxes(_ brut: Double) -> Double {
        guard brut >= 0.0 else {
            return 0.0
        }
        return brut * model.total / 100.0
    }
    
    /// revenus financiers bruts avant charges sociales
    /// - Parameter net: revenus financiers nets
    func brut(_ net: Double) -> Double {
        guard net >= 0.0 else {
            return 0.0
        }
        return net / (1.0 - model.total / 100.0)
    }
}

// MARK: - Charges sociales sur chiffre d'affaire
struct TurnoverTaxesModel: Codable {
    
    // MARK: Nested types

    struct Model: Codable, Versionable {
        var version: Version
        let URSSAF : Double // 24 // %
        var total  : Double {
            URSSAF // %
        }
    }
    
    // MARK: Properties

    var model: Model
    
    // MARK: Methods

    /// chiffre d'affaire net de charges sociales
    /// - Parameter brut: chiffre d'affaire brut
    func net(_ brut: Double) -> Double {
        guard brut >= 0.0 else {
            return 0.0
        }
        return brut - socialTaxes(brut)
    }
    
    /// charges sociales sur le chiffre d'affaire brut
    /// - Parameter brut: chiffre d'affaire brut
    func socialTaxes(_ brut: Double) -> Double {
        guard brut >= 0.0 else {
            return 0.0
        }
        return brut * model.URSSAF / 100.0
    }
}

// MARK: - Impôt sur les plus-values d'assurance vie-Assurance vies
struct LifeInsuranceTaxes: Codable {
    
    // MARK: Nested types

    struct Model: Codable, Versionable {
        var version        : Version
        let rebatePerPerson: Double // 4800.0 // euros
    }
    
    // MARK: Properties

    var model: Model
}

// MARK: - Impots sur les sociétés (SCI)
struct CompanyProfitTaxesModel: Codable {
    
    // MARK: Nested types

    struct Model: Codable, Versionable {
        var version : Version
        let rate    : Double // 15.0 // %
    }
    
    // MARK: Properties

    var model: Model
    
    // MARK: Methods

    /// bénéfice net
    /// - Parameter brut: bénéfice brut
    func net(_ brut: Double) -> Double {
        guard brut >= 0.0 else {
            return 0.0
        }
        return brut - IS(brut)
    }
    
    /// impôts sur les bénéfices
    /// - Parameter brut: bénéfice brut
    func IS(_ brut: Double) -> Double {
        guard brut >= 0.0 else {
            return 0.0
        }
        return brut * model.rate / 100.0
    }
}
