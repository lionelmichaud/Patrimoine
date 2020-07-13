//
//  Child.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 23/06/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

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
        DateComponents(calendar: Date.calendar, year: birthDate.year + ageOfUniversity, month: 09, day: 30)
    }
    
    @Published var ageOfIndependence: Int = 24
    var dateOfIndependence: Date { // computed
        dateOfIndependenceComp.date!
    }
    var dateOfIndependenceComp: DateComponents { // computed
        DateComponents(calendar: Date.calendar, year: birthDate.year + ageOfIndependence, month: 09, day: 30)
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
