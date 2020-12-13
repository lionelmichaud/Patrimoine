//
//  InheritanceDonation.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 13/12/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Droits de succession en ligne directe et de donation au conjoint
///  - Note: [Reference](https://www.service-public.fr/particuliers/vosdroits/F14198)
struct InheritanceDonation: Codable {
    // nested types
    
    // options fiscale du conjoint à la succession
    enum FiscalOption: String, PickableEnum, Codable {
        case fullUsufruct      = "100% Usufruit"
        case quotiteDisponible = "Quotité disponible"
        case usufructPlusBare  = "1/4 PP + 3/4 UF"
        
        var pickerString: String {
            self.rawValue
        }
        
        func shares(nbChildren : Int,
                    spouseAge  : Int)
        -> (forChild  : Double,
            forSpouse : Double) {
            switch self {
                case .fullUsufruct:
                    let demembrement = Fiscal.model.demembrement.demembrement(of: 1.0, usufructuaryAge : spouseAge)
                    return (forChild : demembrement.bareValue / nbChildren.double(),
                            forSpouse: demembrement.usufructValue)
                    
                case .quotiteDisponible:
                    return (forChild : 1.0 / (nbChildren + 1).double(),
                            forSpouse: 1.0 / (nbChildren + 1).double())
                    
                case .usufructPlusBare:
                    let demembrement = Fiscal.model.demembrement.demembrement(of: 1.0, usufructuaryAge : spouseAge)
                    let spouseShare  = 0.25 + 0.75 * demembrement.usufructValue
                    return (forChild : (1.0 - spouseShare) / nbChildren.double(),
                            forSpouse: spouseShare)
            }
        }
    }
    
    // tranche de barême
    struct Slice: Codable {
        let floor : Double // €
        let rate  : Double // %
        var disc  : Double // euro
    }
    
    struct Model: Codable, Versionable {
        var version              : Version
        var gridDonationConjoint : [Slice]
        var abatConjoint         : Double //  80_724€
        var gridLigneDirecte     : [Slice]
        var abatLigneDirecte     : Double // 100_000€
        let fraisFunéraires      : Double //   1_500€
        let decoteResidence      : Double // 20% // %
    }
    
    // properties
    
    var model: Model
    
    // methods
    
    /// Calcule la part d'héritage de chaque enfant en l'absence de conjoint survivant
    /// - Parameter nbChildren: nb d'enfant à se partager l'héritage
    static func childShare(nbChildren: Int) -> Double {
        guard nbChildren > 0 else { return 0 }
        return 1.0 / nbChildren.double()
    }
    
    /// Initializer les paramètres calculés pour les tranches d'imposition à partir des seuils et des taux
    mutating func initialize() {
        for idx in model.gridLigneDirecte.startIndex ..< model.gridLigneDirecte.endIndex {
            if idx == 0 {
                model.gridLigneDirecte[idx].disc = model.gridLigneDirecte[idx].floor * (model.gridLigneDirecte[idx].rate - 0)
            } else {
                model.gridLigneDirecte[idx].disc =
                    model.gridLigneDirecte[idx-1].disc +
                    model.gridLigneDirecte[idx].floor * (model.gridLigneDirecte[idx].rate - model.gridLigneDirecte[idx-1].rate)
            }
        }
        for idx in model.gridDonationConjoint.startIndex ..< model.gridDonationConjoint.endIndex {
            if idx == 0 {
                model.gridDonationConjoint[idx].disc = model.gridDonationConjoint[idx].floor * (model.gridDonationConjoint[idx].rate - 0)
            } else {
                model.gridDonationConjoint[idx].disc =
                    model.gridDonationConjoint[idx-1].disc +
                    model.gridDonationConjoint[idx].floor * (model.gridDonationConjoint[idx].rate - model.gridDonationConjoint[idx-1].rate)
            }
        }
    }
    
    func heritageOfChild(partSuccession: Double)
    -> (netAmount : Double,
        taxe      : Double) {
        // abattement avant application du barême
        let taxable = max(0, partSuccession - model.abatLigneDirecte)
        
        // application du barême
        if let slice = model.gridLigneDirecte.last(where: { $0.floor <= taxable }) {
            let taxe = taxable * slice.rate - slice.disc
            let net  = partSuccession - taxe
            return (netAmount : net,
                    taxe      : taxe)
        } else {
            fatalError()
        }
    }
    
    func donationToSpouse(donation: Double)
    -> (netAmount : Double,
        taxe      : Double) {
        // abattement avant application du barême
        let taxable = max(0, donation - model.abatConjoint)
        
        // application du barême
        if let slice = model.gridLigneDirecte.last(where: { $0.floor <= taxable }) {
            let taxe = taxable * slice.rate - slice.disc
            let net  = donation - taxe
            return (netAmount : net,
                    taxe      : taxe)
        } else {
            fatalError()
        }
    }
}

// MARK: - Droits de succession sur assurance vie
///  - Note: [Reference](https://www.impots.gouv.fr/portail/international-particulier/questions/comment-sont-imposees-les-assurances-vie-en-cas-de-deces-du)
struct LifeInsuranceInheritance: Codable {
    // nested types
    
    // tranche de barême
    struct Slice: Codable {
        let floor : Double // €
        let rate  : Double // %
        var disc  : Double // euro
    }
    
    struct Model: Codable, Versionable {
        var version    : Version
        var grid       : [Slice]
    }
    
    // properties
    
    var model: Model
    
    // methods
    
    /// Initializer les paramètres calculés pour les tranches d'imposition à partir des seuils et des taux
    mutating func initialize() {
        for idx in model.grid.startIndex ..< model.grid.endIndex {
            if idx == 0 {
                model.grid[idx].disc = model.grid[idx].floor * (model.grid[idx].rate - 0)
            } else {
                model.grid[idx].disc =
                    model.grid[idx-1].disc +
                    model.grid[idx].floor * (model.grid[idx].rate - model.grid[idx-1].rate)
            }
        }
    }
    
    func heritageToChild(partSuccession: Double)
    -> (netAmount : Double,
        taxe      : Double) {
        // application du barême
        if let slice = model.grid.last(where: { $0.floor < partSuccession }) {
            let taxe = partSuccession * slice.rate - slice.disc
            let net  = partSuccession - taxe
            return (netAmount : net,
                    taxe      : taxe)
        } else {
            fatalError()
        }
    }
    
    func heritageToConjoint(partSuccession: Double)
    -> (netAmount : Double,
        taxe      : Double) {
        // les sommes héritées par le conjoint, par le partenaire pacsé et sous certaines conditions
        // par les frères et sœurs, sont totalement exonérées de droits de succession.
        return (netAmount : partSuccession,
                taxe      : 0.0)
    }
    
}
