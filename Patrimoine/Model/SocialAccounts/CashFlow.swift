import Foundation

enum CashFlowError: Error {
    case notEnoughCash(missingCash: Double)
}

typealias CashFlowArray = [CashFlowLine]

// MARK: - Ligne annuelle de cash flow

struct CashFlowLine {
    
    // nested types
    
    // MARK: - agrégat des ages
    struct Ages {
        
        // properties
        
        var persons = [(name: String, age: Int)]()
        
        // methods
        
        func print(level: Int = 0) {
            let h = String(repeating: StringCst.header, count: level)
            Swift.print(h + "AGES:")
            Swift.print(h + StringCst.header, persons)
        }
    }
    
    // MARK: - agrégat de revenus pour une catégories donnée
    struct Revenues {
        
        // nested types
        
        /// table des revenus d'une catégorie donnée
        struct NetAndTaxable {
            
            // properties
            
            let name: String
            
            /// table des revenus versés en compte courant avant taxes, prélèvements sociaux et impots
            var credits      = NamedValueTable(withName: "PERCU")
            /// table des fractions de revenus versés en compte courant qui est imposable à l'IRPP
            var taxablesIrpp = NamedValueTable(withName: "TAXABLE")
            
            // initialization
            
            init(name: String) {
                self.name = name
            }
            
            // methods
            
            func print(level: Int = 0) {
                let h = String(repeating: StringCst.header, count: level)
                Swift.print(h + name)
                Swift.print(h + StringCst.header + "credits:      ", credits, "total:", credits.total)
                Swift.print(h + StringCst.header + "taxables IRPP:", taxablesIrpp, "total:", taxablesIrpp.total)
            }
        }
        
        // properties
        
        let name = "REVENUS HORS SCI"
        /// revenus du travail
        var workIncomes     = NetAndTaxable(name: "Revenu Travail")
        /// revenus financiers
        var financials      = NetAndTaxable(name: "Revenu Financier")
        /// revenus des SCPI hors de la SCI
        var scpis           = NetAndTaxable(name: "Revenu de SCPI")
        /// revenus de locations des biens immobiliers
        var realEstateRents = NetAndTaxable(name: "Revenu Location")
        /// total des ventes des SCPI hors de la SCI
        var scpiSale        = NetAndTaxable(name: "Vente SCPI")
        /// total des ventes des biens immobiliers
        var realEstateSale  = NetAndTaxable(name: "Vente Immobilier")
        /// revenus imposable de l'année précédente et reporté à l'année courante
        var taxableIrppRevenueDelayedFromLastYear = Debt(name: "REVENU IMPOSABLE REPORTE DE L'ANNEE PRECEDENTE", value: 0)
        
        /// total de tous les revenus nets de l'année versé en compte courant avant taxes et impots
        var totalCredited: Double {
            workIncomes.credits.total +
                financials.credits.total +
                scpis.credits.total +
                realEstateRents.credits.total +
                scpiSale.credits.total +
                realEstateSale.credits.total
        }
        /// total de tous les revenus de l'année imposables à l'IRPP
        var totalTaxableIrpp: Double {
            workIncomes.taxablesIrpp.total +
                financials.taxablesIrpp.total +
                scpis.taxablesIrpp.total +
                realEstateRents.taxablesIrpp.total +
                scpiSale.taxablesIrpp.total +
                realEstateSale.taxablesIrpp.total +
                // ne pas oublier les revenus en report d'imposition
                taxableIrppRevenueDelayedFromLastYear.value(atEndOf: 0)
        }
        
        /// tableau des noms  et valeurs des catégories de revenus
        var namedValueTable: NamedValueTable {
            var table = NamedValueTable(withName: "REVENUS")
            table.values.append((name  : workIncomes.name,
                                 value : workIncomes.credits.total))
            table.values.append((name  : financials.name,
                                 value : financials.credits.total))
            table.values.append((name  : scpis.name,
                                 value : scpis.credits.total))
            table.values.append((name  : realEstateRents.name,
                                 value : realEstateRents.credits.total))
            table.values.append((name  : scpiSale.name,
                                 value : scpiSale.credits.total))
            table.values.append((name  : realEstateSale.name,
                                 value : realEstateSale.credits.total))
            return table
        }
        
