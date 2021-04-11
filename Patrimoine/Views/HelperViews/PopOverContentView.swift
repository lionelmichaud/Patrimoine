//
//  PopOverContentView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 11/04/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct PopOverContentView: View {
    var title       : String?
    var description : String
    
    var body: some View {
        VStack(spacing: 10) {
            if let title = title {
                Text(title)
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            Text(description)
        }
        .padding()
    }
}

struct PopOverContentView_Previews: PreviewProvider {
    static var previews: some View {
        PopOverContentView(title: "Titre", description: "contenu du popvoer")
    }
}
