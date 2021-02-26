//
//  Adult.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 23/06/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

final class Adult: Person { // swiftlint:disable:this type_body_length
    
    // MARK: - nested types
    
    private enum CodingKeys : String, CodingKey {
        case nb_Of_Child_Birth,
             fiscal_option,
             date_Of_Retirement,
             cause_Retirement,
             layoff_Compensation_Bonified,
             age_Of_Pension_Liquid,
             regime_General_Situation,
             age_Of_Agirc_Pension_Liquid,
             regime_Agirc_Situation,
             work_Income
    }
    
    // MARK: - Static Properties
    
    static var adultRelativesProvider: AdultRelativesProvider!
    
    // MARK: - Static Methods
    
    static func setAdultRelativesProvider(_ adultRelativesProvider: AdultRelativesProvider) {
        self.adultRelativesProvider = adultRelativesProvider
    }
    
    // MARK: - Properties
    
    // nombre d'enfants
    @Published var nbOfChildBirth: Int = 0
    
    /// SUCCESSION: option fiscale
    @Published var fiscalOption : InheritanceDonation.FiscalOption = .fullUsufruct

    /// ACTIVITE: revenus du travail
    @Published var workIncome : WorkIncomeType?
    var workBrutIncome    : Double { // avant charges sociales, dépenses de mutuelle ou d'assurance perte d'emploi
        switch workIncome {
            case .salary(let brutSalary, _, _, _, _):
                return brutSalary
            case .turnOver(let BNC, _):
                return BNC
            case .none:
                return 0
        }
    }
    var workNetIncome     : Double { // net de feuille de paye, net de charges sociales et mutuelle obligatore
        switch workIncome {
            case .salary(_, _, let netSalary, _, _):
                return netSalary
            case .turnOver(let BNC, _):
                return Fiscal.model.turnoverTaxes.net(BNC)
            case .none:
                return 0
        }
    }
    var workLivingIncome  : Double { // net de feuille de paye et de mutuelle facultative ou d'assurance perte d'emploi
        switch workIncome {
            case .salary(_, _, let netSalary, _, let charge):
                return netSalary - charge
            case .turnOver(let BNC, let charge):
                return Fiscal.model.turnoverTaxes.net(BNC) - charge
            case .none:
                return 0
        }
    }
    var workTaxableIncome : Double { // taxable à l'IRPP
        switch workIncome {
            case .none:
                return 0
            default:
                return Fiscal.model.incomeTaxes.taxableIncome(from: workIncome!)
        }
    }
    
    /// ACTIVITE: date et cause de cessation d'activité
    @Published var causeOfRetirement: Unemployment.Cause = .demission
    @Published var dateOfRetirement : Date = Date.distantFuture
    var dateOfRetirementComp        : DateComponents { // computed
        Date.calendar.dateComponents([.year, .month, .day], from: dateOfRetirement)
    } // computed
    var ageOfRetirementComp         : DateComponents { // computed
        Date.calendar.dateComponents([.year, .month, .day], from: birthDateComponents, to: dateOfRetirementComp)
    } // computed
    var displayDateOfRetirement     : String { // computed
        mediumDateFormatter.string(from: dateOfRetirement)
    } // computed
    
