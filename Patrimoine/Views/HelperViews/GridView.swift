//
//  NamedAmountListView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 29/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct GridView<Content: View>: View {
    let rows    : Int
    let columns : Int
    let content : (Int, Int) -> Content

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(0 ..< rows, id: \.self) { row in
                HStack {
                    ForEach(0 ..< self.columns, id: \.self) { column in
                        self.content(row, column)
                    }
                    Spacer()
                }
            }
        }
    }

    init(rows: Int, columns: Int, @ViewBuilder content: @escaping (Int, Int) -> Content) {
        self.rows = rows
        self.columns = columns
        self.content = content
    }
}

struct CellView : View {
    let row : Int
    let col : Int
    
    var body: some View {
        Text("R\(row) C\(col)")
    }
}


struct NamedAmountListView_Previews: PreviewProvider {
    static var previews: some View {
        GridView(rows: 10, columns: 3) { row, col  in
            CellView(row: row, col: col)
        }
            .previewLayout(PreviewLayout.fixed(width: 500, height: 250))
            .padding()
    }
}
