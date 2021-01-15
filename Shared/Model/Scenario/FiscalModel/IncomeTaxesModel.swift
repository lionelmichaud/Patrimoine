//
//  LifeInsuranceTaxes.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 13/12/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Impôts sur le revenu

struct IncomeTaxesModel: Codable {
    
    // MARK: - Nested types
    
    enum ModelError: Error {
        case outOfBounds
        case gridSliceIssue
    }
    
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
    
    struct Model: Codable, Versionable, RateGridable {
        var version           : Version
        var grid              : RateGrid
        let turnOverRebate    : Double // 34.0 %
        let minTurnOverRebate : Double // 305 €
        let salaryRebate      : Double // 10.0 %
        let minSalaryRebate   : Double // 441 €
        let maxSalaryRebate   : Double // 12_627 €
        let childRebate       : Double // 1_512.0 €
    }
    
    // MARK: - Properties
    
    // barême de l'exoneration de charges sociale sur les plus-values immobilières
    var model: Model
    
    // MARK: - Methods

    /// Initializer les paramètres calculés pour les tranches d'imposition à partir des seuils et des taux
    mutating func initialize() throws {
        try model.initializeGrid()
    }
    
    /// Quotion familial
    /// - Parameters:
    ///   - nbAdults: nombre d'adultes
    ///   - nbChildren: nombre d'enfants
    /// - Returns: Quotion familial
    /// - Note: [reference](https://www.economie.gouv.fr/particuliers/quotient-familial)
    func familyQuotient(nbAdults: Int, nbChildren: Int) throws -> Double {
        guard nbAdults >= 0 else {
            throw ModelError.outOfBounds
        }
        switch nbChildren {
            case ...(-1):
                throw ModelError.outOfBounds
            case 0...2:
                return Double(nbAdults) + Double(nbChildren) / 2.0
            default:
                return Double(nbAdults) + 1.0 + Double(nbChildren - 2)
        }
    }
    
    /// Calcul du revenu imposable
    /// - Parameter personalIncome: revenus
    /// - Returns: revenu imposable
    /// - Note:
    ///   - [reference](https://www.economie.gouv.fr/particuliers/revenu-imposable-revenu-fiscal-reference)
    ///   - [reference](https://www.economie.gouv.fr/particuliers/decote-impot-revenu)
    ///   - [reference](https://www.service-public.fr/professionnels-entreprises/vosdroits/F32105)
    ///   - [micr-entrepreneur](https://www.service-public.fr/professionnels-entreprises/vosdroits/F23267)
    func taxableIncome(from personalIncome: WorkIncomeType) -> Double {
        switch personalIncome {
            case .salary(_, let taxableSalary, _, _, _):
                guard taxableSalary >= 0 else {
                    return 0
                }
                // application du rabais sur le salaire imposable
                let rebate = (taxableSalary * model.salaryRebate / 100.0).clamp(low : model.minSalaryRebate,
                                                                                high: model.maxSalaryRebate)
                return zeroOrPositive(taxableSalary - rebate)
                
            case .turnOver(let BNC, _):
                guard BNC >= 0 else {
                    return 0
                }
                // TODO: - prendre en compte le régime du micro-fiscal forfaitaire à 22% si le revenu fiscal de référence est < 80_000€
                let rebate = max(model.minTurnOverRebate,
                                 BNC * model.turnOverRebate / 100.0)
                return zeroOrPositive(BNC - rebate)
        }
    }
    
    /// Répartit l'IRPP en tranches
    /// - Parameters:
    ///   - taxableIncome: revenu imposable
    ///   - nbAdults: nb d'adulte dans la famille
    ///   - nbChildren: nb d'enfant dans la famille
    func slicedIrpp(taxableIncome : Double,
                    nbAdults      : Int,
                    nbChildren    : Int) throws -> SlicedIRPP {
        
        func buildSlice(index                        : Int,
                        sliceWithChildrent           : Int,
                        incomeWithChildren    : Double,
                        sliceWoutChildren            : Int,
                        incomeWithoutChildren : Double) {
            var size               : Double
            var irppMax            : Double
            var sizeithChildren    : Double
            var sizeithoutChildren : Double
            let rate = model.grid[index].rate
            
            if index == model.grid.endIndex - 1 {
                size    = 10000
                irppMax = 0
            } else {
                size    = model.grid[index+1].floor - model.grid[index].floor
                irppMax = model.grid[index].rate * size
            }
            
            var irppWithChildren: Double
            switch index {
                case 0 ..< sliceWithChildrent:
                    sizeithChildren  = size
                    irppWithChildren = irppMax
                    
                case sliceWithChildrent:
                    sizeithChildren = incomeWithChildren - model.grid[index].floor
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
                    sizeithoutChildren  = incomeWithoutChildren - model.grid[index].floor
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
        
        let familyQuotient = try self.familyQuotient(nbAdults  : nbAdults,
                                                 nbChildren: nbChildren)
        let taxableIncomeWithChildren = taxableIncome / familyQuotient
        guard let irppSliceIdx = model.sliceIndex(containing: taxableIncomeWithChildren) else {
            return []
        }
        
        let QuotientWithoutChildren = try self.familyQuotient(nbAdults  : nbAdults,
                                                          nbChildren: 0)
        let taxableIncomeWithoutChildren = taxableIncome / QuotientWithoutChildren
        guard let irppSliceIdx2 = model.sliceIndex(containing: taxableIncomeWithoutChildren) else {
            return []
        }
        
        var slices = SlicedIRPP()
        for idx in 0 ..< model.grid.count {
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
    /// - Note: [reference](https://www.economie.gouv.fr/particuliers/tranches-imposition-impot-revenu)
    func irpp(taxableIncome : Double,
              nbAdults      : Int,
              nbChildren    : Int) throws -> IRPP {
        guard nbAdults != 0 && taxableIncome >= 0.0 else {
            return (amount         : 0.0,
                    familyQuotient : 0.0,
                    marginalRate   : 0.0,
                    averageRate    : 0.0)
        }
        
        let familyQuotient = try self.familyQuotient(nbAdults  : nbAdults,
                                                     nbChildren: nbChildren)
        if let irppSlice = model.slice(containing: taxableIncome / familyQuotient) {
            // calcul de l'impot avec les parts des enfants
            let taxWithChildren = familyQuotient * (try! irppSlice.tax(for: taxableIncome / familyQuotient))
            //print("impot avec les parts des enfants =",taxWithChildren)
            // calcul de l'impot sans les parts des enfants
            let QuotientWithoutChildren = try self.familyQuotient(nbAdults  : nbAdults,
                                                                  nbChildren: 0)
            if let tax = model.tax(for: taxableIncome / QuotientWithoutChildren) {
                let taxWithoutChildren = tax * QuotientWithoutChildren
                //print("impot sans les parts des enfants =",taxWithoutChildren)
                // gain lié aux parts des enfants
                let gain = taxWithoutChildren - taxWithChildren
                //print("gain =",gain)
                // plafond de gain en fonction du nombre de 1/2 part supplémentaire
                let maxGain = Double(familyQuotient - QuotientWithoutChildren) * 2.0 * model.childRebate
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
                throw ModelError.gridSliceIssue
            }
        }
        return (amount         : 0.0,
                familyQuotient : familyQuotient,
                marginalRate   : 0.0,
                averageRate    : 0.0)
    }
}