    /// CHOMAGE
    var SJR: Double { // computed
        guard let workIncome = workIncome else {
            return 0.0
        }
        switch workIncome {
            case .salary:
                // base: salaire brut
                return workBrutIncome / 365.0
            case .turnOver:
                return 0.0
        }
    }
    var hasUnemployementAllocationPeriod      : Bool { // computed
        guard let workIncome = workIncome else {
            return false
        }
        switch workIncome {
            case .turnOver:
                // pas d'allocation pour les non salariés
                return false
            case .salary:
                // pour les salariés, allocation seulement pour certaines causes de départ
                return Unemployment.canReceiveAllocation(for: causeOfRetirement)
        }
    } // computed
    @Published var layoffCompensationBonified : Double? // indemnité accordée par l'entreprise > légal (supra-légale)
    var layoffCompensationBrutLegal           : Double? { // computed
        guard hasUnemployementAllocationPeriod else {
            return nil
        }
        guard let workIncome = workIncome else {
            return nil
        }
        switch workIncome {
            case .salary(_, _, _, let fromDate, _):
                let nbYearsSeniority = numberOf(.year,
                                                from : fromDate,
                                                to   : dateOfRetirement).year!
                return Unemployment.model.indemniteLicenciement.layoffCompensationLegal(
                    yearlyWorkIncomeBrut : workBrutIncome,
                    nbYearsSeniority     : nbYearsSeniority)
            default:
                fatalError()
        }
    } // computed
    var layoffCompensationBrutConvention      : Double? { // computed
        guard hasUnemployementAllocationPeriod else {
            return nil
        }
        guard let workIncome = workIncome else {
            return nil
        }
        switch workIncome {
            case .salary(_, _, _, let fromDate, _):
                let nbYearsSeniority = numberOf(.year,
                                                from : fromDate,
                                                to   : dateOfRetirement).year!
                // base: salaire brut
                return Unemployment.model.indemniteLicenciement.layoffCompensation(
                    actualCompensationBrut : nil,
                    causeOfRetirement      : causeOfRetirement,
                    yearlyWorkIncomeBrut   : workBrutIncome,
                    age                    : age(atDate: dateOfRetirement).year!,
                    nbYearsSeniority       : nbYearsSeniority).brut
            default:
                fatalError()
        }
    } // computed
    var layoffCompensation                    : (nbMonth: Double, brut: Double, net: Double, taxable: Double)? { // computed
        guard hasUnemployementAllocationPeriod else {
            return nil
        }
        guard let workIncome = workIncome else {
            return nil
        }
        switch workIncome {
            case .salary(_, _, _, let fromDate, _):
                let nbYearsSeniority = numberOf(.year,
                                                from : fromDate,
                                                to   : dateOfRetirement).year!
                // base: salaire brut
                return Unemployment.model.indemniteLicenciement.layoffCompensation(
                    actualCompensationBrut : layoffCompensationBonified,
                    causeOfRetirement      : causeOfRetirement,
                    yearlyWorkIncomeBrut   : workBrutIncome,
                    age                    : age(atDate: dateOfRetirement).year!,
                    nbYearsSeniority       : nbYearsSeniority)
            default:
                fatalError()
        }
    } // computed
    var unemployementAllocationDiffere        : Int? { // en jours
        guard hasUnemployementAllocationPeriod else {
            return nil
        }
        guard let compensationSupralegal = layoffCompensation?.brut - layoffCompensationBrutLegal else {
            return nil
        }
        //Swift.print("supralégal = \(compensationSupralegal)")
        return Unemployment.model.allocationChomage.differeSpecifique(
            compensationSupralegal : compensationSupralegal,
            causeOfUnemployement   : causeOfRetirement)
    } // computed
    var unemployementAllocationDuration       : Int? { // en mois
        guard hasUnemployementAllocationPeriod else {
            return nil
        }
        return Unemployment.model.allocationChomage.durationInMonth(age: age(atDate: dateOfRetirement).year!)
    } // computed
    var dateOfStartOfUnemployementAllocation  : Date? { // computed
        guard hasUnemployementAllocationPeriod else {
            return nil
        }
        return unemployementAllocationDiffere!.days.from(dateOfRetirement)!
    } // computed
    var dateOfStartOfAllocationReduction      : Date? { // computed
        guard hasUnemployementAllocationPeriod else {
            return nil
        }
        guard let reductionAfter = Unemployment.model.allocationChomage.reductionAfter(
                age: age(atDate: dateOfRetirement).year!,
                SJR: SJR) else {
            return nil
        }
        guard let dateOfStart = dateOfStartOfUnemployementAllocation else {
            return nil
        }
        return reductionAfter.months.from(dateOfStart)!
    } // computed
    var dateOfEndOfUnemployementAllocation    : Date? { // computed
        guard hasUnemployementAllocationPeriod else {
            return nil
        }
        guard let dateOfStart = dateOfStartOfUnemployementAllocation else {
            return nil
        }
        return unemployementAllocationDuration!.months.from(dateOfStart)!
    } // computed
    var unemployementAllocation               : (brut: Double, net: Double)? { // computed
        guard hasUnemployementAllocationPeriod else {
            return nil
        }
        let dayly = Unemployment.model.allocationChomage.daylyAllocBeforeReduction(SJR: SJR)
        return (brut: dayly.brut * 365, net: dayly.net * 365)
    } // computed
    var unemployementReducedAllocation        : (brut: Double, net: Double)? { // computed
        guard let alloc = unemployementAllocation else {
            return nil
        }
        let reduc = unemployementAllocationReduction!
        return (brut: alloc.brut * (1 - reduc.percentReduc / 100),
                net : alloc.net  * (1 - reduc.percentReduc / 100))
    } // computed
    var unemployementTotalAllocation          : (brut: Double, net: Double)? { // computed
        guard hasUnemployementAllocationPeriod else {
            return nil
        }
        let totalDuration = unemployementAllocationDuration!
        let alloc         = unemployementAllocation!
        let allocReduite  = unemployementReducedAllocation!
        if let afterMonth = unemployementAllocationReduction!.afterMonth {
            return (brut: alloc.brut / 12 * afterMonth.double() + allocReduite.brut / 12 * (totalDuration - afterMonth).double(),
                    net : alloc.net  / 12 * afterMonth.double() + allocReduite.net  / 12 * (totalDuration - afterMonth).double())
        } else {
            return (brut: alloc.brut / 12 * totalDuration.double(),
                    net : alloc.net  / 12 * totalDuration.double())
        }
    } // computed
    var unemployementAllocationReduction      : (percentReduc: Double, afterMonth: Int?)? { // computed
        guard hasUnemployementAllocationPeriod else {
            return nil
        }
        return Unemployment.model.allocationChomage.reduction(age        : age(atDate: dateOfRetirement).year!,
                                                              daylyAlloc : unemployementAllocation!.brut / 365)
    } // computed
    
