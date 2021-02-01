//
//  InheritanceDonation.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 13/12/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

struct InheritanceSharing {
    var forChild : (usufruct: Double, bare: Double)
    var forSpouse: (usufruct: Double, bare: Double)
}

// MARK: - Droits de succession en ligne directe et de donation au conjoint
///  - Note:
///   - [service-public.fr](https://www.service-public.fr/particuliers/vosdroits/F14198)
///   - [capital.fr](https://www.capital.fr/votre-argent/succession-les-mesures-a-prendre-pour-proteger-son-conjoint-1027822)
struct InheritanceDonation: Codable {
    
    // MARK: - Nested types

    enum ModelError: Error {
        case heritageOfChildSlicesIssue
        case donationToSpouseSlicesIssue
    }
    
    // options fiscale du conjoint à la succession
    enum FiscalOption: String, PickableEnum, Codable {
        case fullUsufruct      = "100% Usufruit"
        case quotiteDisponible = "Quotité disponible"
        case usufructPlusBare  = "1/4 PP + 3/4 UF"
        
        var pickerString: String {
            self.rawValue
        }
        
        /// Calcule les valeurs respectives en % des parts d'un héritage
        /// - Parameters:
        ///   - nbChildren: nombre d'enfantss héritiers survivants
        ///   - spouseAge: age du conjoint survivant
        /// - Returns: valeurs respectives en % des parts d'un héritage [0, 1]
        func sharedValues(nbChildren : Int,
                          spouseAge  : Int)
        -> (forChild  : Double,
            forSpouse : Double) {
            if nbChildren == 0 {
                // sans enfant le conjoint hérite de tout
                return (forChild: 0.0, forSpouse: 1.0)
                
            } else {
                switch self {
                    case .fullUsufruct:
                        let demembrement = try! Fiscal.model.demembrement.demembrement(of: 1.0, usufructuaryAge : spouseAge)
                        return (forChild : demembrement.bareValue / nbChildren.double(),
                                forSpouse: demembrement.usufructValue)
                        
                    case .quotiteDisponible:
                        let spouseShare = 1.0 / (nbChildren + 1).double()
                        let childShare  = (1.0 - spouseShare) / nbChildren.double()
                        return (forChild : childShare,
                                forSpouse: spouseShare)
                        
                    case .usufructPlusBare:
                        let demembrement = try! Fiscal.model.demembrement.demembrement(of: 1.0, usufructuaryAge : spouseAge)
                        // Conjoint = 1/4 PP + 3/4 UF
                        let spouseShare  = 0.25 + 0.75 * demembrement.usufructValue
                        return (forChild : (1.0 - spouseShare) / nbChildren.double(),
                                forSpouse: spouseShare)
                }
            }
        }
        
        func shares(nbChildren: Int) -> InheritanceSharing {
            switch self {
                case .fullUsufruct:
                    return InheritanceSharing(forChild : (usufruct: 0, bare: 1 / nbChildren.double()),
                                              forSpouse: (usufruct: 1, bare: 0))
                    
                case .quotiteDisponible:
                    let spouseShare = 1.0 / (nbChildren + 1).double()
                    let childShare  = (1.0 - spouseShare) / nbChildren.double()
                    return InheritanceSharing(forChild : (usufruct: childShare, bare: childShare),
                                              forSpouse: (usufruct: spouseShare, bare: spouseShare))
                    
                case .usufructPlusBare:
                    // Conjoint = 1/4 PP + 3/4 UF
                    return InheritanceSharing(forChild : (usufruct: 0, bare: 0.75 / nbChildren.double()),
                                              forSpouse: (usufruct: 1, bare: 0.25))
            }
        }
    }
    
    struct Model: BundleCodable, Versionable {
        static var defaultFileName: String = "InheritanceDonationModel.json"
        
        var version              : Version
        var gridDonationConjoint : RateGrid
        var abatConjoint         : Double //  80_724€
        var gridLigneDirecte     : RateGrid
        var abatLigneDirecte     : Double // 100_000€
        let fraisFunéraires      : Double //   1_500€
        let decoteResidence      : Double // 20% // %
    }
    
