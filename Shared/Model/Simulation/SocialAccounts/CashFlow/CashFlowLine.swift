import Foundation
import os
import Disk

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.CashFlow")

enum CashFlowError: Error {
    case notEnoughCash(missingCash: Double)
}

// MARK: - Ligne de cash flow annuel

struct CashFlowLine {
    
    // MARK: - nested types
    
    // agrégat des ages
    struct AgeTable {
        
        // properties
        
        var persons = [(name: String, age: Int)]()
        
        // methods
        
        func print(level: Int = 0) {
            let h = String(repeating: StringCst.header, count: level)
            Swift.print(h + "AGES:")
            Swift.print(h + StringCst.header, persons)
        }
    }
    
    // MARK: - properties
    
    let year            : Int
    var ages            = AgeTable()
    // les comptes annuels de la SCI
    let sciCashFlowLine : SciCashFlowLine
    // revenus
    var taxableIrppRevenueDelayedToNextYear = Debt(name: "REVENU IMPOSABLE REPORTE A L'ANNEE SUIVANTE", note: "", value: 0)
    var revenues        = ValuedRevenues(name: "REVENUS HORS SCI")
    var sumOfrevenues   : Double {
        revenues.totalCredited +
            sciCashFlowLine.netCashFlow
    }
    // dépenses
    var taxes           = ValuedTaxes(name: "Taxes")
    var lifeExpenses    = NamedValueTable(tableName: "Dépenses de vie")
    var debtPayements   = NamedValueTable(tableName: "Remb. dette")
    var investPayements = NamedValueTable(tableName: "Investissements")
    var sumOfExpenses: Double {
        taxes.total +
            lifeExpenses.total +
            debtPayements.total +
            investPayements.total
    }
    // les successions légales survenues dans l'année
    var successions     : [Succession] = []
    // les transmissions d'assurances vie survenues dans l'année
    var lifeInsSuccessions : [Succession] = []
    
    // solde net
    var netCashFlow: Double {
        sumOfrevenues - sumOfExpenses
    }
    
    // MARK: - initialization
    
    /// Création et peuplement d'un année de Cash Flow
    /// - Parameters:
    ///   - year: année
    ///   - family: famille à utiliser
    ///   - patrimoine: patrmoine à utiliser
    ///   - taxableIrppRevenueDelayedFromLastyear: revenus taxable à l'IRPP en report d'imposition de l'année précédente
    /// - Throws: Si pas assez de capital -> CashFlowError.notEnoughCash(missingCash: amountRemainingToRemove)
    init(withYear       year                   : Int,
         withFamily     family                 : Family,
         withPatrimoine patrimoine             : Patrimoin,
         taxableIrppRevenueDelayedFromLastyear : Double) throws {
        self.year = year
        let adultsNames = family.adults.compactMap {
            $0.isAlive(atEndOf: year) ? $0.displayName : nil
        }
        revenues.taxableIrppRevenueDelayedFromLastYear.setValue(to: taxableIrppRevenueDelayedFromLastyear)
        
        /// initialize life insurance yearly rebate on taxes
        // TODO: mettre à jour le model de défiscalisation Asurance Vie
        var lifeInsuranceRebate = Fiscal.model.lifeInsuranceTaxes.model.rebatePerPerson * family.nbOfAdultAlive(atEndOf: year).double()
        
        /// SCI: calculer le cash flow de la SCI
        sciCashFlowLine = SciCashFlowLine(withYear : year,
                                          for      : adultsNames,
                                          withSCI  : patrimoine.assets.sci)
        
        try autoreleasepool {
            /// INCOME: populate Ages and Work incomes
            populateIncomes(of: family)
            
            /// REAL ESTATE: populate produit de vente, loyers, taxes sociales et taxes locales des bien immobiliers
            populateRealEstateCashFlow(of  : patrimoine,
                                       for : adultsNames)
            
            /// SCPI: populate produit de vente, dividendes, taxes sociales des SCPI
            populateScpiCashFlow(of  : patrimoine,
                                 for : adultsNames)
            
            /// PERIODIC INVEST: populate revenue, des investissements financiers périodiques
            managePeriodicInvestments(of                  : patrimoine,
                                      for                 : adultsNames,
                                      lifeInsuranceRebate : &lifeInsuranceRebate)
            
            // Note: les intérêts des investissements financiers libres sont capitalisés
            // => ne génèrent des charges sociales et de l'IRPP qu'au moment de leur liquidation
            
            /// IRPP: calcule de l'impot sur l'ensemble des revenus
            populateIrpp(of: family)
            
            /// ISF: calcule de l'impot sur la fortune
            populateISF(of   : family,
                        with : patrimoine)
            /// EXPENSES: compute and populate family expenses
            lifeExpenses.namedValues = family.expenses.namedValueTable(atEndOf: year)
            
            /// LOAN: populate remboursement d'emprunts
            populateLoanCashFlow(for : adultsNames,
                                 of  : patrimoine)
            
            /// SUCCESSIONS: calcule des droits de successions y.c. assurances vies + peuple les successions de l'année
            populateSuccession(of   : family,
                               with : patrimoine)
            
            /// SUCCESSIONS: Transférer les biens des personnes décédées dans l'année vers ses héritiers
            transferOwnershipOfDecedents(of   : family,
                                         with : patrimoine)
            /// FREE INVEST: populate revenue, des investissements financiers libres et investir/retirer le solde net du cash flow de l'année
            try manageYearlyNetCashFlow(of                  : patrimoine,
                                        for                 : adultsNames,
                                        lifeInsuranceRebate : &lifeInsuranceRebate)
        }
        #if DEBUG
        //Swift.print("Year = \(year), Revenus = \(sumOfrevenues), Expenses = \(sumOfExpenses), Net cash flow = \(netCashFlow)")
        #endif
    }
    
