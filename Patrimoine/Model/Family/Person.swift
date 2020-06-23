//
//  Person.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

import TypePreservingCodingAdapter // https://github.com/IgorMuzyka/Type-Preserving-Coding-Adapter.git

// MARK: -
enum Sexe: Int, PickableEnum, Codable {
    case male
    case female
    
    var id: Int {
        return self.rawValue
    }
    var displayString: String {
        switch self {
            case .male:
                return "M."
            case .female:
                return "Mme"
        }
    }
    var pickerString: String {
        switch self {
            case .male:
                return "Homme"
            case .female:
                return "Femme"
        }
    }
}

// MARK: -
enum Seniority: Int, PickableEnum {
    case adult
    case enfant
    
    var id: Int {
        return self.rawValue
    }
    var displayString: String {
        switch self {
            case .adult:
                return "(adulte)"
            case .enfant:
                return "(enfant)"
        }
    }
    var pickerString: String {
        switch self {
            case .adult:
                return "Adulte"
            case .enfant:
                return "Enfant"
        }
    }
}

// MARK: -
class Person : ObservableObject, Identifiable, CustomStringConvertible, Codable {
    
    // MARK: - Nested types

    private enum CodingKeys : String, CodingKey {
        case sexe, name, birthDate, ageOfDeath
    }
    
    struct CoderPreservingType {
        let adapter = TypePreservingCodingAdapter()
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        init() {
            self.encoder.outputFormatting     = .prettyPrinted
            self.encoder.dateEncodingStrategy = .iso8601
            self.encoder.keyEncodingStrategy  = .useDefaultKeys
            
            self.decoder.dateDecodingStrategy = .iso8601
            self.decoder.keyDecodingStrategy  = .useDefaultKeys
            
            // inject it into encoder and decoder
            self.encoder.userInfo[.typePreservingAdapter] = self.adapter
            self.decoder.userInfo[.typePreservingAdapter] = self.adapter
            
            // register your types with adapter
            self.adapter
                .register(type: Person.self)
                .register(alias: "personne", for: Person.self)
                .register(type: Adult.self)
                .register(alias: "adult", for: Adult.self)
                .register(type: Child.self)
                .register(alias: "enfant", for: Child.self)
        }
    }
    
    // MARK: - Type properties
    
    static let coder = CoderPreservingType()
    
    // MARK: - Properties
    
    let id = UUID()
    let sexe                  : Sexe
    var name                  : PersonNameComponents
    var birthDate             : Date
    var birthDateComponents   : DateComponents
    @Published var ageOfDeath : Int
    var yearOfDeath           : Int { // computed
        birthDateComponents.year! + ageOfDeath
    }
    var ageComponents: DateComponents { // computed
        Date.calendar.dateComponents([.year, .month, .day], from: birthDateComponents, to: CalendarCst.nowComponents)
    }
    var ageAtEndOfCurrentYear: Int { // computed
        Date.calendar.dateComponents([.year], from: birthDateComponents, to: CalendarCst.endOfYearComp).year!
    }
    var displayName: String {
        let formatter = PersonNameComponentsFormatter()
        formatter.style = .long
        return formatter.string(from: name)
    }
    var displayBirthDate: String {
        mediumDateFormatter.string(from: birthDate)
    }
    var description: String {
        return """
        \(displayName)
        seniority: \(String(describing: type(of: self)))
        sexe:      \(sexe)
        birthdate: \(mediumDateFormatter.string(from: birthDate))
        age:       \(ageComponents.description)
        age of death:  \(ageOfDeath)
        year of death: \(yearOfDeath)
        
        """
    }
    
    // MARK: - Initialization

    // reads from JSON
    required init(from decoder: Decoder) throws {
        let container            = try decoder.container(keyedBy: CodingKeys.self)
        self.name                = try container.decode(PersonNameComponents.self, forKey: .name)
        self.sexe                = try container.decode(Sexe.self, forKey: .sexe)
        self.birthDate           = try container.decode(Date.self, forKey: .birthDate)
        self.ageOfDeath          = try container.decode(Int.self, forKey: .ageOfDeath)
        self.birthDateComponents = Date.calendar.dateComponents([.year, .month, .day], from : birthDate)
    }
    
    init(sexe: Sexe,
                givenName: String, familyName: String,
                yearOfBirth: Int, monthOfBirth: Int, dayOfBirth: Int,
                ageOfDeath: Int = CalendarCst.forever) {
        self.sexe                = sexe
        self.name                = PersonNameComponents()
        self.name.namePrefix     = sexe.displayString
        self.name.givenName      = givenName
        self.name.familyName     = familyName.localizedUppercase
        self.birthDateComponents = DateComponents(calendar: Date.calendar,
                                                  year: yearOfBirth, month: monthOfBirth, day: dayOfBirth)
        self.birthDate           = birthDateComponents.date!
        self.ageOfDeath          = ageOfDeath
    }
    
