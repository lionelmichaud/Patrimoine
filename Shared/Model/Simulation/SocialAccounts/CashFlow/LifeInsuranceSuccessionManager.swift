//
//  LifeInsuranceSuccessionManager.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 21/04/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

struct LifeInsuranceSuccessionManager {
    /// Calcule la masse totale d'assurance vie taxable à la succession d'une personne
    /// - Note: [Reference]()
    /// - Parameters:
    ///   - year: année du décès - 1
    ///   - decedent: défunt
    /// - Returns: masse totale d'assurance vie taxable à la succession du défunt
    /// - WARNING: prendre en compte la capital à la fin de l'année précédent le décès. Important pour FreeInvestement.
    fileprivate func taxableLifeInsuraceInheritanceValue(in patrimoine : Patrimoin,
                                                         of decedent   : Person,
                                                         atEndOf year  : Int) -> Double {
        var taxable: Double = 0
        patrimoine.forEachOwnable { ownable in
            taxable += ownable.ownedValue(by               : decedent.displayName,
                                          atEndOf          : year,
                                          evaluationMethod : .lifeInsuranceSuccession)
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
    func lifeInsuraceSuccession(in patrimoine : Patrimoin,
                                of decedent   : Person,
                                atEndOf year  : Int) -> Succession {
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
        let totalTaxableInheritance = taxableLifeInsuraceInheritanceValue(in      : patrimoine,
                                                                          of      : decedent,
                                                                          atEndOf : year - 1)
        //        print("  Masse successorale d'assurance vie = \(totalTaxableInheritance.rounded())")
        
        // pour chaque assurance vie
        patrimoine.assets.freeInvests.items.forEach { invest in
            lifeInsuranceSuccessionMasses(of               : decedent,
                                          for              : invest,
                                          atEndOf          : year,
                                          massesSuccession : &massesSuccession)
        }
        patrimoine.assets.periodicInvests.items.forEach { invest in
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
}
