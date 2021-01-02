//
//  Patrimoine.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 10/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Patrimoine constitué d'un Actif et d'un Passif
final class Patrimoin: ObservableObject {
    
    // MARK: - Static properties
    
    // doit être injecté depuis l'extérieur avant toute instanciation de la classe
    static var family: Family?
    
    // MARK: - Static Methods
    
    /// Définir le mode de simulation à utiliser pour tous les calculs futurs
    /// - Parameter simulationMode: mode de simulation à utiliser
    static func setSimulationMode(to simulationMode : SimulationModeEnum) {
        Assets.setSimulationMode(to: simulationMode)
    }
    
    // MARK: - Properties
    
    @Published var assets      = Assets(family: Patrimoin.family)
    @Published var liabilities = Liabilities(family: Patrimoin.family)
    
    // MARK: - Methods
    
    func value(atEndOf year: Int) -> Double {
        assets.value(atEndOf: year) +
            liabilities.value(atEndOf: year)
    }
    
    /// Calls the given closure on each element in the sequence in the same order as a for-in loop
    func forEachOwnable(_ body: (Ownable) throws -> Void) rethrows {
        try assets.forEachOwnable(body)
        try liabilities.forEachOwnable(body)
    }
    
    /// Transférer la propriété d'un bien d'un défunt vers ses héritiers en fonction de l'option
    ///  fiscale du conjoint survivant éventuel
    /// - Parameters:
    ///   - decedentName: défunt
    ///   - chidrenNames: noms des enfants héritiers survivant éventuels
    ///   - spouseName: nom du conjoint survivant éventuel
    ///   - spouseFiscalOption: option fiscale du conjoint survivant éventuel
    func transferOwnershipOf(decedentName       : String,
                             chidrenNames       : [String]?,
                             spouseName         : String?,
                             spouseFiscalOption : InheritanceDonation.FiscalOption?) {
        assets.transferOwnershipOf(decedentName       : decedentName,
                                   chidrenNames       : chidrenNames,
                                   spouseName         : spouseName,
                                   spouseFiscalOption : spouseFiscalOption)
        liabilities.transferOwnershipOf(decedentName       : decedentName,
                                        chidrenNames       : chidrenNames,
                                        spouseName         : spouseName,
                                        spouseFiscalOption : spouseFiscalOption)
    }
    
    /// Transférer les biens d'un défunt vers ses héritiers
    /// - Parameter year: décès dans l'année en cours
    func transferOwnershipOf(decedent     : Person,
                             atEndOf year : Int) {
        guard let family = Patrimoin.family else {
            fatalError("La famille n'est pas définie dans Patrimoin.transferOwnershipOf")
        }
        // rechercher un conjont survivant
        var spouseName         : String?
        var spouseFiscalOption : InheritanceDonation.FiscalOption?
        if let decedent = decedent as? Adult, let spouse = family.spouseOf(decedent) {
            if spouse.isAlive(atEndOf: year) {
                spouseName         = spouse.displayName
                spouseFiscalOption = spouse.fiscalOption
            }
        }
        // rechercher des enfants héritiers vivants
        let chidrenNames = family.chidldrenAlive(atEndOf: year)?.map { $0.displayName }
        
        // leur transférer la propriété de tous les biens détenus par le défunt
        transferOwnershipOf(decedentName       : decedent.displayName,
                            chidrenNames       : chidrenNames,
                            spouseName         : spouseName,
                            spouseFiscalOption : spouseFiscalOption)
    }
    
    /// Calcule la masse totale d'assurance vie taxable à la succession d'une personne
    /// - Note: [Reference]()
    /// - Parameters:
    ///   - year: année du décès - 1
    ///   - decedent: défunt
    /// - Returns: masse totale d'assurance vie taxable à la succession du défunt
    /// - WARNING: prendre en compte la capital à la fin de l'année précédent le décès. Important pour FreeInvestement.
    fileprivate func taxableLifeInsuraceInheritanceValue(of decedent  : Person,
                                                         atEndOf year : Int) -> Double {
        var taxable: Double = 0
        self.forEachOwnable { ownable in
            taxable += ownable.ownedValue(by               : decedent.displayName,
                                          atEndOf          : year,
                                          evaluationMethod : .lifeInsuranceSuccession)
        }
        return taxable
    }
    
