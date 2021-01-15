//
//  GlobalFunctions.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 13/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

// Convert Error -> String of descriptions
func convertErrorToString(_ error: Error) -> String {
    return """
        Domain: \((error as NSError).domain)
        Code: \((error as NSError).code)
        Description: \(error.localizedDescription)
        Failure Reason: \((error as NSError).localizedFailureReason ?? "nil")
        Suggestions: \((error as NSError).localizedRecoverySuggestion ?? "nil")\n
        """
}
