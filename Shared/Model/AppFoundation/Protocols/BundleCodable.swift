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
    init(from file            : String?,
         dateDecodingStrategy : JSONDecoder.DateDecodingStrategy,
         keyDecodingStrategy  : JSONDecoder.KeyDecodingStrategy)
    
    /// Lit l'objet depuis un fichier stocké dans le Bundle de contenant la définition de la classe aClass
    init(for aClass           : AnyClass,
         from file            : String?,
         dateDecodingStrategy : JSONDecoder.DateDecodingStrategy,
         keyDecodingStrategy  : JSONDecoder.KeyDecodingStrategy)
    
    /// Encode l'objet dans un fichier stocké dans le Bundle Main de l'Application
    func saveToBundle(to file              : String?,
                      dateEncodingStrategy : JSONEncoder.DateEncodingStrategy,
                      keyEncodingStrategy  : JSONEncoder.KeyEncodingStrategy)

    /// Encode l'objet dans un fichier stocké dans le Bundle de contenant la définition de la classe aClass
    func saveToBundle(for aClass           : AnyClass,
                      to file              : String?,
                      dateEncodingStrategy : JSONEncoder.DateEncodingStrategy,
                      keyEncodingStrategy  : JSONEncoder.KeyEncodingStrategy)
}

extension BundleCodable {
    init(from file            : String? = nil,
         dateDecodingStrategy : JSONDecoder.DateDecodingStrategy = .iso8601,
         keyDecodingStrategy  : JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) {
        self = Bundle.main.decode(Self.self,
                                  from                 : file ?? Self.defaultFileName,
                                  dateDecodingStrategy : dateDecodingStrategy,
                                  keyDecodingStrategy  : keyDecodingStrategy)
    }
    
    init(for aClass           : AnyClass,
         from file            : String? = nil,
         dateDecodingStrategy : JSONDecoder.DateDecodingStrategy = .iso8601,
         keyDecodingStrategy  : JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) {
        let bundle = Bundle(for: aClass)
        self = bundle.decode(Self.self,
                                 from                 : file ?? Self.defaultFileName,
                                 dateDecodingStrategy : dateDecodingStrategy,
                                 keyDecodingStrategy  : keyDecodingStrategy)
    }
    
    func saveToBundle(to file              : String? = nil,
                      dateEncodingStrategy : JSONEncoder.DateEncodingStrategy = .iso8601,
                      keyEncodingStrategy  : JSONEncoder.KeyEncodingStrategy = .useDefaultKeys) {
        Bundle.main.encode(self,
                           to                   : file ?? Self.defaultFileName,
                           dateEncodingStrategy : dateEncodingStrategy,
                           keyEncodingStrategy  : keyEncodingStrategy)
    }
    
    func saveToBundle(for aClass           : AnyClass,
                      to file              : String? = nil,
                      dateEncodingStrategy : JSONEncoder.DateEncodingStrategy = .iso8601,
                      keyEncodingStrategy  : JSONEncoder.KeyEncodingStrategy = .useDefaultKeys) {
        let bundle = Bundle(for: aClass)
        bundle.encode(self,
                          to                   : file ?? Self.defaultFileName,
                          dateEncodingStrategy : dateEncodingStrategy,
                          keyEncodingStrategy  : keyEncodingStrategy)
    }
}
