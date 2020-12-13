//
//  Patrimoine.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 10/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Méthode d'évaluation d'un Patrmoine (régles fiscales à appliquer)
enum EvaluationMethod: String, PickableEnum {
    case ifi         = "IFI"
    case isf         = "ISF"
    case inheritance = "Succession"
    case patrimoine  = "Patrimoniale"
    
    var pickerString: String {
        return self.rawValue
    }
}

// MARK: - Héritage dune personne
struct Inheritance {
    var person  : Person
    var percent : Double
    var brut    : Double
    var net     : Double
    var tax     : Double
}

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
    func transferOwnershipOfDecedent(decedentName       : String,
                                     chidrenNames       : [String]?,
                                     spouseName         : String?,
                                     spouseFiscalOption : InheritanceDonation.FiscalOption?) {
        assets.transferOwnershipOfDecedent(decedentName       : decedentName,
                                           chidrenNames       : chidrenNames,
                                           spouseName         : spouseName,
                                           spouseFiscalOption : spouseFiscalOption)
        liabilities.transferOwnershipOfDecedent(decedentName       : decedentName,
                                                chidrenNames       : chidrenNames,
                                                spouseName         : spouseName,
                                                spouseFiscalOption : spouseFiscalOption)
   }
    
    /// Transférer les biens d'un défunt vers ses héritiers
    /// - Parameter year: décès dans l'année en cours
    func transferOwnershipOfDecedent(atEndOf year : Int) {
        guard let family = Patrimoin.family else {
            fatalError("La famille n'est pas définie dans Patrimoin.transferOwnershipOfDecedent")
        }
        // rechercher l'adulte qui vient de décéder
        // TODO: - gérer la cas de deux décès dans la même année
        if let decedent = family.members.first(where: { !$0.isAlive(atEndOf: year) && $0.isAlive(atEndOf: year-1) }) {
            // un décès est survenu
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
            transferOwnershipOfDecedent(decedentName       : decedent.displayName,
                                        chidrenNames       : chidrenNames,
                                        spouseName         : spouseName,
                                        spouseFiscalOption : spouseFiscalOption)
        }
    }
    
    /// Calcule l'actif net taxable à la succession d'une personne
    /// - Note: [Reference](https://www.service-public.fr/particuliers/vosdroits/F14198)
    /// - Parameters:
    ///   - year: année d'évaluation
    ///   - decedent: défunt
    /// - Returns: Masse successorale nette taxable du défunt
    func taxableInheritanceValue(of decedent  : Person,
                                 atEndOf year : Int) -> Double {
        assets.taxableInheritanceValue(of: decedent, atEndOf: year) +
            liabilities.taxableInheritanceValue(of: decedent, atEndOf: year)
    }
    
    /// Calcule la masse successorale taxable du défunt
    /// - Parameters:
    ///   - decedent: défunt
    ///   - year: année d'évaluation
    /// - Returns: Table des héritages et droits de succession pour chaque héritier
    func inheritance(of decedent  : Person,
                     atEndOf year : Int) -> [Inheritance] {
        
        var inheritances      : [Inheritance] = []
        var inheritanceShares : (forChild: Double, forSpouse: Double) = (0, 0)
        
        guard let family = Patrimoin.family else { return inheritances }
        print("Succession de \(decedent.displayName)")

        // Calcul de la masse successorale taxable du défunt
        let totalTaxableInheritance = taxableInheritanceValue(of: decedent, atEndOf: year)
        
        // Rechercher l'option fiscale du conjoint survivant et calculer sa part d'héritage
        if let conjointSurvivant = family.members.first(where: { member in
            member is Adult && member.isAlive(atEndOf: year) && member != decedent
        }) {
            // parts d'héritage résultant de l'option fiscale retenue par le conjoint
            inheritanceShares = (conjointSurvivant as! Adult).fiscalOption.shares(nbChildren : family.nbOfChildrenAlive(atEndOf: year),
                                                                                  spouseAge  : conjointSurvivant.age(atEndOf: year))
            
            // calculer la part d'héritage du conjoint
            let share = inheritanceShares.forSpouse
            let brut  = totalTaxableInheritance * share
            
            // caluler les droits de succession du conjoint
            let tax = 0.0
            
            print("  Part d'héritage de \(conjointSurvivant.displayName) = \(brut)")
            print("  Taxe = \(tax)")
            inheritances.append(Inheritance(person  : conjointSurvivant,
                                            percent : share,
                                            brut    : brut,
                                            net     : brut - tax,
                                            tax     : tax))
        } else {
            // pas de conjoint survivant, les enfants se partagent l'héritage
            if family.nbOfChildrenAlive(atEndOf: year) > 0 {
                inheritanceShares.forSpouse = 0
                inheritanceShares.forChild  = InheritanceDonation.childShare(nbChildren : family.nbOfChildrenAlive(atEndOf : year))
            } else {
                // pas d'enfant surivant
                return inheritances
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
                    
                    print("Part d'héritage de \(child.displayName) = \(brut)")
                    print("  Taxe = \(inheritance.taxe)")
                    inheritances.append(Inheritance(person  : child,
                                                    percent : share,
                                                    brut    : brut,
                                                    net     : inheritance.netAmount,
                                                    tax     : inheritance.taxe))
                }
            }
        }
        print("    Taxe totale = ", inheritances.sum(for: \.tax))
        return inheritances
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
    func resetFreeInvestementCurrentValue() {
        var investements = [FreeInvestement]()
        assets.freeInvests.items.forEach {
            var invest = $0
            invest.resetCurrentState()
            investements.append(invest)
        }
        assets.freeInvests.items = investements
    }
    
    func reLoad() {
        assets.reLoad()
        liabilities.reLoad()
    }
    
    /// Capitaliser les intérêts des investissements financiers libres
    /// - Parameters:
    ///   - year: à la fin de cette année
    func capitalizeFreeInvestments(atEndOf year: Int) {
        var investements = [FreeInvestement]()
        assets.freeInvests.items.forEach {
            var invest = $0
            invest.capitalize(atEndOf: year)
            investements.append(invest)
        }
        assets.freeInvests.items = investements
    }
    
    /// Placer le net cash flow en fin d'année
    /// - Parameters:
    ///   - amount: montant à placer
    ///   - category: dans cette catégories d'actif
    fileprivate func investNetCashFlow(amount      : inout Double,
                                       in category : InvestementType) {
        guard amount != 0 else {
            return
        }
        var investements = [FreeInvestement]()
        assets.freeInvests.items.sorted(by: {$0.interestRate > $1.interestRate}).forEach {
            var invest = $0
            switch invest.type {
                case category:
                    // ajouter le montant à cette assurance vie si cela n'est pas encore fait
                    if amount != 0 {
                        invest.add(amount)
                        amount = 0
                    }
                    // ajouter l'item à la liste après en avoir modifier le montant au besoin
                    investements.append(invest)
                default:
                    // ajouter l'item à la liste sans modification
                    investements.append(invest)
            }
        }
        assets.freeInvests.items = investements
    }
    
    /// Ajouter la capacité d'épargne à l'investissement libre de type Assurance vie de meilleur rendement
    /// - Parameters:
    ///   - patrimoine: du patrimoine
    ///   - amount: capacité d'épargne = montant à investir
    func investNetCashFlow(_ amount: Double) {
        var amount = amount
        // investir en priorité dans une assurance vie
        investNetCashFlow(amount: &amount,
                          in: .lifeInsurance(periodicSocialTaxes: true))
        investNetCashFlow(amount: &amount,
                          in: .lifeInsurance(periodicSocialTaxes: false))
        
        // si pas d'assurance vie alors investir dans un PEA
        investNetCashFlow(amount: &amount, in: .pea)
        
        // si pas d'assurance vie ni de PEA alors investir dans un autre placement
        investNetCashFlow(amount: &amount, in: .other)
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
        var investements            = [FreeInvestement]()
        var amountRemainingToRemove = amount
        var totalTaxableInterests   = 0.0
        
        // retirer le montant d'un investissement libre: d'abord le PEA procurant le moins bon rendement
        assets.freeInvests.items.sorted(by: {$0.interestRate < $1.interestRate}).forEach {
            var invest = $0
            switch invest.type {
                case .pea:
                    // tant que l'on a pas retiré le montant souhaité
                    if amountRemainingToRemove > 0.0 {
                        // retirer le montant du PEA s'il n'est pas vide
                        if invest.value(atEndOf: year) > 0.0 {
                            let removal = invest.remove(netAmount: amountRemainingToRemove)
                            amountRemainingToRemove -= removal.revenue
                            // IRPP: les plus values PEA ne sont pas imposables à l'IRPP
                            // Prélèvements sociaux: prélevés à la source sur le montant brut du retrait donc pas à payer dans le futur
                        }
                    }
                default:
                    ()
            }
            investements.append(invest)
        }
        assets.freeInvests.items = investements
        
        investements = [FreeInvestement]()
        if amountRemainingToRemove > 0.0 {
            // si le solde des PEA n'était pas suffisant alors retirer de l'Assurances vie procurant le moins bon rendement
            assets.freeInvests.items.sorted(by: {$0.interestRate < $1.interestRate}).forEach {
                var invest = $0
                switch invest.type {
                    case .lifeInsurance:
                        // tant que l'on a pas retiré le montant souhaité
                        if amountRemainingToRemove > 0.0 {
                            // retirer le montant de l'Assurances vie si elle n'est pas vide
                            if invest.value(atEndOf: year) > 0.0 {
                                let removal = invest.remove(netAmount: amountRemainingToRemove)
                                amountRemainingToRemove -= removal.revenue
                                // IRPP: part des produit de la liquidation inscrit en compte courant imposable à l'IRPP après déduction de ce qu'il reste de franchise
                                var taxableInterests: Double
                                // apply rebate if some is remaining
                                taxableInterests = max(0.0, removal.taxableInterests - lifeInsuranceRebate)
                                lifeInsuranceRebate -= (removal.taxableInterests - taxableInterests)
                                // géré comme un revenu en report d'imposition (dette)
                                totalTaxableInterests += taxableInterests
                                // Prélèvements sociaux => prélevés à la source sur le montant brut du retrait donc pas à payer dans le futur
                            }
                        }
                    default:
                        ()
                }
                investements.append(invest)
            }
            self.assets.freeInvests.items = investements
        }
        
        // TODO: - Si pas assez alors prendre sur la trésorerie
        
        if amountRemainingToRemove > 0.0 {
            // on a pas pu retirer suffisament pour couvrir le déficit de cash de l'année
            throw CashFlowError.notEnoughCash(missingCash: amountRemainingToRemove)
        }
        
        return totalTaxableInterests
    }
    
}
