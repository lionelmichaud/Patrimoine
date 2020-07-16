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
        @Published var allocationBrut        : Double = 0
        @Published var allocationNet         : Double = 0
        @Published var durationInMonth       : Int    = 0
        @Published var percentReduc          : Double = 0
        @Published var afterMonth            : Int?
    }
    
    // MARK: - Properties
    
    @EnvironmentObject var member: Person
    @ObservedObject var viewModel = ViewModel()

    var body: some View {
        Form {
            IntegerView(label: "Durée d'allocation en trimestres", integer: viewModel.durationInMonth)
            AmountView(label: "Allocation annuelle brute", amount: viewModel.allocationBrut)
            AmountView(label: "Allocation annuelle nette", amount: viewModel.allocationNet, weight: .bold)
            if viewModel.afterMonth != nil {
                IntegerView(label: "Réduction de l'allocation après trimestres", integer: viewModel.afterMonth!)
                PercentView(label: "Coefficient de réduction", percent: viewModel.percentReduc / 100)
                AmountView(label: "Allocation annuelle réduite brute", amount: viewModel.allocationReducedBrut)
                AmountView(label: "Allocation annuelle réduite nette", amount: viewModel.allocationReducedNet, weight: .bold)
            }
        }
        .navigationBarTitle("Allocation chômage de \(member.displayName)", displayMode: .inline)
        .onAppear(perform: onAppear)
    }
    
    // MARK: - Methods
    
    func onAppear() {
        let adult = member as! Adult
        viewModel.durationInMonth = adult.unemployementAllocationDuration!
        (viewModel.allocationBrut, viewModel.allocationNet) = adult.unemployementAllocation!
        (viewModel.percentReduc, viewModel.afterMonth) =
            Unemployment.model.allocationChomage.reduction(age: adult.age(atDate: adult.dateOfRetirement).year!, daylyAlloc: viewModel.allocationBrut)
        viewModel.allocationReducedBrut = viewModel.allocationBrut * (1 - viewModel.percentReduc / 100)
        viewModel.allocationReducedNet  = viewModel.allocationNet  * (1 - viewModel.percentReduc / 100)
    }
}

struct UnemployementDetailView_Previews: PreviewProvider {
    static var previews: some View {
        UnemployementDetailView()
    }
}
