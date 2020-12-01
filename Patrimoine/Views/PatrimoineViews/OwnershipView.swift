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
    private let title        : String
    let updateSharedValues : () -> () // methode permettant de mettre à jour les valeurs
    private let index        : Int
    @Binding var owners      : Owners
    @State private var owner : Owner
    
    var body: some View {
        GroupBox(label: Text(title)) {
            VStack {
                HStack {
                    Text(owner.name)
                    Spacer()
                    Text(String(owner.age) + " ans")
                }.padding(.top, 8)
                
                HStack {
                    Stepper(value: $owner.fraction,
                            in: 0.0...100.0,
                            step: 5.0,
                            onEditingChanged:
                                { started in
                                    if !started {
                                        // mettre à jour la liste contenant le owner pour forcer l'update de la View
                                        owners[index].fraction = owner.fraction
                                        // mettre à jour les valeurs en conséquence
                                        updateSharedValues()
                                    }
                                },
                            label:
                                {
                                    Text("Fraction détenue: ") +
                                        Text((owner.fraction).percentString() + " %")
                                        .bold()
                                        .foregroundColor(percentagesOk() ? .blue : .red)
                                })
                        .frame(width: 300, alignment: .leading)
                    Spacer()
                    Text("Valeur détenue: ") + Text(owner.ownedValue.€String).bold()
                }
            }
            .padding(.leading)
        }
        .groupBoxStyle(DefaultGroupBoxStyle())
    }
    
    internal init(title              : String,
                  owner              : Owner,
                  owners             : Binding<Owners>,
                  updateSharedValues : @escaping () -> ()) {
        self.title   = title
        self._owner  = State(initialValue : owner)
        self._owners = owners
        self.index   = owners.wrappedValue.firstIndex(of: owner)!
        self.updateSharedValues = updateSharedValues
    }
    
    func percentagesOk() -> Bool {
        owners.sumOfOwnedFractions == 100.0
    }
    
}

struct OwnersListView : View {
    @EnvironmentObject var family: Family
    let title                    : String
    let updateSharedValues       : () -> () // methode permettant de mettre à jour les valeurs
    @Binding var owners          : Owners
    @State private var alertItem : AlertItem?
    @State private var name      : String = ""

    var body: some View {
        List {
            Text(family.members.first!.displayName)
            ForEach(owners, id: \.self) { owner in
                OwnerGroupBox(title  : title,
                              owner  : owner,
                              owners : $owners,
                              updateSharedValues: updateSharedValues)
            }
            .onDelete(perform: deleteOwner)
            .onMove(perform: moveOwners)
            AmountView(label: "Total " + title + "s", amount: owners.sumOfOwnedValues)
        }
        .navigationTitle(title+"s")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                EditButton()
            }
            ToolbarItem(placement: .automatic) {
                Menu(content: menuContents, label: menuLabel)
            }
        }
        .onChange(of: name, perform: addOwner)
        .alert(item: $alertItem, content: myAlert)
    }
    
    func addOwner(newPersonName: String) {
        let newPerson    = family.member(withName: newPersonName)
        let newPersonAge = newPerson?.age(atEndOf: Date.now.year)
        let newOwner     = Owner(name: newPersonName, age: newPersonAge!, fraction: 0.0, ownedValue: 0.0)
        // ajouter le nouveau copropriétaire
        owners.append(newOwner)
        // et recalculculer les valeurs de chaque personne en conséquence
//        owners.updateOwnersFraction(updateSharedValues: {
//            updateSharedValues()
//        } )
    }
    
    func deleteOwner(at offsets: IndexSet) {
        // Empêcher de supprimer la dernière personne
        guard owners.count > 1 else {
            self.alertItem = AlertItem(title         : Text("Il doit y a voir au moins un " + title),
                                       dismissButton : .default(Text("OK")))
            return
        }
        // retirer la personne de la liste
        owners.remove(atOffsets: offsets)
        // Réattribuer les % de la personne supprimée aux personnes restantes
        // et recalculculer les valeurs de chaque personne en conséquence
//        owners.updateOwnersFraction(updateSharedValues: {
//            updateSharedValues()
//        } )
        
        // TODO: - Demander à l'utilisateur de mettre à jour les % manuellement
    }
    
    func moveOwners(from indexes: IndexSet, to destination: Int) {
        owners.move(fromOffsets: indexes, toOffset: destination)
    }
    
    func isAnOwner(_ name: String) -> Bool {
        owners.contains(where: { $0.name == name })
    }
    
    @ViewBuilder func menuLabel() -> some View {
        Image(systemName: "plus")
            .imageScale(.large)
            .padding()
    }
    
    @ViewBuilder func menuContents() -> some View {
        Picker(selection: $name, label: Text("Personne")) {
            ForEach(family.members.filter { !isAnOwner($0.displayName) }) { person in
                PersonNameRow(member: person)
            }
        }
    }
}

struct OwnershipView: View {
    @EnvironmentObject var family: Family
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
                                                               owners             : $ownership.usufructOwners).environmentObject(family)) {
                        AmountView(label  : usufruitierStr+"s",
                                   amount : ownership.usufructOwners.sumOfOwnedValues)
                            .foregroundColor(.blue)
                    }
                    NavigationLink(destination: OwnersListView(title              : nuPropStr,
                                                               updateSharedValues : { ownership.updateSharedValues() },
                                                               owners             : $ownership.bareOwners).environmentObject(family)) {
                        AmountView(label  : nuPropStr+"s",
                                   amount : ownership.bareOwners.sumOfOwnedValues)
                            .foregroundColor(.blue)
                    }
                }.padding(.leading)
                
            } else {
                /// pleine propriété
                NavigationLink(destination: OwnersListView(title              : proprietaireStr,
                                                           updateSharedValues : {
                                                            ownership.updateSharedValues()
                                                           },
                                                           owners             : $ownership.fullOwners).environmentObject(family)) {
                    AmountView(label  : proprietaireStr+"s",
                               amount : ownership.fullOwners.sumOfOwnedValues)
                        .foregroundColor(.blue)
                }.padding(.leading)
            }
        }
        .onAppear(perform: { ownership.updateSharedValues() })
    }
}

struct OwnershipView_Previews: PreviewProvider {
    static var family  = Family()

    struct Container: View {
        @State var ownership: Ownership
        @StateObject var family = Family()

        var body: some View {
            VStack {
                Button("incrémenter Valeur", action: { ownership.totalValue += 100.0})
                Form {
                    OwnershipView(ownership: $ownership)
                        .environmentObject(family)
                }
            }
        }
    }
    
    static var previews: some View {
        Group {
            //ExampleView()
            NavigationView() {
                Form {
                    OwnershipView(ownership: .constant(Ownership()))
                        .environmentObject(family)
                }
            }
            .previewDevice("iPhone Xs")
            
            NavigationView() {
                Container(ownership: Ownership(totalValue: 100.0))
            }
        }
    }
}