    // MARK: - methods
    
    /// Définir toutes les successions de l'année et Calculer les droits de succession des personnes décédées dans l'année
    fileprivate mutating func populateSuccession(of family       : Family,
                                                 with patrimoine : Patrimoin) {
        // FIXME: - en fait il faudrait traiter les sucessions en séquences: calcul taxe => transmission puis calcul tax => transmission
        // identification des personnes décédées dans l'année
        let decedents = family.deceasedPersons(during: year)
        
        // ajouter les droits de succession (légales et assurances vie) aux taxes
        var totalSuccessionTax   = 0.0
        var totalLiSuccessionTax = 0.0
        // pour chaque défunt
        decedents.forEach { decedent in
            Swift.print("Succession de \(decedent.displayName) en \(year)")
            // calculer les droits de successions légales
            let succession = patrimoine.legalSuccession(of      : decedent,
                                                        atEndOf : year)
            successions.append(succession)
            totalSuccessionTax += succession.tax
            
            // calculer les droits de transmission assurances vies
            let liSuccession = patrimoine.lifeInsuraceSuccession(of      : decedent,
                                                                 atEndOf : year)
            lifeInsSuccessions.append(liSuccession)
            totalLiSuccessionTax += liSuccession.tax
        }
        taxes.perCategory[.succession]?.namedValues
            .append((name  : TaxeCategory.succession.rawValue,
                     value : totalSuccessionTax.rounded()))
        taxes.perCategory[.liSuccession]?.namedValues
            .append((name  : TaxeCategory.liSuccession.rawValue,
                     value : totalLiSuccessionTax.rounded()))
    }
    
    /// Transférer les biens des personnes décédées dans l'année vers ses héritiers
    func transferOwnershipOfDecedents(of family       : Family,
                                      with patrimoine : Patrimoin) {
        // identification des personnes décédées dans l'année
        let decedents = family.deceasedPersons(during: year)

        // pour chaque défunt
        decedents.forEach { decedent in
            // transférer les biens d'un défunt vers ses héritiers
            patrimoine.transferOwnershipOf(decedent: decedent, atEndOf: year)
        }
    }
    
    fileprivate mutating func populateIrpp(of family: Family) {
        taxes.irpp = try! Fiscal.model.incomeTaxes.irpp(taxableIncome : revenues.totalTaxableIrpp,
                                                        nbAdults      : family.nbOfAdultAlive(atEndOf: year),
                                                        nbChildren    : family.nbOfFiscalChildren(during: year))
        taxes.perCategory[.irpp]?.namedValues.append((name  : TaxeCategory.irpp.rawValue,
                                                      value : taxes.irpp.amount.rounded()))
    }
    
