//
//  LegalSuccessionManager.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 21/04/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

struct LegalSuccessionManager {
    /// Calcule l'actif net taxable à la succession d'une personne
    /// - Note: [Reference](https://www.service-public.fr/particuliers/vosdroits/F14198)
    /// - Parameters:
    ///   - year: année du décès - 1
    ///   - decedent: défunt
    /// - Returns: Masse successorale nette taxable du défunt
    /// - WARNING: prendre en compte la capital à la fin de l'année précédent le décès. Important pour FreeInvestement.
    func taxableInheritanceValue(in patrimoine : Patrimoin,
                                 of decedent   : Person,
                                 atEndOf year  : Int) -> Double {
        var taxable: Double = 0
        patrimoine.forEachOwnable { ownable in
            taxable += ownable.ownedValue(by               : decedent.displayName,
                                          atEndOf          : year,
                                          evaluationMethod : .legalSuccession)
        }
        return taxable
    }
    
    /// Calcule la succession légale d'un défunt et retourne une table des héritages et droits de succession pour chaque héritier
    /// - Parameters:
    ///   - decedent: défunt
    ///   - year: année du décès
    /// - Returns: Succession légale du défunt incluant la table des héritages et droits de succession pour chaque héritier
    func legalSuccession(in patrimoine : Patrimoin,
                         of decedent   : Person,
                         atEndOf year  : Int) -> Succession {
        
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
        let totalTaxableInheritance = taxableInheritanceValue(in: patrimoine,
                                                              of      : decedent,
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

}
