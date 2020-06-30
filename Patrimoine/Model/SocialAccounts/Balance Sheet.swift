import Foundation

typealias BalanceSheetArray = [BalanceSheetLine]

// MARK: - Ligne annuelle du bilan

struct BalanceSheetLine {

	// properties
	
	// année de début de la simulation
	var year: Int   = 0
	// actifs
    var assets      = NamedValueTable(withName: "ACTIF")
	// passifs
	var liabilities = NamedValueTable(withName: "PASSIF")
	// net
	var net       : Double {
		assets.total + liabilities.total
	}
    var headerCSV : String {
        let assetsNames      = assets.headerCSV
        let liabilitiesNames = liabilities.headerCSV
        return "\(assetsNames); \(liabilitiesNames)\n"
    }
    var valuesCSV : String {
        let assetsValues      = assets.valuesCSV
        let liabilitiesValues = liabilities.valuesCSV
        return "\(assetsValues); \(liabilitiesValues)\n"
    }

	// initialization
	
    init(withYear year             : Int,
         withPatrimoine patrimoine : Patrimoin) {
		self.year = year
		
		// actifs
		for asset in patrimoine.assets.realEstates.items.sorted(by:<) {
			// populate real estate assets
			appendToAssets(asset, year)
		}
        for asset in patrimoine.assets.periodicInvests.items.sorted(by:<) {
			// populate periodic investments assets
			appendToAssets(asset, year)
		}
        for asset in patrimoine.assets.freeInvests.items.sorted(by:<) {
			// populate free investment assets
 			appendToAssets(asset, year)
		}
        for asset in patrimoine.assets.scpis.items.sorted(by:<) {
            // populate SCPI assets
             appendToAssets(asset, year)
        }

		// actifs SCI - SCPI
        for asset in patrimoine.assets.sci.scpis.items.sorted(by:<) {
			// populate SCI assets
			appendToAssets(asset, year, "SCI - ")
		}
		
		// dettes
		for liability in patrimoine.liabilities.debts.items.sorted(by:<) {
			// populate debt liabilities
			appendToLiabilities(liability, year)
		}
		// emprunts
		for liability in patrimoine.liabilities.loans.items.sorted(by:<) {
			// populate loan liabilities
			appendToLiabilities(liability, year)
		}
	}
	
	// methods
	
    mutating func appendToAssets(_ asset          : NameableAndValueable,
                                 _ year           : Int,
                                 _ withNamePrefix : String = "") {
		assets.values.append((name  : withNamePrefix + asset.name,
                              value : asset.value(atEndOf: year).rounded()))
	}
    
    mutating func appendToLiabilities(_ liability      : NameableAndValueable,
                                      _ year           : Int,
                                      _ withNamePrefix : String = "") {
		liabilities.values.append((name  : withNamePrefix + liability.name,
                                   value : liability.value(atEndOf: year).rounded()))
	}
    
	func print() {
		Swift.print("YEAR:", year)
		// actifs
		assets.print(level: 1)
		// passifs
		liabilities.print(level: 1)
		// net
		Swift.print("Net: \(net)")
		Swift.print("-----------------------------------------")
	}
	
}
