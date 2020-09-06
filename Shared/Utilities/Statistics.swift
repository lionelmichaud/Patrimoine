//
//  Statistics.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 05/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

struct Bucket {
    let Xmin     : Double
    let Xmed     : Double
    let Xmax     : Double
    var sampleNb : Int = 0
    
    init(Xmin     : Double,
         Xmax     : Double) {
        self.Xmin = Xmin
        self.Xmed = (Xmax - Xmin) / 2
        self.Xmax = Xmax
    }

    mutating func record(_ data: Double) {
        sampleNb += 1
    }
}

struct Histogram {
    var dataset  = [Double]()
    let Xmin     : Double
    let Xmax     : Double
    var Ymin     : Double = Double.infinity
    var Ymax     : Double = -Double.infinity
    var sampleNb : Int = 0
    var bucketNb : Int = 0
    var buckets  = [Bucket]()
    var xValues    = [Double]()
    var yValues    : [Int] {
        buckets.map { $0.sampleNb }
    }
    var values: [(x: Double, y: Int)] {
        var values = [(x: Double, y: Int)]()
        for i in 0..<bucketNb {
            values.append((x: xValues[i], y: buckets[i].sampleNb))
        }
        return values
    }
    
    init(Xmin     : Double = 0.0,
         Xmax     : Double,
         bucketNb : Int) {
        self.Xmin = Xmin
        self.Xmax = Xmax
        guard bucketNb >= 1 else {
            return
        }
        self.bucketNb = bucketNb
        
        for i in 0..<bucketNb {
            buckets.append(Bucket(Xmin: Xmin + i.double() * (Xmax - Xmin) / bucketNb.double(),
                                  Xmax: Xmin + (i.double() + 1) * (Xmax - Xmin) / bucketNb.double()))
            xValues[i] = buckets[i].Xmed
        }
    }
    
    subscript(idx: Int) -> Int {
        get {
            return buckets[idx].sampleNb
        }
    }
    
    mutating func record(_ data: Double) {
        if let idx = buckets.firstIndex(where: { $0.Xmin > data }) {
            Ymin = min(Ymin, data)
            Ymax = min(Ymax, data)
            sampleNb += 1
            buckets[idx].record(data)
        }
    }
}
