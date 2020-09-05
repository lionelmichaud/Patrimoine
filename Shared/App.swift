/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 The single entry point for the Patrimoine app on iOS and macOS.
 */

import SwiftUI

@main
struct FrutaApp: App {
    
    // MARK: - Properties
    
    /// data model object that you want to use throughout your app and that will be shared among the scenes
    @StateObject private var family     = Family()
    @StateObject private var patrimoine = Patrimoin()
    @StateObject private var simulation = Simulation()
    
    var body: some Scene {
        MainScene(family     : family,
                  patrimoine : patrimoine,
                  simulation : simulation)
    }
}