    /// Calcule l'actif net taxable à la succession d'une personne
    /// - Note: [Reference](https://www.service-public.fr/particuliers/vosdroits/F14198)
    /// - Parameters:
    ///   - year: année du décès - 1
    ///   - decedent: défunt
    /// - Returns: Masse successorale nette taxable du défunt
    /// - WARNING: prendre en compte la capital à la fin de l'année précédent le décès. Important pour FreeInvestement.
    func taxableInheritanceValue(of decedent  : Person,
                                 atEndOf year : Int) -> Double {
        var taxable: Double = 0
        forEachOwnable { ownable in
            taxable += ownable.ownedValue(by               : decedent.displayName,
                                          atEndOf          : year,
                                          evaluationMethod : .legalSuccession)
        }
        return taxable
    }
    
    fileprivate func lifeInsuranceSuccessionMasses(of decedent      : Person,
                                                   for invest       : FinancialEnvelop,
                                                   atEndOf year     : Int,
                                                   massesSuccession : inout [String : Double]) {
        var _invest = invest
        if let clause = invest.clause {
            // on a affaire à une assurance vie
            // masse successorale pour cet investissement
            let masseDecedent = invest.ownedValue(by      : decedent.displayName,
                                                  atEndOf : year - 1,
                                                  evaluationMethod: .lifeInsuranceSuccession)
            guard masseDecedent != 0 else { return }
            
            if invest.ownership.isDismembered {
                // le capital de l'assurane vie est démembré
                if invest.ownership.usufructOwners.contains(where: { decedent.displayName == $0.name }) {
                    // le défunt est usufruitier
                    // l'usufruit rejoint la nue-propriété sans taxe
                    ()
                    
                } else if invest.ownership.bareOwners.contains(where: { decedent.displayName == $0.name }) {
                    // le défunt est un nue-propriétaire
                    // TODO: - traiter le cas où le capital de l'assurance vie est démembré et le défunt est nue-propriétaire
                    fatalError("lifeInsuraceSuccession: cas non traité (capital démembré et le défunt est nue-propriétaire)")
                }
                
            } else {
                // le capital de l'assurance vie n'est pas démembré
                // le défunt est-il un des PP du capital de l'assurance vie ?
                if invest.ownership.fullOwners.contains(where: { decedent.displayName == $0.name }) {
                    // le seul ?
                    if invest.ownership.fullOwners.count == 1 {
                        if clause.isDismembered {
                            // la clause bénéficiaire de l'assurane vie est démembrée
                            // simuler localement le transfert de propriété pour connaître les masses héritées
                            _invest.ownership.transferLifeInsuranceUsufructAndBareOwnership(clause: clause)
                            
                        } else {
                            // la clause bénéficiaire de l'assurane vie n'est pas démembrée
                            // simuler localement le transfert de propriété pour connaître les masses héritées
                            _invest.ownership.transferLifeInsuranceFullOwnership(clause: clause)
                        }
                        let ownedValues = _invest.ownedValues(atEndOf: year - 1, evaluationMethod: .lifeInsuranceSuccession)
                        ownedValues.forEach { (name, value) in
                            if massesSuccession[name] != nil {
                                // incrémenter
                                massesSuccession[name]! += value
                            } else {
                                massesSuccession[name] = value
                            }
                        }
                        
                    } else {
                        // TODO: - traiter le cas où le capital est co-détenu en PP par plusieurs personnes
                        fatalError("lifeInsuraceSuccession: cas non traité (capital co-détenu en PP par plusieurs personnes)")
                    }
                } // sinon on ne fait rien
            }
        }
    }
    
