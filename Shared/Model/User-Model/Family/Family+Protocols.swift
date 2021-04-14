//
//  Family+Protocols.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 13/04/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - DI: Protocol de service de fourniture de l'age d'une personne

protocol PersonAgeProvider {
    func ageOf(_ name: String, _ year: Int) -> Int
}

// MARK: - DI: Protocol de service de fourniture de l'année d'un événement de vie d'une personne

protocol PersonEventYearProvider {
    func yearOf(lifeEvent : LifeEvent,
                for name  : String) -> Int?
    func yearOf(lifeEvent : LifeEvent,
                for group : GroupOfPersons,
                order     : SoonestLatest) -> Int?
}

// MARK: - DI: Protocol de service de fourniture de dénombrement dans la famille

protocol MembersCountProvider {
    var nbOfChildren: Int { get }
    func nbOfAdultAlive(atEndOf year: Int) -> Int
    func nbOfFiscalChildren(during year: Int) -> Int
}

// MARK: - DI: Protocol de service de fourniture de l'époux d'un adulte

protocol AdultSpouseProvider {
    func spouseOf(_ member: Adult) -> Adult?
}

// MARK: - DI: Protocol de service de fourniture de la liste des noms des membres de la famille

protocol MembersNameProvider {
    var membersName  : [String] { get }
    var adultsName   : [String] { get }
    var childrenName : [String] { get }
}

typealias AdultRelativesProvider = MembersCountProvider & AdultSpouseProvider

// MARK: - DI: Protocol de service d'itération sur les membres du foyer fiscal dans la famille

protocol FiscalHouseholdSumator {
    func sum(atEndOf year : Int,
             memberValue  : (String) -> Double) -> Double
}