        /// tableau détaillé des noms des revenus: concaténation des catégories
        var headersDetailedArray: [String] {
            workIncomes.credits.headersArray +
                financials.credits.headersArray +
                scpis.credits.headersArray +
                realEstateRents.credits.headersArray +
                scpiSale.credits.headersArray +
                realEstateSale.credits.headersArray
        }
        /// tableau détaillé des valeurs des revenus: concaténation des catégories
        var valuesDetailedArray: [Double] {
            workIncomes.credits.valuesArray +
                financials.credits.valuesArray +
                scpis.credits.valuesArray +
                realEstateRents.credits.valuesArray +
                scpiSale.credits.valuesArray +
                realEstateSale.credits.valuesArray
        }
        
        // methods
        
        func print(level: Int = 0) {
            let h = String(repeating: StringCst.header, count: level)
            Swift.print(h + name + ":    ")
            // incomes
            workIncomes.print(level: level+1)
            // financial investements
            financials.print(level: level+1)
            // SCPIs
            scpis.print(level: level+1)
            // realEstateRents
            realEstateRents.print(level: level+1)
            // real estate sales
            scpiSale.print(level: level+1)
            // real estate sales
            realEstateSale.print(level: level+1)
            // revenus imposable de l'année précédente et reporté à l'année courante
            taxableIrppRevenueDelayedFromLastYear.print()
            // total des revenus
            Swift.print(h + StringCst.header + "TOTAL NET:", totalCredited, "TOTAL TAXABLE:", totalTaxableIrpp)
        }
    }
    
    // MARK: - agrégat des impôts et taxes
    struct Taxes {
        
        // properties
        
        let name = "TAXES"
        var familyQuotient: Double = 0.0
        var irpp: Double           = 0.0
        var localTaxes             = NamedValueTable(withName: "Taxes Locales")
        var socialTaxes            = NamedValueTable(withName: "Prélev Sociaux")
        var total: Double { localTaxes.total + socialTaxes.total + irpp }
        
        // methods
        
        var namedValueTable: NamedValueTable {
            var table = NamedValueTable(withName: name)
            table.values.append((name  : "IRPP",
                                 value : irpp))
            table.values.append((name  : localTaxes.name,
                                 value : localTaxes.total))
            table.values.append((name  : socialTaxes.name,
                                 value : socialTaxes.total))
            return table
        }
        
        func print(level: Int = 0) {
            let h = String(repeating: StringCst.header, count: level)
            Swift.print(h + name + ":")
            Swift.print(h + StringCst.header + "QUOTIEN FAMILIAL:", familyQuotient, "IRPP:", irpp)
            // impôts locaux
            localTaxes.print(level: level+1)
            // prélèvements sociaux
            socialTaxes.print(level: level+1)
            // total des taxes
            Swift.print(h + StringCst.header + "TOTAL TAXES:", total)
        }
    }
    
    // MARK: - agrégat des dépense
    struct Expenses {
        
        // properties
        
        var namedValueTable = NamedValueTable(withName: "LIFE EXPENSES")
        var summaryValueTable: NamedValueTable {
            var table = NamedValueTable(withName: "Dépenses")
            table.values.append((name  : "Dépenses",
                                 value : namedValueTable.total))
            return table
        }
        //        let name = "LIFE EXPENSES"
        //        var amounts = [(name: String, value: Double)]()
        //        var total: Double {
        //            return amounts.reduce(.zero, {result, element in result + element.value})
        //        }
        
        // methods
        
        //        func print(level: Int = 0) {
        //            let h = String(repeating: StringCst.header, count: level)
        //            Swift.print(h + name + ":")
        //            Swift.print(h + StringCst.header, amounts, "total:", total)
        //        }
    }
    
    // MARK: - properties
    
