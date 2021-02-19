//
//  RealEstateCapitalGainTaxesModel.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 14/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Charges sociales sur plus-values immobilières
struct RealEstateCapitalGainTaxesModel: Codable {
    
    // MARK: - Nested types
    
    // tranche de barême de l'IRPP
    struct ExonerationSlice: Codable {
        let floor        : Int    // 0 // year
        let discountRate : Double // 0.0 // % par année de détention au-delà de floor
        let prevDiscount : Double // 0.0 // % cumul des tranches précédentes
    }
    
    struct Model: BundleCodable, Versionable {
        static var defaultFileName : String = "RealEstateCapitalGainTaxesModel.json"
        var version         : Version
        let discountTravaux : Double // 15 // %
        let discountAfter   : Int // 5 // ans
        let exoGrid         : [ExonerationSlice]
        let CRDS            : Double // 0.5 // %
        let CSG             : Double // 9.2 // %
        let prelevSocial    : Double // 7.5 // %
        var total           : Double {
            CRDS + CSG + prelevSocial // %
        }
    }
    
    // MARK: - Properties
    
    var model: Model
    
    // MARK: - Methods
    
    /**
     Charges sociales dûes sur la plus-value immobilièrae
     La plus-value est taxée au titre de l’impôt sur le revenu au taux forfaitaire actuel de 19 % (avec un abattement linéaire de 6 % à partir de la 6ème année)
     et au titre des prélèvements sociaux au taux actuel de 17,2 % (avec un abattement progressif à partir de la 6ème année).
     Le montant de l’impôt sera prélevé par le notaire sur le prix de vente lors de la signature de l’acte authentique et versé par ses soins à l’administration fiscale.
     
     - Parameter capitalGain: plus-value immobilière
     La plus-value est égale à la différence entre le prix de vente (diminué des frais de cession et du montant de la TVA acquittée) et le prix d’achat
     (majoré des frais d’enregistrement réellement payés lors de l’achat ou forfaitairement de 7,5 % du prix d'achat) ou la valeur déclarée lorsque le bien
     a été reçu par donation ou succession (majorée des frais réels et droits de mutation à titre gratuit si ceux-ci ont été supportés par le donataire ou l’héritier).
     Alternativement, le vendeur peut majorer de 15 % la valeur d’acquisition s’il est propriétaire depuis plus de 5 ans, de manière forfaitaire, sans avoir à établir
     la réalité des travaux, le montant des travaux effectivement réalisés ou son impossibilité à fournir des justificatifs (CGI, art. 150 VB II, 4°). Il n'y a pas lieu de
     rechercher si les dépenses de travaux ont déjà été prises en compte pour l'assiette de l'impôt sur le revenu. Le forfait de 15 % est une simple faculté pour les
     contribuables propriétaires de leur bien depuis plus de cinq ans. Il ne se cumule pas avec les frais réellement supportés par le propriétaire.
     - Parameter detentionDuration: durée de la détention du bien
     
     - Returns: Charges sociales dûes sur la plus-value immobilièrae
     - Note:
     - [notaires](https://www.notaires.fr/fr/immobilier-fiscalité/fiscalité-et-gestion-du-patrimoine/les-plus-values-immobilières)
     - [impots gouv](https://www.service-public.fr/particuliers/vosdroits/F10864)
     **/
    func socialTaxes (capitalGain       : Double,
                      detentionDuration : Int) -> Double {
        guard capitalGain > 0 else {
            return 0
        }
        // exoneration partielle ou totale de charges sociales en fonction de la durée de détention
        var discount = 0.0
        if let slice = model.exoGrid.last(where: \.floor, <, detentionDuration) {
            discount = min(slice.prevDiscount + slice.discountRate * Double(detentionDuration - slice.floor), 100.0)
        }
        var discountTravaux = 0.0
        if detentionDuration >= model.discountAfter {
            discountTravaux = model.discountTravaux
        }
        return capitalGain * (1.0 - discountTravaux / 100.0) * (1.0 - discount / 100.0) * model.total / 100.0
    }
}
