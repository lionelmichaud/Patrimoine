//
//  BundleCodable.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 15/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Protocol apportant Codable JSON à partir d'un fichier d'un Bundle de l'application

protocol BundleCodable: Codable {
    
    static var defaultFileName : String { get set }
    
    /// Lit le modèle dans un fichier JSON du Bundle Main
    init()
    init(from file: String)
    init(from file            : String,
         dateDecodingStrategy : JSONDecoder.DateDecodingStrategy,
         keyDecodingStrategy  : JSONDecoder.KeyDecodingStrategy)
    
    /// Encode l'objet dans un fichier stocké dans le Bundle de contenant la définition de la classe aClass
    init(for aClass           : AnyClass,
         from file            : String,
         dateDecodingStrategy : JSONDecoder.DateDecodingStrategy,
         keyDecodingStrategy  : JSONDecoder.KeyDecodingStrategy)
    
    /// Encode l'objet dans un fichier stocké dans le Bundle Main de l'Application
    func saveToBundle()
    func saveToBundle(to file: String)
    func saveToBundle(to file              : String,
                      dateEncodingStrategy : JSONEncoder.DateEncodingStrategy,
                      keyEncodingStrategy  : JSONEncoder.KeyEncodingStrategy)

    /// Encode l'objet dans un fichier stocké dans le Bundle de contenant la définition de la classe aClass
    func saveToBundle(for aClass           : AnyClass,
                      to file              : String,
                      dateEncodingStrategy : JSONEncoder.DateEncodingStrategy,
                      keyEncodingStrategy  : JSONEncoder.KeyEncodingStrategy)
}

extension BundleCodable {
    init() {
        self = Bundle.main.decode(Self.self,
                                  from                 : Self.defaultFileName,
                                  dateDecodingStrategy : .iso8601,
                                  keyDecodingStrategy  : .useDefaultKeys)
    }
    init(from file: String) {
        self = Bundle.main.decode(Self.self,
                                  from                 : file,
                                  dateDecodingStrategy : .iso8601,
                                  keyDecodingStrategy  : .useDefaultKeys)
    }
    
    init(from file            : String,
         dateDecodingStrategy : JSONDecoder.DateDecodingStrategy,
         keyDecodingStrategy  : JSONDecoder.KeyDecodingStrategy) {
        self = Bundle.main.decode(Self.self,
                                  from                 : file,
                                  dateDecodingStrategy : dateDecodingStrategy,
                                  keyDecodingStrategy  : keyDecodingStrategy)
    }
    
    init(for aClass           : AnyClass,
         from file            : String,
         dateDecodingStrategy : JSONDecoder.DateDecodingStrategy,
         keyDecodingStrategy  : JSONDecoder.KeyDecodingStrategy) {
        let testBundle = Bundle(for: aClass)
        self = testBundle.decode(Self.self,
                                 from                 : file,
                                 dateDecodingStrategy : dateDecodingStrategy,
                                 keyDecodingStrategy  : keyDecodingStrategy)
    }
    
    func saveToBundle() {
        Bundle.main.encode(self,
                           to                   : Self.defaultFileName,
                           dateEncodingStrategy : .iso8601,
                           keyEncodingStrategy  : .useDefaultKeys)
    }
    
    func saveToBundle(to file: String) {
        Bundle.main.encode(self,
                           to                   : file,
                           dateEncodingStrategy : .iso8601,
                           keyEncodingStrategy  : .useDefaultKeys)
    }
    
    func saveToBundle(to file              : String,
                      dateEncodingStrategy : JSONEncoder.DateEncodingStrategy,
                      keyEncodingStrategy  : JSONEncoder.KeyEncodingStrategy) {
        Bundle.main.encode(self,
                           to                   : file,
                           dateEncodingStrategy : dateEncodingStrategy,
                           keyEncodingStrategy  : keyEncodingStrategy)
    }
    
    func saveToBundle(for aClass           : AnyClass,
                      to file              : String,
                      dateEncodingStrategy : JSONEncoder.DateEncodingStrategy,
                      keyEncodingStrategy  : JSONEncoder.KeyEncodingStrategy) {
        let testBundle = Bundle(for: aClass)
        testBundle.encode(self,
                          to                   : file,
                          dateEncodingStrategy : dateEncodingStrategy,
                          keyEncodingStrategy  : keyEncodingStrategy)
    }
}
