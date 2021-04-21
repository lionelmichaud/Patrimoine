//
//  Patrimoine.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 10/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import os

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.Patrimoin")

enum CashFlowError: Error {
    case notEnoughCash(missingCash: Double)
}

// MARK: - Patrimoine constitué d'un Actif et d'un Passif
final class Patrimoin: ObservableObject {
    
    // MARK: - Static properties
    
    // doit être injecté depuis l'extérieur avant toute instanciation de la classe
    static var family: Family?
    
    // MARK: - Nested Type
    
    struct Memento {
        private(set) var assets      : Assets
        private(set) var liabilities : Liabilities
        init(assets      : Assets,
             liabilities : Liabilities) {
            self.assets      = assets
            self.liabilities = liabilities
        }
    }
    
    // MARK: - Static Methods
    
    /// Définir le mode de simulation à utiliser pour tous les calculs futurs
    /// - Parameter simulationMode: mode de simulation à utiliser
    static func setSimulationMode(to simulationMode : SimulationModeEnum) {
        Assets.setSimulationMode(to: simulationMode)
    }
    
    // MARK: - Properties
    
    @Published var assets      : Assets
    @Published var liabilities : Liabilities
    var memento: Memento?
    
    // MARK: - Initializers
    
    init() {
        self.assets      = Assets(with      : Patrimoin.family)
        self.liabilities = Liabilities(with : Patrimoin.family)
        //self.save()
    }
    
    // MARK: - Methods
    
    func reload() {
        assets      = Assets(with      : Patrimoin.family)
        liabilities = Liabilities(with : Patrimoin.family)
        memento     = nil
    }
    
    func value(atEndOf year: Int) -> Double {
        assets.value(atEndOf: year) +
            liabilities.value(atEndOf: year)
    }
    
    /// Réinitialiser les valeurs courantes des investissements libres
    /// - Warning:
    ///   - Doit être appelée après le chargement d'un objet FreeInvestement depuis le fichier JSON
    ///   - Doit être appelée après toute simulation ayant affectée le Patrimoine (succession)
    func resetFreeInvestementCurrentValue() {
        assets.resetFreeInvestementCurrentValue()
    }
    
    /// Sauvegarder l'état courant du Patrimoine
    /// - Warning: Doit être appelée avant toute simulation pouvant affecter le Patrimoine (succession)
    func save() {
        memento = Memento(assets      : assets,
                          liabilities : liabilities)
    }
    
    /// Recharger les actifs et passifs à partir des de la dernière sauvegarde pour repartir d'une situation initiale sans aucune modification
    /// - Warning: Doit être appelée après toute simulation ayant affectée le Patrimoine (succession)
    func restore() {
        guard let memento = memento else {
            customLog.log(level: .fault, "patrimoine.restore: tentative de restauration d'un patrimoine non sauvegardé")
            fatalError("patrimoine.restore: tentative de restauration d'un patrimoine non sauvegardé")
        }
        assets      = memento.assets
        liabilities = memento.liabilities
    }
    
    /// Calls the given closure on each element in the sequence in the same order as a for-in loop
    func forEachOwnable(_ body: (Ownable) throws -> Void) rethrows {
        try assets.forEachOwnable(body)
        try liabilities.forEachOwnable(body)
    }

    /// Calcule  la valeur nette taxable du patrimoine immobilier de la famille selon la méthode de calcul choisie
    ///  - Note:
    ///  Pour l'IFI:
    ///
    ///  Foyer taxable:
    ///  - adultes + enfants non indépendants
    ///
    ///  Patrimoine taxable à l'IFI =
    ///  - tous les actifs immobiliers dont un propriétaire ou usufruitier
    ///  est un membre du foyer taxable
    ///
    ///  Valeur retenue:
    ///  - actif détenu en pleine-propriété: valeur de la part détenue en PP
    ///  - actif détenu en usufuit : valeur de la part détenue en PP
    ///  - la résidence principale faire l’objet d’une décote de 30 %
    ///  - les immeubles que vous donnez en location peuvent faire l’objet d’une décote de 10 % à 30 % environ
    ///  - en indivision : dans ce cas, ils sont imposables à hauteur de votre quote-part minorée d’une décote de l’ordre de 30 % pour tenir compte des contraintes liées à l’indivision)
    ///
    /// - Parameters:
    ///   - year: année d'évaluation
    ///   - evaluationMethod: méthode d'évalution des biens
    /// - Returns: assiette nette fiscale calculée selon la méthode choisie
    func realEstateValue(atEndOf year     : Int,
                         evaluationMethod : EvaluationMethod) -> Double {
        assets.realEstateValue(atEndOf          : year,
                               for              : Patrimoin.family!,
                               evaluationMethod : evaluationMethod) +
            liabilities.realEstateValue(atEndOf          : year,
                                        for              : Patrimoin.family!,
                                        evaluationMethod : evaluationMethod)
    }
}

extension Patrimoin: CustomStringConvertible {
    var description: String {
        """
        PATRIMOINE:
        \(assets.description.withPrefixedSplittedLines("  "))
        \(liabilities.description.withPrefixedSplittedLines("  "))
        """
    }
}
