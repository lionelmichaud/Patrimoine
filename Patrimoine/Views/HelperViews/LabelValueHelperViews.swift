//
//  LabelValueHelpersView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 23/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import Combine

struct LabeledValueRowView: View {
    @Binding var colapse: Bool
    let label           : String
    let value           : Double
    let indentLevel     : Int
    let header          : Bool
    
    var body: some View {
        HStack {
            if header {
                // bouton pour déplier / replier la liste
                Button(action: {
                    self.colapse.toggle()
                },
                label: {
                    Image(systemName: "chevron.right.2")
                        .foregroundColor(.accentColor)
                        //.imageScale(.large)
                        .rotationEffect(.degrees(colapse ? 0 : 90))
                        //.scaleEffect(colapse ? 1 : 1.5)
                        //.padding()
                        .animation(.easeInOut)
                } )
                Text(label)
                    .font(Font.system(size: ListTheme[indentLevel].labelFontSize,
                                      design: Font.Design.default))
                    .fontWeight(.bold)
                
            } else {
                HStack {
                    // symbol document en tête de ligne
                    Image(systemName: "doc")
                        .imageScale(.large)
                    //.font(Font.title.weight(.semibold))
                    Text(label)
                        .font(Font.system(size: ListTheme[indentLevel].labelFontSize,
                                          design: Font.Design.default))
                }
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

// MARK: - Saisie d'un montant en €
struct AmountEditView: View {
    let label            : String
    @Binding var amount  : Double
    @State var textAmount: String
    
    var body: some View {
        let textValueBinding = Binding<String>(
            get: {
                self.textAmount
            },
            set: {
                self.textAmount = $0
                // actualiser la valeur numérique
                self.amount = Double($0) ?? 0
            })
        
        return HStack {
            Text(label)
            Spacer()
            TextField("montant",
                      text: textValueBinding)
                //.textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(maxWidth: 88)
                .keyboardType(.numbersAndPunctuation)
                .multilineTextAlignment(.trailing)
                .onReceive(Just(textAmount)) { newValue in
                    // FIXME: ne filtre pas correctement
                    // filtrer les caractères non numériques
                    let filtered = newValue.filter { "-0123456789".contains($0) }
                    if filtered != newValue {
                        self.textAmount = filtered
                    }
                }
            Text("€")
        }
        .textFieldStyle(RoundedBorderTextFieldStyle())
    }
    
    init(label: String, amount: Binding<Double>) {
        self.label  = label
        _amount     = amount
        _textAmount = State(initialValue: amount.wrappedValue.roundedString)
    }
    
}

// MARK: - Affichage d'un montant en €
struct AmountView: View {
    let label   : String
    let amount  : Double
    let weight  : Font.Weight
    let comment : String?
    
    var body: some View {
        HStack {
            Text(label)
                .fontWeight(weight)
            Spacer()
            if comment != nil { Text(comment!).foregroundColor(.secondary) }
            Text(value€Formatter.string(from: amount as NSNumber) ?? "")
                .fontWeight(weight)
                .frame(maxWidth: 100, alignment: .trailing)
        }
    }
    
    init(label: String, amount: Double, weight: Font.Weight = .regular, comment: String? = nil) {
        self.label   = label
        self.amount  = amount
        self.weight  = weight
        self.comment = comment
    }
}

// MARK: - Saisie d'un Integer
struct IntegerEditView: View {
    let label            : String
    @Binding var integer : Int
    @State var textAmount: String
    
    var body: some View {
        let textValueBinding = Binding<String>(get: {
            self.textAmount
        }, set: {
            self.textAmount = $0
            // actualiser la valeur numérique
            self.integer = Int($0) ?? 0
        })
        
        return HStack {
            Text(label)
            Spacer()
            TextField("entier",
                      text: textValueBinding)
                //.textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(maxWidth: 88)
                .keyboardType(.numbersAndPunctuation)
                .multilineTextAlignment(.trailing)
                .onReceive(Just(textAmount)) { newValue in
                    // FIXME: ne filtre pas correctement
                    // filtrer les caractères non numériques
                    let filtered = newValue.filter { "-0123456789".contains($0) }
                    if filtered != newValue {
                        self.textAmount = filtered
                    }
                }
        }
        .textFieldStyle(RoundedBorderTextFieldStyle())
    }
    
    init(label: String, integer: Binding<Int>) {
        self.label  = label
        _integer    = integer
        _textAmount = State(initialValue: String(integer.wrappedValue))
    }
    
}

// MARK: - Affichage d'un Integer
struct IntegerView: View {
    let label   : String
    let integer : Int
    let weight  : Font.Weight
    let comment : String?
    
    var body: some View {
        HStack {
            Text(label)
                .fontWeight(weight)
            Spacer()
            if comment != nil { Text(comment!).foregroundColor(.secondary) }
            Text(String(integer))
                .fontWeight(weight)
                .frame(maxWidth: 100, alignment: .trailing)
        }
    }
    
    init(label: String, integer: Int, weight: Font.Weight = .regular, comment: String? = nil) {
        self.label   = label
        self.integer = integer
        self.weight  = weight
        self.comment = comment
    }
}


// MARK: - Saisie d'un pourcentage %
struct PercentEditView: View {
    private let label     : String
    @Binding var percent  : Double
    @State var textPercent: String
    
    var body: some View {
        let textValueBinding = Binding<String>(get: {
            self.textPercent
        }, set: {
            self.textPercent = $0
            // actualiser la valeur numérique
            self.percent = Double($0) ?? 0
        })
        
        return HStack {
            Text(label)
            Spacer()
            TextField("montant",
                      text: textValueBinding)
                //.textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(maxWidth: 88)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .onReceive(Just(textPercent)) { newValue in
                    // filtrer les caractères non numériques
                    let filtered = newValue.filter { "0123456789.,".contains($0) }
                    if filtered != newValue {
                        self.textPercent = filtered
                    }
                }
            Text("%")
        }
        .textFieldStyle(RoundedBorderTextFieldStyle())
    }
    
    init(label: String, percent: Binding<Double>) {
        self.label  = label
        _percent     = percent
        _textPercent = State(initialValue: percent.wrappedValue.percentString(digit: 2))
    }
}

// MARK: - Affichage d'un pourcentage %
struct PercentView: View {
    let label   : String
    let percent : Double
    let comment : String?
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            if comment != nil { Text(comment!).foregroundColor(.secondary) }
            Text(percentFormatter.string(from: percent as NSNumber) ?? "??")
                .frame(maxWidth: 100, alignment: .trailing)
        }
    }
    
    init(label: String, percent : Double, comment: String? = nil) {
        self.label   = label
        self.percent = percent
        self.comment = comment
    }
}

// MARK: - Saisie d'un text "TextEditor"
struct LabeledTextEditor : View {
    let label         : String
    let labelWidth    : Int
    @Binding var text : String
    
