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
    
    init(Xmin     : Double,
         Xmax     : Double) {
        self.Xmin = Xmin
        self.Xmed = (Xmax - Xmin) / 2
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
    var xCounts : [(x: Double, n: Int)] {
        guard bucketNb > 0 else {
            return []
        }
        var values = [(x: Double, n: Int)]()
        for i in 0..<bucketNb {
            values.append((x: xValues[i],
                           n: buckets[i].sampleNb))
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
        // Il faudra utiliser la fonction "reset" pour ca.
    }
    
    init(Xmin     : Double = 0.0,
         Xmax     : Double,
         bucketNb : Int) {
        guard bucketNb >= 1 else {
            return
        }
        self.Xmin = Xmin
        self.Xmax = Xmax
        
        // créer les cases
        self.bucketNb = bucketNb
        let nbClosedBucket = bucketNb - 1
        
        for i in 0..<nbClosedBucket {
            buckets.append(Bucket(Xmin: Xmin + i.double() * (Xmax - Xmin) / nbClosedBucket.double(),
                                  Xmax: Xmin + (i.double() + 1) * (Xmax - Xmin) / nbClosedBucket.double()))
            xValues[i] = buckets[i].Xmed
        }
        // the last bucket is an open end bucket
        buckets.append(Bucket(Xmin: Xmax,
                              Xmax: Double.infinity))
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
    
    mutating func set(Xmin     : Double? = nil,
                      Xmax     : Double? = nil,
                      bucketNb : Int) {
        guard !dataset.isEmpty else {
            return
        }
        guard bucketNb >= 1 else {
            return
        }
        self.Xmin = Xmin ?? self.min!
        self.Xmax = Xmin ?? self.max!

        // créer les cases
        self.bucketNb = bucketNb
        let nbClosedBucket = bucketNb - 1
        
        for i in 0..<nbClosedBucket {
            buckets.append(Bucket(Xmin: self.Xmin + i.double() * (self.Xmax - self.Xmin) / nbClosedBucket.double(),
                                  Xmax: self.Xmin + (i.double() + 1) * (self.Xmax - self.Xmin) / nbClosedBucket.double()))
            xValues[i] = buckets[i].Xmed
        }
        // the last bucket is an open end bucket
        buckets.append(Bucket(Xmin: self.Xmax,
                              Xmax: Double.infinity))

        // ranger les échantillons dans une case
        for data in dataset {
            if let idx = buckets.firstIndex(where: { $0.Xmin > data }) {
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
        if let idx = buckets.firstIndex(where: { $0.Xmin > data }) {
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