    let year: Int
    var ages          = Ages()
    var revenues      = Revenues()
    var taxes         = Taxes()
    var expenses      = Expenses()
    var debtPayements = NamedValueTable(withName : "Remb. dette")
    var taxableIrppRevenueDelayedToNextYear = Debt(name: "REVENU IMPOSABLE REPORTE A L'ANNEE SUIVANTE", value: 0)
    let sciCashFlowLine : SciCashFlowLine // les comptes annuels de la SCI
    var sumOfrevenues   : Double {
        revenues.totalCredited + sciCashFlowLine.netCashFlow
    }
    var sumOfExpenses: Double {
        taxes.total + expenses.namedValueTable.total + debtPayements.total
    }
    var netCashFlow: Double {
        sumOfrevenues - sumOfExpenses
    }
    
    // MARK: - initialization
    
    init(withYear       year                   : Int,
         withFamily     family                 : Family,
         withPatrimoine patrimoine             : Patrimoine,
         taxableIrppRevenueDelayedFromLastyear : Double) throws {
        self.year = year
        revenues.taxableIrppRevenueDelayedFromLastYear.setValue(to: taxableIrppRevenueDelayedFromLastyear)
        
        // initialize life insurance yearly rebate on taxes
        // TODO: mettre à jour le model de défiscalisation Asurance Vie
        var lifeInsuranceRebate = Fiscal.model.lifeInsuranceTaxes.model.rebatePerPerson * family.nbOfAdultAlive(atEndOf: year).double()
        
        // SCI: calculer le cash flow de la SCI
        sciCashFlowLine = SciCashFlowLine(withYear : year,
                                          withSCI  : patrimoine.assets.sci)
        
        // INCOME: populate Ages and Work incomes
        populateWorkIncome(of: family)
        
        // REAL ESTATE: populate produit de vente, loyers, taxes sociales et taxes locales des bien immobiliers
        populateRealEstateCashFlow(of: patrimoine)
        
        // SCPI: populate produit de vente, dividendes, taxes sociales des SCPI
        populateScpiCashFlow(of: patrimoine)
        
        // PERIODIC INVEST: populate revenue, des investissements financiers périodiques
        populatePeriodicInvestmentsCashFlow(of                  : patrimoine,
                                            lifeInsuranceRebate : &lifeInsuranceRebate)
        
        // Note: les intérêts des investissements financiers libres sont capitalisés
        
        // IRPP: calcule de l'impot sur l'ensemble des revenus: IRPP
        taxes.familyQuotient = Fiscal.model.incomeTaxes.familyQuotient(nbAdults   : family.nbOfAdultAlive(atEndOf: year),
                                                                       nbChildren : family.nbOfFiscalChildren(during: year))
        taxes.irpp = Fiscal.model.incomeTaxes.irpp(taxableIncome : revenues.totalTaxableIrpp,
                                                   nbAdults      : family.nbOfAdultAlive(atEndOf: year),
                                                   nbChildren    : family.nbOfFiscalChildren(during: year)).rounded()
        
        // EXPENSES: compute and populate family expenses
        expenses.namedValueTable.values = family.expenses.namedValueTable(atEndOf: year)
        
        // LOAN: populate remboursement d'emprunts
        populateLoanCashFlow(of: patrimoine)
        
        #if DEBUG
        Swift.print("Year = \(year), Revenus = \(sumOfrevenues), Expenses = \(sumOfExpenses), Net cash flow = \(netCashFlow)")
        #endif
        try manageYearlyNetCashFlow(of                  : patrimoine,
                                    lifeInsuranceRebate : &lifeInsuranceRebate,
                                    atEndOf             : year)
    }
    
    // MARK: - methods
    
    /// Populate Ages and Work incomes
    /// - Parameter family: de la famille
    fileprivate mutating func populateWorkIncome(of family: Family) {
        // pour chaque membre de la famille
        for person in family.members.sorted(by:>) {
            // populate ages of family members
            let name = person.name.familyName! + " " + person.name.givenName!
            ages.persons.append((name: name, age: person.age(atEndOf: year)))
            // populate work incomes of family members
            if let adult = person as? Adult {
                let income = adult.personalIncome(during: year)
                // revenus inscrit en compte avant IRPP (net de dépenses de mutuelle ou d'assurance perte d'emploi)
                revenues.workIncomes.credits.values.append((name: name, value: income.net.rounded()))
                // part des revenus inscrit en compte imposable à l'IRPP
                revenues.workIncomes.taxablesIrpp.values.append((name: name, value: income.taxableIrpp.rounded()))
            }
        }
    }
    
