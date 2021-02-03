//
//  Statistics.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 05/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import SigmaSwiftStatistics

enum DistributionType: String, Codable {
    case continuous = "Continue"
    case discrete   = "Discrète"
}

// MARK: - Bucket

struct Bucket: Codable {
    
    // MARK: - Properties
    
    let Xmin     : Double // limite inférieure de la case
    let Xmed     : Double // milieu de la case
    let Xmax     : Double // limite supérieure de la case
    var sampleNb : Int = 0 // nombre d'échantillonsdans la case
    
    // MARK: - Initializer
    
    init(Xmin             : Double,
         Xmax             : Double,
         step             : Double?  = nil) {
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
    
    /// Incrémente le nb d'échantillons de la case
    mutating func record() {
        // incrémente le nombre d'échantillons dans la case
        sampleNb += 1
    }
    /// Vide la case
    mutating func empty() {
        sampleNb = 0
    }
}

typealias BucketsArray = [Bucket]
extension BucketsArray {
    /// Ajoute un échantillon à la bonne case
    /// - Parameter data: échantillon
    mutating func record(_ data: Double) {
        // ranger l'échantillon dans une case
        if let idx = self.lastIndex(where: { $0.Xmin <= data }) {
            // incrémente le nombre d'échantillons dans la case
            self[idx].record()
        }
    }
    
    /// Crée une copie avec toutes les cases vides
    mutating func emptyCopy() -> BucketsArray {
        self.map {
            var newBucket = $0
            newBucket.empty()
            return newBucket
        }
    }
}

// MARK: - Histogram

/// Histogramme d'échantillons
///
/// Usage 1:
/// ```
///     var histogram = Histogram(name             : "histogramme",
///                                 distributionType : .continuous,
///                                 openEnds         : false,
///                                 Xmin             : minX,
///                                 Xmax             : maxX,
///                                 bucketNb         : 50)
///
///     // ajoute une séquence d'échantillons à l'histogramme
///     histogram.record(sequence)
///
///     // récupère la densité de probabiilité
///     let pdf = histogram.xPDF
///
///     // récupère la densité de probabiilité cumulée
///     let cdf = histogram.xCDF
/// ```
///
/// Usage 2:
/// ```
///     var histogram = Histogram(name: "histogramme")
///
///     // ajoute une séquence d'échantillons à l'histogramme
///     histogram.record(sequence)
///
///     // trier les échantillons dans les cases:
///     // Note: on eut le faire plusieurs fois de suite avec les mêmes échantillons
///     histogram.sort(distributionType : .continuous,
///                     openEnds         : false,
///                     Xmin             : minX,
///                     Xmax             : maxX,
///                     bucketNb         : 50)
///
///     // récupère la densité de probabiilité
///     let pdf = histogram.xPDF
///
///     // récupère la densité de probabiilité cumulée
///     let cdf = histogram.xCDF
/// ```
///
struct Histogram: Codable {
    
    // MARK: - Properties
    