    /// RETRAITE: date de demande de liquidation de pension régime général
    var dateOfPensionLiquid              : Date { // computed
        Date.calendar.date(from: dateOfPensionLiquidComp)!
    } // computed
    var dateOfPensionLiquidComp          : DateComponents { // computed
        let liquidDate = Date.calendar.date(byAdding: ageOfPensionLiquidComp, to: birthDate)
        return Date.calendar.dateComponents([.year, .month, .day], from: liquidDate!)
    } // computed
    @Published var ageOfPensionLiquidComp: DateComponents = DateComponents(calendar: Date.calendar, year: 62, month: 0, day: 1)
    var displayDateOfPensionLiquid       : String { // computed
        mediumDateFormatter.string(from: dateOfPensionLiquid)
    } // computed
    @Published var lastKnownPensionSituation = RegimeGeneralSituation()
    var pensionRegimeGeneral: (brut: Double, net: Double) {
        // pension du régime général
        if let (brut, net) =
            Retirement.model.regimeGeneral.pension(
                birthDate                : birthDate,
                dateOfRetirement         : dateOfRetirement,
                dateOfEndOfUnemployAlloc : dateOfEndOfUnemployementAllocation,
                dateOfPensionLiquid      : dateOfPensionLiquid,
                lastKnownSituation       : lastKnownPensionSituation,
                nbEnfant                 : 3) {
            return (brut, net)
        } else {
            return (0, 0)
        }
    } // computed
    
    /// RETRAITE: date de demande de liquidation de pension complémentaire
    var dateOfAgircPensionLiquid              : Date { // computed
        Date.calendar.date(from: dateOfAgircPensionLiquidComp)!
    } // computed
    var dateOfAgircPensionLiquidComp          : DateComponents { // computed
        let liquidDate = Date.calendar.date(byAdding: ageOfAgircPensionLiquidComp, to: birthDate)
        return Date.calendar.dateComponents([.year, .month, .day], from: liquidDate!)
    } // computed
    @Published var ageOfAgircPensionLiquidComp: DateComponents = DateComponents(calendar: Date.calendar, year: 62, month: 0, day: 1)
    var displayDateOfAgircPensionLiquid       : String { // computed
        mediumDateFormatter.string(from: dateOfAgircPensionLiquid)
    } // computed
    @Published var lastKnownAgircPensionSituation = RegimeAgircSituation()
    var pensionRegimeAgirc: (brut: Double, net: Double) {
        if let pensionAgirc =
            Retirement.model.regimeAgirc.pension(
                lastAgircKnownSituation  : lastKnownAgircPensionSituation,
                birthDate                : birthDate,
                lastKnownSituation       : lastKnownPensionSituation,
                dateOfRetirement         : dateOfRetirement,
                dateOfEndOfUnemployAlloc : dateOfEndOfUnemployementAllocation,
                dateOfPensionLiquid      : dateOfAgircPensionLiquid,
                nbEnfantNe               : Adult.adultRelativesProvider.nbOfChildren,
                nbEnfantACharge          : Adult.adultRelativesProvider.nbOfFiscalChildren(during: dateOfAgircPensionLiquid.year)) {
            return (pensionAgirc.pensionBrute,
                    pensionAgirc.pensionNette)
        } else {
            return (0, 0)
        }
    } // computed
    
