import Foundation
import os

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.SocialAccounts")

// MARK: - Comptes sociaux

/// Comptes sociaux: Table de Compte de résultat annuels + Bilans annuels
struct SocialAccounts {
    
    // MARK: - Static Properties
    
    //#if DEBUG
    /// URL du fichier de stockage du résultat de calcul au format CSV
    static let balanceSheetFileUrl = Bundle.main.url(forResource: "BalanceSheet.csv", withExtension: nil)
    /// URL du fichier de stockage du résultat de calcul au format CSV
    static let cashFlowFileUrl = Bundle.main.url(forResource: "CashFlow.csv", withExtension: nil)
    //#endif
    
    // MARK: - Properties
    
    var cashFlowArray = CashFlowArray()
    var balanceArray  = BalanceSheetArray()
    var firstYear     = Date.now.year
    var lastYear      = Date.now.year
    // les successions
    var successions   : [Succession] = []

    // MARK: - Computed Properties
    
    var isEmpty: Bool {
        cashFlowArray.isEmpty || balanceArray.isEmpty
    }
    
    // MARK: - Methods
    
    /// Réinitialiser les comptes sociaux
    mutating func reset() {
        cashFlowArray = CashFlowArray()
        balanceArray  = BalanceSheetArray()
        firstYear     = Date.now.year
        lastYear      = Date.now.year
        successions   = []
}
    
    /// Mémorise le niveau le bas atteint par les actifs financiers au cours du run
    /// - Parameters:
    ///   - kpis: les KPI à utiliser
    ///   - simulationMode: mode de simluation en cours
    func computeMinimumAssetKpiValue(withKPIs kpiDefinitions : inout KpiArray,
                                     withMode simulationMode : SimulationModeEnum,
                                     currentKPIs             : inout DictionaryOfKpiResults) {
        let minBalanceSheetLine = balanceArray.min { a, b in
            a.totalFinancialAssets < b.totalFinancialAssets
        }
        // KPI 3: mémoriser le minimum d'actif financier net au cours du temps
        kpiDefinitions[SimulationKPIEnum.minimumAsset.id].record(minBalanceSheetLine!.totalFinancialAssets, withMode: simulationMode)
        currentKPIs[.minimumAsset] = KpiResult(value              : minBalanceSheetLine!.totalFinancialAssets,
                                               objectiveIsReached : minBalanceSheetLine!.totalFinancialAssets >= kpiDefinitions[SimulationKPIEnum.minimumAsset.id].objective)
    }

    /// il n'y a plus de Cash => on arrête la simulation
    /// - Parameters:
    ///   - kpis: les KPI à utiliser
    ///   - year: année du run courant
    ///   - currentKPIs: valeur des KPIs pour le run courant
    func computeCurrentKpisValues(year                    : Int,
                                  withFamily family       : Family,
                                  withKPIs kpiDefinitions : inout KpiArray,
                                  currentKPIs             : inout DictionaryOfKpiResults,
                                  withMode simulationMode : SimulationModeEnum) {
        customLog.log(level: .info, "Arrêt de la construction de la table de Comptes sociaux: Actifs financiers = 0 \(Self.self, privacy: .public)")
        Swift.print("Arrêt de la construction de la table de Comptes sociaux: Actifs financiers = 0")
        
        // mémoriser le montant de l'Actif financier Net
        switch family.nbOfAdultAlive(atEndOf: year) {
            case 2:
                // il reste 2 adultes vivants
                kpiDefinitions[SimulationKPIEnum.assetAt1stDeath.id].record(0, withMode: simulationMode)
                currentKPIs[.assetAt1stDeath] = KpiResult(value              : 0,
                                                          objectiveIsReached : false)
                
                kpiDefinitions[SimulationKPIEnum.assetAt2ndtDeath.id].record(0, withMode: simulationMode)
                currentKPIs[.assetAt2ndtDeath] = KpiResult(value              : 0,
                                                           objectiveIsReached : false)
                
            case 1:
                // il reste 1 seul adulte vivant
                kpiDefinitions[SimulationKPIEnum.assetAt2ndtDeath.id].record(0, withMode: simulationMode)
                currentKPIs[.assetAt2ndtDeath] = KpiResult(value              : 0,
                                                           objectiveIsReached : false)
                
            case 0:
                // il ne plus d'adulte vivant
                ()
                
            default:
                // ne devrait jamais se produire
                customLog.log(level: .fault, "Nombre d'adulte survivants inattendu: \(family.nbOfAdultAlive(atEndOf: year), privacy: .public) dans \(Self.self, privacy: .public)")
                fatalError("Nombre d'adulte survivants inattendu: \(family.nbOfAdultAlive(atEndOf: year)) dans  \(Self.self)")
        }
        /// KPI n°3 : on est arrivé à la fin de la simulation
        // rechercher le minimum d'actif financier net au cours du temps
        computeMinimumAssetKpiValue(withKPIs    : &kpiDefinitions,
                                  withMode    : simulationMode,
                                  currentKPIs : &currentKPIs)
    }
    
