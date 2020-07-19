//
//  UnemployementDetailView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 15/07/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct UnemployementDetailView: View {

    // MARK: - View Model
    
    class ViewModel: ObservableObject {
        @Published var allocationReducedBrut : Double = 0
        @Published var allocationReducedNet  : Double = 0
        @Published var allocationSupraLegale : Bool   = false
        @Published var allocationBrut        : Double = 0
        @Published var allocationNet         : Double = 0
        @Published var totalAllocationNet    : Double = 0
        @Published var durationInMonth       : Int    = 0
        @Published var percentReduc          : Double = 0
        @Published var afterMonth            : Int?
        @Published var compensationBrut      : Double = 0
        @Published var compensationNet       : Double = 0
        @Published var compensationTaxable   : Double = 0
        @Published var compensationNbMonth   : Double = 0
    }
    
    // MARK: - Properties
    
    @EnvironmentObject var member : Person
    @ObservedObject var viewModel = ViewModel()
    
    var body: some View {
        Form {
            Section(header: Text("Indemnité de licenciement").font(.subheadline)) {
                if viewModel.allocationSupraLegale {
                    AmountView(label: "Montant brut supra-légal", amount: viewModel.compensationBrut)
                } else {
                    HStack {
                        IntegerView(label: "Equivalent à", integer: Int(viewModel.compensationNbMonth.rounded()))
                        Text("mois")
                    }
                    AmountView(label: "Montant brut légal ou conventionnel", amount: viewModel.compensationBrut)
                }
                AmountView(label: "Montant net", amount: viewModel.compensationNet)
                AmountView(label: "Montant imposable", amount: viewModel.compensationTaxable)
            }
            Section(header: Text("Allocation chômage").font(.subheadline)) {
                HStack {
                    IntegerView(label: "Durée d'allocation", integer: viewModel.durationInMonth)
                    Text("mois")
                }
                AmountView(label: "Montant total perçu net", amount: viewModel.totalAllocationNet)
            }
            Section(header: Text("Allocation chômage non réduite").font(.subheadline)) {
                AmountView(label: "Montant annuel brut", amount: viewModel.allocationBrut)
                AmountView(label: "Montant annuel net", amount: viewModel.allocationNet, weight: .bold)
            }
            if viewModel.afterMonth != nil {
                Section(header: Text("Allocation chômage réduite").font(.subheadline)) {
                    HStack {
                        IntegerView(label: "Réduction de l'allocation après", integer: viewModel.afterMonth!)
                        Text("mois")
                    }
                    PercentView(label: "Coefficient de réduction", percent: viewModel.percentReduc / 100)
                    AmountView(label: "Montant annuel réduit brut", amount: viewModel.allocationReducedBrut)
                    AmountView(label: "Montant annuel réduit net", amount: viewModel.allocationReducedNet, weight: .bold)
                }
            }
        }
        .navigationBarTitle("Allocation chômage de \(member.displayName)", displayMode: .inline)
        .onAppear(perform: onAppear)
    }
    
    // MARK: - Methods
    
    func onAppear() {
        let adult = member as! Adult
        viewModel.durationInMonth                                         = adult.unemployementAllocationDuration!
        (viewModel.allocationBrut, viewModel.allocationNet)               = adult.unemployementAllocation!
        (viewModel.percentReduc, viewModel.afterMonth)                    = adult.unemployementAllocationReduction!
        (viewModel.compensationNbMonth, viewModel.compensationBrut,
         viewModel.compensationNet, viewModel.compensationTaxable)        = adult.layoffCompensation!
        viewModel.allocationSupraLegale                                   = (adult.layoffCompensationBonified != nil)
        (viewModel.allocationReducedBrut, viewModel.allocationReducedNet) = adult.unemployementReducedAllocation!
        viewModel.totalAllocationNet                                      = adult.unemployementTotalAllocation!.net
    }
}

struct UnemployementDetailView_Previews: PreviewProvider {
    static var family  = Family()
    
    static var previews: some View {
        let aMember = family.members.first!
        
        return UnemployementDetailView().environmentObject(aMember)
    }
}
