//
//  PickerHelperViews.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 23/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

// MARK: - Saisie d'une Année
struct YearPicker: View {
    let title              : String
    let inRange            : ClosedRange<Int>
    @Binding var selection : Int
    @State var rows = [Int]()
    
    var body: some View {
        Picker(title, selection: $selection) {
            ForEach(rows, id: \.self) { year in
                Text(String(year))
            }
        }
        .onAppear( perform: { self.inRange.forEach {self.rows.append($0)}})
    }
}

// MARK: - Saisie d'un Enum
struct CasePicker<T: PickableEnum>: View where T.AllCases: RandomAccessCollection {
    @Binding var pickedCase: T
    let label: String
    
    var body: some View {
        Picker(selection: $pickedCase, label: Text(label)) {
            ForEach(T.allCases, id: \.self) { enu in
                Text(enu.pickerString)
            }
        }
    }
}

// MARK: - Saisie d'un Enum avec Valeurs associées
struct CaseWithAssociatedValuePicker<T: PickableIdentifiableEnum>: View where T.AllCases: RandomAccessCollection {
    @Binding var caseIndex: Int
    let label: String
    
    var body: some View {
        Picker(selection: $caseIndex, label: Text(label)) {
            ForEach(T.allCases ) { enu in
                Text(enu.pickerString).tag(enu.id)
            }
        }
    }
}

// MARK: - Tests & Previews

struct PickerHelperViews_Previews: PreviewProvider {
    enum TestEnum: Int, PickableEnum {
        case un, deux, trois
        var pickerString: String {
            switch self {
                case .un:
                    return "Un"
                case .deux:
                    return "Deux"
                case .trois:
                    return "Trois"
            }
        }
    }

    static var previews: some View {
        Group {
            YearPicker(title: "Année", inRange: 2010...2025, selection: .constant(2020))
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding([.bottom, .top])
                .previewDisplayName("YearPicker")
            CasePicker<TestEnum>(pickedCase: .constant(TestEnum.deux), label: "Enum")
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding([.bottom, .top])
                .previewDisplayName("CasePicker<TestEnum>")
        }
    }
}
