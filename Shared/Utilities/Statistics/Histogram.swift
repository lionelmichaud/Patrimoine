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
    private var buckets  = [Bucket]()
    // largeur en X d'une case
    private var Xstep: Double = 0.0
    // valeure minimum pour qu'un échantillon soit rangé dans une case
    var Xmin     : Double = 0.0
    // valeure maximum pour qu'un échantillon soit rangé dans une case
    var Xmax     : Double = 0.0
    // valeures centrales des cases
    var xValues  = [Double]()
    var isInitialized: Bool {
        buckets.count != 0
    } // computed
    private var Xrange: Double {
        Xmax - Xmin
    } // computed
    private var bucketNb: Int {
        buckets.count
    } // computed
    // nombre d'échantillons par case
    var counts: [Int] {
        precondition(isInitialized , "Histogram.counts: histogramme non initialisé")
        return buckets.map { $0.sampleNb }
    } // computed
    // nombre d'échantillons cumulés de la première case à la case courante
    var cumulatedCounts: [Int] {
        precondition(isInitialized , "Histogram.cumulatedCounts: histogramme non initialisé")
        var result = [Int]()
        let bucketsCounts = self.counts
        for idx in bucketsCounts.indices {
            var sum = 0
            for i in 0...idx {
                sum += bucketsCounts[i]
            }
            result.append(sum)
        }
        return result
    } // computed
    // nombre d'échantillons cumulés de la première case à la case courante
    var xCumulatedCounts : [(x: Double, n: Int)] {
        precondition(isInitialized , "Histogram.xCumulatedCounts: histogramme non initialisé")
        let yCumulatedValues = self.cumulatedCounts
        var values = [(x: Double, n: Int)]()
        for i in yCumulatedValues.indices {
            values.append((x: xValues[i], n: yCumulatedValues[i]))
        }
        return values
    } // computed
    // densités de probabilité
    var PDF: [Double] { // en %
        precondition(isInitialized , "Histogram.PDF: histogramme non initialisé")
        let normalizer = dataset.count.double() * Xrange / buckets.count.double()
        return buckets.map { $0.sampleNb.double() / normalizer }
    } // computed
    // densités de probabilité
    var xPDF: [(x: Double, p: Double)] {
        precondition(isInitialized , "Histogram.xPDF: histogramme non initialisé")
        let pdf    = PDF
        var values = [(x : Double, p : Double)]()
        for i in pdf.indices {
            values.append((x: xValues[i],
                           p: pdf[i]))
        }
        return values
    } // computed
    // densités de probabilité cumulées
    var CDF: [Double] {
        precondition(isInitialized , "Histogram.CDF: histogramme non initialisé")
        var result          = [Double]()
        let cumulatedCounts = self.cumulatedCounts
        let normalizer      = dataset.count.double()
        for idx in cumulatedCounts.indices {
            result.append(cumulatedCounts[idx].double() / normalizer)
        }
        return result
    } // computed
    // densités de probabilité cumulées
    var xCDF: [(x: Double, p: Double)] {
        precondition(isInitialized , "Histogram.xCDF: histogramme non initialisé")
        let cdf = self.CDF
        var values = [(x: Double, p: Double)]()
        for i in cdf.indices {
            values.append((x: xValues[i],
                           p: cdf[i]))
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
        initializeBuckets(openEnds : openEnds,
                          Xmin     : Xmin,
                          Xmax     : Xmax,
                          bucketNb : bucketNb)
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
    
    /// Initilize les propriétés internes de l'objet
    /// - Parameters:
    ///   - openEnds: true si le domaine de X sétend à l'infini
    ///   - Xmin: valeure minimale du domaine de X
    ///   - Xmax: valeure maximale du domaine de X
    ///   - bucketNb: nombre de cases fermées sur le doamine de X
    /// - Warning: bucketNb ne doit as iclure des 2 case s'étendant à l'inifini si openEnds = true
    mutating func initializeBuckets(openEnds : Bool = true,
                                    Xmin     : Double,
                                    Xmax     : Double,
                                    bucketNb : Int) {
        precondition(bucketNb >= 1 , "Histogram.init: Pas de case dans l'histogramme pour ranger les échantillons")
        precondition(Xmax > Xmin , "Histogram.init: Xmax <= Xmin")
        self.Xmin = Xmin
        self.Xmax = Xmax

        // créer les cases
        self.Xstep = (Xmax - Xmin) / bucketNb.double()
        
        if openEnds {
            // créer une première case sétendant à l'infini
            buckets.append(Bucket(Xmin: -Double.infinity,
                                  Xmax: self.Xmin,
                                  step: self.Xstep / 2))
            xValues.append(buckets.last!.Xmed)
        }
        // créer les cases fermées
        for i in 0..<bucketNb {
            buckets.append(Bucket(Xmin: self.Xmin + i.double() * self.Xstep,
                                  Xmax: self.Xmin + (i.double() + 1) * self.Xstep))
            xValues.append(buckets.last!.Xmed)
        }
        if openEnds {
            // créer une dernère case sétendant à l'infini
            buckets.append(Bucket(Xmin: self.Xmax,
                                  Xmax: Double.infinity,
                                  step: self.Xstep / 2))
            xValues.append(buckets.last!.Xmed)
        }
    }
    
    /// Initialise les cases de l'histogramme et range les échantillons dans les cases
    /// - Parameters:
    ///   - openEnds:true si les premières et derniers case s'étendent à l'infini
    ///   - Xmin: borne inf
    ///   - Xmax: borne sup
    ///   - bucketNb: nombre de cases (incluant les éventuelles cases s'étendant à l'infini)
    mutating func sort(openEnds : Bool = true,
                       Xmin     : Double? = nil,
                       Xmax     : Double? = nil,
                       bucketNb : Int) {
        guard !dataset.isEmpty else {
            // pas d'échantillons à traiter
            return
        }
        let computedXmin = Xmin ?? self.min! // minimum de tous les échantillons
        let computedXmax = Xmax ?? self.max!
        
        buckets = [Bucket]()
        xValues = [Double]()
        initializeBuckets(openEnds : openEnds,
                          Xmin     : computedXmin,
                          Xmax     : computedXmax,
                          bucketNb : bucketNb)
        
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
    }
}