    var body: some View {
        HStack{
            Text(label)
                .frame(width: CGFloat(labelWidth), alignment: .leading)
            TextEditor(text: $text)
                .border(Color("borderTextColor"), width: 1)
        }
    }
    
    init(label       : String,
         labelWidth  : Int = 70,
         text        : Binding<String>) {
        self.label       = label
        self.labelWidth  = labelWidth > 0 ? labelWidth : 70
        self._text       = text
    }
}

// MARK: - Saisie d'un text "TextField"
struct LabeledTextField : View {
    let label         : String
    let labelWidth    : Int
    let defaultText   : String?
    @Binding var text : String
    
    var body: some View {
        HStack{
            Text(label)
                .frame(width: CGFloat(labelWidth), alignment: .leading)
            TextField(defaultText ?? "", text: $text)
        }
    }
    
    init(label       : String,
         labelWidth  : Int = 70,
         defaultText : String?  = nil,
         text        : Binding<String>) {
        self.label       = label
        self.labelWidth  = labelWidth > 0 ? labelWidth : 70
        self.defaultText = defaultText
        self._text       = text
    }
    
}

// MARK: - Affichage d'un text "text"
struct LabeledText: View {
    let label : String
    let text  : String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(text)
        }
    }
    
    init(label: String, text : String, comment: String? = nil) {
        self.label   = label
        self.text    = text
    }
}

// MARK: - Saisie d'un intervalle de Dates
struct DateRangeEditView: View {
    let fromLabel         : String
    @Binding var fromDate : Date
    let toLabel           : String
    @Binding var toDate   : Date
    let `in`              : ClosedRange<Date>?
    
    var body: some View {
        VStack {
            if `in` != nil {
                // contraintes sur la plage de dates
                DatePicker(selection           : $fromDate,
                           in                  : `in`!.lowerBound...`in`!.upperBound,
                           displayedComponents : .date,
                           label               : { Text(fromLabel) })
                
                DatePicker(selection           : $toDate,
                           in                  : max(fromDate,`in`!.lowerBound)...Date.distantFuture,
                           displayedComponents : .date,
                           label               : { Text(toLabel) })
            } else {
                DatePicker(selection           : $fromDate,
                           displayedComponents : .date,
                           label               : { Text(fromLabel) })
                
                DatePicker(selection           : $toDate,
                           displayedComponents : .date,
                           label               : { Text(toLabel) })
            }
        }
    }
}

// MARK: - Tests & Previews

