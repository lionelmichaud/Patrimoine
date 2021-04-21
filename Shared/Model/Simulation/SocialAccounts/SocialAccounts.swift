import Foundation
import os

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.SocialAccounts")

// MARK: - Comptes sociaux

/// Comptes sociaux: Table de Compte de résultat annuels + Bilans annuels
struct SocialAccounts {
    
    // MARK: - Static Properties
    
    // #if DEBUG
    /// URL du fichier de stockage du résultat de calcul au format CSV
    // en mode DEBUG sauvegarder le fichier .CSV dans le répertoire Bundle/csv
    // en plus du répertoire Data/Documents/csv
    static let balanceSheetFileUrl = Bundle.main.url(forResource: "BalanceSheet.csv", withExtension: nil)
    /// URL du fichier de stockage du résultat de calcul au format CSV
    // en mode DEBUG sauvegarder le fichier .CSV dans le répertoire Bundle/csv
    // en plus du répertoire Data/Documents/csv
    static let cashFlowFileUrl = Bundle.main.url(forResource: "CashFlow.csv", withExtension: nil)
    // #endif
    
    // MARK: - Properties
    
    var cashFlowArray = CashFlowArray()
    var balanceArray  = BalanceSheetArray()
    var firstYear     = Date.now.year
    var lastYear      = Date.now.year
    // les successions légales
    var legalSuccessions   : [Succession] = []
    // les transmissions d'assurances vie
    var lifeInsSuccessions : [Succession] = []

    // MARK: - Computed Properties
    
    var isEmpty: Bool {
        cashFlowArray.isEmpty || balanceArray.isEmpty
    }

    // MARK: - Methods
    
    fileprivate func setKpiValue(kpiEnum          : SimulationKPIEnum,
                                 value            : Double,
                                 _ kpiDefinitions : inout KpiArray,
                                 _ kpiResults     : inout DictionaryOfKpiResults,
                                 _ simulationMode : SimulationModeEnum) {
        kpiDefinitions[kpiEnum.id].record(value, withMode: simulationMode)
        kpiResults[kpiEnum] =
            KpiResult(value              : value,
                      objectiveIsReached : kpiDefinitions[kpiEnum.id].objectiveIsReached(for : value))
    }
    
    /// Mémorise le niveau le + bas atteint par les actifs financiers (hors immobilier physique) au cours du run
    /// - Parameters:
    ///   - kpis: les KPI à utiliser
    ///   - simulationMode: mode de simluation en cours
    fileprivate func computeMinimumAssetKpiValue(withKPIs kpiDefinitions : inout KpiArray,
                                                 withMode simulationMode : SimulationModeEnum,
                                                 kpiResults              : inout DictionaryOfKpiResults) {
        let minBalanceSheetLine = balanceArray.min { a, b in
            a.financialAssets < b.financialAssets
        }
        // KPI 3: mémoriser le minimum d'actif financier net au cours du temps
        setKpiValue(kpiEnum: .minimumAsset, value: minBalanceSheetLine!.financialAssets,
                    &kpiDefinitions, &kpiResults,
                    simulationMode)
    }