    /// Calcule la transmission d'assurance vie d'un défunt et retourne une table des héritages et droits de succession pour chaque héritier
    /// - Parameters:
    ///   - decedent: défunt
    ///   - year: année du décès
    /// - Returns: Succession du défunt incluant la table des héritages et droits de succession pour chaque héritier
    func lifeInsuraceSuccession(of decedent  : Person,
                                atEndOf year : Int) -> Succession {
        var inheritances     : [Inheritance]     = []
        var massesSuccession : [String : Double] = [:]
        
        guard let family = Patrimoin.family else {
            return Succession(yearOfDeath  : year,
                              decedent     : decedent,
                              taxableValue : 0,
                              inheritances : inheritances)
        }
        
        // calculer la masse taxable au titre de l'assurance vie
        // WARNING: prendre en compte la capital à la fin de l'année précédent le décès. Important pour FreeInvestement.
        let totalTaxableInheritance = taxableLifeInsuraceInheritanceValue(of      : decedent,
                                                                          atEndOf : year - 1)
        print("  Masse successorale d'assurance vie = \(totalTaxableInheritance.rounded())")
        
        // pour chaque assurance vie
        assets.freeInvests.items.forEach { invest in
            lifeInsuranceSuccessionMasses(of               : decedent,
                                          for              : invest,
                                          atEndOf          : year,
                                          massesSuccession : &massesSuccession)
        }
        assets.periodicInvests.items.forEach { invest in
            lifeInsuranceSuccessionMasses(of               : decedent,
                                          for              : invest,
                                          atEndOf          : year,
                                          massesSuccession : &massesSuccession)
        }

        // pour chaque membre de la famille autre que le défunt
        for member in family.members where member != decedent {
            if let masse = massesSuccession[member.displayName] {
                var heritage = (netAmount: 0.0, taxe: 0.0)
                if member is Adult {
                    // le conjoint
                    heritage = Fiscal.model.lifeInsuranceInheritance.heritageToConjoint(partSuccession: masse)
                } else {
                    // les enfants
                    heritage = Fiscal.model.lifeInsuranceInheritance.heritageToChild(partSuccession: masse)
                }
                print("  Part d'héritage de \(member.displayName) = \(masse.rounded())")
                print("    Taxe = \(heritage.taxe.rounded())")
                inheritances.append(Inheritance(person  : member,
                                                percent : masse / totalTaxableInheritance,
                                                brut    : masse,
                                                net     : heritage.netAmount,
                                                tax     : heritage.taxe))
            }
        }
        
        print("  Masse totale = ", inheritances.sum(for: \.brut).rounded())
        print("  Taxe totale = ", inheritances.sum(for: \.tax).rounded())
        return Succession(yearOfDeath  : year,
                          decedent     : decedent,
                          taxableValue : totalTaxableInheritance,
                          inheritances : inheritances)
    }
    
