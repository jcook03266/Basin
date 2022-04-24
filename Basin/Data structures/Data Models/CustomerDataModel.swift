//
//  CustomerDataModel.swift
//  Stuy Wash N Dry
//
//  Created by Justin Cook on 2/10/22.
//

import UIKit
/** Custom data model class and various other utils used to represent and store the information associated with customer entities*/

//MARK: - User Class
/** Superclass from which all the other appropriate classes are upcasted*/
public class User{
    var profile_picture: URL?
    var created: Date
    var updated: Date
    var user_id: String
    var username: String
    var email: String
    var password: String
    var name: String
    var firstName: String
    var lastName: String
    var phoneNumber: String
    var gender: String
    var DOB: Date
    
    init(created: Date, updated: Date, profile_picture: URL?, user_id: String, username: String, email: String, password: String, name: String, firstName: String, lastName: String, phoneNumber: String, gender: String, DOB: Date){
        self.profile_picture = profile_picture
        self.created = created
        self.updated = updated
        self.user_id = user_id
        self.username = username
        self.email = email
        self.password = password
        self.name = name
        self.firstName = firstName
        self.lastName = lastName
        self.phoneNumber = phoneNumber
        self.gender = gender
        self.DOB = DOB
    }
}
// MARK: - Address Class
/** Class that stores a map of all properties necessary for a standard physical address*/
public class Address{
    /** This is New York baby!*/
    let country = "US"
    let city = "New York"
    let state = "New York"

    var borough: Borough
    var zipCode: UInt
    /** The nickname for this address*/
    var alias: String
    /** Contains the name of the street*/
    var streetAddress1: String
    /** Contains apartment / house number (if any)*/
    var streetAddress2: String
    /** Contains any edge case special instructions that a driver would need to know*/
    var specialInstructions: String
    
    init(borough: Borough, zipCode: UInt, alias: String, streetAddress1: String, streetAddress2: String, specialInstructions: String) {
        self.borough = borough
        self.zipCode = zipCode
        self.alias = alias
        self.streetAddress1 = streetAddress1
        self.streetAddress2 = streetAddress2
        self.specialInstructions = specialInstructions
    }
}

/** Simple class that stores username, password, phone number, and email criteria along with userID*/
public class UserLogin{
    var userID: String
    var username: String
    var phoneNumber: String
    var email: String
    var password: String
    
    init(userID: String, username: String, phoneNumber: String, email: String, password: String){
        self.userID = userID
        self.username = username
        self.phoneNumber = phoneNumber
        self.email = email
        self.password = password
    }
}

/** - Returns: A dictionary containing the properties of the given addresses in string form*/
func addressToDictionary(address: Address)->[String:String]{
    let dictionary: [String : String] = [
        "Country": address.country,
        "State": address.state,
        "City": address.city,
        "Zip Code": address.zipCode.description,
        "Borough": address.borough.rawValue,
        "Alias": address.alias,
        "Address 1": address.streetAddress1,
        "Address 2": address.streetAddress2,
        "Instructions": address.specialInstructions
    ]
    
    return dictionary
}

/** - Returns: An array of dictionaries containing the properties of the given addresses in string form*/
func addressToMap(addresses: [Address])->[[String : String]]{
    var dictionaries: [[String : String]] = []
    
    for address in addresses {
        let dictionary: [String : String] = [
            "Country": address.country,
            "State": address.state,
            "City": address.city,
            "Zip Code": address.zipCode.description,
            "Borough": address.borough.rawValue,
            "Alias": address.alias,
            "Address 1": address.streetAddress1,
            "Address 2": address.streetAddress2,
            "Instructions": address.specialInstructions
        ]

        dictionaries.append(dictionary)
    }
    
    return dictionaries
}

// MARK: - Customer Class
/** Customer profile model that stores the customer's profile properties and updates the remote entry using local changes*/
public class Customer: User{
    /** Where do you live?*/
    var addresses: [Address]
    /** Default membership level for a new user is 1, anything higher is obtained through a subscription*/
    var membership_level: UInt8
    
    init(profile_picture: URL?, created: Date, updated: Date, user_id: String, username: String, email: String, password: String, name: String, firstName: String, lastName: String, phoneNumber: String, gender: String, DOB: Date, verified_email: Bool, membership_level: UInt8, addresses: [Address]){
        self.membership_level = membership_level
        self.addresses = addresses
        
        super.init(created: created, updated: updated, profile_picture: profile_picture, user_id: user_id, username: username, email: email, password: password, name: name, firstName: firstName, lastName: lastName, phoneNumber: phoneNumber, gender: gender, DOB: DOB)
    }
    
    /** Various methods that access the database tables to scrape and aggregate the data into usable information for the front end*/
    func getTotalReviews(){
        
    }
    
    func getAverageRating(){
        
    }
    
    func getReviews(){
        
    }
    
    func getTotalOrders(){
        
    }
    
    func getCurrentOrders(){
        
    }
    
    func isOrderInProgress(){
        
    }
}
