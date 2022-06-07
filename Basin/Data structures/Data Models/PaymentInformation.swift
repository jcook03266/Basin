//
//  PaymentInformation.swift
//  Basin
//
//  Created by Justin Cook on 5/25/22.
//

import UIKit
import Stripe
import Firebase
import FirebaseFunctions

/** Important classes structs and functions for supporting customer payment data storage, transportation, and client-side encryption*/

/** An object that stores details about a payment sent from the user's payment method*/
public class payment{
    
}

/*
/** A class that stores information about a generic payment method*/
public class paymentMethod{
    let name: paymentTypes
    
    
}

public class bankingCard{
    
}*/

/** Specify the region of the cloud function provision*/
var functions = Functions.functions(region: "us-east4")

/** Obtain the generated client secret from a server-side request*/
func getClientSecret(using card: paymentTypes, currency: currencyTypes, completion: @escaping (String?)-> ()){
    
    /** Turn the given parameters into a dictionary*/
    let json: [String : Any] = ["paymentMethodType":card.rawValue,"currency": currency.rawValue]
    
    functions.httpsCallable("createPaymentIntent").call(json){result, error in
        if let error = error as NSError? {
            if error.domain == FunctionsErrorDomain {
                let code = FunctionsErrorCode(rawValue: error.code)
                let message = error.localizedDescription
                let details = error.userInfo[FunctionsErrorDetailsKey]
                print("Error calling function: \(code.debugDescription) / \(message) / \(details.debugDescription)")
            }
            completion(nil)
        }
        else if let data = result?.data as? [String: Any], let stringData = data["clientSecret"] as? String {
            completion(stringData)
        }
    }
}

/** Acceptable payment types for this application*/
public enum paymentTypes: String{
    case card = "card"
    
}

/** Currencies accepted by this application*/
public enum currencyTypes: String{
    case usd = "usd"
}

