import Foundation
import TypePreservingCodingAdapter // https://github.com/IgorMuzyka/Type-Preserving-Coding-Adapter.git

// MARK: - Class Family: la Famille, ses membres, leurs actifs et leurs revenus

/// la Famille, ses membres, leurs actifs et leurs revenus
final class Family: ObservableObject, CustomStringConvertible {
    
    // MARK: - Properties
    
    // structure de la famille
    @Published private(set) var members: [Person] 
    // dépenses
    @Published var expenses: LifeExpensesDic
    // revenus
    var workNetIncome    : Double { // computed
        var netIcome : Double = 0.0
        for person in members {
            if let adult = person as? Adult {netIcome += adult.workNetIncome}
        }
        return netIcome
    }
    var workTaxableIncome: Double { // computed
        var taxableIncome : Double = 0.0
        for person in members {
            if let adult = person as? Adult {taxableIncome += adult.workTaxableIncome}
        }
        return taxableIncome
    }
    // coefficient familial
    var familyQuotient   : Double { // computed
        Fiscal.model.incomeTaxes.familyQuotient(nbAdults: nbOfAdults, nbChildren: nbOfChildren)
    }
    // impots
    var irpp             : Double { // computed
        Fiscal.model.incomeTaxes.irpp(taxableIncome: workTaxableIncome, nbAdults: nbOfAdults, nbChildren: nbOfChildren)
    }
    var description      : String {
        return members.debugDescription + "\n"
    }
    
    var nbOfChildren     : Int { // computed
        var nb = 0
        for person in members {
            if person is Child {nb += 1}
        }
        return nb
    }
    var nbOfAdults       : Int { // computed
        var nb = 0
        for person in members {
            if person is Adult {nb += 1}
        }
        return nb
    }
    
    // MARK: - Initialization

    init() {
        // initialiser les membres de la famille à partir du fichier JSON
        self.members  = Family.loadMembersFromFile()
        // initialiser les catégories de dépenses à partir des fichiers JSON
        self.expenses = LifeExpensesDic()
        // injection de family dans la propriété statique de Expense pour lier les évenements à des personnes
        LifeExpense.family = self
        // injection de family dans la propriété statique de Person pour lier les évenements à des personnes
        Person.family = self
    }
    
    // MARK: - Methodes
    
    /// Rend l'époux d'un adult de la famille (s'il existe)
    /// - Parameter member: membre adult de la famille
    /// - Returns: époux  (s'il existe)
    func spouseOf(_ member: Adult) -> Adult? {
        for person in members {
            if let adult = person as? Adult {
                if adult != member { return adult }
            }
        }
        return nil
    }
    
    /// Nombre d'enfant dans le foyer fiscal
    /// - Parameter year: année
    func nbOfFiscalChildren(during year: Int) -> Int {
        var nb = 0
        for person in members {
            if let child = person as? Child {
                if !child.isIndependant(during: year) {nb += 1}
            }
        }
        return nb
    }
    
    /// Nombre d'adulte vivant à la fin de l'année
    /// - Parameter year: année
    func nbOfAdultAlive(atEndOf year: Int) -> Int {
        var nb = 0
        for person in members {
            if let adult = person as? Adult {
                if adult.isAlive(atEndOf: year) {nb += 1}
            }
        }
        return nb
    }
    
    /// Revenus du tavail cumulés de la famille durant l'année
    /// - Parameter year: année
    /// - Parameter netIncome: revenu net de charges et d'assurance (à vivre)
    /// - Parameter taxableIncome: Revenus du tavail cumulés imposable à l'IRPP
    func income(during year: Int) -> (netIncome: Double, taxableIncome: Double) {
        var totalNetIncome     : Double = 0.0
        var totalTaxableIncome : Double = 0.0
        for person in members {
            if let adult = person as? Adult {
                let income = adult.workIncome(during: year)
                totalNetIncome     += income.net
                totalTaxableIncome += income.taxableIrpp
            }
        }
        return (totalNetIncome, totalTaxableIncome)
    }
    
