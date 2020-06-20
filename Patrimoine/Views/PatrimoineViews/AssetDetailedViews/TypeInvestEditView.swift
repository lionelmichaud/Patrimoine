//
//  TypeInvestEditView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 03/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import Combine

// MARK: - Saisie dy type d'investissement
//struct TypeInvestEditView2 : View {
//    @Binding var typeIndex  : Int
//    @Binding var isPeriodic : Bool
//
//    var body: some View {
//        VStack {
//            CaseWithAssociatedValuePicker<InvestementType>(caseIndex: $typeIndex, label: "")
//                .pickerStyle(SegmentedPickerStyle())
//            if typeIndex == InvestementType.lifeInsurance(periodicSocialTaxes: true).id {
//                Toggle("Prélèvement sociaux annuels", isOn: $isPeriodic)
//            }
//        }
//    }
//}

struct TypeInvestEditView : View {
    @Binding var investType  : InvestementType
    @State public var typeIndex  : Int
    @State public var isPeriodic : Bool
    
    var body: some View {
        VStack {
            CaseWithAssociatedValuePicker<InvestementType>(caseIndex: $typeIndex, label: "")
                .pickerStyle(SegmentedPickerStyle())
                .onReceive(Just(typeIndex)) { newValue in
                    switch newValue {
                        case InvestementType.pea.id:
                            self.investType = .pea
                        case InvestementType.other.id:
                            self.investType = .other
                        case InvestementType.lifeInsurance(periodicSocialTaxes: true).id:
                            self.investType = .lifeInsurance(periodicSocialTaxes: self.isPeriodic)
                        default:
                            fatalError("InvestementType : Case out of bound")
                    }
            }
            if typeIndex == InvestementType.lifeInsurance(periodicSocialTaxes: true).id {
                Toggle("Prélèvement sociaux annuels", isOn: $isPeriodic)
                    .onReceive(Just(isPeriodic)) { newValue in
                        self.investType = .lifeInsurance(periodicSocialTaxes: newValue)
                }
            }
        }
    }
    
    init(investType: Binding<InvestementType>) {
        self._investType = investType
        self._typeIndex = State(initialValue: investType.wrappedValue.id)
        switch investType.wrappedValue {
            case .lifeInsurance(let periodicSocialTaxes):
                self._isPeriodic = State(initialValue: periodicSocialTaxes)
            default:
                self._isPeriodic = State(initialValue: false)
        }
    }
}


struct TypeInvestEditView_Previews: PreviewProvider {
    static var previews: some View {
        TypeInvestEditView(investType: .constant(InvestementType.lifeInsurance(periodicSocialTaxes: true)))
            .previewLayout(PreviewLayout.sizeThatFits)
            .padding([.bottom, .top])
            .previewDisplayName("TypeInvestEditView")
    }
}
