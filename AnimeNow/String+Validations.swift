//
//  String+Validations.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 8/7/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import ANCommonKit

struct RegexHelper {
    let regex: NSRegularExpression?

    init(_ pattern: String) {
        regex = try! NSRegularExpression(pattern: pattern,
                                         options: .CaseInsensitive)
    }

    func match(input: String) -> Bool {
        if let matches = regex?.matchesInString(input,
                                                options: [],
                                                range: NSMakeRange(0, input.characters.count)) {
            return matches.count > 0
        } else {
            return false
        }
    }
}

extension String {
    public func validEmail(viewController: UIViewController) -> Bool {
        let emailRegex = "[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?"
        let regularExpression = try? NSRegularExpression(pattern: emailRegex, options: NSRegularExpressionOptions.CaseInsensitive)
        let matches = regularExpression?.numberOfMatchesInString(self, options: [], range: NSMakeRange(0, self.characters.count))
        
        let validEmail = (matches == 1)
        if !validEmail {
            viewController.presentAlertWithTitle("Invalid email")
        }
        return validEmail
    }
    
    public func validPassword(viewController: UIViewController) -> Bool {
        
        let validPassword = self.characters.count >= 6
        if !validPassword {
            viewController.presentAlertWithTitle("Invalid password", message: "Length should be at least 6 characters")
        }
        return validPassword
    }
    
    public func validUsername(viewController: UIViewController) -> Bool {

        switch self {
        case _ where self.characters.count < 3:
            viewController.presentAlertWithTitle("Invalid username", message: "Make it 3 characters or longer")
            return false
        case _ where !RegexHelper("^[a-zA-z0-9]*$").match(self):
            viewController.presentAlertWithTitle("Invalid username", message: "Can't have special characters, use letter or numbers 👍")
            return false
        case _ where self.rangeOfString(" ") != nil:
            viewController.presentAlertWithTitle("Invalid username", message: "It can't have spaces")
            return false
        default:
            return true
        }
    }
    
    public func usernameIsUnique() -> BFTask {
        let query = User.query()!
        query.limit = 1
        query.whereKey("aozoraUsername", matchesRegex: self, modifiers: "i")
        return query.findObjectsInBackground()
    }
}