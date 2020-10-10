//
//  TableView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 01/06/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct ListTableRowView: View {
    let label           : String
    let value           : Double
    let indentLevel     : Int
    let header          : Bool

    var body: some View {
        HStack {
            if header {
                Image(systemName: "chevron.down")
                Text(label)
                    .font(Font.system(size: ListTheme[indentLevel].labelFontSize,
                                      design: Font.Design.default))
                    .fontWeight(.bold)
                
            } else {
                Text(label)
                    .font(Font.system(size: ListTheme[indentLevel].labelFontSize,
                                      design: Font.Design.default))
            }
            Spacer()
            Text(value.€String)
                .font(Font.system(size: ListTheme[indentLevel].valueFontSize,
                                  design: Font.Design.default))
        }
            .padding(EdgeInsets(top: 0,
                                leading: ListTheme[indentLevel].indent,
                                bottom: 0,
                                trailing: 0))
            .listRowBackground(ListTheme.rowsBaseColor.opacity(header ? ListTheme[indentLevel].opacity:0.0))
    }
}

struct TableView_Previews: PreviewProvider {
    static var previews: some View {
        ListTableRowView(label: "Titre",
                         value: 12345,
                         indentLevel: 0,
                         header: true)
    }
}
