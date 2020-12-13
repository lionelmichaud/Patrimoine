//
//  LifeInsuranceTaxes.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 13/12/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Impôts sur le revenu

struct IncomeTaxes: Codable {
    
    // nested types
    
    typealias IRPP = (amount         : Double,
                      familyQuotient : Double,
                      marginalRate   : Double,
                      averageRate    : Double)
    
    typealias SlicedIRPP = [(size                : Double,
                             sizeithChildren     : Double,
                             sizeithoutChildren  : Double,
                             rate                : Double,
                             irppMax             : Double,
                             irppWithChildren    : Double,
                             irppWithoutChildren : Double)]
    
    // tranche de barême de l'IRPP
    struct IrppSlice: Codable {
        let floor : Double // euro
        let rate  : Double // %
        var disc  : Double // euro
    }
    
    struct Model: Codable, Versionable {
        var version        : Version
        var irppGrid       : [IrppSlice]
        let turnOverRebate : Double // 34.0 // %
        let salaryRebate   : Double // 10.0 // %
        let minRebate      : Double // 441 // €
        let maxRebate      : Double // 12_627 // €
        let childRebate    : Double // 1_512.0 // €
    }
    
    // properties
    
    // barême de l'exoneration de charges sociale sur les plus-values immobilières
    var model: Model
    
    // methods
    
    /// Initializer les paramètres calculés pour les tranches d'imposition à partir des seuils et des taux
    mutating func initialize() {
        for idx in model.irppGrid.startIndex ..< model.irppGrid.endIndex {
            if idx == 0 {
                model.irppGrid[idx].disc = model.irppGrid[idx].floor * (model.irppGrid[idx].rate - 0)
            } else {
                model.irppGrid[idx].disc =
                    model.irppGrid[idx-1].disc +
                    model.irppGrid[idx].floor * (model.irppGrid[idx].rate - model.irppGrid[idx-1].rate)
            }
        }
    }
    
    /// Quotion familial
    /// - Parameters:
    ///   - nbAdults: nombre d'adultes
    ///   - nbChildren: nombre d'enfants
    /// - Returns: Quotion familial
    func familyQuotient(nbAdults: Int, nbChildren: Int) -> Double {
        Double(nbAdults) + Double(nbChildren) / 2.0
    }
    
    /// Calcul du revenu imposable
    /// - Parameter personalIncome: revenus
    /// - Returns: revenu imposable
    func taxableIncome(from personalIncome: WorkIncomeType) -> Double {
        switch personalIncome {
            case .salary(_, let taxableSalary, _, _, _):
                // application du rabais sur le salaire imposable
                let rebate = (taxableSalary * Fiscal.model.incomeTaxes.model.salaryRebate / 100.0).clamp(low : model.minRebate,
                                                                                                         high: model.maxRebate)
                return taxableSalary - rebate
                
            case .turnOver(let BNC, _):
                return BNC * (1 - Fiscal.model.incomeTaxes.model.turnOverRebate / 100.0)
        }
    }
    