    /// RETRAITE: pension évaluée l'année de la liquidation de la pension (non révaluée)
    var pension: BrutNetTaxable { // computed
        let pensionGeneral = pensionRegimeGeneral
        let pensionAgirc   = pensionRegimeAgirc
        let brut           = pensionGeneral.brut + pensionAgirc.brut
        let net            = pensionGeneral.net  + pensionAgirc.net
        let taxable        = try! Fiscal.model.pensionTaxes.taxable(brut: brut, net:net)
        return BrutNetTaxable(brut: brut, net: net, taxable: taxable)
    } // computed
    
    /// DEPENDANCE
    @Published var nbOfYearOfDependency : Int = 0
    var ageOfDependency                 : Int {
        return ageOfDeath - nbOfYearOfDependency
    } // computed
    var yearOfDependency                : Int {
        return yearOfDeath - nbOfYearOfDependency
    } // computed
    
    override var description: String {
        return super.description +
            """
        age of retirement:  \(ageOfRetirementComp)
        date of retirement: \(dateOfRetirement.stringMediumDate)
        age of AGIRC pension liquidation:  \(ageOfAgircPensionLiquidComp)
        date of AGIRC pension liquidation: \(dateOfAgircPensionLiquid.stringMediumDate)
        age of pension liquidation:  \(ageOfPensionLiquidComp)
        date of pension liquidation: \(dateOfPensionLiquid.stringMediumDate)
        number of children: \(nbOfChildBirth)
        type de revenus: \(workIncome?.displayString ?? "aucun")
        net income for living: \(workLivingIncome.€String)
        taxable income: \(workTaxableIncome.€String) \n
        """
    }
    
    // MARK: - initialization
    
    required init(from decoder: Decoder) throws {
        // Get our container for this subclass' coding keys
        let container =
            try decoder.container(keyedBy: CodingKeys.self)
        nbOfChildBirth =
            try container.decode(Int.self,
                                 forKey : .nb_Of_Child_Birth)
        fiscalOption =
            try container.decode(InheritanceDonation.FiscalOption.self,
                                 forKey : .fiscal_option)
        dateOfRetirement =
            try container.decode(Date.self,
                                 forKey: .date_Of_Retirement)
        causeOfRetirement =
            try container.decode(Unemployment.Cause.self,
                                 forKey: .cause_Retirement)
        layoffCompensationBonified =
            try container.decode(Double?.self,
                                 forKey: .layoff_Compensation_Bonified)
        ageOfPensionLiquidComp =
            try container.decode(DateComponents.self,
                                 forKey: .age_Of_Pension_Liquid)
        lastKnownPensionSituation =
            try container.decode(RegimeGeneralSituation.self,
                                 forKey: .regime_General_Situation)
        ageOfAgircPensionLiquidComp =
            try container.decode(DateComponents.self, forKey: .age_Of_Agirc_Pension_Liquid)
        lastKnownAgircPensionSituation =
            try container.decode(RegimeAgircSituation.self,
                                 forKey: .regime_Agirc_Situation)
        // initialiser avec la valeur moyenne déterministe
        nbOfYearOfDependency = Int(HumanLife.model.nbOfYearsOfdependency.value(withMode: .deterministic))
        workIncome =
            try container.decode(WorkIncomeType.self,
                                 forKey: .work_Income)
        
        try super.init(from: decoder)

        // pas de dépendance avant l'âge de 65 ans
        nbOfYearOfDependency = min(nbOfYearOfDependency, zeroOrPositive(ageOfDeath - 65))
    }
    
    override init(sexe       : Sexe,
                  givenName  : String,
                  familyName : String,
                  birthDate  : Date,
                  ageOfDeath : Int = CalendarCst.forever) {
        super.init(sexe: sexe, givenName: givenName, familyName: familyName, birthDate: birthDate, ageOfDeath: ageOfDeath)
    }
    
