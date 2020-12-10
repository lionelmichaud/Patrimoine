//
//  Generics.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 26/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

func rawValueGeneric<T: CaseIterable >(of enu: T) -> Int where T: Equatable, T.AllCases == [T] {
    if Mirror(reflecting: enu).children.count != 0 {
        // le swich case possède des associated values
        let selfCaseName = Mirror(reflecting: enu).children.first!.label!
        
        return T.allCases.firstIndex(where: { swichCase in
            let switchingCaseName = Mirror(reflecting: swichCase).children.first!.label!
            return switchingCaseName == selfCaseName
        })!
    } else {
        return T.allCases.firstIndex(where: { swichCase in
            return swichCase == enu
        })!
    }
}
