//
//  Adult.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 23/06/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: -
final class Adult: Person {
    
    // nested types
    
    private enum CodingKeys : String, CodingKey {
        case nbOfChildBirth,
        dateOfRetirement,
        ageOfPensionLiquid,
        regimeGeneralSituation,
        ageOfAgircPensionLiquid,
        regimeAgircSituation,
        nbOfYearOfDependency,
        initialPersonalIncome
    }
    
    // properties
    
    // nombre d'enfants
    @Published var nbOfChildBirth: Int = 0
    
    // date de cessation d'activité
    @Published var dateOfRetirement: Date = Date.distantFuture
    var dateOfRetirementComp: DateComponents { // computed
        Date.calendar.dateComponents([.year, .month, .day], from: dateOfRetirement)
    } // computed
    var ageOfRetirementComp:  DateComponents { // computed
        Date.calendar.dateComponents([.year, .month, .day], from: birthDateComponents, to: dateOfRetirementComp)
    } // computed
    var displayDateOfRetirement: String { // computed
        mediumDateFormatter.string(from: dateOfRetirement)
    } // computed
    
    // date de demande de liquidation de pension
    var dateOfPensionLiquid: Date { // computed
        Date.calendar.date(from: dateOfPensionLiquidComp)!
    } // computed
    var dateOfPensionLiquidComp: DateComponents { // computed
        let liquidDate = Date.calendar.date(byAdding: ageOfPensionLiquidComp, to: birthDate)
        return Date.calendar.dateComponents([.year, .month, .day], from: liquidDate!)
    } // computed
    @Published var ageOfPensionLiquidComp:  DateComponents = DateComponents(calendar: Date.calendar, year: 62, month: 0, day: 1)
    var displayDateOfPensionLiquid: String { // computed
        mediumDateFormatter.string(from: dateOfPensionLiquid)
    } // computed
    var lastKnownPensionSituation = RegimeGeneralSituation()
    var pensionRegimeGeneral: (brut: Double, net: Double) {
        // pension du régime général
        if let pensionGeneral =
            Pension.model.regimeGeneral.pensionWithDetail(birthDate               : birthDate,
                                                          dateOfPensionLiquidComp : dateOfPensionLiquidComp,
                                                          lastKnownSituation      : lastKnownPensionSituation) {
            return (pensionGeneral.pensionBrute,
                    pensionGeneral.pensionNette)
        } else {
            return (0, 0)
        }
    }
    
    // date de demande de liquidation de pension complémentaire
    var dateOfAgircPensionLiquid: Date { // computed
        Date.calendar.date(from: dateOfAgircPensionLiquidComp)!
    } // computed
    var dateOfAgircPensionLiquidComp: DateComponents { // computed
        let liquidDate = Date.calendar.date(byAdding: ageOfAgircPensionLiquidComp, to: birthDate)
        return Date.calendar.dateComponents([.year, .month, .day], from: liquidDate!)
    } // computed
    @Published var ageOfAgircPensionLiquidComp:  DateComponents = DateComponents(calendar: Date.calendar, year: 62, month: 0, day: 1)
    var displayDateOfAgircPensionLiquid: String { // computed
        mediumDateFormatter.string(from: dateOfAgircPensionLiquid)
    } // computed
    var lastKnownAgircPensionSituation = RegimeAgircSituation()
    var pensionRegimeAgirc: (brut: Double, net: Double) {
        if let pensionAgirc =
            Pension.model.regimeAgirc.pension(lastAgircKnownSituation : lastKnownAgircPensionSituation,
                                              birthDate               : birthDate,
                                              lastKnownSituation      : lastKnownPensionSituation,
                                              dateOfPensionLiquidComp : dateOfAgircPensionLiquidComp,
                                              ageOfPensionLiquidComp  : ageOfAgircPensionLiquidComp) {
            return (pensionAgirc.pensionBrute,
                    pensionAgirc.pensionNette)
        } else {
            return (0, 0)
        }
    }

    @Published var nbOfYearOfDependency: Int = 0
    var ageOfDependency: Int {
        return ageOfDeath - nbOfYearOfDependency
    } // computed
    var yearOfDependency: Int {
        return yearOfDeath - nbOfYearOfDependency
    } // computed
    