    /// Répartit l'IRPP en tranches
    /// - Parameters:
    ///   - taxableIncome: revenu imposable
    ///   - nbAdults: nb d'adulte dans la famille
    ///   - nbChildren: nb d'enfant dans la famille
    func slicedIrpp(taxableIncome : Double,
                    nbAdults      : Int,
                    nbChildren    : Int) -> SlicedIRPP {
        
        func buildSlice(index                        : Int,
                        sliceWithChildrent           : Int,
                        incomeWithChildren    : Double,
                        sliceWoutChildren            : Int,
                        incomeWithoutChildren : Double) {
            var size               : Double
            var irppMax            : Double
            var sizeithChildren    : Double
            var sizeithoutChildren : Double
            let rate = model.irppGrid[index].rate
            
            if index == model.irppGrid.endIndex - 1 {
                size    = 10000
                irppMax = 0
            } else {
                size    = model.irppGrid[index+1].floor - model.irppGrid[index].floor
                irppMax = model.irppGrid[index].rate * size
            }
            
            var irppWithChildren: Double
            switch index {
                case 0 ..< sliceWithChildrent:
                    sizeithChildren  = size
                    irppWithChildren = irppMax
                    
                case sliceWithChildrent:
                    sizeithChildren = incomeWithChildren - model.irppGrid[index].floor
                    irppWithChildren = rate * sizeithChildren
                    
                case (sliceWithChildrent+1)... :
                    sizeithChildren  = 0
                    irppWithChildren = 0
                    
                default:
                    sizeithChildren  = 0
                    irppWithChildren = 0
            }
            
            var irppWithoutChildren: Double
            switch index {
                case 0 ..< sliceWoutChildren:
                    sizeithoutChildren  = size
                    irppWithoutChildren = irppMax
                    
                case sliceWoutChildren:
                    sizeithoutChildren  = incomeWithoutChildren - model.irppGrid[index].floor
                    irppWithoutChildren = rate * sizeithoutChildren
                    
                case (sliceWoutChildren+1)... :
                    sizeithoutChildren  = 0
                    irppWithoutChildren = 0
                    
                default:
                    sizeithoutChildren  = 0
                    irppWithoutChildren = 0
            }
            
            slices.append((size                : size,
                           sizeithChildren     : sizeithChildren,
                           sizeithoutChildren  : sizeithoutChildren,
                           rate                : rate,
                           irppMax             : irppMax,
                           irppWithChildren    : irppWithChildren,
                           irppWithoutChildren : irppWithoutChildren))
        }
        
        //--------------------------------
        guard nbAdults != 0 else {
            return []
        }
        
        let familyQuotient = self.familyQuotient(nbAdults  : nbAdults,
                                                 nbChildren: nbChildren)
        let taxableIncomeWithChildren = taxableIncome / familyQuotient
        guard let irppSliceIdx = model.irppGrid.lastIndex(where: { $0.floor < taxableIncomeWithChildren}) else {
            return []
        }
        
        let QuotientWithoutChildren = self.familyQuotient(nbAdults  : nbAdults,
                                                          nbChildren: 0)
        let taxableIncomeWithoutChildren = taxableIncome / QuotientWithoutChildren
        guard let irppSliceIdx2 = model.irppGrid.lastIndex(where: { $0.floor < taxableIncomeWithoutChildren}) else {
            return []
        }
        
        var slices = SlicedIRPP()
        for idx in 0 ..< model.irppGrid.count {
            buildSlice(index                 : idx,
                       sliceWithChildrent    : irppSliceIdx,
                       incomeWithChildren    : taxableIncomeWithChildren,
                       sliceWoutChildren     : irppSliceIdx2,
                       incomeWithoutChildren : taxableIncomeWithoutChildren)
        }
        
        return slices
    }
    
    /// Impôt sur le revenu
    /// - Parameters:
    ///   - taxableIncome: revenu imposable
    ///   - nbAdults: nombre d'adulte dans la famille
    ///   - nbChildren: nombre d'enfant dans la famille
    /// - Returns: Impôt sur le revenu
    func irpp (taxableIncome : Double,
               nbAdults      : Int,
               nbChildren    : Int) -> IRPP {
        guard nbAdults != 0 else {
            return (amount         : 0.0,
                    familyQuotient : 0.0,
                    marginalRate   : 0.0,
                    averageRate    : 0.0)
        }
        
        // FIXME: Vérifier calcul
        let familyQuotient = self.familyQuotient(nbAdults  : nbAdults,
                                                 nbChildren: nbChildren)
        if let irppSlice = model.irppGrid.last(where: { $0.floor < taxableIncome / familyQuotient}) {
            // calcul de l'impot avec les parts des enfants
            let taxWithChildren = taxableIncome * irppSlice.rate - familyQuotient * irppSlice.disc
            //print("impot avec les parts des enfants =",taxWithChildren)
            // calcul de l'impot sans les parts des enfants
            let QuotientWithoutChildren = self.familyQuotient(nbAdults  : nbAdults,
                                                              nbChildren: 0)
            if let irppSlice2 = model.irppGrid.last(where: { $0.floor < taxableIncome / QuotientWithoutChildren}) {
                let taxWithoutChildren = taxableIncome * irppSlice2.rate - QuotientWithoutChildren * irppSlice2.disc
                //print("impot sans les parts des enfants =",taxWithoutChildren)
                // gain lié aux parts des enfants
                let gain = taxWithoutChildren - taxWithChildren
                //print("gain =",gain)
                // plafond de gain
                let maxGain = Double(nbChildren) * model.childRebate
                //print("gain max=",maxGain)
                // plafonnement du gain lié aux parts des enfants
                if gain > maxGain {
                    let irpp = taxWithoutChildren - maxGain
                    return (amount         : irpp,
                            familyQuotient : familyQuotient,
                            marginalRate   : irppSlice.rate,
                            averageRate    : irpp / taxableIncome)
                } else {
                    let irpp = taxWithChildren
                    return (amount         : irpp,
                            familyQuotient : familyQuotient,
                            marginalRate   : irppSlice.rate,
                            averageRate    : irpp / taxableIncome)
                }
            } else {
                fatalError()
            }
        }
        return (amount         : 0.0,
                familyQuotient : familyQuotient,
                marginalRate   : 0.0,
                averageRate    : 0.0)
    }
}
