//
//  FileUtilities.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

/// URL du dossier Document de l'App
/// - Returns: URL du dossier Document de l'App
func getDocumentsDirectory() -> URL? {
    do {
        let possibleURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return possibleURL
    } catch let error {
        print("ERROR: \(error.localizedDescription)")
        return nil
    }}

/// URL du dossier 'Application Support' de l'App. Si le dossier n'existe pas, le créer. Si la création échoue alors fataError.
/// - Returns: URL du dossier 'Application Support' de l'App
func getAppSupportDirectory() -> URL {
    // find all possible application support directories for this user
    guard let appSupportDirectory = FileManager.default.urls(for : .applicationSupportDirectory, in  : .userDomainMask).first else {
        // le dossier 'Application Support' n'existe pas -> le créer
        do {
            // créer le dossier 'Application Support'
            try FileManager.default.createDirectory(atPath                      : "Library/Application Support",
                                                    withIntermediateDirectories : false,
                                                    attributes                  : nil)
        } catch {
            // la création du dossier 'Application Support' a échouée
            print("Error while creating directory at path 'Library/Application Support' :")
            print(error)
            fatalError()
        }
        // la création du dossier 'Application Support' a réussie
        guard let appSupportDirectory = FileManager.default.urls(for : .applicationSupportDirectory, in  : .userDomainMask).first else {
            print("La recherche de 'Library/Application Support' a échouée")
            fatalError()
        }
        return appSupportDirectory
    }
    
    // le dossier 'Application Support' existe bien
    return appSupportDirectory
}

/// Vérifie l'existence d'une directory. si elle n'existe pas, la créer
/// - Parameter path: chemin de la directory
func checkIfExistOrCreateDirectory(at path: String) {
    let fm = FileManager.default
    if !fm.fileExists(atPath: path) {
        do {
            try fm.createDirectory(atPath                      : path,
                                   withIntermediateDirectories : false,
                                   attributes                  : nil)
        } catch {
            print("Error while creating directory at path '\(path)' : ")
            print(error)
        }
    }
}

/// Vérifie l'existence d'une directory. si elle n'existe pas, la créer
/// - Parameter url: URL de la directory
func checkIfExistOrCreateDirectory(at url: URL) {
    let fm = FileManager.default
    if !fm.fileExists(atPath: url.absoluteString) {
        do {
            try fm.createDirectory(at                          : url,
                                   withIntermediateDirectories : false,
                                   attributes                  : nil)
        } catch {
            print("Error while creating directory at path '\(url.absoluteString)' :")
            print(error)
        }
    }
}