    /// Calcule la succession légale d'un défunt et retourne une table des héritages et droits de succession pour chaque héritier
    /// - Parameters:
    ///   - decedent: défunt
    ///   - year: année du décès
    /// - Returns: Succession légale du défunt incluant la table des héritages et droits de succession pour chaque héritier
    func legalSuccession(of decedent  : Person,
                         atEndOf year : Int) -> Succession {
        
        var inheritances      : [Inheritance] = []
        var inheritanceShares : (forChild: Double, forSpouse: Double) = (0, 0)
        
        guard let family = Patrimoin.family else {
            return Succession(yearOfDeath  : year,
                              decedent     : decedent,
                              taxableValue : 0,
                              inheritances : inheritances)
        }
        
        // Calcul de la masse successorale taxable du défunt
        // WARNING: prendre en compte la capital à la fin de l'année précédent le décès. Important pour FreeInvestement.
        let totalTaxableInheritance = taxableInheritanceValue(of      : decedent,
                                                              atEndOf : year - 1)
        print("  Masse successorale légale = \(totalTaxableInheritance.rounded())")
        
        // Rechercher l'option fiscale du conjoint survivant et calculer sa part d'héritage
        if let conjointSurvivant = family.members.first(where: { member in
            member is Adult && member.isAlive(atEndOf: year) && member != decedent
        }) {
            // il y a un conjoint survivant
            // parts d'héritage résultant de l'option fiscale retenue par le conjoint
            inheritanceShares = (conjointSurvivant as! Adult)
                .fiscalOption
                .sharedValues(nbChildren : family.nbOfChildrenAlive(atEndOf: year),
                              spouseAge  : conjointSurvivant.age(atEndOf: year))
            
            // calculer la part d'héritage du conjoint
            let share = inheritanceShares.forSpouse
            let brut  = totalTaxableInheritance * share
            
            // caluler les droits de succession du conjoint
            let tax = 0.0
            
            print("  Part d'héritage de \(conjointSurvivant.displayName) = \(brut.rounded())")
            print("    Taxe = \(tax.rounded())")
            inheritances.append(Inheritance(person  : conjointSurvivant,
                                            percent : share,
                                            brut    : brut,
                                            net     : brut - tax,
                                            tax     : tax))
        } else {
            // pas de conjoint survivant, les enfants se partagent l'héritage
            if family.nbOfChildrenAlive(atEndOf: year) > 0 {
                inheritanceShares.forSpouse = 0
                inheritanceShares.forChild  = InheritanceDonation.childShare(nbChildren: family.nbOfChildrenAlive(atEndOf: year))
            } else {
                // pas d'enfant survivant
                return Succession(yearOfDeath  : year,
                                  decedent     : decedent,
                                  taxableValue : totalTaxableInheritance,
                                  inheritances : inheritances)
            }
        }
        
        if family.nbOfAdults > 0 {
            // Calcul de la part revenant à chaque enfant compte tenu de l'option fiscale du conjoint
            for member in family.members {
                if let child = member as? Child {
                    // un enfant
                    // calculer la part d'héritage d'un enfant
                    let share = inheritanceShares.forChild
                    let brut  = totalTaxableInheritance * share
                    
                    // caluler les droits de succession du conjoint
                    let inheritance = Fiscal.model.inheritanceDonation.heritageOfChild(partSuccession: brut)
                    
                    print("  Part d'héritage de \(child.displayName) = \(brut.rounded())")
                    print("    Taxe = \(inheritance.taxe.rounded())")
                    inheritances.append(Inheritance(person  : child,
                                                    percent : share,
                                                    brut    : brut,
                                                    net     : inheritance.netAmount,
                                                    tax     : inheritance.taxe))
                }
            }
        }
        print("  Taxe totale = ", inheritances.sum(for: \.tax).rounded())
        return Succession(yearOfDeath  : year,
                          decedent     : decedent,
                          taxableValue : totalTaxableInheritance,
                          inheritances : inheritances)
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
                               evaluationMethod : evaluationMethod) +
            liabilities.realEstateValue(atEndOf          : year,
                                        evaluationMethod : evaluationMethod)
    }
    
    /// Réinitialiser les valeurs courantes des investissements libres
    /// - Warning:
    ///   - Doit être appelée après le chargement d'un objet FreeInvestement depuis le fichier JSON
    ///   - Doit être appelée après toute simulation ayant affectée le Patrimoine (succession)
    func resetFreeInvestementCurrentValue() {
        assets.resetFreeInvestementCurrentValue()
    }
    
    /// Recharger les actifs et passifs à partir des fichiers pour repartir d'une situation initiale sans aucune modification
    /// - Warning: Doit être appelée après toute simulation ayant affectée le Patrimoine (succession)
    func reLoad() {
        assets.reLoad()
        liabilities.reLoad()
    }
    
    /// Capitaliser les intérêts des investissements financiers libres
    /// - Parameters:
    ///   - year: à la fin de cette année
    func capitalizeFreeInvestments(atEndOf year: Int) {
        for idx in 0..<assets.freeInvests.items.count {
            assets.freeInvests.items[idx].capitalize(atEndOf: year)
        }
    }
    
    /// Ajouter la capacité d'épargne à l'investissement libre de type Assurance vie de meilleur rendement
    /// - Parameters:
    ///   - patrimoine: du patrimoine
    ///   - amount: capacité d'épargne = montant à investir
    func investNetCashFlow(_ amount: Double) {
        assets.freeInvests.items.sort(by: {$0.averageInterestRate > $1.averageInterestRate})
        
        // investir en priorité dans une assurance vie
        for idx in 0..<assets.freeInvests.items.count {
            switch assets.freeInvests.items[idx].type {
                case .lifeInsurance(let periodicSocialTaxes, _):
                    if periodicSocialTaxes && amount != 0 {
                        // investir la totalité du cash
                        assets.freeInvests.items[idx].add(amount)
                        return
                    }
                default: ()
            }
        }
        for idx in 0..<assets.freeInvests.items.count {
            switch assets.freeInvests.items[idx].type {
                case .lifeInsurance(let periodicSocialTaxes, _):
                    if !periodicSocialTaxes && amount != 0 {
                        // investir la totalité du cash
                        assets.freeInvests.items[idx].add(amount)
                        return
                    }
                default: ()
            }
        }
        
        // si pas d'assurance vie alors investir dans un PEA
        for idx in 0..<assets.freeInvests.items.count where assets.freeInvests.items[idx].type == .pea {
            // investir la totalité du cash
            assets.freeInvests.items[idx].add(amount)
            return
        }
        // si pas d'assurance vie ni de PEA alors investir dans un autre placement
        for idx in 0..<assets.freeInvests.items.count where assets.freeInvests.items[idx].type == .other {
            // investir la totalité du cash
            assets.freeInvests.items[idx].add(amount)
            return
        }
    }
    
    /// Retirer le montant d'un investissement libre: d'abord PEA ensuite Assurance vie puis autre
    /// - Parameters:
    ///   - patrimoine: du patrimoine
    ///   - amount: découvert en fin d'année à combler = montant à désinvestir
    ///   - lifeInsuranceRebate: franchise d'imposition sur les plus values
    ///   - year: année en cours
    /// - Throws: Si pas assez de capital -> CashFlowError.notEnoughCash(missingCash: amountRemainingToRemove)
    /// - Returns: taxable Interests
    func removeFromInvestement(thisAmount amount   : Double,
                               atEndOf year        : Int,
                               lifeInsuranceRebate : inout Double) throws -> Double {
        var amountRemainingToRemove = amount
        var totalTaxableInterests   = 0.0
        
        assets.freeInvests.items.sort(by: {$0.averageInterestRate < $1.averageInterestRate})
        
        // PEA: retirer le montant d'un investissement libre: d'abord le PEA procurant le moins bon rendement
        for idx in 0..<assets.freeInvests.items.count where assets.freeInvests.items[idx].type == .pea {
            // tant que l'on a pas retiré le montant souhaité
            // retirer le montant du PEA s'il y en avait assez à la fin de l'année dernière
            if amountRemainingToRemove > 0.0 && assets.freeInvests.items[idx].value(atEndOf: year-1) > 0.0 {
                let removal = assets.freeInvests.items[idx].remove(netAmount: amountRemainingToRemove)
                amountRemainingToRemove -= removal.revenue
                // IRPP: les plus values PEA ne sont pas imposables à l'IRPP
                // Prélèvements sociaux: prélevés à la source sur le montant brut du retrait donc pas à payer dans le futur
                if amountRemainingToRemove <= 0.0 { return totalTaxableInterests }
            }
        }
        
        // ASSURANCE VIE: si le solde des PEA n'était pas suffisant alors retirer de l'Assurances vie procurant le moins bon rendement
        for idx in 0..<assets.freeInvests.items.count {
            switch assets.freeInvests.items[idx].type {
                case .lifeInsurance:
                    // tant que l'on a pas retiré le montant souhaité
                    // retirer le montant de l'Assurances vie s'il y en avait assez à la fin de l'année dernière
                    if amountRemainingToRemove > 0.0 && assets.freeInvests.items[idx].value(atEndOf: year-1) > 0.0 {
                        let removal = assets.freeInvests.items[idx].remove(netAmount: amountRemainingToRemove)
                        amountRemainingToRemove -= removal.revenue
                        // IRPP: part des produit de la liquidation inscrit en compte courant imposable à l'IRPP après déduction de ce qu'il reste de franchise
                        var taxableInterests: Double
                        // apply rebate if some is remaining
                        taxableInterests = max(0.0, removal.taxableInterests - lifeInsuranceRebate)
                        lifeInsuranceRebate -= (removal.taxableInterests - taxableInterests)
                        // géré comme un revenu en report d'imposition (dette)
                        totalTaxableInterests += taxableInterests
                        // Prélèvements sociaux => prélevés à la source sur le montant brut du retrait donc pas à payer dans le futur
                        if amountRemainingToRemove <= 0.0 { return totalTaxableInterests }
                    }
                default:
                    ()
            }
        }
        
        // TODO: - Si pas assez alors prendre sur la trésorerie
        
        if amountRemainingToRemove > 0.0 {
            // on a pas pu retirer suffisament pour couvrir le déficit de cash de l'année
            throw CashFlowError.notEnoughCash(missingCash: amountRemainingToRemove)
        }
        
        return totalTaxableInterests
    }
}
