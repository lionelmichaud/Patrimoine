import Foundation
//import Cocoa

// MARK: - Comptes sociaux

/// Comptes sociaux: Table de Compte de résultat annuels + Bilans annuels
struct SocialAccounts {
    
   // static properties
    
    #if DEBUG
    /// URL du fichier de stockage du résultat de calcul au format CSV
    static let balanceSheetFileUrl = Bundle.main.url(forResource: "BalanceSheet.csv", withExtension: nil)
    /// URL du fichier de stockage du résultat de calcul au format CSV
    static let cashFlowFileUrl = Bundle.main.url(forResource: "CashFlow.csv", withExtension: nil)
    #endif

    // properties
    
    var cashFlowArray = CashFlowArray()
    var balanceArray  = BalanceSheetArray()
    var firstYear     = Date.now.year
    var lastYear      = Date.now.year
    var isEmpty: Bool {
        cashFlowArray.isEmpty || balanceArray.isEmpty
    }

    // methods
    
    /// réinitialiser les comptes sociaux
    /// - Parameters:
    ///   - family: la famille dont il faut faire le bilan
    ///   - patrimoine: le patrimoine
    mutating func reset(withPatrimoine patrimoine : Patrimoine) {
        cashFlowArray = CashFlowArray()
        balanceArray  = BalanceSheetArray()
        firstYear     = Date.now.year
        lastYear      = Date.now.year
        
        patrimoine.resetFreeInvestementCurrentValue()
    }
    
    // MARK: - Construction de la table des comptes sociaux = Bilan + CashFlow
    /// construire la table de comptes sociaux au fil des années
    /// - Parameters:
    ///   - nbOfYears: nombre d'années à construire
    ///   - family: la famille dont il faut faire le bilan
    ///   - patrimoine: le patrimoine
    ///   - reportProgress: closure pour indiquer l'avancement de la simulation
    mutating func build(nbOfYears                 : Int,
                        withFamily family         : Family,
                        withPatrimoine patrimoine : Patrimoine) {
        firstYear = Date.now.year
        lastYear  = firstYear + nbOfYears - 1

        for year in firstYear ... lastYear {
            
            // construire la ligne annuelle de Cash Flow
            //------------------------------------------
            // gérer le report de revenu imposable
            var lastYearDelayedTaxableIrppRevenue: Double
            if let lastLine = cashFlowArray.last { // de l'année précédente, s'il y en a une
                lastYearDelayedTaxableIrppRevenue = lastLine.taxableIrppRevenueDelayedToNextYear.value(atEndOf: year - 1)
            }
            else {
                lastYearDelayedTaxableIrppRevenue = 0
            }
            
            // ajouter une nouvelle ligne
            do {
                let newLine = try CashFlowLine(withYear                              : year,
                                               withFamily                            : family,
                                               withPatrimoine                        : patrimoine,
                                               taxableIrppRevenueDelayedFromLastyear : lastYearDelayedTaxableIrppRevenue)
                cashFlowArray.append(newLine)
            } catch {
                Swift.print("Arrêt de la construction de la table de Comptes sociaux: Actifs financiers = 0")
                lastYear = year
                return // arrêter la construction de la table
            }
            
            // construire la ligne annuelle de Bilan de fin d'année
            //-----------------------------------------------------
            let newLine = BalanceSheetLine(withYear       : year,
                                           withPatrimoine : patrimoine)
            balanceArray.append(newLine)
        }
    }
    
    // MARK: - Impression écran
    func printBalanceSheetTable() {
        Swift.print("================================================")
        Swift.print(" BILAN")
        Swift.print("================================================")
        for line in balanceArray {
            line.print()
        }
    }
    
    func printCashFlowTable() {
        Swift.print("================================================")
        Swift.print(" CASH FLOW")
        Swift.print("================================================")
        print(cashFlowArray)
        for line in cashFlowArray {
            line.print()
        }
    }
}