    var name: String
    // type de sitribution
    private var distributionType: DistributionType = .continuous
    // openEnds:true si les premières et derniers case s'étendent à l'infini
    private var openEnds : Bool = false
    // tableau de tous les échantillons reçus
    private var dataset  = [Double]()
    var lastRecordedValue: Double? {
        dataset.last
    }
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
    private var bucketNb: Int { // nombre de cases fermées
        openEnds ? buckets.count - 2 : buckets.count
    } // computed
    // nombre d'échantillons par case
    var counts: [Int] {
        precondition(isInitialized, "Histogram.counts: histogramme non initialisé")
        return buckets.map { $0.sampleNb }
    } // computed
    var xCounts: [(x: Double, n: Int)] {
        precondition(isInitialized, "Histogram.xCounts: histogramme non initialisé")
        let yCounts = self.counts
        var values = [(x: Double, n: Int)]()
        for i in yCounts.indices {
            values.append((x: xValues[i], n: yCounts[i]))
        }
        return values
    } // computed
    // nombre d'échantillons cumulés de la première case à la case courante
    var cumulatedCounts: [Int] {
        precondition(isInitialized, "Histogram.cumulatedCounts: histogramme non initialisé")
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
    var xCumulatedCounts : [(x: Double, n: Int)] {
        precondition(isInitialized, "Histogram.xCumulatedCounts: histogramme non initialisé")
        let yCumulatedValues = self.cumulatedCounts
        var values = [(x: Double, n: Int)]()
        for i in yCumulatedValues.indices {
            values.append((x: xValues[i], n: yCumulatedValues[i]))
        }
        return values
    } // computed
    // densités de probabilité
    var PDF: [Double] { // en %
        precondition(isInitialized, "Histogram.PDF: histogramme non initialisé")
        var normalizer: Double
        switch distributionType {
            case .discrete:
                normalizer = dataset.count.double()
                
            case .continuous:
                normalizer = dataset.count.double() * Xstep
        }
        return buckets.map { $0.sampleNb.double() / normalizer }
    } // computed
    var xPDF: [(x: Double, p: Double)] {
        precondition(isInitialized, "Histogram.xPDF: histogramme non initialisé")
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
        precondition(isInitialized, "Histogram.CDF: histogramme non initialisé")
        var result          = [Double]()
        let cumulatedCounts = self.cumulatedCounts
        let normalizer      = dataset.count.double()
        for idx in cumulatedCounts.indices {
            result.append(cumulatedCounts[idx].double() / normalizer)
        }
        return result
    } // computed
    var xCDF: [(x: Double, p: Double)] {
        precondition(isInitialized, "Histogram.xCDF: histogramme non initialisé")
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
    
    init(name: String = "") {
        // Les échantillons seront mémorisés mais pas rangés
        // car les cases ne seront pas initialisées.
        // Il faudra utiliser la fonction "set" pour pour ranger les échantillons après les avoir ajoutés.
        self.name = name
    }
    
    /// Initialise les cases de l'histogramme
    /// - Parameters:
    ///   - distributionType: type de distribution (.continuous, .discrete)
    ///   - openEnds:true si les premières et derniers case s'étendent à l'infini
    ///   - Xmin: borne inf
    ///   - Xmax: borne sup
    ///   - bucketNb: nombre de cases (incluant les éventuelles cases s'étendant à l'infini)
    init(name             : String = "",
         distributionType : DistributionType,
         openEnds         : Bool = true,
         Xmin             : Double,
         Xmax             : Double,
         bucketNb         : Int) {
        self.name = name
        initializeBuckets(distributionType : distributionType,
                          openEnds         : openEnds,
                          Xmin             : Xmin,
                          Xmax             : Xmax,
                          bucketNb         : bucketNb)
    }
    
    // MARK: - Subscript
    
    /// nombre d'échantillons dans la case idx
    subscript(idx: Int) -> Int? {
        guard (0...buckets.count).contains(idx) else {
            return nil
        }
        return buckets[idx].sampleNb
    }
    
    // MARK: - Methods
    
    /// Initilize les propriétés internes de l'objet
    /// - Parameters:
    ///   - distributionType: type de distribution
    ///   - openEnds: true si le domaine de X sétend à l'infini
    ///   - Xmin: valeure minimale du domaine de X
    ///   - Xmax: valeure maximale du domaine de X
    ///   - bucketNb: nombre de cases fermées sur le doamine de X
    /// - Warning: bucketNb ne doit as iclure des 2 case s'étendant à l'inifini si openEnds = true
    fileprivate mutating func initializeBuckets(distributionType : DistributionType,
                                                openEnds         : Bool = false,
                                                Xmin             : Double,
                                                Xmax             : Double,
                                                bucketNb         : Int) {
        precondition(bucketNb >= 1, "Histogram.init: bucketNb < 1: pas de case dans l'histogramme pour ranger les échantillons")
        precondition(Xmax >= Xmin, "Histogram.init: Xmax < Xmin")
        
        // si Xmin = Xmax alors 1 seule case
        var _bucketNb : Int
        if Xmin == Xmax {
            _bucketNb = 1
        } else {
            _bucketNb = bucketNb
        }
        
        self.Xmin             = Xmin
        self.Xmax             = Xmax
        self.distributionType = distributionType
        self.openEnds         = openEnds
        
        // créer les cases
        self.Xstep = (Xmax - Xmin) / _bucketNb.double()
        
        if openEnds {
            // créer une première case sétendant à l'infini
            buckets.append(Bucket(Xmin: -Double.infinity,
                                  Xmax: self.Xmin,
                                  step: self.Xstep / 2))
            xValues.append(buckets.last!.Xmed)
        }
        // créer les cases fermées
        for i in 0..<_bucketNb {
            buckets.append(Bucket(Xmin: self.Xmin + i.double() * self.Xstep,
                                  Xmax: self.Xmin + (i.double() + 1) * self.Xstep))
            xValues.append(buckets.last!.Xmed)
        }
        if openEnds {
            // créer une dernière case sétendant à l'infini
            buckets.append(Bucket(Xmin: self.Xmax,
                                  Xmax: Double.infinity,
                                  step: self.Xstep / 2))
            xValues.append(buckets.last!.Xmed)
        }
    }
    
    /// Initialise les cases de l'histogramme et range les échantillons dans les cases
    ///
    /// - Warning: les échantillons doivent avoir été enregistrées au préalable
    ///
    /// - Parameters:
    ///   - distributionType: type de sitribution (.continuous ou .discrete)
    ///   - openEnds:true si les premières et derniers case s'étendent à l'infini
    ///   - Xmin: borne inf. Si nil alors = min des échantillons
    ///   - Xmax: borne sup.  Si nil alors = max des échantillons
    ///   - bucketNb: nombre de cases (incluant les éventuelles cases s'étendant à l'infini)
    mutating func sort(distributionType : DistributionType,
                       openEnds         : Bool     = false,
                       Xmin             : Double?  = nil,
                       Xmax             : Double?  = nil,
                       bucketNb         : Int) {
        guard !dataset.isEmpty else {
            // pas d'échantillons à traiter
            return
        }
        let computedXmin = Xmin ?? self.min! // minimum de tous les échantillons
        let computedXmax = Xmax ?? self.max!
        
        buckets = [Bucket]()
        xValues = [Double]()
        
        // initializer les cases de rangement
        initializeBuckets(distributionType : distributionType,
                          openEnds         : openEnds,
                          Xmin             : computedXmin,
                          Xmax             : computedXmax,
                          bucketNb         : bucketNb)
        
        // ranger les échantillons dans les cases
        for data in dataset {
            buckets.record(data)
        }
    }
    
    /// Ajoute un échantillon à l'histogramme
    /// - Parameter data: échantillon
    mutating func record(_ data: Double) {
        // ajouter la valeur au dataset
        dataset.append(data)
        // ranger l'échantillon dans une case (si les cases on été initialisées)
        // sinon il faudra utiliser la méthode "sort" pour les trier
        buckets.record(data)
    }
    
    /// Ajoute une séquence d'échantillons à l'histogramme
    /// - Parameter data: séquence d'échantillons
    mutating func record(_ sequence: [Double]) {
        sequence.forEach { record($0) }
    }
    
    /// Supprimer les échantillons et supprimer les cases
    mutating func reset() {
        // vider les échantillons
        dataset = [Double]()
        // Supprimer toutes las cases
        buckets = [Bucket]()
        xValues = [Double]()
    }
    
    /// Supprimer les échantillons et vider les cases (mais conservées les cases)
    mutating func resetDataset() {
        // vider les échantillons
        dataset = [Double]()
        buckets = buckets.emptyCopy()
    }
    
    /// Renvoie la valeur x telle que P(X<x) >= probability
    /// - Parameter probability: probabilité
    /// - Returns: x telle que P(X<x) >= probability
    /// - Warning: probability in [0, 1]
    func percentile(for probability: Double) -> Double? {
        guard !dataset.isEmpty else {
            // pas d'échantillons à traiter
            return nil
        }
        return Sigma.percentile(dataset, percentile: probability)
    }

    /// Renvoie la probabilité P telle que CDF(X) >= P
    /// - Parameter x: valeure dont il faut rechercher la probabilité
    /// - Returns: probabilité P telle que CDF(X) >= P
    /// - Warning: x in [Xmin, Xmax]
    func probability(for x: Double) -> Double? {
        guard let idx = xCDF.firstIndex(where: { x <= $0.x }) else {
            fatalError("Histogram.probability(x): x out of bound")
        }
        if idx > 0 {
            let k = (x - xCDF[idx-1].x) / (xCDF[idx].x - xCDF[idx-1].x)
            return xCDF[idx-1].p + k * (xCDF[idx].p - xCDF[idx-1].p)
        } else {
            return xCDF[idx].p
        }
    }
}
