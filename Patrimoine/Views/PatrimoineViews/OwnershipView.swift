//
//  OwnershipView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 29/11/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct OwnerGroupBox: View {
    private let title        : String
    private let index        : Int
    @Binding var owners      : Owners
    @State private var owner : Owner
    
    var body: some View {
        GroupBox(label: Text(title)) {
            VStack {
                Label(owner.name, systemImage: "person.fill").padding(.top, 8)
                Stepper(value: $owner.fraction,
                        in: 0.0...100.0,
                        step: 5.0,
                        onEditingChanged:
                            { started in
                                if !started {
                                    // mettre à jour la liste contenant le owner pour forcer l'update de la View
                                    owners[index].fraction = owner.fraction
                                }
                            },
                        label:
                            {
                                Text("Fraction détenue: ") +
                                    Text((owner.fraction).percentString() + " %")
                                    .bold()
                                    .foregroundColor(owners.percentageOk ? .blue : .red)
                            })
                    .frame(maxWidth: 300)
            }
            .padding(.leading)
        }
        .groupBoxStyle(DefaultGroupBoxStyle())
    }
    
    internal init(title              : String,
                  owner              : Owner,
                  owners             : Binding<Owners>) {
        self.title   = title
        self._owner  = State(initialValue : owner)
        self._owners = owners
        self.index   = owners.wrappedValue.firstIndex(of: owner)!
    }
}

struct OwnersListView : View {
    @EnvironmentObject var family: Family
    let title                    : String
    @Binding var owners          : Owners
    @State private var alertItem : AlertItem?
    @State private var name      : String = ""
    
    var body: some View {
        List {
            if owners.isEmpty {
                Text("Ajouter des " + title + " à l'aide du bouton '+'").foregroundColor(.red)
            } else {
                ForEach(owners, id: \.self) { owner in
                    OwnerGroupBox(title  : title,
                                  owner  : owner,
                                  owners : $owners)
                }
                .onDelete(perform: deleteOwner)
                .onMove(perform: moveOwners)
                PercentView(label: "Total " + title + "s (doit être de 100%)", percent: owners.sumOfOwnedFractions / 100.0)
                    .foregroundColor(owners.isvalid ? .blue : .red)
            }
        }
        .navigationTitle(title+"s")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                EditButton()
            }
            ToolbarItem(placement: .automatic) {
                Menu(content: menuAdd, label: menuAddLabel)
            }
        }
        .onChange(of: name, perform: addOwner)
        .onAppear(perform: checkPercentageOfOwnership)
        .alert(item: $alertItem, content: myAlert)
    }
    
    func checkPercentageOfOwnership() {
        if !owners.isEmpty && !(owners.sumOfOwnedFractions == 100.0) {
            self.alertItem = AlertItem(title         : Text("Vérifier la part en % de chaque " + title),
                                       dismissButton : .default(Text("OK")))
        }
    }

    func addOwner(newPersonName: String) {
        // ajouter le nouveau copropriétaire
        let newOwner = Owner(name: newPersonName, fraction: owners.isEmpty ? 100.0 : 0.0)
        owners.append(newOwner)
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
        
        if owners.count == 1 {
            owners[0].fraction = 100.0
        } else {
            // demander à l'utilisateur de mettre à jour les % manuellement
            self.alertItem = AlertItem(title         : Text("Vérifier la part en % de chaque " + title),
                                       dismissButton : .default(Text("OK")))
        }
    }
    
    func moveOwners(from indexes: IndexSet, to destination: Int) {
        owners.move(fromOffsets: indexes, toOffset: destination)
    }
    
    func isAnOwner(_ name: String) -> Bool {
        owners.contains(where: { $0.name == name })
    }
    
    @ViewBuilder func menuAddLabel() -> some View {
        Image(systemName: "plus")
            .imageScale(.large)
            .padding()
    }
    
    @ViewBuilder func menuAdd() -> some View {
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
                    NavigationLink(destination: OwnersListView(title  : usufruitierStr,
                                                               owners : $ownership.usufructOwners).environmentObject(family)) {
                        if ownership.isvalid {
                            PercentView(label  : usufruitierStr+"s",
                                        percent : ownership.demembrementPercentage(atEndOf: Date.now.year).usufructPercent / 100.0)
                                .foregroundColor(.blue)
                        } else {
                            if !ownership.usufructOwners.isEmpty && ownership.usufructOwners.isvalid {
                                Text(usufruitierStr+"s").foregroundColor(.blue)
                            } else {
                                Text(usufruitierStr+"s").foregroundColor(.red)
                            }
                        }
                    }
                    NavigationLink(destination: OwnersListView(title  : nuPropStr,
                                                               owners : $ownership.bareOwners).environmentObject(family)) {
                        if ownership.isvalid {
                            PercentView(label  : nuPropStr+"s",
                                        percent : ownership.demembrementPercentage(atEndOf: Date.now.year).bareValuePercent / 100.0)
                                .foregroundColor(.blue)
                        } else {
                            if !ownership.bareOwners.isEmpty && ownership.bareOwners.isvalid  {
                                Text(nuPropStr+"s").foregroundColor(.blue)
                            } else {
                                Text(nuPropStr+"s").foregroundColor(.red)
                            }
                        }
                    }
                }.padding(.leading)
                
            } else {
                /// pleine propriété
                NavigationLink(destination: OwnersListView(title  : proprietaireStr,
                                                           owners : $ownership.fullOwners).environmentObject(family)) {
                    Text(proprietaireStr+"s")
                        .foregroundColor(ownership.isvalid ? .blue : .red)
                }.padding(.leading)
            }
        }
    }
}

struct OwnershipView_Previews: PreviewProvider {
    static var family  = Family()

    static func ageOf(_ name: String, _ year: Int) -> Int {
        let person = family.member(withName: name)
        return person?.age(atEndOf: Date.now.year) ?? -1
    }
    
    struct Container: View {
        @State var ownership  : Ownership
        @State var totalValue : Double = 100.0

        var body: some View {
            VStack {
                Button("incrémenter Valeur", action: { totalValue += 100.0})
                Form {
                    OwnershipView(ownership: $ownership)
                        .environmentObject(family)
                    ForEach(OwnershipView_Previews.family.members) { member in
                        AmountView(label: member.displayName,
                                   amount: ownership.ownedValue(by     : member.displayName,
                                                                ofValue: 100.0,
                                                                atEndOf: Date.now.year,
                                                                evaluationMethod: .ifi) )
                    }
                }
            }
        }
    }
    
    static var previews: some View {
        Group {
            NavigationView() {
                Form {
                    OwnershipView(ownership: .constant(Ownership(ageOf: ageOf)))
                        .environmentObject(family)
                }
            }
            .previewDevice("iPhone Xs")
            
            NavigationView() {
                Container(ownership: Ownership(ageOf: ageOf))
            }
            .preferredColorScheme(.dark)
        }
    }
}
