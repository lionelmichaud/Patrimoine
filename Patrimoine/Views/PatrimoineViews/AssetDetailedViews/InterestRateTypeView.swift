//
//  InterestRateTypeView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 14/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct InterestRateTypeEditView : View {
    @Binding var rateType         : InterestRateType
    @State private var typeIndex  : Int
    @State private var fixedRate  : Double
    @State private var stockRatio : Double
    
    var body: some View {
        VStack {
            CaseWithAssociatedValuePicker<InterestRateType>(caseIndex: $typeIndex, label: "")
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: typeIndex) { newValue in
                    switch newValue {
                        case InterestRateType.contractualRate(fixedRate: 0).id:
                            self.rateType = .contractualRate(fixedRate: self.fixedRate)
                            
                        case InterestRateType.marketRate(stockRatio: 0).id:
                            self.rateType = .marketRate(stockRatio: self.stockRatio)
                            
                        default:
                            fatalError("InterestRateType : Case out of bound")
                    }
                }
            switch typeIndex {
                case InterestRateType.contractualRate(fixedRate: 0).id:
                    PercentEditView(label: "Taux fixe", percent: $fixedRate)
                        .onChange(of: fixedRate) { newValue in
                            self.rateType = .contractualRate(fixedRate: newValue)
                        }
                case InterestRateType.marketRate(stockRatio: 0).id:
                    VStack(alignment: .leading) {
                        Text("Fraction en actions: \(Int(stockRatio)) %")
                        HStack {
                            Text("0%")
                            Slider(value : $stockRatio,
                                   in    : 0 ... 100,
                                   step  : 5,
                                   onEditingChanged: { _ in
                                    self.rateType = .marketRate(stockRatio: stockRatio)
                                   })
                            Text("100%")
                        }
                    }
                default:
                    EmptyView()
            }
        }
    }
    
    init(rateType: Binding<InterestRateType>) {
        _rateType = rateType
        _typeIndex = State(initialValue: rateType.wrappedValue.id)
        switch rateType.wrappedValue {
            case .contractualRate(let fixedRate):
                self._stockRatio = State(initialValue: 0)
                self._fixedRate  = State(initialValue: fixedRate)
                
            case .marketRate(let stockRatio):
                self._stockRatio = State(initialValue: stockRatio)
                self._fixedRate  = State(initialValue: 0)
        }
    }
}

struct InterestRateTypeEditView_Previews: PreviewProvider {
    static var previews: some View {
        InterestRateTypeEditView(rateType: .constant(InterestRateType.contractualRate(fixedRate: 1.5)))
            .previewLayout(PreviewLayout.sizeThatFits)
            .padding([.bottom, .top])
            .previewDisplayName("InterestRateTypeEditView")
    }
}
