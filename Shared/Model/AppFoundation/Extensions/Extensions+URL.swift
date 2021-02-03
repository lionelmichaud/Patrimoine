//
//  Extensions+URL.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Encodage JSON vers un fichier désigné par son URL

extension URL {
    func encode <T: Encodable> (_ object: T,
                                to file: String,
                                dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .deferredToDate,
                                keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .useDefaultKeys) {
        
        let encoder = JSONEncoder()
        encoder.outputFormatting     = .prettyPrinted
        encoder.dateEncodingStrategy = dateEncodingStrategy
        encoder.keyEncodingStrategy  = keyEncodingStrategy
        
        // encodage
        if let encoded = try? encoder.encode(object) {
            // impression debug
            if let jsonString = String(data: encoded, encoding: .utf8) {
                print(jsonString)
            } else {
                print("failed to convert to string")
            }
            // find file's URL
            let url = self.appendingPathComponent(file, isDirectory: false)
            #if DEBUG
            print("encoding to file: ", url)
            #endif
            // sauvegader les données
            do {
                try encoded.write(to: url, options: [.atomicWrite])
            } catch {
                fatalError("Failed to save data to '\(file)' in documents directory.")
            }
        } else {
            fatalError("Failed to encode object to JSON format.")
        }
    }
}

// MARK: - Déodage JSON vers un fichier désigné par son URL

extension URL {
    func decode <T: Decodable> (_ type: T.Type,
                                from file: String,
                                dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate,
                                keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) -> T {
        
        // find file's URL
        let url = self.appendingPathComponent(file, isDirectory: false)
        #if DEBUG
        print("decoding from file: ", url)
        #endif

        // load data from URL
        guard let data = try? Data(contentsOf: url) else {
            fatalError("Failed to load \(file) in documents directory.")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = dateDecodingStrategy
        decoder.keyDecodingStrategy = keyDecodingStrategy
        
        // decode JSON data
        do {
            return try decoder.decode(T.self, from: data)
        } catch DecodingError.keyNotFound(let key, let context) {
            fatalError("Failed to decode \(file) in documents directory due to missing key '\(key.stringValue)' not found – \(context.debugDescription)")
        } catch DecodingError.typeMismatch(_, let context) {
            fatalError("Failed to decode \(file) in documents directory due to type mismatch – \(context.debugDescription)")
        } catch DecodingError.valueNotFound(let type, let context) {
            fatalError("Failed to decode \(file) in documents directory due to missing \(type) value – \(context.debugDescription)")
        } catch DecodingError.dataCorrupted(let context) {
            fatalError("Failed to decode \(file) in documents directory because it appears to be invalid JSON – \(context.codingPath)–  \(context.debugDescription)")
        } catch {
            fatalError("Failed to decode \(file) in documents directory: \(error.localizedDescription)")
        }
    }
}