    /// Gérer les KPI quand il n'y a plus de Cash => on arrête la simulation et on calcule la valeur des KPIs
    /// - Parameters:
    ///   - year: année du run courant
    ///   - withKPIs: les KPI à utiliser
    ///   - kpiResults: valeur des KPIs pour le run courant
    fileprivate func computeKpisAtZeroCashAvailable // swiftlint:disable:this function_parameter_count
    (year                    : Int,
     withFamily family       : Family,
     withKPIs kpiDefinitions : inout KpiArray,
     kpiResults              : inout DictionaryOfKpiResults,
     withMode simulationMode : SimulationModeEnum,
     withbalanceSheetLine    : BalanceSheetLine?) {
        customLog.log(level: .info, "Arrêt de la construction de la table en \(year) de Comptes sociaux: Actifs financiers = 0 dans \(Self.self, privacy: .public)")

        // Actif Net (hors immobilier physique)
        let netAsset = withbalanceSheetLine?.netFinancialAssets ?? 0
        
        // mémoriser le montant de l'Actif financier Net (hors immobilier physique)
        switch family.nbOfAdultAlive(atEndOf: year) {
            case 2:
                // il reste 2 adultes vivants
//                setKpiValue(kpiEnum: .assetAt1stDeath, value: netAsset,
//                            &kpiDefinitions, &kpiResults,
//                            simulationMode)
//
//                setKpiValue(kpiEnum: .assetAt2ndtDeath, value: netAsset,
//                            &kpiDefinitions, &kpiResults,
//                            simulationMode)
            ()

            case 1:
                // il reste 1 seul adulte vivant
                if family.nbOfAdultAlive(atEndOf: year-1) == 2 {
                    // un des deux adulte est décédé cette année
                    setKpiValue(kpiEnum: .assetAt1stDeath, value: netAsset,
                                &kpiDefinitions, &kpiResults,
                                simulationMode)
                }
//                setKpiValue(kpiEnum: .assetAt2ndtDeath, value: netAsset,
//                            &kpiDefinitions, &kpiResults,
//                            simulationMode)

            case 0:
                // il ne plus d'adulte vivant
                ()
                
            default:
                // ne devrait jamais se produire
                customLog.log(level: .fault, "Nombre d'adulte survivants inattendu: \(family.nbOfAdultAlive(atEndOf: year), privacy: .public) dans \(Self.self, privacy: .public)")
                fatalError("Nombre d'adulte survivants inattendu: \(family.nbOfAdultAlive(atEndOf: year)) dans \(Self.self)")
        }
        /// KPI n°3 : on est arrivé à la fin de la simulation car il n'y a plus de cash dans les Free Investements
        /// mais il peut éventuellement rester d'autres actifs (immobilier de rendement...)
        // TODO: - il faudrait définir un KPI spécifique
        setKpiValue(kpiEnum: .minimumAsset, value: 0,
                    &kpiDefinitions, &kpiResults,
                    simulationMode)
    }
    