    /// Quotien familiale durant l'année
    /// - Parameter year: année
    func familyQuotient (during year: Int) -> Double {
        Fiscal.model.incomeTaxes.familyQuotient(nbAdults: nbOfAdultAlive(atEndOf: year), nbChildren: nbOfFiscalChildren(during: year))
    }
    
    /// IRPP sur les revenus du travail de la famille
    /// - Parameter year: année
    func irpp (for year: Int) -> Double {
        Fiscal.model.incomeTaxes.irpp(
            // FIXME: A CORRIGER pour prendre en compte tous les revenus imposable
            taxableIncome : income(during : year).taxableIncome, // A CORRIGER
            nbAdults      : nbOfAdultAlive(atEndOf    : year),
            nbChildren    : nbOfFiscalChildren(during : year))
    }
    
    /// Pensions de retraite cumulées de la famille durant l'année
    /// - Parameter year: année
    /// - Returns: Pensions de retraite cumulées brutes
    func pension(during year: Int, withReversion: Bool = true) -> Double {
        var pension = 0.0
        for person in members {
            if let adult = person as? Adult {
                pension += adult.pension(during        : year,
                                         withReversion : withReversion).brut
            }
        }
        return pension
    }
    
    /// Mettre à jour le nombre d'enfant de chaque parent de la famille
    func updateChildrenNumber() {
        for member in members { // pour chaque membre de la famille
            if let adult = member as? Adult { // si c'est un parent
                adult.gaveBirthTo(children: nbOfChildren) // mettre à jour le nombre d'enfant
            }
        }

    }
    
    /// Trouver le membre de la famille avec le displayName recherché
    /// - Parameter name: displayName recherché
    /// - Returns: membre de la famille trouvé ou nil
    func member(withName name: String) -> Person? {
        self.members.first(where: { $0.displayName == name })
    }
    
    /// Ajouter un membre à la famille
    /// - Parameter person: personne à ajouter
    func addMember(_ person: Person) {
        // ajouter le nouveau membre
        members.append(person)
        
        // mettre à jour le nombre d'enfant de chaque parent de la famille
        updateChildrenNumber()
        
        // sauvegarder les membres de la famille dans le fichier
        storeMembersToFile()
    }
    
    func deleteMembers(at offsets: IndexSet) {
        // retirer les membres
        members.remove(atOffsets: offsets)
        
        // mettre à jour le nombre d'enfant de chaque parent de la famille
        updateChildrenNumber()
        
        // sauvegarder les membres de la famille dans le fichier
        storeMembersToFile()
    }
    
    func moveMembers(from indexes: IndexSet, to destination: Int) {
        self.members.move(fromOffsets: indexes, toOffset: destination)
        
        // mettre à jour le nombre d'enfant de chaque parent de la famille
        self.updateChildrenNumber()
        
        self.storeMembersToFile()
    }
    
    func aMemberIsUpdated() {
        // mettre à jour le nombre d'enfant de chaque parent de la famille
        self.updateChildrenNumber()
        
        // sauvegarder les membres de la famille dans le fichier
        self.storeMembersToFile()

    }
    
    private func storeMembersToFile() {
        // encoder
        if let encoded = try? Person.coder.encoder.encode(members.map { Wrap(wrapped: $0) }) {
            // find file's URL
            let fileName = FileNameCst.familyMembersFileName
            guard let url = Bundle.main.url(forResource: fileName, withExtension: nil) else {
                fatalError("Failed to locate \(fileName) in bundle.")
            }
            // impression debug
            #if DEBUG
            Swift.print("saving members (Person) to file: ", url)
            #endif
            if let jsonString = String(data: encoded, encoding: .utf8) {
                #if DEBUG
                Swift.print(jsonString)
                #endif
            } else {
                Swift.print("failed to convert 'family.members' encoded data to string.")
            }
            do {
                // sauvegader les données
                try encoded.write(to: url, options: [.atomicWrite])
            } catch {
                fatalError("Failed to save data to '\(fileName)' in documents directory.")
            }
        } else {
            fatalError("Failed to encode 'family.members' to JSON format.")
        }
    }
    
