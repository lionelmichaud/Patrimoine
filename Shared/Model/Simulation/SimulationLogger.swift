//
//  Logger.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 30/03/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

enum LogTopic: String, PickableEnum, Codable, CustomStringConvertible {
    case simulationEvent = "Simulation"
    case lifeEvent       = "Evénement de vie"
    case error           = "Erreur"
    case other           = "Autre"

    // MARK: - Computed Properties
    
    var pickerString: String {
        return self.rawValue
    }
    
    var description: String {
        pickerString
    }
    
}

/// The Singleton class defines the `shared` field that lets clients access the
/// unique singleton instance.
class SimulationLogger {
    static var activ = true

    /// The static field that controls the access to the singleton instance.
    ///
    /// This implementation let you extend the Singleton class while keeping
    /// just one instance of each subclass around.
    static var shared: SimulationLogger = {
        let instance = SimulationLogger()
        // ... configure the instance
        // ...
        return instance
    }()
    
    /// The Singleton's initializer should always be private to prevent direct
    /// construction calls with the `new` operator.
    private init() {}
    
    /// Finally, any singleton should define some business logic, which can be
    /// executed on its instance.
    func log(run      : Int = 0,
             logTopic : LogTopic,
             message  : String) {
        guard SimulationLogger.activ else { return }
        print("Run: \(run) | \(logTopic.description) | \(message)")
    }
}

/// Singletons should not be cloneable.
extension SimulationLogger: NSCopying {
    
    func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
}