    /// Populate loyers, produit de la vente et impots locaux des biens immobiliers
    /// - Parameter patrimoine: du patrimoine
    fileprivate mutating func populateRealEstateCashFlow(of patrimoine: Patrimoine) {
        for realEstate in patrimoine.assets.realEstates.items.sorted(by:<) {
            // populate real estate rent revenues and social taxes
            let yearlyRent = realEstate.yearlyRent(during: year)
            let name       = realEstate.name
            // loyers inscrit en compte courant avant prélèvements sociaux et IRPP
            revenues.realEstateRents.credits.values.append((name: name, value: yearlyRent.revenue.rounded()))
            // part des loyers inscrit en compte courant imposable à l'IRPP - idem ci-dessus car même base
            revenues.realEstateRents.taxablesIrpp.values.append((name: name, value: yearlyRent.taxableIrpp.rounded()))
            // prélèvements sociaux payés sur le loyer
            taxes.socialTaxes.values.append((name: name, value: yearlyRent.socialTaxes.rounded()))
            
            // produit de la vente inscrit en compte courant: produit net de charges sociales et d'impôt sur la plus-value
            let liquidatedValue = realEstate.liquidatedValue(year)
            revenues.realEstateSale.credits.values.append((name: name, value: liquidatedValue.netRevenue.rounded()))
            
            // impôts locaux
            let yearlyLocaltaxes = realEstate.yearlyLocalTaxes(during: year)
            taxes.localTaxes.values.append((name: name, value: yearlyLocaltaxes.rounded()))
        }
    }
    
    /// Populate produit de vente, dividendes, taxes sociales des SCPI hors de la SCI
    /// - Parameter patrimoine: du patrimoine
    fileprivate mutating func populateScpiCashFlow(of patrimoine: Patrimoine) {
        for scpi in patrimoine.assets.scpis.items.sorted(by:<) {
            // populate SCPI revenues and social taxes
            let yearlyRevenue = scpi.yearlyRevenue(atEndOf: year)
            let name          = scpi.name
            // dividendes inscrit en compte courant avant prélèvements sociaux et IRPP
            revenues.scpis.credits.values.append((name: name, value: yearlyRevenue.revenue.rounded()))
            // part des dividendes inscrit en compte courant imposable à l'IRPP
            revenues.scpis.taxablesIrpp.values.append((name: name, value: yearlyRevenue.taxableIrpp.rounded()))
            // prélèvements sociaux payés sur les dividendes de SCPI
            taxes.socialTaxes.values.append((name: name, value: yearlyRevenue.socialTaxes.rounded()))
            // populate SCPI sale revenue: produit de vente net de charges sociales et d'impôt sur la plus-value
            let liquidatedValue = scpi.liquidatedValue(year)
            revenues.scpiSale.credits.values.append((name: name, value: liquidatedValue.netRevenue.rounded()))
        }
    }
    
