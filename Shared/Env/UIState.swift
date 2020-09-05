//
//  UIState.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 17/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

class UIState: ObservableObject {
    enum Tab: Int {
        case family, expense, asset, scenario, simulation
    }
    
    // MARK: - Etat de la vue Patrimoine
    struct PatrimoineViewState {
        struct AssetsViewState {
            var colapseAsset      : Bool = false
            var colapseImmobilier : Bool = true
            var colapseFinancier  : Bool = true
            var colapseSCI        : Bool = true
            var colapseEstate     : Bool = true
            var colapseSCPI       : Bool = true
            var colapsePeriodic   : Bool = true
            var colapseFree       : Bool = true
            var colapseSCISCPI    : Bool = true
        }
        struct LiabilitiesViewState {
            var colapseLiab        : Bool = false
            var colapseEmprunts    : Bool = true
            var colapseDettes      : Bool = true
            var colapseEmpruntlist : Bool = true
            var colapseDetteListe  : Bool = true
        }
        var evalDate       : Double = Date.now.year.double()
        var assetViewState = AssetsViewState()
        var liabViewState  = LiabilitiesViewState()
    }
    
    // MARK: - Etat de la vue Expense
    struct ExpenseViewState {
        var colapseCategories : [Bool] = []
        var endDate           : Double = (Date.now.year + 25).double()
        var evalDate          : Double = Date.now.year.double()
    }
    
    // MARK: - Etat de la vue Simulation
    struct SimulationViewState {
        var selectedItem: SimulationView.PushedItem?
    }
    
    // MARK: - Etat de la vue Charts
    struct ChartsViewState {
        var selectedItem: ChartsView.PushedItem?
    }
    
    // MARK: - Etat de la vue Compute
    struct ComputationState {
        var nbYears: Double = 15
    }
    
    // MARK: - Etat des filtres graphes Bilan
    struct BalanceSheetChartState {
        var combination    : SocialAccounts.AssetLiabilitiesCombination = .both
        var itemSelection  : [(label: String, selected: Bool)] = []
    }
    
    // MARK: - Etat des filtres graphes Cash Flow
    struct CashFlowChartState {
        var combination            : SocialAccounts.CashCombination = .both
        var itemSelection          : [(label: String, selected: Bool)] = []
        var onlyOneCategorySeleted : Bool {
            let count = itemSelection.reduce(.zero, { result, element in result + (element.selected ? 1 : 0) } )
            return count == 1
        }
    }
    
    @Published var selectedTab         = Tab.family
    @Published var patrimoineViewState = PatrimoineViewState()
    @Published var simulationViewState = SimulationViewState()
    @Published var chartsViewState     = ChartsViewState()
    @Published var expenseViewState    = ExpenseViewState()
    @Published var computationState    = ComputationState()
    @Published var bsChartState        = BalanceSheetChartState()
    @Published var cfChartState        = CashFlowChartState()
    
    init() {
        expenseViewState.colapseCategories = Array(repeating: true, count: LifeExpenseCategory.allCases.count)
    }
    
    func resetSimulation() {
        simulationViewState.selectedItem = .computation
        chartsViewState.selectedItem     = nil
    }
}
