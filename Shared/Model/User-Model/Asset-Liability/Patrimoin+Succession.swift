//
//  Patrimoin+Succession.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 02/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

extension Patrimoin {
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
//        print("  Masse successorale d'assurance vie = \(totalTaxableInheritance.rounded())")
        
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
                    heritage = try! Fiscal.model.lifeInsuranceInheritance.heritageOfChild(partSuccession: masse)
                }
//                print("  Part d'héritage de \(member.displayName) = \(masse.rounded())")
//                print("    Taxe = \(heritage.taxe.rounded())")
                inheritances.append(Inheritance(person  : member,
                                                percent : masse / totalTaxableInheritance,
                                                brut    : masse,
                                                net     : heritage.netAmount,
                                                tax     : heritage.taxe))
            }
        }
        
//        print("  Masse totale = ", inheritances.sum(for: \.brut).rounded())
//        print("  Taxe totale = ", inheritances.sum(for: \.tax).rounded())
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
            
            // calculer les droits de succession du conjoint
            // TODO: le soritr d'une fonction du modèle fiscal
            let tax = 0.0
            
//            print("  Part d'héritage de \(conjointSurvivant.displayName) = \(brut.rounded())")
//            print("    Taxe = \(tax.rounded())")
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
                    let inheritance = try! Fiscal.model.inheritanceDonation.heritageOfChild(partSuccession: brut)
                    
//                    print("  Part d'héritage de \(child.displayName) = \(brut.rounded())")
//                    print("    Taxe = \(inheritance.taxe.rounded())")
                    inheritances.append(Inheritance(person  : child,
                                                    percent : share,
                                                    brut    : brut,
                                                    net     : inheritance.netAmount,
                                                    tax     : inheritance.taxe))
                }
            }
        }
//        print("  Taxe totale = ", inheritances.sum(for: \.tax).rounded())
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
                               for              : Patrimoin.family!,
                               evaluationMethod : evaluationMethod) +
            liabilities.realEstateValue(atEndOf          : year,
                                        for              : Patrimoin.family!,
                                        evaluationMethod : evaluationMethod)
    }
    
}
