//
//  Statistics.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 05/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import SigmaSwiftStatistics

// MARK: - Bucket

struct Bucket {
    
    // MARK: - Properties
    
    let Xmin     : Double // limite inférieure de la case
    let Xmed     : Double // milieu de la case
    let Xmax     : Double // limite supérieure de la case
    var sampleNb : Int = 0 // nombre d'échantillonsdans la case
    
    // MARK: - Initializer
    
    init(Xmin : Double,
         Xmax : Double,
         step : Double? = nil) {
        self.Xmin = Xmin
        if Xmin == -Double.infinity {
            self.Xmed = step != nil ? Xmax - step! : Xmax
        } else if Xmax == Double.infinity {
            self.Xmed = step != nil ? Xmin + step! : Xmin
        } else {
            self.Xmed = (Xmax + Xmin) / 2
        }
        self.Xmax = Xmax
    }
    
    // MARK: - Methods
    
    mutating func record() {
        // incrémente le nombre d'échantillons dans la case
        sampleNb += 1
    }
}

// MARK: - Histogram

struct Histogram {
    
    // MARK: - Properties
    
    // tableau de tous les échantillons reçus
    private var dataset  = [Double]()
    // cases pour compter les échantillons dans chaque case
    private var bucketNb : Int = 0
    // les cases
    private var buckets  = [Bucket]()
    // valeure minimum pour qu'un échantillon soit rangé dans une case
    var Xmin     : Double = 0.0
    // valeure maximum pour qu'un échantillon soit rangé dans une case
    var Xmax     : Double = 0.0
    // valeures centrales des cases
    var xValues  = [Double]()
    // nombre d'échantillons par case
    var counts  : [Int] {
        buckets.map { $0.sampleNb }
    } // computed
    var countsNormalized  : [Int] {
        let count = dataset.count
        return buckets.map { $0.sampleNb / count }
    } // computed
    var xCountsNormalized : [(x: Double, n: Int)] {
        guard bucketNb > 0 else {
            return []
        }
        var values = [(x: Double, n: Int)]()
        let count = dataset.count
        for i in 0..<bucketNb {
            values.append((x: xValues[i],
                           n: buckets[i].sampleNb / count))
        }
        return values
    } // computed
    // nombre d'échantillons cumulés dela première case à la case courante
    var cumulatedCounts  : [Int] {
        guard bucketNb > 0 else {
            return []
        }
        var result = [Int]()
        let yValues = self.counts
        for idx in 0..<yValues.count {
            var sum = 0
            for i in 0...idx {
                sum += yValues[i]
            }
            result.append(sum)
        }
        return result
    } // computed
    var xCumulatedCounts : [(x: Double, n: Int)] {
        guard bucketNb > 0 else {
            return []
        }
        let yCumulatedValues = self.cumulatedCounts
        var values = [(x: Double, n: Int)]()
        for i in 0..<bucketNb {
            values.append((x: xValues[i], n: yCumulatedValues[i]))
        }
        return values
    } // computed
    var cumulatedProbability  : [Double] {
        guard bucketNb > 0 else {
            return []
        }
        var result          = [Double]()
        let cumulatedCounts = self.cumulatedCounts
        for idx in 0..<cumulatedCounts.count {
            result.append(cumulatedCounts[idx].double() / dataset.count.double())
        }
        return result
    } // computed
    var xCumulatedProbability : [(x: Double, p: Double)] {
        guard bucketNb > 0 else {
            return []
        }
        let cumulatedProbability = self.cumulatedProbability
        var values = [(x: Double, p: Double)]()
        for i in 0..<bucketNb {
            values.append((x: xValues[i],
                           p: cumulatedProbability[i]))
        }
        return values
    } // computed
    // minimum de tous les échantillons
    var min: Double? {
        Sigma.min(dataset)
    } // computed
    // maximum de tous les échantillons
    var max: Double? {
        Sigma.max(dataset)
    } // computed
    // moyenne de tous les échantillons
    var average: Double? {
        Sigma.average(dataset)
    } // computed
    // médiane de tous les échantillons
    var median: Double? {
        Sigma.median(dataset)
    } // computed
    
    // MARK: - Initializer
    
    init() {
        // Les échantillons seront mémorisés mais pas rangés
        // car les cases ne seront pas initialisées.
        // Il faudra utiliser la fonction "set" pour pour ranger les échantillons après les avoir ajoutés.
    }
    
