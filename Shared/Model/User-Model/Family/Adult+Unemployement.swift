//
//  Adult+Unemployement.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 13/12/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

extension Adult {
    /// true si est vivant à la fin de l'année et année égale ou postérieur à l'année de cessation d'activité et égale ou inférieure à l'année de fin de droit d'allocation chomage
    /// - Parameter year: année
    func isReceivingUnemployementAllocation(during year: Int) -> Bool {
        guard isRetired(during: year) else {
            return false
        }
        guard let startDate = dateOfStartOfUnemployementAllocation,
              let endDate   = dateOfEndOfUnemployementAllocation else {
            return false
        }
        return (startDate.year...endDate.year).contains(year)
    }
    
    /// Allocation chômage perçue dans l'année
    /// - Parameter year: année
    /// - Returns: Allocation chômage perçue dans l'année brute, nette de charges sociales, taxable à l'IRPP
    func unemployementAllocation(during year: Int) -> BrutNetTaxable {
        guard isReceivingUnemployementAllocation(during: year) else {
            return BrutNetTaxable(brut: 0, net: 0, taxable: 0)
        }
        let firstYearDay = firstDayOf(year : year)
        let lastYearDay  = lastDayOf(year  : year)
        let alloc        = unemployementAllocation!
        let dateDebAlloc = dateOfStartOfUnemployementAllocation!
        let dateFinAlloc = dateOfEndOfUnemployementAllocation!
        if let dateReducAlloc = dateOfStartOfAllocationReduction {
            // reduction d'allocation après un certaine date
            let allocReduite  = unemployementReducedAllocation!
            // intersection de l'année avec la période taux plein
            var debut   = max(dateDebAlloc, firstYearDay)
            var fin     = min(dateReducAlloc, lastYearDay)
            let nbDays1 = zeroOrPositive(numberOfDays(from : debut, to : fin).day!)
            // intersection de l'année avec la période taux réduit
            debut       = max(dateReducAlloc, firstYearDay)
            fin         = min(dateFinAlloc, lastYearDay)
            let nbDays2 = zeroOrPositive(numberOfDays(from : debut, to : fin).day!)
            // somme des deux parties
            let brut = alloc.brut/365 * nbDays1.double() +
                allocReduite.brut/365 * nbDays2.double()
            let net = alloc.net/365  * nbDays1.double() +
                allocReduite.net/365 * nbDays2.double()
            return BrutNetTaxable(brut    : brut,
                                  net     : net,
                                  taxable : net)
            
        } else {
            // pas de réduction d'allocation
            var nbDays: Int
            // nombre de jours d'allocation dans l'année
            if year == dateDebAlloc.year {
                // première année d'allocation
                nbDays = 365 - dateDebAlloc.dayOfYear!
            } else if year == dateFinAlloc.year {
                // dernière année d'allocation
                nbDays = dateFinAlloc.dayOfYear!
            } else {
                // année pleine
                nbDays = 365
            }
            let brut = alloc.brut/365 * nbDays.double()
            let net  = alloc.net/365  * nbDays.double()
            return BrutNetTaxable(brut    : brut,
                                  net     : net,
                                  taxable : net)
        }
    }
    
    /// Indemnité de licenciement perçue dans l'année
    /// - Parameter year: année
    /// - Returns: Indemnité de licenciement perçue dans l'année brute, nette de charges sociales, taxable à l'IRPP
    /// - Note: L'indemnité de licenciement est due m^me si le licencié est décédé pendant le préavis
    func layoffCompensation(during year: Int) -> BrutNetTaxable {
        guard year == dateOfRetirement.year else {
            return BrutNetTaxable(brut: 0, net: 0, taxable: 0)
        }
        // on est bien dans l'année de cessation d'activité
        guard isAlive(atEndOf: year-1) else {
            // la personne n'était plus vivante l'année précédent son licenciement
            return BrutNetTaxable(brut: 0, net: 0, taxable: 0)
        }
        // la personne était encore vivante l'année précédent son licenciement
        if let layoffCompensation = layoffCompensation {
            return BrutNetTaxable(brut    : layoffCompensation.brut,
                                  net     : layoffCompensation.net,
                                  taxable : layoffCompensation.taxable)
        } else {
            // pas droit à une indemnité
            return BrutNetTaxable(brut: 0, net: 0, taxable: 0)
        }
    }
}