    // revenus
    @Published var initialPersonalIncome: PersonalIncomeType? { // observed
        willSet {
            (initialPersonalNetIncome, initialPersonalTaxableIncome) =
                Fiscal.model.incomeTaxes.netAndTaxableIncome(from: newValue!)
        }
    } // observed
    @Published var initialPersonalNetIncome     : Double = 0 // net de dépenses de mutuelle ou d'assurance perte d'emploi
    @Published var initialPersonalTaxableIncome : Double = 0 // taxable à l'IRPP
    
    // pension
    var pension  : (brut: Double, net: Double, taxable: Double) { // computed
        let pensionGeneral = pensionRegimeGeneral
        let pensionAgirc   = pensionRegimeAgirc
        let brut           = pensionGeneral.brut + pensionAgirc.brut
        let net            = pensionGeneral.net  + pensionAgirc.net
        let taxable        = Fiscal.model.pensionTaxes.taxable(from: net)
        return (brut, net, taxable)
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
        type de revenus: \(initialPersonalIncome?.displayString ?? "aucun")
        net income:     \(initialPersonalNetIncome.euroString)
        taxable income: \(initialPersonalTaxableIncome.euroString) \n
        """
    }
    
    // initialization
    
    required init(from decoder: Decoder) throws {
        // Get our container for this subclass' coding keys
        let container                  = try decoder.container(keyedBy: CodingKeys.self)
        nbOfChildBirth                 = try container.decode(Int.self, forKey: .nbOfChildBirth)
        dateOfRetirement               = try container.decode(Date.self, forKey: .dateOfRetirement)
        ageOfPensionLiquidComp         = try container.decode(DateComponents.self, forKey: .ageOfPensionLiquid)
        lastKnownPensionSituation      = try container.decode(RegimeGeneralSituation.self, forKey: .regimeGeneralSituation)
        ageOfAgircPensionLiquidComp    = try container.decode(DateComponents.self, forKey: .ageOfAgircPensionLiquid)
        lastKnownAgircPensionSituation = try container.decode(RegimeAgircSituation.self, forKey: .regimeAgircSituation)
        nbOfYearOfDependency           = try container.decode(Int.self, forKey: .nbOfYearOfDependency)
        initialPersonalIncome          = try container.decode(PersonalIncomeType.self, forKey: .initialPersonalIncome)
        
        // Get superDecoder for superclass and call super.init(from:) with it
        //let superDecoder = try container.superDecoder()
        try super.init(from: decoder)
    }
    
    override init(sexe         : Sexe,
                  givenName    : String,
                  familyName   : String,
                  yearOfBirth  : Int,
                  monthOfBirth : Int,
                  dayOfBirth   : Int,
                  ageOfDeath   : Int = CalendarCst.forever) {
        super.init(sexe: sexe, givenName: givenName, familyName: familyName, yearOfBirth: yearOfBirth, monthOfBirth: monthOfBirth, dayOfBirth: dayOfBirth, ageOfDeath: ageOfDeath)
    }
    
    override init(sexe       : Sexe,
                  givenName  : String,
                  familyName : String,
                  birthDate  : Date,
                  ageOfDeath : Int = CalendarCst.forever) {
        super.init(sexe: sexe, givenName: givenName, familyName: familyName, birthDate: birthDate, ageOfDeath: ageOfDeath)
    }
    
    // methods
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(nbOfChildBirth, forKey: .nbOfChildBirth)
        try container.encode(dateOfRetirement, forKey: .dateOfRetirement)
        try container.encode(ageOfPensionLiquidComp, forKey: .ageOfPensionLiquid)
        try container.encode(lastKnownPensionSituation, forKey: .regimeGeneralSituation)
        try container.encode(ageOfAgircPensionLiquidComp, forKey: .ageOfAgircPensionLiquid)
        try container.encode(lastKnownAgircPensionSituation, forKey: .regimeAgircSituation)
        try container.encode(nbOfYearOfDependency, forKey: .nbOfYearOfDependency)
        try container.encode(initialPersonalIncome, forKey: .initialPersonalIncome)
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
            // TODO:ajouter le licenciement
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
    func setAgeOfPensionLiquidComp(year: Int, month: Int = 0, day: Int = 0) {
        ageOfPensionLiquidComp = DateComponents(calendar: Date.calendar, year: year, month: month, day: day)
    }
    func setAgeOfAgircPensionLiquidComp(year: Int, month: Int = 0, day: Int = 0) {
        ageOfAgircPensionLiquidComp = DateComponents(calendar: Date.calendar, year: year, month: month, day: day)
    }
    /// true si est vivant à la fin de l'année et encore en activité pendant une partie de l'année
    /// - Parameter year: année
    func isActive(during year: Int) -> Bool {
        isAlive(atEndOf: year) && year <= dateOfRetirementComp.year!
    }
    /// true si est vivant à la fin de l'année et année égale ou postérieur à l'année de cessation d'activité
    /// - Parameter year: année
    func isRetired(during year: Int) -> Bool {
        isAlive(atEndOf: year) && (dateOfRetirementComp.year! <= year)
    }
    /// true si est vivant à la fin de l'année et année égale ou postérieur à l'année de liquidation de la pension du régime général
    /// - Parameter year: première année incluant des revenus
    func isPensioned(during year: Int) -> Bool {
        isAlive(atEndOf: year) && (dateOfPensionLiquidComp.year! <= year)
    }
    /// true si est vivant à la fin de l'année et année égale ou postérieur à l'année de liquidation de la pension du régime complémentaire
    /// - Parameter year: première année incluant des revenus
    func isAgircPensioned(during year: Int) -> Bool {
        isAlive(atEndOf: year) && (dateOfAgircPensionLiquidComp.year! <= year)
    }
    /// true si est vivant à la fin de l'année et année égale ou postérieur à l'année de liquidation de la pension du régime complémentaire
    /// - Parameter year: première année incluant des revenus
    func isDependent(during year: Int) -> Bool {
        isAlive(atEndOf: year) && (yearOfDependency <= year)
    }
    /// Revenu net de charges et revenu taxable à l'IRPP
    /// - Parameter year: année
    /// - Returns: taxableIrpp: revenu taxable à l'IRPP
    func personalIncome(during year: Int) -> (net: Double, taxableIrpp: Double) {
        // TODO: proratiser
        if isActive(during: year) {
            let nbMonths = (dateOfRetirementComp.year == year ? dateOfRetirement.weekOfYear.double() : 52)
            return (net         : initialPersonalNetIncome * nbMonths / 52,
                    taxableIrpp : initialPersonalTaxableIncome * nbMonths / 52)
        } else {
            return (0.0, 0.0)
        }
    }
    /// Calcul de la pension de retraite
    /// - Parameter year: année
    /// - Returns: pension brute, nette de charges sociales, taxable à l'IRPP
    func pension(during year: Int) -> (brut: Double, net: Double, taxable: Double) {
        var brut = 0.0
        var net  = 0.0
        // pension du régime général
        if isPensioned(during: year) {
            let pension = pensionRegimeGeneral
            let nbMonths = (dateOfPensionLiquidComp.year == year ? (52 - dateOfPensionLiquid.weekOfYear).double() : 52)
            brut += pension.brut * nbMonths / 52
            net  += pension.net  * nbMonths / 52
        }
        // pension du régime complémentaire
        if isAgircPensioned(during: year) {
            let pension = pensionRegimeAgirc
            let nbMonths = (dateOfAgircPensionLiquidComp.year == year ? (52 - dateOfAgircPensionLiquid.weekOfYear).double() : 52)
            brut += pension.brut * nbMonths / 52
            net  += pension.net  * nbMonths / 52
        }
        let taxable = Fiscal.model.pensionTaxes.taxable(from: net)
        return (brut, net, taxable)
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
        Swift.print("      ", initialPersonalIncome ?? "none","euro")
        Swift.print("       net income:    ", initialPersonalNetIncome,"euro")
        Swift.print("       taxable income:", initialPersonalTaxableIncome,"euro")
    }
}

