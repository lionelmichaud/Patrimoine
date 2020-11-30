//
//  OwnershipView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 29/11/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI


struct ExampleView: View {
    @State private var day: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Group {
                Text("Selected day: ") + Text(day).foregroundColor(.blue)
            }.font(.headline)
            
            Menu(content: menuContents, label: menuLabel)
                .frame(width: 200)
        }
    }
    
    @ViewBuilder func menuContents() -> some View {
        Button("All Days") { self.day = "All Days"}
        
        Menu("Working Day") {
            Button("Monday") { self.day = "Monday" }
            Button("Tuesday") { self.day = "Tuesday" }
            Button("Wednesday") { self.day = "Wednesday" }
            Button("Thursday") { self.day = "Thursday" }
            Button("Friday") { self.day = "Friday" }
        }
        
        // This view is required to avoid SwiftUI merging menus "Working Day" and "Weekend"
        Color.clear.frame(width: 1, height: 1)
        
        Menu("Weekend") {
            Button("Saturday") { self.day = "Saturday" }
            Button("Sunday") { self.day = "Sunday" }
        }
    }
    
    @ViewBuilder func menuLabel() -> some View {
        HStack {
            Image(systemName: "calendar")
            
            Text("Select Day")
        }
    }
}



struct OwnerGroupBox: View {
    let title: String
    let owner: Owner
    
    var body: some View {
        GroupBox(label: Text(title)) {
            VStack {
                HStack {
                    Text(owner.name)
                    Spacer()
                    Text(String(owner.age) + " ans")
                }.padding(.top, 8)
                HStack {
                    Text("Fraction détenue: ") + Text((owner.fraction * 100.0).percentString() + " %").bold()
                    Menu("Modifier") {
                        /*@START_MENU_TOKEN@*/Text("Menu Item 1")/*@END_MENU_TOKEN@*/
                        /*@START_MENU_TOKEN@*/Text("Menu Item 2")/*@END_MENU_TOKEN@*/
                        /*@START_MENU_TOKEN@*/Text("Menu Item 3")/*@END_MENU_TOKEN@*/
                    }
                    Spacer()
                    Text("Valeur détenue: ") + Text(owner.ownedValue.€String).bold()
                }
            }
            .padding(.leading)
        }
        .groupBoxStyle(DefaultGroupBoxStyle())
    }
}

struct OwnersListView : View {
    let title              : String
    let updateSharedValues : () -> ()
    @Binding var owners    : Owners
    @State private var showingSheet = false
    @Environment(\.presentationMode) var presentationMode
    @State private var alertItem : AlertItem?

    var body: some View {
        List {
            ForEach(owners, id: \.self) { owner in
                OwnerGroupBox(title: title,
                              owner: owner)
            }
            .onDelete(perform: deleteMember)
            .onMove(perform: moveMembers)
            AmountView(label: "Total " + title + "s", amount: owners.sumOfOwnedValues)
            
        }
        .navigationTitle(title+"s")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                EditButton()
            }
            ToolbarItem(placement: .automatic) {
                Button(
                    action: {
                        withAnimation {
                            self.showingSheet = true
                        }
                    },
                    label: {
                        Image(systemName: "plus").padding()
                    })
            }
        }
        // Vue modale de saisie d'un nouveau membre de la famille
        .sheet(isPresented: $showingSheet) {
            EmptyView()
        }
        .alert(item: $alertItem, content: myAlert)
    }
    
    func deleteMember(at offsets: IndexSet) {
        // Empêcher de supprimer la dernière personne
        guard owners.count > 1 else {
            self.alertItem = AlertItem(title         : Text("Il doit y a voir au moins un " + title),
                                       dismissButton : .default(Text("OK")))
            return
        }
        // retirer la personne de la liste
        owners.remove(atOffsets: offsets)
        // TODO: - Réattribuer les % de la personne supprimée aux personnes restantes
        owners.updateOwnersFraction(updateSharedValues: { updateSharedValues() } )
        // TODO: - recalculculer les valeurs de chaque personne en conséquence
        
        // TODO: - Demander à l'utilisateur de mettre à jour les % manuellement
        
        self.presentationMode.wrappedValue.dismiss()
    }
    
    func moveMembers(from indexes: IndexSet, to destination: Int) {
        owners.move(fromOffsets: indexes, toOffset: destination)
    }
    
}

struct OwnershipView: View {
    @Binding var ownership: Ownership
    let usufruitierStr  = "Usufruitier"
    let proprietaireStr = "Propriétaire"
    let nuPropStr       = "Nu-Propriétaire"

    var body: some View {
        Section(header: Text("PROPRIETE")) {
            Toggle("Démembrement de propriété", isOn: $ownership.isDismembered)
            if ownership.isDismembered {
                /// démembrement de propriété
                Group {
                    NavigationLink(destination: OwnersListView(title              : usufruitierStr,
                                                               updateSharedValues : { ownership.updateSharedValues() },
                                                               owners             : $ownership.usufructOwners)) {
                        AmountView(label  : usufruitierStr+"s",
                                   amount : ownership.usufructOwners.sumOfOwnedValues)
                            .foregroundColor(.blue)
                    }
                    NavigationLink(destination: OwnersListView(title              : nuPropStr,
                                                               updateSharedValues : { ownership.updateSharedValues() },
                                                               owners             : $ownership.bareOwners)) {
                        AmountView(label  : nuPropStr+"s",
                                   amount : ownership.bareOwners.sumOfOwnedValues)
                            .foregroundColor(.blue)
                    }
                }.padding(.leading)
                
            } else {
                /// pleine propriété
                NavigationLink(destination: OwnersListView(title              : proprietaireStr,
                                                           updateSharedValues : { ownership.updateSharedValues() },
                                                           owners             : $ownership.fullOwners)) {
                    AmountView(label  : proprietaireStr+"s",
                               amount : ownership.fullOwners.sumOfOwnedValues)
                        .foregroundColor(.blue)
                }.padding(.leading)
            }
        }
    }
}

struct OwnershipView_Previews: PreviewProvider {
    struct Container: View {
        @State var ownership = Ownership()
        var body: some View {
            OwnershipView(ownership: $ownership)
                .onAppear(perform: { ownership.updateTotalValue(with: 100.0) })
        }
    }
    
    static var previews: some View {
        Group {
            ExampleView()
            NavigationView() {
                Form {
                    OwnershipView(ownership: .constant(Ownership()))
                }
            }
            .previewDevice("iPhone Xs")
            NavigationView() {
                Form {
                    Container(ownership: Ownership())
                }
            }
            
        }
    }
}