    /// Initialise les cases de l'histogramme
    /// - Parameters:
    ///   - openEnds:true si les premières et derniers case s'étendent à l'infini
    ///   - Xmin: borne inf
    ///   - Xmax: borne sup
    ///   - bucketNb: nombre de cases (incluant les éventuelles cases s'étendant à l'infini)
    init(openEnds : Bool = true,
         Xmin     : Double,
         Xmax     : Double,
         bucketNb : Int) {
        initializeBuckets(openEnds: openEnds, Xmin: Xmin, Xmax: Xmax, bucketNb: bucketNb)
    }
    
    // MARK: - Subscript
    
    /// nombre d'échantillons dans la case idx
    subscript(idx: Int) -> Int? {
        get {
            guard (0...buckets.count).contains(idx) else {
                return nil
            }
            return buckets[idx].sampleNb
        }
    }
    
    // MARK: - Methods
    
    mutating func initializeBuckets(openEnds : Bool = true,
                                    Xmin     : Double,
                                    Xmax     : Double,
                                    bucketNb : Int) {
        guard bucketNb >= 1 else {
            fatalError("Histogram.init: Pas de case dans l'histogramme pour ranger les échantillons")
        }
        self.Xmin = Xmin
        self.Xmax = Xmax
        
        // créer les cases
        self.bucketNb = bucketNb
        let lastClosedBucketIdx  = openEnds ? bucketNb - 2 : bucketNb - 1
        let nbClosedBucket       = openEnds ? bucketNb - 2 : bucketNb
        let step = (self.Xmax - self.Xmin) / nbClosedBucket.double()
        
        if openEnds {
            // créer une première case sétendant à l'infini
            buckets.append(Bucket(Xmin: -Double.infinity,
                                  Xmax: self.Xmin,
                                  step: step / 2))
            xValues.append(buckets[0].Xmed)
        }
        // créer les cases fermées
        for i in 0..<nbClosedBucket {
            buckets.append(Bucket(Xmin: self.Xmin + i.double() * step,
                                  Xmax: self.Xmin + (i.double() + 1) * step))
            xValues.append(buckets[openEnds ? i+1 : i].Xmed)
        }
        if openEnds {
            // créer une dernère case sétendant à l'infini
            buckets.append(Bucket(Xmin: self.Xmax,
                                  Xmax: Double.infinity,
                                  step: step / 2))
            xValues.append(buckets[lastClosedBucketIdx].Xmed)
        }
    }
    
    mutating func set(openEnds : Bool = true,
                      Xmin     : Double? = nil,
                      Xmax     : Double? = nil,
                      bucketNb : Int) {
        guard !dataset.isEmpty else {
            // pas d'échantillons à traiter
            return
        }
        guard bucketNb >= 1 else {
            fatalError("Pas de case dans l'histogramme pour ranger les échantillons")
        }
        let computedXmin = Xmin ?? self.min! // minimum de tous les échantillons
        let computedXmax = Xmax ?? self.max!
        
        initializeBuckets(openEnds: openEnds,
                          Xmin: computedXmin,
                          Xmax: computedXmax,
                          bucketNb: bucketNb)
        
        // ranger les échantillons dans une case
        for data in dataset {
            if let idx = buckets.firstIndex(where: { data < $0.Xmax }) {
                // incrémente le nombre d'échantillons dans la case
                buckets[idx].record()
            }
        }
    }
    
    /// Ajoute un échantillon à l'histogramme
    /// - Parameter data: échantillon
    mutating func record(_ data: Double) {
        // ajoute la valeur au dataset
        dataset.append(data)
        
        // ranger l'échantillon dans une case
        if let idx = buckets.firstIndex(where: { data < $0.Xmax }) {
            // incrémente le nombre d'échantillons dans la case
            buckets[idx].record()
        }
    }
    
    /// Renvoie la borne supérieure de la case (X) telle que P(X) >= probability
    /// - Parameter probability: probabilité
    /// - Returns: borne supérieure de la case (X) telle que P(X) >= probability
    /// - Warning: probability in [0, 1]
    func percentile(probability: Double) -> Double? {
        Sigma.percentile(dataset, percentile: probability)
        
        //        guard (0.0 ... 1.0).contains(probability) else {
        //            return nil
        //        }
        //        let sortedData = dataset.sorted(by: <)
        //        let idx = (probability * sortedData.count.double()).rounded(.down)
        //        return sortedData[Int(idx)]
        
        //        if let idx = cumulatedProbability.firstIndex(where: { $0 >= probability }) {
        //            return buckets[idx].Xmax
        //        } else {
        //            return nil
        //        }
    }
}