    fileprivate mutating func populateISF(of family       : Family,
                                          with patrimoine : Patrimoin) {
        let taxableAsset = patrimoine.realEstateValue(atEndOf          : year,
                                                      evaluationMethod : .ifi)
        taxes.isf = try! Fiscal.model.isf.isf(taxableAsset: taxableAsset)
        taxes.perCategory[.isf]?.namedValues.append((name  : TaxeCategory.isf.rawValue,
                                                     value : taxes.isf.amount.rounded()))
    }
    
    /// Populate Ages and Work incomes
    /// - Parameter family: de la famille
    fileprivate mutating func populateIncomes(of family: Family) {
        var totalPensionDiscount = 0.0
        
        // pour chaque membre de la famille
        for person in family.members.sorted(by:>) {
            // populate ages of family members
            let name = person.name.familyName! + " " + person.name.givenName!
            ages.persons.append((name: name, age: person.age(atEndOf: year)))
            // populate work, pension and unemployement incomes of family members
            if let adult = person as? Adult {
                /// revenus du travail
                let workIncome = adult.workIncome(during: year)
                // revenus du travail inscrit en compte avant IRPP (net charges sociales, de dépenses de mutuelle ou d'assurance perte d'emploi)
                revenues.perCategory[.workIncomes]?.credits.namedValues
                    .append((name: name,
                             value: workIncome.net.rounded()))
                // part des revenus du travail inscrite en compte qui est imposable à l'IRPP
                revenues.perCategory[.workIncomes]?.taxablesIrpp.namedValues
                    .append((name: name,
                             value: workIncome.taxableIrpp.rounded()))
                
                /// pension de retraite
                let pension  = adult.pension(during: year)
                // pension inscrit en compte avant IRPP (net de charges sociales)
                revenues.perCategory[.pensions]?.credits.namedValues
                    .append((name: name,
                             value: pension.net.rounded()))
                // part de la pension inscrite en compte qui est imposable à l'IRPP
                let relicat = Fiscal.model.pensionTaxes.model.maxRebate - totalPensionDiscount
                var discount = pension.net - pension.taxable
                if relicat >= discount {
                    // l'abattement est suffisant pour cette personne
                    revenues.perCategory[.pensions]?.taxablesIrpp.namedValues
                        .append((name: name,
                                 value: pension.taxable.rounded()))
                } else {
                    discount = relicat
                    revenues.perCategory[.pensions]?.taxablesIrpp.namedValues
                        .append((name: name,
                                 value: (pension.net - discount).rounded()))
                }
                totalPensionDiscount += discount
                
                /// indemnité de licenciement
                let compensation = adult.layoffCompensation(during: year)
                revenues.perCategory[.layoffCompensation]?.credits.namedValues
                    .append((name: name,
                             value: compensation.net.rounded()))
                revenues.perCategory[.layoffCompensation]?.taxablesIrpp.namedValues
                    .append((name: name,
                             value: compensation.taxable.rounded()))
                /// allocation chomage
                let alocation = adult.unemployementAllocation(during: year)
                revenues.perCategory[.unemployAlloc]?.credits.namedValues
                    .append((name: name, value: alocation.net.rounded()))
                revenues.perCategory[.unemployAlloc]?.taxablesIrpp.namedValues
                    .append((name: name,
                             value: alocation.taxable.rounded()))
                
            }
        }
    }
    
