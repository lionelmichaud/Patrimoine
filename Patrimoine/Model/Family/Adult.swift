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
        case nbOfChildBirth, dateOfRetirement, ageOfPensionLiquid, nbOfYearOfDependency, initialPersonalIncome
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
    
    @Published var nbOfYearOfDependency: Int = 0
    var ageOfDependency: Int {
        return ageOfDeath - nbOfYearOfDependency
    } // computed
    var yearOfDependency: Int {
        return yearOfDeath - nbOfYearOfDependency
    }
    
    // revenus
    @Published var initialPersonalIncome: PersonalIncomeType? { // observed
        willSet {
            switch newValue! {
                case .salary(let netSalary, let charge):
                    initialPersonalNetIncome = netSalary - charge
                    initialPersonalTaxableIncome = netSalary * (1 - Fiscal.model.incomeTaxes.model.salaryRebate / 100.0)
                case .turnOver(let BNC, let charge):
                    let net = Fiscal.model.socialTaxesOnTurnover.net(BNC)
                    initialPersonalNetIncome = net - charge
                    initialPersonalTaxableIncome = BNC * (1 - Fiscal.model.incomeTaxes.model.turnOverRebate / 100.0)
            }
            //Swift.print("net personalIncome =",netIncome," taxable personalIncome =",taxableIncome)
        }
    }
    @Published var initialPersonalNetIncome     : Double = 0 // net de dépenses de mutuelle ou d'assurance perte d'emploi
    @Published var initialPersonalTaxableIncome : Double = 0 // taxable à l'IRPP
    @Published var initialPersonalPension       : Double = 0 // euro
    override var description: String {
        return super.description +
        """
        age of retirement:  \(ageOfRetirementComp)
        date of retirement: \(dateOfRetirement.stringMediumDate))
        age of pension liquidation:  \(ageOfPensionLiquidComp)
        date of pension liquidation: \(dateOfPensionLiquid.stringMediumDate))
        number of children: \(nbOfChildBirth)
        type de revenus: \(initialPersonalIncome?.displayString ?? "aucun")
        net income:     \(initialPersonalNetIncome.euroString)
        taxable income: \(initialPersonalTaxableIncome.euroString) \n
        """
    }
    
    // initialization
    
    required init(from decoder: Decoder) throws {
        // Get our container for this subclass' coding keys
        let container          = try decoder.container(keyedBy: CodingKeys.self)
        nbOfChildBirth         = try container.decode(Int.self, forKey: .nbOfChildBirth)
        dateOfRetirement       = try container.decode(Date.self, forKey: .dateOfRetirement)
        ageOfPensionLiquidComp = try container.decode(DateComponents.self, forKey: .ageOfPensionLiquid)
        nbOfYearOfDependency   = try container.decode(Int.self, forKey: .nbOfYearOfDependency)
        initialPersonalIncome  = try container.decode(PersonalIncomeType.self, forKey: .initialPersonalIncome)
        
        // Get superDecoder for superclass and call super.init(from:) with it
        //let superDecoder = try container.superDecoder()
        try super.init(from: decoder)
    }
    
    override init(sexe: Sexe,
                         givenName: String, familyName: String,
                         yearOfBirth: Int, monthOfBirth: Int, dayOfBirth: Int,
                         ageOfDeath: Int = CalendarCst.forever) {
        super.init(sexe: sexe, givenName: givenName, familyName: familyName, yearOfBirth: yearOfBirth, monthOfBirth: monthOfBirth, dayOfBirth: dayOfBirth, ageOfDeath: ageOfDeath)
    }
    
    override init(sexe: Sexe,
                         givenName: String, familyName: String,
                         birthDate : Date,
                         ageOfDeath: Int = CalendarCst.forever) {
        super.init(sexe: sexe, givenName: givenName, familyName: familyName, birthDate: birthDate, ageOfDeath: ageOfDeath)
    }
    
    // methods
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(nbOfChildBirth, forKey: .nbOfChildBirth)
        try container.encode(dateOfRetirement, forKey: .dateOfRetirement)
        try container.encode(ageOfPensionLiquidComp, forKey: .ageOfPensionLiquid)
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
    /// true si est vivant à la fin de l'année et encore en activité pendant une partie de l'année
    /// - Parameter year: année
    func isActive(during year: Int) -> Bool {
        isAlive(atEndOf: year) && year <= dateOfRetirementComp.year!
    }
    /// true si est vivant à la fin de l'année et année postérieur à l'année de cessation d'activité
    /// et avant liquidation de la pension
    /// - Parameter year: année
    func isRetired(during year: Int) -> Bool {
        isAlive(atEndOf: year) && (dateOfRetirementComp.year! < year) && (year <= dateOfPensionLiquidComp.year!)
    }
    /// true si est vivant à la fin de l'année et année postérieur à l'année de liquidation de la pension
    /// - Parameter year: année
    func isPensioned(during year: Int) -> Bool {
        isAlive(atEndOf: year) && (dateOfPensionLiquidComp.year! < year)
    }
    /// Revenu net de charges et revenu taxable à l'IRPP
    /// - Parameter year: année
    /// - Parameter net: Revenu net de charges
    /// - Parameter taxableIrpp: revenu taxable à l'IRPP
    func personalIncome(during year: Int) -> (net: Double, taxableIrpp: Double) {
        if isActive(during: year) {
            return (initialPersonalNetIncome, initialPersonalTaxableIncome)
        } else {
            return (0.0, 0.0)
        }
    }
    override func print() {
        super.print()
        Swift.print("       date of retirement:", dateOfRetirementComp)
        Swift.print("       age of retirement:", ageOfRetirementComp)
        Swift.print("       date of pension liquidation:", dateOfPensionLiquidComp)
        Swift.print("       age of pension liquidation:", ageOfPensionLiquidComp)
        Swift.print("       number of children:", nbOfChildBirth)
        Swift.print("      ", initialPersonalIncome ?? "none","euro")
        Swift.print("       net income:    ", initialPersonalNetIncome,"euro")
        Swift.print("       taxable income:", initialPersonalTaxableIncome,"euro")
    }
}