    init(sexe: Sexe,
                givenName: String, familyName: String,
                birthDate : Date,
                ageOfDeath : Int = CalendarCst.forever) {
        self.sexe                = sexe
        self.name                = PersonNameComponents()
        self.name.namePrefix     = sexe.displayString
        self.name.givenName      = givenName
        self.name.familyName     = familyName.localizedUppercase
        self.birthDate           = birthDate
        self.birthDateComponents = Date.calendar.dateComponents([.year, .month, .day], from : birthDate)
        self.ageOfDeath          = ageOfDeath
    }
    
    // MARK: - Methodes

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(sexe, forKey: .sexe)
        try container.encode(birthDate, forKey: .birthDate)
        try container.encode(ageOfDeath, forKey: .ageOfDeath)
    }
    
    func age(atEndOf year: Int) -> Int {
        ageAtEndOfCurrentYear + (year - CalendarCst.thisYear)
    }
    /// True si la personne est encore vivante à la fin de l'année donnée
    /// - Parameter year: année
    /// - Returns: True si la personne est encore vivante
    func isAlive(atEndOf year : Int) -> Bool {
        year < yearOfDeath
    }
    /// Année ou a lieu l'événement recherché
    /// - Parameter event: événement recherché
    /// - Returns: Année ou a lieu l'événement recherché, nil si l'événement n'existe pas
    func yearOf(event: LifeEvent) -> Int? {
        switch event {
            case .deces:
                return yearOfDeath
            default:
                return nil
        }
    }
    func print() {
        Swift.print("    ", displayName, ":")
        Swift.print("       birthdate:", mediumDateFormatter.string(from: birthDate))
        Swift.print("       age:", ageComponents)
        Swift.print("       age of death:", ageOfDeath)
        Swift.print("       year of death:", yearOfDeath)
    }
}

// MARK: Extensions
extension Person : Hashable {
    static func == (l: Person, r: Person) -> Bool { (l.id == r.id) }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

extension Person: Comparable {
    static func < (lhs: Person, rhs: Person) -> Bool {
        // trier par date de naissance croissante
        lhs.birthDate < rhs.birthDate
    }
}

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
                // TODO: - implémenter la date de dépence dans le modèle
                return nil
            
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

// MARK: -
final class Child: Person {
    
    // nested types
    
    private enum CodingKeys : String, CodingKey {
        case ageOfUniversity, ageOfIndependence
    }
    
    // properties
    
    @Published var ageOfUniversity: Int = 18
    var dateOfUniversity: Date { // computed
        dateOfUniversityComp.date!
    }
    var dateOfUniversityComp: DateComponents { // computed
        DateComponents(calendar: Date.calendar, year: birthDate.year + ageOfUniversity, month: 12, day: 31)
    }
    
    @Published var ageOfIndependence: Int = 24
    var dateOfIndependence: Date { // computed
        dateOfIndependenceComp.date!
    }
    var dateOfIndependenceComp: DateComponents { // computed
        DateComponents(calendar: Date.calendar, year: birthDate.year + ageOfIndependence, month: 12, day: 31)
    }
    
    override var description: String {
        return super.description +
        """
        age at university:  \(ageOfUniversity) ans
        date of university: \(mediumDateFormatter.string(from: dateOfUniversity))
        age of independance:  \(ageOfIndependence) ans
        date of independance: \(mediumDateFormatter.string(from: dateOfIndependence)) \n
        """
    }
    
    // initialization
    
    required init(from decoder: Decoder) throws {
        // Get our container for this subclass' coding keys
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ageOfUniversity = try container.decode(Int.self, forKey: .ageOfUniversity)
        ageOfIndependence = try container.decode(Int.self, forKey: .ageOfIndependence)
        
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
        try container.encode(ageOfUniversity, forKey: .ageOfUniversity)
        try container.encode(ageOfIndependence, forKey: .ageOfIndependence)
    }
    
    /// true si l'année est postérieure à l'année d'entrée à l'université et avant indépendance financière
    /// - Parameter year: année
    func isAtUniversity(during year: Int) -> Bool {
        (dateOfUniversityComp.year! < year) && !isIndependant(during: year)
    }
    /// true si l'année est postérieure à l'année d'indépendance financière
    /// - Parameter year: année
    func isIndependant(during year: Int) -> Bool {
        dateOfIndependenceComp.year! < year
    }
    /// Année ou a lieu l'événement recherché
    /// - Parameter event: événement recherché
    /// - Returns: Année ou a lieu l'événement recherché, nil si l'événement n'existe pas
    override func yearOf(event: LifeEvent) -> Int? {
        switch event {
            case .debutEtude:
                return dateOfUniversity.year
            
            case .independance:
                return dateOfIndependence.year
            
            case .dependence:
                return nil
            
            case .deces:
                return super.yearOf(event: event)
            
            case .cessationActivite:
                return nil
            
            case .liquidationPension:
                return nil
        }
    }
    
    override func print() {
        super.print()
        Swift.print("       age at university: ", ageOfUniversity,"years old")
        Swift.print("       date of university:", mediumDateFormatter.string(from: dateOfUniversity))
        Swift.print("       age of independance: ", ageOfIndependence,"years old")
        Swift.print("       date of independance:", mediumDateFormatter.string(from: dateOfIndependence))
    }
}