    /// Populate loyers, produit de la vente et impots locaux des biens immobiliers
    /// - Parameter patrimoine: du patrimoine
    /// - Note: le produit de la vente se répartit entre UF et NP si démembrement
    fileprivate mutating func populateRealEstateCashFlow(of patrimoine  : Patrimoin,
                                                         for adultsName : [String]) {
        for realEstate in patrimoine.assets.realEstates.items .sorted(by:<)
        where realEstate.isPartOfPatrimoine(of: adultsName) {
            let name = realEstate.name
            
            /// Revenus
            // les revenus ne reviennent qu'aux UF ou PP, idem pour les impôts locaux
            if realEstate.providesRevenue(to: adultsName) {
                // populate real estate rent revenues and social taxes
                let yearlyRent = realEstate.yearlyRent(during: year)
                // loyers inscrit en compte courant avant prélèvements sociaux et IRPP
                revenues.perCategory[.realEstateRents]?.credits.namedValues
                    .append((name: name,
                             value: yearlyRent.revenue.rounded()))
                // part des loyers inscrit en compte courant imposable à l'IRPP - idem ci-dessus car même base
                revenues.perCategory[.realEstateRents]?.taxablesIrpp.namedValues
                    .append((name: name,
                             value: yearlyRent.taxableIrpp.rounded()))
                // prélèvements sociaux payés sur le loyer
                taxes.perCategory[.socialTaxes]?.namedValues.append((name : name,
                                                                     value: yearlyRent.socialTaxes.rounded()))
                
                // impôts locaux
                let yearlyLocaltaxes = realEstate.yearlyLocalTaxes(during: year)
                taxes.perCategory[.localTaxes]?.namedValues
                    .append((name: name,
                             value: yearlyLocaltaxes.rounded()))
            }
            
            /// Vente
            // le produit de la vente se répartit entre UF et NP si démembrement
            if realEstate.isPartOfPatrimoine(of: adultsName) {
                // produit de la vente inscrit en compte courant:
                //    produit net de charges sociales et d'impôt sur la plus-value
                // le crédit se fait au début de l'année qui suit la vente
                let liquidatedValue = realEstate.liquidatedValue(year - 1)
                revenues.perCategory[.realEstateSale]?.credits.namedValues
                    .append((name: name,
                             value: liquidatedValue.netRevenue.rounded()))
            }
        }
    }
    
    /// Populate produit de vente, dividendes, taxes sociales des SCPI hors de la SCI
    /// - Parameter patrimoine: du patrimoine
    /// - Note: le produit de la vente se répartit entre UF et NP si démembrement
    fileprivate mutating func populateScpiCashFlow(of patrimoine  : Patrimoin,
                                                   for adultsName : [String]) {
        for scpi in patrimoine.assets.scpis.items.sorted(by:<)
        where scpi.isPartOfPatrimoine(of: adultsName) {
            let name = scpi.name
            
            /// Revenus
            if scpi.providesRevenue(to: adultsName) {
                // populate SCPI revenues and social taxes
                let yearlyRevenue = scpi.yearlyRevenue(during: year)
                // dividendes inscrit en compte courant avant prélèvements sociaux et IRPP
                revenues.perCategory[.scpis]?.credits.namedValues
                    .append((name: name,
                             value: yearlyRevenue.revenue.rounded()))
                // part des dividendes inscrit en compte courant imposable à l'IRPP
                revenues.perCategory[.scpis]?.taxablesIrpp.namedValues
                    .append((name: name,
                             value: yearlyRevenue.taxableIrpp.rounded()))
                // prélèvements sociaux payés sur les dividendes de SCPI
                taxes.perCategory[.socialTaxes]?.namedValues
                    .append((name: name,
                             value: yearlyRevenue.socialTaxes.rounded()))
            }
            
            /// Vente
            // le produit de la vente se répartit entre UF et NP si démembrement
            // populate SCPI sale revenue: produit de vente net de charges sociales et d'impôt sur la plus-value
            // le crédit se fait au début de l'année qui suit la vente
            let liquidatedValue = scpi.liquidatedValue(year - 1)
            revenues.perCategory[.scpiSale]?.credits.namedValues
                .append((name: name,
                         value: liquidatedValue.netRevenue.rounded()))
        }
    }
    