struct TestView: View {
    var body: some View {
        List {
            LabeledValueRowView(colapse: .constant(false),
                                label: "Level 0",
                                value: 12345,
                                indentLevel: 0,
                                header: true)
            LabeledValueRowView(colapse: .constant(false),
                                label: "level 1",
                                value: 12345,
                                indentLevel: 1,
                                header: true)
            LabeledValueRowView(colapse: .constant(false),
                                label: "Level 2",
                                value: 12345,
                                indentLevel: 2,
                                header: true)
            LabeledValueRowView(colapse: .constant(false),
                                label: "Level 3",
                                value: 12345,
                                indentLevel: 3,
                                header: true)
            LabeledValueRowView(colapse: .constant(true),
                                label: "Level 4",
                                value: 12345,
                                indentLevel: 3,
                                header: false)
        }
    }
}

struct TextView_Previews: View {
    var body: some View {
        Group {
            LabeledText(label: "Label", text: "Text", comment: "Comment")
                .previewDisplayName("LabeledText")
            LabeledTextField(label: "Label", labelWidth: 70, defaultText: "Obligatoire", text: .constant("text"))
                .previewDisplayName("LabeledTextField")
            LabeledTextEditor(label: "Label", labelWidth: 70, text: .constant("text"))
        }
    }
}
struct LabelValueHelpersView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TestView().colorScheme(.dark)
                .previewDisplayName("LabeledValueRowView")
            TestView().colorScheme(.light)
                .previewDisplayName("LabeledValueRowView")
            IntegerView(label: "Label", integer: 4)
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding([.bottom, .top])
                .previewDisplayName("IntegerView")
            IntegerEditView(label: "Label", integer: .constant(4))
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding([.bottom, .top])
                .previewDisplayName("IntegerEditView")
            PercentView(label: "Label", percent: 4)
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding([.bottom, .top])
                .previewDisplayName("PercentView")
            PercentEditView(label: "Label", percent: .constant(4.9))
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding([.bottom, .top])
                .previewDisplayName("PercentEditView")
            AmountView(label: "Label", amount: 1234.3)
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding([.bottom, .top])
                .previewDisplayName("AmountView")
            AmountEditView(label: "Label", amount: .constant(1234.3))
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding([.bottom, .top])
                .previewDisplayName("AmountEditView")
            DateRangeEditView(fromLabel: "Label1",
                              fromDate: .constant(Date.now),
                              toLabel: "Label2",
                              toDate: .constant(Date.now),
                              in: 1.months.ago!...3.years.fromNow!)
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding([.bottom, .top])
                .previewDisplayName("DateRangeEditView")
            TextView_Previews()
        }
    }
}

// MARK: - Library Views

struct LabelValueHelpersView_Library: LibraryContentProvider {
    @LibraryContentBuilder
    var views: [LibraryItem] {
        let integer = 4
        let percent = 4.0
        let amount = 1000.0
        LibraryItem(IntegerView(label: "Label", integer: integer),
                    title: "Integer View",
                    category: .control,
                    matchingSignature: "intview")
        LibraryItem(IntegerEditView(label: "Label", integer: .constant(4)),
                    title: "Integer Edit View",
                    category: .control,
                    matchingSignature: "inteditview")
        LibraryItem(PercentView(label: "Label", percent: percent),
                    title: "Percent View",
                    category: .control,
                    matchingSignature: "pctview")
        LibraryItem(PercentEditView(label: "Label", percent: .constant(4.9)),
                    title: "Percent Edit View",
                    category: .control,
                    matchingSignature: "pcteditview")
        LibraryItem(AmountView(label: "Label", amount: amount),
                    title: "Amount View",
                    category: .control,
                    matchingSignature: "amountview")
        LibraryItem(AmountEditView(label: "Label", amount: .constant(1234.3)),
                    title: "Amount Edit View",
                    category: .control,
                    matchingSignature: "amounteditview")
        LibraryItem(LabeledText(label: "Label", text: "Text", comment: "Comment"),
                    title: "Labeled Text",
                    category: .control,
                    matchingSignature: "labeltext")
        LibraryItem(LabeledTextField(label: "Label", labelWidth: 70, defaultText: "Obligatoire", text: .constant("text")),
                    title: "Labeled TextField",
                    category: .control,
                    matchingSignature: "labeltextfield")
        LibraryItem(LabeledTextEditor(label: "Label", labelWidth: 70, text: .constant("text")),
                    title: "Labeled TextEditor",
                    category: .control,
                    matchingSignature: "labeltexteditor")
        LibraryItem(DateRangeEditView(fromLabel: "Label1",
                                      fromDate: .constant(Date.now),
                                      toLabel: "Label2",
                                      toDate: .constant(Date.now),
                                      in: 1.months.ago!...3.years.fromNow!),
                    title: "Date Range Edit View",
                    category: .control,
                    matchingSignature: "daterange")
    }
}