    // MARK: - Properties

    var model: Model
    
    // MARK: - Methods

    /// Calcule la part d'héritage de chaque enfant en l'absence de conjoint survivant
    /// - Parameter nbChildren: nb d'enfant à se partager l'héritage
    static func childShare(nbChildren: Int) -> Double {
        guard nbChildren > 0 else { return 0 }
        return 1.0 / nbChildren.double()
    }
    
    /// Initializer les paramètres calculés pour les tranches d'imposition à partir des seuils et des taux
    mutating func initialize() throws {
        try model.gridLigneDirecte.initialize()
        try model.gridDonationConjoint.initialize()
    }
    
    /// Calcul des droits de succession sur l'héritage par un enfant
    /// - Parameter partSuccession: part successorale de l'enfant
    /// - Returns: taxe et montant net
    /// - Note: le conjoint est exonéré de droit de succession
    func heritageOfChild(partSuccession: Double) throws
    -> (netAmount : Double,
        taxe      : Double) {
        // abattement avant application du barême
        let taxable = zeroOrPositive(partSuccession - model.abatLigneDirecte)
        
        // application du barême
        if let taxe = model.gridLigneDirecte.tax(for: taxable) {
            let net  = partSuccession - taxe
            return (netAmount : net,
                    taxe      : taxe)
        } else {
            throw ModelError.heritageOfChildSlicesIssue
        }
    }
    
    /// Calcul des droits de donation d'un conjoint marié
    /// - Parameter partSuccession: part successorale du conjoint
    /// - Returns: taxe et montant net
    func donationToSpouse(donation: Double) throws
    -> (netAmount : Double,
        taxe      : Double) {
        // abattement avant application du barême
        let taxable = zeroOrPositive(donation - model.abatConjoint)
        
        // application du barême
        if let taxe = model.gridLigneDirecte.tax(for: taxable) {
            let net  = donation - taxe
            return (netAmount : net,
                    taxe      : taxe)
        } else {
            throw ModelError.donationToSpouseSlicesIssue
        }
    }
}

// MARK: - Droits de succession sur assurance vie
///  - Note: [Reference](https://www.impots.gouv.fr/portail/international-particulier/questions/comment-sont-imposees-les-assurances-vie-en-cas-de-deces-du)
struct LifeInsuranceInheritance: Codable {

    // MARK: - Nested types

    enum ModelError: Error {
        case heritageOfChildSlicesIssue
    }
    
    struct Model: BundleCodable, Versionable, RateGridable {
        static var defaultFileName: String = "LifeInsuranceInheritanceModel.json"
        
        var version : Version
        var grid    : RateGrid
    }
    
    // MARK: - Properties

    var model: Model
    
    // MARK: - Methods

    /// Initializer les paramètres calculés pour les tranches d'imposition à partir des seuils et des taux
    mutating func initialize() throws {
        try model.initializeGrid()
    }
    
    /// Calcul les taxes sur la transmission de l'assurance vie vers un enfant
    /// - Parameter partSuccession: masse transmise vers un enfant
    func heritageOfChild(partSuccession: Double) throws
    -> (netAmount : Double,
        taxe      : Double) {
        // application du barême
        if let taxe = model.tax(for: partSuccession) {
            let net  = partSuccession - taxe
            return (netAmount : net,
                    taxe      : taxe)
        } else {
            throw ModelError.heritageOfChildSlicesIssue
        }
    }
    
    /// Calcul les taxes sur la transmission de l'assurance vie vers un conjoint
    /// - Parameter partSuccession: masse transmise vers un conjoint
    func heritageToConjoint(partSuccession: Double)
    -> (netAmount : Double,
        taxe      : Double) {
        // les sommes héritées par le conjoint, par le partenaire pacsé et sous certaines conditions
        // par les frères et sœurs, sont totalement exonérées de droits de succession.
        return (netAmount : partSuccession,
                taxe      : 0.0)
    }
    
}