    /// gérer les KPI n°1, 2, 3 au décès de l'un ou des 2 conjoints
    func computeKpisAtDeath (year                    : Int, // swiftlint:disable:this function_parameter_count
                             withFamily family       : Family,
                             withKPIs kpiDefinitions : inout KpiArray,
                             currentKPIs             : inout DictionaryOfKpiResults,
                             withMode simulationMode : SimulationModeEnum,
                             withbalanceSheetLine    : BalanceSheetLine) {
        let netAsset = withbalanceSheetLine.netAssets
        switch family.nbOfAdultAlive(atEndOf: year) {
            case 1:
                /// KPI n°1: décès du premier conjoint et mémoriser la valeur du KPI
                // mémoriser le montant de l'Actif Net
                kpiDefinitions[SimulationKPIEnum.assetAt1stDeath.id].record(netAsset,
                                                                            withMode : simulationMode)
                currentKPIs[.assetAt1stDeath] =
                    KpiResult(value              : netAsset,
                              objectiveIsReached : netAsset >= kpiDefinitions[SimulationKPIEnum.assetAt1stDeath.id].objective)
                
            case 0:
                if family.nbOfAdultAlive(atEndOf: year-1) == 2 {
                    /// KPI n°1: décès du premier conjoint et mémoriser la valeur du KPI
                    // mémoriser le montant de l'Actif Net
                    kpiDefinitions[SimulationKPIEnum.assetAt1stDeath.id].record(netAsset,
                                                                                withMode: simulationMode)
                    currentKPIs[.assetAt1stDeath] =
                        KpiResult(value              : netAsset,
                                  objectiveIsReached : netAsset >= kpiDefinitions[SimulationKPIEnum.assetAt1stDeath.id].objective)
                }
                /// KPI n°2: décès du second conjoint et mémoriser la valeur du KPI
                // mémoriser le montant de l'Actif Net
                kpiDefinitions[SimulationKPIEnum.assetAt2ndtDeath.id].record(netAsset,
                                                                             withMode: simulationMode)
                currentKPIs[.assetAt2ndtDeath] =
                    KpiResult(value              : netAsset,
                              objectiveIsReached : netAsset >= kpiDefinitions[SimulationKPIEnum.assetAt2ndtDeath.id].objective)
                /// KPI n°3 : on est arrivé à la fin de la simulation
                // rechercher le minimum d'actif financier net au cours du temps
                computeMinimumAssetKpiValue(withKPIs    : &kpiDefinitions,
                                            withMode    : simulationMode,
                                            currentKPIs : &currentKPIs)
                
            default:
                // ne devrait jamais se produire
                customLog.log(level: .fault, "Nombre d'adulte survivants inattendu: \(family.nbOfAdultAlive(atEndOf: year), privacy: .public) dans \(Self.self, privacy: .public)")
                fatalError("Nombre d'adulte survivants inattendu: \(family.nbOfAdultAlive(atEndOf: year)) dans  \(Self.self)")
        }
    }
    
    // MARK: - Construction de la table des comptes sociaux = Bilan + CashFlow
    
