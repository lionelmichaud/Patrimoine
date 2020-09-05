//
//  MainScene.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 03/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

/// Defines the main scene of the App
struct MainScene: Scene {
    
    // MARK: - Environment Properties

    @Environment(\.scenePhase) var scenePhase
    
    // MARK: - Properties

    @ObservedObject var family     : Family
    @ObservedObject var patrimoine : Patrimoin
    @ObservedObject var simulation : Simulation
    
    /// object that you want to use throughout your views and that will be specific to each scene
    @StateObject private var uiState = UIState()

    var body: some Scene {
        WindowGroup {
            /// defines the views hierachy of the scene
            ContentView()
                .environmentObject(uiState)
                .environmentObject(family)
                .environmentObject(patrimoine)
                .environmentObject(simulation)
        }
        .onChange(of: scenePhase) { scenePhase in
            switch scenePhase {
                case .active:
                    ()
                case .background:
                    ()
                default:
                    break
            }
        }
    }
}
