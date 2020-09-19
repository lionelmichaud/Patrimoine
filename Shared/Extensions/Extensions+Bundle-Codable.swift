//
//  Extensions+Bundle-Codable.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import os

fileprivate let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Extensions.Bundle")

extension Bundle {
    func encode <T: Encodable> (_ object: T,
                                to file: String,
                                dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .deferredToDate,
                                keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .useDefaultKeys) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = dateEncodingStrategy
        encoder.keyEncodingStrategy = keyEncodingStrategy
        
        if let encoded = try? encoder.encode(object) {
            // find file's URL
            guard let url = self.url(forResource: file, withExtension: nil) else {
                customLog.log(level: .fault, "Failed to locate file '\(file)' in bundle.")
                fatalError("Failed to locate file '\(file)' in bundle.")
            }
            // impression debug
            #if DEBUG
            print("encoding to file: ", url)
            #endif
            if let jsonString = String(data: encoded, encoding: .utf8) {
                #if DEBUG
                print(jsonString)
                #endif
            } else {
                print("failed to convert \(String(describing: T.self)) object to string")
            }
            do {
                // sauvegader les données
                try encoded.write(to: url, options: [.atomicWrite])
            } catch {
                customLog.log(level: .fault, "Failed to save data to file '\(file)' in bundle.")
                fatalError("Failed to encode \(String(describing: T.self)) object to JSON format.")
            }
        } else {
            customLog.log(level: .fault, "Failed to save data to file '\(file)' in bundle.")
            fatalError("Failed to encode \(String(describing: T.self)) object to JSON format.")
        }
    }
}

extension Bundle {
    func decode <T: Decodable> (from file: String) -> T {
        // find file's URL
        guard let url = self.url(forResource: file, withExtension: nil) else {
            customLog.log(level: .fault, "Failed to locate \(file) in bundle.")
            fatalError("Failed to locate \(file) in bundle.")
        }
        // MARK: - DEBUG - A supprimer
        #if DEBUG
        print("decoding file: ", url)
        #endif
        
        // load data from URL
        guard let data = try? Data(contentsOf: url) else {
            customLog.log(level: .fault, "Failed to load \(file) data from bundle.")
            fatalError("Failed to load \(file) data from bundle.")
        }
        
        // decode JSON data
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "y-MM-dd"
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        guard let decoded = try? decoder.decode(T.self, from: data) else {
            customLog.log(level: .fault, "Failed to decode \(file) data from bundle.")
            fatalError("Failed to decode \(file) data from bundle.")
        }
        
        return decoded
    }
}

extension Bundle {
    func decode <T: Decodable> (_ type: T.Type,
                                from file: String,
                                dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate,
                                keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) -> T {
        // find file's URL
        guard let url = self.url(forResource: file, withExtension: nil) else {
            customLog.log(level: .fault, "Failed to locate file '\(file)' in bundle.")
            fatalError("Failed to locate file '\(file)' in bundle.")
        }
        // MARK: - DEBUG - A supprimer
        #if DEBUG
        print("decoding file: ", url)
        #endif
        
        // load data from URL
        guard let data = try? Data(contentsOf: url) else {
            customLog.log(level: .fault, "Failed to load file '\(file)' from bundle.")
            fatalError("Failed to load file '\(file)' from bundle.")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = dateDecodingStrategy
        decoder.keyDecodingStrategy = keyDecodingStrategy
        
        // decode JSON data
        do {
            return try decoder.decode(T.self, from: data)
        } catch DecodingError.keyNotFound(let key, let context) {
            customLog.log(level: .fault, "Failed to decode object of type '\(String(describing: T.self))' from file '\(file)' from bundle due to missing key '\(key.stringValue)' not found – \(context.debugDescription).")
            fatalError("Failed to decode object of type '\(String(describing: T.self))' from file '\(file)' from bundle due to missing key '\(key.stringValue)' not found – \(context.debugDescription)")
        } catch DecodingError.typeMismatch(_, let context) {
            customLog.log(level: .fault, "Failed to decode object of type '\(String(describing: T.self))' from file '\(file)' from bundle due to type mismatch – \(context.debugDescription)")
            fatalError("Failed to decode object of type '\(String(describing: T.self))' from file '\(file)' from bundle due to type mismatch – \(context.debugDescription)")
        } catch DecodingError.valueNotFound(let type, let context) {
            customLog.log(level: .fault, "Failed to decode object of type '\(String(describing: T.self))' from file '\(file)' from bundle due to missing \(type) value – \(context.debugDescription).")
            fatalError("Failed to decode object of type '\(String(describing: T.self))' from file '\(file)' from bundle due to missing \(type) value – \(context.debugDescription)")
        } catch DecodingError.dataCorrupted(let context) {
            customLog.log(level: .fault, "Failed to decode object of type '\(String(describing: T.self))' from file '\(file)' from bundle because it appears to be invalid JSON \n \(context.codingPath) \n \(context.debugDescription).")
            fatalError("Failed to decode object of type '\(String(describing: T.self))' from file '\(file)' from bundle because it appears to be invalid JSON \n \(context.codingPath) \n \(context.debugDescription)")
        } catch {
            customLog.log(level: .fault, "Failed to decode object of type '\(String(describing: T.self))' from file '\(file)' from bundle: \(error.localizedDescription).")
            fatalError("Failed to decode object of type '\(String(describing: T.self))' from file '\(file)' from bundle: \(error.localizedDescription)")
        }
    }
}