    /// construire la table de comptes sociaux au fil des années
    /// - Parameters:
    ///   - nbOfYears: nombre d'années à construire
    ///   - family: la famille dont il faut faire le bilan
    ///   - patrimoine: le patrimoine
    ///   - reportProgress: closure pour indiquer l'avancement de la simulation
    ///   - kpis: les KPI
    ///   - simulationMode: mode de simluation en cours
    mutating func build(nbOfYears                 : Int,
                        withFamily family         : Family,
                        withPatrimoine patrimoine : Patrimoin,
                        withKPIs kpis             : inout KpiArray,
                        withMode simulationMode   : SimulationModeEnum) -> DictionaryOfKpiResults {
        
        //-------------------------------------------------------------------------------------------
        firstYear = Date.now.year
        lastYear  = firstYear + nbOfYears - 1
        cashFlowArray.reserveCapacity(nbOfYears)
        balanceArray.reserveCapacity(nbOfYears)
        
        var currentKPIs = DictionaryOfKpiResults()
        
        for year in firstYear ... lastYear {
            // construire la ligne annuelle de Cash Flow
            //------------------------------------------
            /// gérer le report de revenu imposable
            var lastYearDelayedTaxableIrppRevenue: Double
            if let lastLine = cashFlowArray.last { // de l'année précédente, s'il y en a une
                lastYearDelayedTaxableIrppRevenue = lastLine.taxableIrppRevenueDelayedToNextYear.value(atEndOf: year - 1)
            } else {
                lastYearDelayedTaxableIrppRevenue = 0
            }
            
            /// ajouter une nouvelle ligne pour une nouvelle année
            do {
                let newCashFlowLine = try CashFlowLine(withYear                              : year,
                                                       withFamily                            : family,
                                                       withPatrimoine                        : patrimoine,
                                                       taxableIrppRevenueDelayedFromLastyear : lastYearDelayedTaxableIrppRevenue)
                cashFlowArray.append(newCashFlowLine)
                // ajouter les éventuelles successions survenues pendant l'année à la liste globale
                successions += newCashFlowLine.successions
            } catch {
                /// il n'y a plus de Cash => on arrête la simulation
                lastYear = year
                computeCurrentKpisValues(year        : year,
                                         withFamily  : family,
                                         withKPIs    : &kpis,
                                         currentKPIs : &currentKPIs,
                                         withMode    : simulationMode)
                return currentKPIs // arrêter la construction de la table
            }
            
            // construire la ligne annuelle de Bilan de fin d'année
            //-----------------------------------------------------
            let newBalanceSheetLine = BalanceSheetLine(withYear : year,
                                                       withPatrimoine       : patrimoine)
            balanceArray.append(newBalanceSheetLine)
            
            // décès d'un adulte
            if family.nbOfAdultAlive(atEndOf: year) < family.nbOfAdultAlive(atEndOf: year-1) {
                // gérer les KPI n°1, 2, 3 au décès de l'un ou des 2 conjoints
                computeKpisAtDeath(year                 : year,
                                   withFamily           : family,
                                   withKPIs             : &kpis,
                                   currentKPIs          : &currentKPIs,
                                   withMode             : simulationMode,
                                   withbalanceSheetLine : newBalanceSheetLine)
                // transférer les biens du défunt vers ses héritiers
                patrimoine.transferOwnershipOfDecedent(atEndOf: year)
                
            }
            
            if family.nbOfAdultAlive(atEndOf: year-1) == 0 {
                // il n'y avait plus d'adulte vivant l'année précédente,
                // on arrête la simulation après avoir clos la dernière succession
                return currentKPIs
            }
        }
        
        /// KPI n°3 : on est arrivé à la fin de la simulation
        // rechercher le minimum d'actif financier net au cours du temps
        computeMinimumAssetKpiValue(withKPIs    : &kpis,
                                    withMode    : simulationMode,
                                    currentKPIs : &currentKPIs)
        return currentKPIs
    }
    
    /// Sauvegarder les résultats de simulation dans des fchier CSV
    ///
    /// - un fichier pour le Cash Flow
    /// - un fichier pour le Bilan
    ///
    /// - Parameter simulationTitle: Titre de la simulation utilisé pour générer les nom de répertoire
    func save(simulationTitle: String) {
        balanceArray.storeTableCSV(simulationTitle: simulationTitle)
        cashFlowArray.storeTableCSV(simulationTitle: simulationTitle)
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