    /// Populate produit de la vente des investissements financiers périodiques
    /// - Parameters:
    ///   - patrimoine: du patrimoine
    ///   - lifeInsuranceRebate: franchise d'imposition sur les plus values
    /// - Note: le produit de la vente se répartit entre UF et NP si démembrement
    fileprivate mutating func managePeriodicInvestments(of patrimoine       : Patrimoin,
                                                        for adultsName      : [String],
                                                        lifeInsuranceRebate : inout Double) {
        // pour chaque investissement financier periodique
        for periodicInvestement in patrimoine.assets.periodicInvests.items.sorted(by:<)
        where periodicInvestement.isPartOfPatrimoine(of: adultsName) {
            let name = periodicInvestement.name
            /// Vente
            // le crédit se fait au début de l'année qui suit la vente
            let liquidatedValue = periodicInvestement.liquidatedValue(atEndOf: year - 1)
            // produit de la liquidation inscrit en compte courant avant prélèvements sociaux et IRPP
            revenues.perCategory[.financials]?.credits.namedValues.append(
                (name: name,
                 value: liquidatedValue.revenue.rounded()))
            // créditer le produit de la vente sur les comptes des personnes
            // en fonction de leur part de propriété respective
            let ownedSaleValues = periodicInvestement
                .ownedValues(ofValue          : liquidatedValue.revenue,
                             atEndOf          : year,
                             evaluationMethod : .patrimoine)
            patrimoine.investCapital(ownedCapitals : ownedSaleValues,
                                     atEndOf       : year)
            
            // populate plus values taxables à l'IRPP
            switch periodicInvestement.type {
                case .lifeInsurance:
                    var taxableInterests: Double
                    // apply rebate if some is remaining
                    taxableInterests = zeroOrPositive(liquidatedValue.taxableIrppInterests - lifeInsuranceRebate)
                    lifeInsuranceRebate -= (liquidatedValue.taxableIrppInterests - taxableInterests)
                    // part des produit de la liquidation inscrit en compte courant imposable à l'IRPP
                    revenues.perCategory[.financials]?.taxablesIrpp.namedValues.append(
                        (name: name,
                         value: taxableInterests.rounded()))
                case .pea:
                    // part des produit de la liquidation inscrit en compte courant imposable à l'IRPP
                    revenues.perCategory[.financials]?.taxablesIrpp.namedValues.append(
                        (name: name,
                         value: liquidatedValue.taxableIrppInterests.rounded()))
                case .other:
                    // part des produit de la liquidation inscrit en compte courant imposable à l'IRPP
                    revenues.perCategory[.financials]?.taxablesIrpp.namedValues.append(
                        (name: name,
                         value: liquidatedValue.taxableIrppInterests.rounded()))
            }
            // populate prélèvements sociaux
            taxes.perCategory[.socialTaxes]?.namedValues.append(
                (name: name,
                 value: liquidatedValue.socialTaxes.rounded()))
            
            /// Versements
            // on compte quand même les versements de la dernière année
            let yearlyPayement = periodicInvestement.yearlyTotalPayement(atEndOf: year)
            investPayements.namedValues.append(
                (name : name,
                 value: yearlyPayement.rounded()))
        }
    }
    
    /// Populate remboursement d'emprunts
    /// - Parameter patrimoine: du patrimoine
    fileprivate mutating func populateLoanCashFlow(for adultsName : [String],
                                                   of patrimoine  : Patrimoin) {
        for loan in patrimoine.liabilities.loans.items.sorted(by:<)
        where loan.isPartOfPatrimoine(of: adultsName) {
            let yearlyPayement = -loan.yearlyPayement(year)
            let name           = loan.name
            debtPayements.namedValues.append((name : name,
                                              value: yearlyPayement.rounded()))
        }
    }
    
    /// Gérer l'excédent ou le déficit de trésorierie en fin d'année
    /// - Parameters:
    ///   - patrimoine: du patrimoine
    ///   - year: en fin d'année
    ///   - lifeInsuranceRebate: franchise d'imposition sur les plus values
    /// - Throws: Si pas assez de capital -> CashFlowError.notEnoughCash(missingCash: amountRemainingToRemove)
    fileprivate mutating func manageYearlyNetCashFlow(of patrimoine       : Patrimoin,
                                                      for adultsName      : [String],
                                                      lifeInsuranceRebate : inout Double) throws {
        if netCashFlow > 0.0 {
            // capitaliser les intérêts des investissements libres
            patrimoine.capitalizeFreeInvestments(atEndOf: year)
            // ajouter le cash flow net à un investissement libre de type Assurance vie
            patrimoine.investNetCashFlow(amount : netCashFlow,
                                         for    : adultsName)
            
        } else {
            // retirer le solde net d'un investissement libre: d'abord PEA ensuite Assurance vie
            // géré comme un revenu en report d'imposition (dette)
            let totalTaxableInterests =
                try patrimoine.getCashFromInvestement(thisAmount          : -netCashFlow,
                                                      atEndOf             : year,
                                                      for                 : adultsName,
                                                      taxes               : &taxes.perCategory,
                                                      lifeInsuranceRebate : &lifeInsuranceRebate)
            taxableIrppRevenueDelayedToNextYear.increase(by: totalTaxableInterests.rounded())
            
            // capitaliser les intérêts des investissements libres
            patrimoine.capitalizeFreeInvestments(atEndOf: year)
        }
    }
}