    /// Populate produit de la vente des investissements financiers périodiques
    /// - Parameters:
    ///   - patrimoine: du patrimoine
    ///   - lifeInsuranceRebate: franchise d'imposition sur les plus values
    fileprivate mutating func populatePeriodicInvestmentsCashFlow(of patrimoine: Patrimoine, lifeInsuranceRebate: inout Double) {
        // pour chaque investissement financier periodique
        for periodicInvestement in patrimoine.assets.periodicInvests.items.sorted(by:<) {
            let liquidatedValue = periodicInvestement.liquidatedValue(atEndOf: year)
            let name            = periodicInvestement.name
            // produit de la liquidation inscrit en compte courant avant prélèvements sociaux et IRPP
            revenues.financials.credits.values.append((name: name, value: liquidatedValue.revenue.rounded()))
            // populate taxable interests
            switch periodicInvestement.type {
                case .lifeInsurance( _):
                    var taxableInterests: Double
                    // apply rebate if some is remaining
                    taxableInterests = max(0.0, liquidatedValue.taxableIrppInterests - lifeInsuranceRebate)
                    lifeInsuranceRebate -= (liquidatedValue.taxableIrppInterests - taxableInterests)
                    // part des produit de la liquidation inscrit en compte courant imposable à l'IRPP
                    revenues.financials.taxablesIrpp.values.append((name: name, value: taxableInterests.rounded()))
                case .pea:
                    // part des produit de la liquidation inscrit en compte courant imposable à l'IRPP
                    revenues.financials.taxablesIrpp.values.append((name: name, value: liquidatedValue.taxableIrppInterests.rounded()))
                case .other:
                    // part des produit de la liquidation inscrit en compte courant imposable à l'IRPP
                    revenues.financials.taxablesIrpp.values.append((name: name, value: liquidatedValue.taxableIrppInterests.rounded()))
            }
            // prélèvements sociaux
            taxes.socialTaxes.values.append((name: name, value: liquidatedValue.socialTaxes.rounded()))
        }
    }
    
    /// Populate remboursement d'emprunts
    /// - Parameter patrimoine: du patrimoine
    fileprivate mutating func populateLoanCashFlow(of patrimoine: Patrimoine) {
        for loan in patrimoine.liabilities.loans.items.sorted(by:<) {
            let yearlyPayement = -loan.yearlyPayement(year)
            let name           = loan.name
            debtPayements.values.append((name: name, value: yearlyPayement.rounded()))
        }
    }
    
    /// Gérer l'excédent ou le déficit de trésorierie en fin d'année
    /// - Parameters:
    ///   - patrimoine: du patrimoine
    ///   - year: en fin d'année
    ///   - lifeInsuranceRebate: franchise d'imposition sur les plus values
    /// - Throws: Si pas assez de capital -> CashFlowError.notEnoughCash(missingCash: amountRemainingToRemove)
    fileprivate mutating func manageYearlyNetCashFlow(of patrimoine       : Patrimoine,
                                                      lifeInsuranceRebate : inout Double,
                                                      atEndOf year        : Int) throws {
        if netCashFlow > 0.0 {
            // capitaliser les intérêts des investissements libres
            patrimoine.capitalizeFreeInvestments(atEndOf: year)
            // ajouter le cash flow net à un investissement libre de type Assurance vie
            patrimoine.investNetCashFlow(netCashFlow)
            
        } else {
            // retirer le solde net d'un investissement libre: d'abord PEA ensuite Assurance vie
            // géré comme un revenu en report d'imposition (dette)
            let totalTaxableInterests = try patrimoine.removeFromInvestement(thisAmount          : -netCashFlow,
                                                                             atEndOf             : year,
                                                                             lifeInsuranceRebate : &lifeInsuranceRebate)
            taxableIrppRevenueDelayedToNextYear.add(amount: totalTaxableInterests.rounded())

            // capitaliser les intérêts des investissements libres
            patrimoine.capitalizeFreeInvestments(atEndOf: year)
        }
    }
            
    func print() {
        Swift.print("YEAR:", year)
        // ages
        ages.print(level: 1)
        // revenues hors SCI
        revenues.print(level: 1)
        // SCI
        sciCashFlowLine.print(level: 1)
        // taxes
        taxes.print(level: 1)
        // expenses
        expenses.namedValueTable.print(level: 1)
        // remboursements d'emprunts
        debtPayements.print(level: 1)
        // net cash flow
        Swift.print(StringCst.header + "NET CASH FLOW:", netCashFlow)
        // revenu imposable à l'IRPP reporté à l'année suivante
        // (issu des retraits de fin d'année pour équilibrer le budget de l'année courante)
        taxableIrppRevenueDelayedToNextYear.print()
        Swift.print("-----------------------------------------")
    }
}
