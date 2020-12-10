//
//  CSV-Utilities.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

func createCSVX(from recArray:[[String: AnyObject]]) {
    // No need for string interpolation ("\("Time"),\("Force")\n"), just say what you want:
    let heading = "Time, Force\n"
    
    // For every element in recArray, extract the values associated with 'T' and 'F' as a comma-separated string.
    // Force-unwrap (the '!') to get a concrete value (or crash) rather than an optional
    let rows = recArray.map { "\($0["T"]!),\($0["F"]!)" }
    
    // Turn all of the rows into one big string
    let csvString = heading + rows.joined(separator: "\n")
    
    do {
        let path = try FileManager.default.url(for: .documentDirectory,
                                               in: .userDomainMask,
                                               appropriateFor: nil,
                                               create: false)
        
        let fileURL = path.appendingPathComponent("TrailTime.csv")
        try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
    } catch {
        print("error creating file")
    }
}