    // MARK: - methods
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(nbOfChildBirth, forKey: .nb_Of_Child_Birth)
        try container.encode(fiscalOption, forKey: .fiscal_option)
        try container.encode(dateOfRetirement, forKey: .date_Of_Retirement)
        try container.encode(causeOfRetirement, forKey: .cause_Retirement)
        try container.encode(layoffCompensationBonified, forKey: .layoff_Compensation_Bonified)
        try container.encode(ageOfPensionLiquidComp, forKey: .age_Of_Pension_Liquid)
        try container.encode(lastKnownPensionSituation, forKey: .regime_General_Situation)
        try container.encode(ageOfAgircPensionLiquidComp, forKey: .age_Of_Agirc_Pension_Liquid)
        try container.encode(lastKnownAgircPensionSituation, forKey: .regime_Agirc_Situation)
//        try container.encode(nbOfYearOfDependency, forKey: .nb_Of_Year_Of_Dependency)
        try container.encode(workIncome, forKey: .work_Income)
    }
    
    /// Année ou a lieu l'événement recherché
    /// - Parameter event: événement recherché
    /// - Returns: Année ou a lieu l'événement recherché, nil si l'événement n'existe pas
    override func yearOf(event: LifeEvent) -> Int? {
        switch event {
            case .debutEtude:
                return nil
                
            case .independance:
                return nil
                
            case .dependence:
                return yearOfDependency
                
            case .deces:
                return super.yearOf(event: event)
                
            case .cessationActivite:
                return dateOfRetirement.year
                
            case .liquidationPension:
                return dateOfPensionLiquid.year
            // TODO: ajouter la liquidation de la pension complémentaire
            // TODO: ajouter le licenciement
            // TODO: ajouter la fin des indemnités chomage
        }
    }
    
    func gaveBirthTo(children : Int) {
        if sexe == .female {nbOfChildBirth = children}
    }
    func addChild() {
        if sexe == .female {nbOfChildBirth += 1}
    }
    func removeChild() {
        if sexe == .female {nbOfChildBirth -= 1}
    }
    func nbOfFiscalChildren(during year: Int) -> Int {
        Adult.adultRelativesProvider.nbOfFiscalChildren(during: year)
    }
    func nbOfChildren() -> Int {
        Adult.adultRelativesProvider.nbOfChildren
    }
    func setAgeOfPensionLiquidComp(year: Int, month: Int = 0, day: Int = 0) {
        ageOfPensionLiquidComp = DateComponents(calendar: Date.calendar, year: year, month: month, day: day)
    }
    func setAgeOfAgircPensionLiquidComp(year: Int, month: Int = 0, day: Int = 0) {
        ageOfAgircPensionLiquidComp = DateComponents(calendar: Date.calendar, year: year, month: month, day: day)
    }
    
    /// true si est vivant à la fin de l'année et encore en activité pendant une partie de l'année
    /// - Parameter year: année
    func isActive(during year: Int) -> Bool {
        isAlive(atEndOf: year) && (year <= dateOfRetirement.year)
    }
    
    /// true si est vivant à la fin de l'année et année égale ou postérieur à l'année de cessation d'activité
    /// - Parameter year: année
    func isRetired(during year: Int) -> Bool {
        isAlive(atEndOf: year) && (dateOfRetirement.year <= year)
    }
    
    /// true si est vivant à la fin de l'année et année égale ou postérieur à l'année de liquidation de la pension du régime complémentaire
    /// - Parameter year: première année incluant des revenus
    func isDependent(during year: Int) -> Bool {
        isAlive(atEndOf: year) && (yearOfDependency <= year)
    }
    
    /// Revenu net de charges pour vivre et revenu taxable à l'IRPP
    /// - Parameter year: année
    func workIncome(during year: Int)
    -> (net: Double, taxableIrpp: Double) {
        guard isActive(during: year) else {
            return (0, 0)
        }
        let nbWeeks = (dateOfRetirementComp.year == year ? dateOfRetirement.weekOfYear.double() : 52)
        return (net         : workLivingIncome  * nbWeeks / 52,
                taxableIrpp : workTaxableIncome * nbWeeks / 52)
    }
    
    /// Réinitialiser les prioriétés aléatoires des membres
    override func nextRandomProperties() {
        super.nextRandomProperties()
        
        // générer une nouvelle valeure aléatoire
        // réinitialiser la durée de dépendance
        nbOfYearOfDependency = Int(HumanLife.model.nbOfYearsOfdependency.next())
        
        // pas de dépendance avant l'âge de 65 ans
        nbOfYearOfDependency = min(nbOfYearOfDependency, zeroOrPositive(ageOfDeath - 65))
    }

    override func print() {
        super.print()
        Swift.print("       date of retirement:", dateOfRetirementComp)
        Swift.print("       age of retirement:", ageOfRetirementComp)
        Swift.print("       date of AGIRC pension liquidation:", dateOfAgircPensionLiquidComp)
        Swift.print("       age of AGIRC pension liquidation:", ageOfAgircPensionLiquidComp)
        Swift.print("       date of pension liquidation:", dateOfPensionLiquidComp)
        Swift.print("       age of pension liquidation:", ageOfPensionLiquidComp)
        Swift.print("       number of children:", nbOfChildBirth)
        Swift.print("      ", workIncome ?? "none", "euro")
        Swift.print("       net income for living:", workLivingIncome, "euro")
        Swift.print("       taxable income:", workTaxableIncome, "euro")
    }
}
