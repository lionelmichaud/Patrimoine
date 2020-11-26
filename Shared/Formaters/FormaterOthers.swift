//
//  FormaterOthers.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 25/11/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

var personNameFormatter : PersonNameComponentsFormatter = {
    let formatter = PersonNameComponentsFormatter()
    formatter.style = .long
    return formatter
}()