    static func loadMembersFromFile() -> [Person] {
        //        Bundle.main.decode([Person].self,
        //                           from: FileNameCst.familyMembersFileName,
        //                           dateDecodingStrategy: .iso8601)
        //            return getDocumentsDirectory().decode([Person].self,
        //                                           from: FileNameCst.familyMembersFileName,
        //                                           dateDecodingStrategy: .iso8601)
        
        // find file's URL
        let fileName = FileNameCst.familyMembersFileName
        // let url = getDocumentsDirectory().appendingPathComponent(fileName, isDirectory: false)
        guard let url = Bundle.main.url(forResource: fileName, withExtension: nil) else {
            fatalError("Failed to locate \(fileName) in bundle.")
        }
        #if DEBUG
        Swift.print("loading members (Person) from file: ", url)
        #endif
                
        // load data from URL
        guard let data = try? Data(contentsOf: url) else {
            fatalError("Failed to load \(url) in documents directory.")
        }
        
        // decode object back and unwrap them force casting to a common ancestor type
        do {
            return try Person.coder.decoder.decode([Wrap].self, from: data).map { $0.wrapped as! Person }
        } catch DecodingError.keyNotFound(let key, let context) {
            fatalError("Failed to decode \(fileName) in documents directory due to missing key '\(key.stringValue)' not found – \(context.debugDescription)")
        } catch DecodingError.typeMismatch(_, let context) {
            fatalError("Failed to decode \(fileName) in documents directory due to type mismatch – \(context.debugDescription)")
        } catch DecodingError.valueNotFound(let type, let context) {
            fatalError("Failed to decode \(fileName) in documents directory due to missing \(type) value – \(context.debugDescription)")
        } catch DecodingError.dataCorrupted(let context) {
            fatalError("Failed to decode \(fileName) in documents directory because it appears to be invalid JSON – \(context.codingPath)–  \(context.debugDescription)")
        } catch {
            fatalError("Failed to decode \(fileName) in documents directory: \(error.localizedDescription)")
        }
    }
    
    func print() {
        Swift.print("FAMILLE:")
        Swift.print("  number of adults in the family:", nbOfAdults)
        Swift.print("  number of children in the family:", nbOfChildren)
        Swift.print("  family members:")
        for person in members {
            person.print()
        }
        Swift.print("  family net income:    ",workNetIncome,"euro")
        Swift.print("  family taxable income:",workTaxableIncome,"euro")
        Swift.print("  family income tax quotient:",familyQuotient)
        Swift.print("  family income taxes:",irpp,"euro")
        // investissement périodiques
        //        Swift.print("  Periodic investements: \(periodicInvests.count)")
        //        for periodicInvestment in periodicInvests { periodicInvestment.print() }
        //        // investissement libres
        //        Swift.print("  Free investements: \(freeInvests.count)")
        //        for freeInvestement in freeInvests { freeInvestement.print() }
        //        // investissement biens immobiliers
        //        Swift.print("  Real estate assets: \(realEstateAssets.count)")
        //        for asset in realEstateAssets { asset.print() }
        //        // investissement SCPI
        //        Swift.print("  SCPI: \(scpis.count)")
        //        for scpi in scpis { scpi.print() }
        //        // SCI
        //        sci.print()
        //        // Emprunts
        //        Swift.print("  Emprunts: \(loans.count)")
        //        for loan in loans { loan.print() }
        //        // Dettes
        //        Swift.print("  Dettes: \(debts.count)")
        //        for debt in debts { debt.print() }
        //        // Dépenses
        //        Swift.print("  Expenses: \(listOfexpenses.expenses.count)")
        //        for expense in listOfexpenses.expenses { expense.print() }
    }
}