    /// Gérer les KPI n°1, 2, 3 au décès de l'un ou des 2 conjoints
    /// - Parameters:
    ///   - year: année du run courant
    ///   - withKPIs: les KPI à utiliser
    ///   - kpiResults: valeur des KPIs pour le run courant
    fileprivate func computeKpisAtDeath (year                    : Int, // swiftlint:disable:this function_parameter_count
                                         withFamily family       : Family,
                                         withKPIs kpiDefinitions : inout KpiArray,
                                         kpiResults              : inout DictionaryOfKpiResults,
                                         withMode simulationMode : SimulationModeEnum,
                                         withbalanceSheetLine    : BalanceSheetLine) {
        // Actif Net (hors immobilier physique)
        let netAsset = withbalanceSheetLine.netFinancialAssets
        
        switch family.nbOfAdultAlive(atEndOf: year) {
            case 1:
                /// KPI n°1: décès du premier conjoint et mémoriser la valeur du KPI
                // mémoriser le montant de l'Actif Net (hors immobilier physique)
                setKpiValue(kpiEnum: .assetAt1stDeath, value: netAsset,
                            &kpiDefinitions, &kpiResults,
                            simulationMode)

            case 0:
                if family.nbOfAdultAlive(atEndOf: year-1) == 2 {
                    /// KPI n°1: décès du premier conjoint et mémoriser la valeur du KPI
                    // mémoriser le montant de l'Actif Net (hors immobilier physique)
                    setKpiValue(kpiEnum: .assetAt1stDeath, value: netAsset,
                                &kpiDefinitions, &kpiResults,
                                simulationMode)
                }
                /// KPI n°2: décès du second conjoint et mémoriser la valeur du KPI
                // mémoriser le montant de l'Actif Net (hors immobilier physique)
                setKpiValue(kpiEnum: .assetAt2ndtDeath, value: netAsset,
                            &kpiDefinitions, &kpiResults,
                            simulationMode)
                /// KPI n°3 : on est arrivé à la fin de la simulation
                // rechercher le minimum d'actif financier au cours du temps (hors immobilier physique)
                computeMinimumAssetKpiValue(withKPIs   : &kpiDefinitions,
                                            withMode   : simulationMode,
                                            kpiResults : &kpiResults)
                
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
    mutating func build(run                       : Int, // swiftlint:disable:this function_parameter_count
                        nbOfYears                 : Int,
                        withFamily family         : Family,
                        withPatrimoine patrimoine : Patrimoin,
                        withKPIs kpis             : inout KpiArray,
                        withMode simulationMode   : SimulationModeEnum) -> DictionaryOfKpiResults {
        
        //-------------------------------------------------------------------------------------------
        firstYear = Date.now.year
        lastYear  = firstYear + nbOfYears - 1
        cashFlowArray.reserveCapacity(nbOfYears)
        balanceArray.reserveCapacity(nbOfYears)
        
        var kpiResults = DictionaryOfKpiResults()
        
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
                let newCashFlowLine = try CashFlowLine(run                                   : run,
                                                       withYear                              : year,
                                                       withFamily                            : family,
                                                       withPatrimoine                        : patrimoine,
                                                       taxableIrppRevenueDelayedFromLastyear : lastYearDelayedTaxableIrppRevenue)
                cashFlowArray.append(newCashFlowLine)
                // ajouter les éventuelles successions survenues pendant l'année à la liste globale
                legalSuccessions   += newCashFlowLine.successions
                // ajouter les éventuelles transmissions d'assurance vie survenues pendant l'année à la liste globale
                lifeInsSuccessions += newCashFlowLine.lifeInsSuccessions
            } catch {
                /// il n'y a plus de Cash => on arrête la simulation
                lastYear = year
                computeKpisAtZeroCashAvailable(year                 : year,
                                               withFamily           : family,
                                               withKPIs             : &kpis,
                                               kpiResults           : &kpiResults,
                                               withMode             : simulationMode,
                                               withbalanceSheetLine : balanceArray.last)
                //                withbalanceSheetLine : balanceArray[balanceArray.endIndex - 2])
                SimulationLogger.shared.log(run      : run,
                                            logTopic : LogTopic.simulationEvent,
                                            message  : "Fin du run: à cours de cash en \(year)")
                return kpiResults // arrêter la construction de la table
            }

            // construire la ligne annuelle de Bilan de fin d'année
            //-----------------------------------------------------
            let newBalanceSheetLine = BalanceSheetLine(withYear        : year,
                                                       withMembersName : family.membersName,
                                                       withAssets      : patrimoine.assets.allOwnableItems,
                                                       withLiabilities : patrimoine.liabilities.allOwnableItems)
            balanceArray.append(newBalanceSheetLine)

            if family.nbOfAdultAlive(atEndOf: year) < family.nbOfAdultAlive(atEndOf: year-1) {
                // décès d'un adulte
                // gérer les KPI n°1, 2, 3 au décès de l'un ou des 2 conjoints
                computeKpisAtDeath(year                 : year,
                                   withFamily           : family,
                                   withKPIs             : &kpis,
                                   kpiResults           : &kpiResults,
                                   withMode             : simulationMode,
                                   withbalanceSheetLine : newBalanceSheetLine)
            }
            
            if family.nbOfAdultAlive(atEndOf: year) == 0 {
                // il n'y a plus d'adulte vivant à la fin de l'année
                // on arrête la simulation après avoir clos les dernières successions
                lastYear = year
                SimulationLogger.shared.log(run      : run,
                                            logTopic : LogTopic.simulationEvent,
                                            message  : "Fin du run: plus d'adulte en vie en \(year)")
                return kpiResults
            }
        }
        
        /// KPI n°3 : on est arrivé à la fin de la simulation
        // rechercher le minimum d'actif financier net au cours du temps
        computeMinimumAssetKpiValue(withKPIs   : &kpis,
                                    withMode   : simulationMode,
                                    kpiResults : &kpiResults)
        return kpiResults
    }
    
    /// Sauvegarder les résultats de simulation dans des fchier CSV
    ///
    /// - un fichier pour le Cash Flow
    /// - un fichier pour le Bilan
    ///
    /// - Parameter simulationTitle: Titre de la simulation utilisé pour générer les nom de répertoire
    func save(simulationTitle: String,
              withMode mode  : SimulationModeEnum) {
        balanceArray.storeTableCSV(simulationTitle: simulationTitle,
                                   withMode: mode)
        cashFlowArray.storeTableCSV(simulationTitle: simulationTitle)
    }
}
