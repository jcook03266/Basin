//
//  REGEX.swift
//  Stuy Wash N Dry
//
//  Created by Justin Cook on 2/20/22.
//

/** Regular expression methods that check inputs for valid specified patterns*/
import UIKit
import PhoneNumberKit
/** REGEX Explained
 ?= - Look ahead, used to denote that there are more requirements ahead
 ^ - Start
 $ - End
 \s - Allow white space character
 To analyze the entire string leave these start and stop anchors out when using the .range(of: ,option:) method
 
 Example 1:
 1 - Password length is 8.
 2 - One Alphabet in Password.
 3 - One Special Character in Password.
 
 ^                              - Start Anchor.
 (?=.*[a-z])              -Ensure string has one character.
 (?=.[$@$#!%?&])   -Ensure string has one special character.
 {8,}                            -Ensure password length is 8.
 $                               -End Anchor.
 ----------------------------------------
 Example 2:
 1 - Password length is 8.
 2 - 2 UpperCase letters in Password.
 3 - One Special Character in Password.
 4 - Two Number in Password.
 5- Three letters of lowercase in password.
 
 ^                                                          -Start Anchor.
 (?=.*[A-Z].*[A-Z])                            -Ensure string has two uppercase letters.
 (?=.[$@$#!%?&])                             -Ensure string has one special character.
 (?=.*[0-9].*[0-9])                              -Ensure string has two digits.
 (?=.*[a-z].*[a-z].?*[a-z])                 -Ensure string has three lowercase letters.
 {8,}                                                      -Ensure password length is 8.
 $                                                          -End Anchor.
 */

/**Filters password to make sure it contains at least one uppercase letter, and one lowercase letter, one number, and at least one special character for a total of 8 characters, and a max of 30 characters*/
func isPasswordValid(_ input: String) -> Bool{
    let passwordRegEx = "^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-]).{8,30}$"
    let passwordPred = NSPredicate(format:"SELF MATCHES %@", passwordRegEx)
    
    return passwordPred.evaluate(with: input)
}

/**Usernames can contain characters A-Z a-z, 0-9, underscores dashes and periods. The username cannot start with a ._- nor end with a ._-. It must also not have more than one ._- sequentially. Max length is 30 chars, minimum of 3.*/
func isUsernameValid(_ input: String) -> Bool{
    let usernameRegEx = "^(?=[a-zA-Z0-9._-]{3,30}$)(?!.*[_.-]{2})[^_.-].*[^_.-]$"
    
    let usernamePred = NSPredicate(format:"SELF MATCHES %@", usernameRegEx)
    return usernamePred.evaluate(with: input)
}

/**Email Address must match the regulated standard in terms of allowed characters and length*/
func isEmailValid(_ input: String) -> Bool{
    let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    
    let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
    return emailPred.evaluate(with: input)
}

/**First name and last names can only contain alphabetical characters, min length of 1 character and a max of 30*/
func isNameValid(_ input: String) -> Bool{
    let nameRegEx = "^([a-zA-Z]{1,30})$"
    let namePred = NSPredicate(format:"SELF MATCHES %@", nameRegEx)
    return namePred.evaluate(with: input)
}

/**Address 1 and Address 2 can only contain alphanumerical characters as well as commas, periods, apostrophes, and white space characters, min length of 1 character and a max of 40*/
func isAddressValid(_ input: String) -> Bool{
    let addressRegEx = "^([#.a-zA-Z0-9'\\.\\-\\s\\,]{1,40})$"
    let addressPred = NSPredicate(format:"SELF MATCHES %@", addressRegEx)
    return addressPred.evaluate(with: input)
}

/**State names can only contain alphanumerical characters as well as  white space characters, min length of 1 character and a max of 40*/
func isStateValid(_ input: String) -> Bool{
    let stateRegEx = "^([#.a-zA-Z0-9\\s]{1,40})$"
    let statePred = NSPredicate(format:"SELF MATCHES %@", stateRegEx)
    return statePred.evaluate(with: input)
}

/**City names can only contain alphanumerical characters as well as periods, apostrophes, and white space characters, min length of 1 character and a max of 40*/
func isCityValid(_ input: String) -> Bool{
    let cityRegEx = "^([#.a-zA-Z0-9'\\.\\s]{1,40})$"
    let cityPred = NSPredicate(format:"SELF MATCHES %@", cityRegEx)
    return cityPred.evaluate(with: input)
}

/** Classify whether the input is a username or email address in order to query the correct tables for login information*/
func classifyInput(input: String)->String{
    var classification = ""
    
    /**If the input isn't an email address then test to see if it's a phone number instead*/
    if(classification == ""){
        var phoneNumberKit: PhoneNumberKit? = PhoneNumberKit()
        
        if phoneNumberKit!.isValidPhoneNumber(input) == true{
        classification = "phone"
        }
        
        /** Deinit this expensive object*/
        phoneNumberKit = nil
    }
    
    /**Test to see if the input is an email address with the RegEx case below*/
    /**Email Address must match the regulated standard in terms of allowed characters and length*/
    let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    
    let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
    if emailPred.evaluate(with: input) == true{
        classification = "email"
    }
    
    /**If the input isn't an email address then test to see if it's a username instead*/
    if(classification == ""){
        /**Usernames can contain characters a-z, 0-9, underscores and periods. The username cannot start with a period nor end with a period. It must also not have more than one period sequentially. Max length is 30 chars.*/
        let usernameRegEx = "^(?=[a-zA-Z0-9._-]{3,30}$)(?!.*[_.-]{2})[^_.-].*[^_.-]$"
        
        let usernamePred = NSPredicate(format:"SELF MATCHES %@", usernameRegEx)
        if usernamePred.evaluate(with: input) == true{
            classification = "username"
        }
    }
    
    /**Note:*/
    /**If the classification stays "" then prompt an error message for the username input field*/
    
    return classification
}


