//
//  CustomerDataModel.swift
//  Stuy Wash N Dry
//
//  Created by Justin Cook on 2/10/22.
//

import UIKit
import CoreLocation
import Firebase

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
    /** Classify the given address*/
    var addressType: AddressType
    /** The coordinates of this address*/
    var coordinates: CLLocationCoordinate2D? = nil
    
    init(borough: Borough, zipCode: UInt, alias: String, streetAddress1: String, streetAddress2: String, specialInstructions: String, addressType: AddressType) {
        self.borough = borough
        self.zipCode = zipCode
        self.alias = alias
        self.streetAddress1 = streetAddress1
        self.streetAddress2 = streetAddress2
        self.specialInstructions = specialInstructions
        self.addressType = addressType
    }
}

// MARK: - Update address, Local and Remote
/** If no coordinates exist for this address then add the coordinates via an API request and then push this change to the remote, this is used in order to prevent the over usage of the geocoding API which costs a lot over time*/
func updateTheCoordinatesOfThisCustomerAddress(address: Address, customer: Customer){
    guard internetAvailable == true else {
        return
    }
    
    getCoordinatesOf(this: address){(result: Result<CLLocation,APIService.APIError>) in
        switch result{
        case .success(let location):
            address.coordinates = location.coordinate
            
            /** Find this address in the stored address array*/
            for (index, storedAddress) in customer.addresses.enumerated(){
                if storedAddress.streetAddress1 == address.streetAddress1{
                    customer.addresses[index] = address
                }
            }
            
            updateAddressesOfThisCustomer(customer: customer)
        case .failure(let apiError):
            switch apiError{
            case .error(let errorString):
                print("Error: The geocoded location for the provided address could not be fetched and decoded")
                print(errorString)
            }
        }
    }
}

func updateTheCoordinatesOfThisEmployeeAddress(address: Address, employee: BusinessClient){
    guard internetAvailable == true else {
        return
    }
    
    getCoordinatesOf(this: address){(result: Result<CLLocation,APIService.APIError>) in
        switch result{
        case .success(let location):
            address.coordinates = location.coordinate
            
            employee.address = address
            
            updateAddressOfThisEmployee(employee: employee)
        case .failure(let apiError):
            switch apiError{
            case .error(let errorString):
                print("Error: The geocoded location for the provided address could not be fetched and decoded")
                print(errorString)
            }
        }
    }
}

func updateTheCoordinatesOfThisDriverAddress(address: Address, driver: Driver){
    guard internetAvailable == true else {
        return
    }
    
    getCoordinatesOf(this: address){(result: Result<CLLocation,APIService.APIError>) in
        switch result{
        case .success(let location):
            address.coordinates = location.coordinate
            
            driver.address = address
            
            updateAddressOfThisDriver(driver: driver)
        case .failure(let apiError):
            switch apiError{
            case .error(let errorString):
                print("Error: The geocoded location for the provided address could not be fetched and decoded")
                print(errorString)
            }
        }
    }
}

/** For the user to specify what kind of address the given address is*/
public enum AddressType: Int{
    case home = 0
    /** Can be used to specify if the user's address is a business or not (useful for company orders)*/
    case business = 1
    case hotel = 2
    /** Unspecified address type for special cases where the user can't describe the location*/
    case other = 3
    /** Reserved for laundromat and dry cleaning businesses using the services, users aren't permitted to use this*/
    case retail = 4
}

/** Init this enum using the given raw value*/
extension AddressType{
    /** Return the address type as a string representation of its case*/
    func toString()->String{
        switch self{
        case .home:
            return "Home"
        case .business:
            return "Business"
        case .hotel:
            return "Hotel"
        case .other:
            return "Other"
        case .retail:
            return "Retail"
        }
    }
    
    
    public init?(rawValue: Int) {
        switch rawValue{
        case AddressType.home.rawValue:
            self = AddressType.home
        case AddressType.business.rawValue:
            self = AddressType.business
        case AddressType.hotel.rawValue:
            self = AddressType.hotel
        case AddressType.other.rawValue:
            self = AddressType.other
        case AddressType.retail.rawValue:
            self = AddressType.retail
        default:
            return nil
        }
    }
}

/** - Returns: A suitable image icon for the address type given*/
func getImageFor(this addressType: AddressType)->UIImage{
    switch addressType{
    case AddressType.home:
        return UIImage(named: "home-type")!
    case AddressType.business:
        return UIImage(named: "business-type")!
    case AddressType.hotel:
        return UIImage(named: "hotel-type")!
    case AddressType.other:
        return UIImage(named: "other-type")!
    case AddressType.retail:
        return UIImage(named: "retail-type")!
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

// MARK: - Coordinate data type casting
/** Cast a geopoint to a CLLocation Coordinate2D*/
func geopointToCLLocationCoordinate(geopoint: GeoPoint)->CLLocationCoordinate2D{
    return CLLocationCoordinate2D(latitude: geopoint.latitude, longitude: geopoint.longitude)
}

/** Cast a CLLocation Coordinate2D to a geopoint*/
func CLLocationCoordinateToGeoPoint(coordinate: CLLocationCoordinate2D)->GeoPoint{
    return GeoPoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
}

/** - Returns: A dictionary containing the properties of the given addresses in string form*/
func addressToDictionary(address: Address)->[String : Any?]{
    /** Firestore only knows geopoint objects, CLL can't be casted to that type unless manually done*/
    var geopoint: GeoPoint? = nil
    if let coordinates = address.coordinates{
    geopoint = CLLocationCoordinateToGeoPoint(coordinate: coordinates)
    }
    
    let dictionary: [String : Any?] = [
        "Country": address.country,
        "State": address.state,
        "City": address.city,
        "Zip Code": address.zipCode,
        "Borough": address.borough.rawValue,
        "Alias": address.alias,
        "Address 1": address.streetAddress1,
        "Address 2": address.streetAddress2,
        "Instructions": address.specialInstructions,
        "Address Type": address.addressType.rawValue,
        "Coordinates": geopoint
    ]
    
    return dictionary
}

/** - Returns: An array of dictionaries containing the properties of the given addresses in string form*/
func addressToMap(addresses: [Address])->[[String : Any?]]{
    var dictionaries: [[String : Any?]] = []
    
    for address in addresses{
        
        var geopoint: GeoPoint? = nil
        if let coordinates = address.coordinates{
        geopoint = CLLocationCoordinateToGeoPoint(coordinate: coordinates)
        }
        
        let dictionary: [String : Any?] = [
            "Country": address.country,
            "State": address.state,
            "City": address.city,
            "Zip Code": address.zipCode,
            "Borough": address.borough.rawValue,
            "Alias": address.alias,
            "Address 1": address.streetAddress1,
            "Address 2": address.streetAddress2,
            "Instructions": address.specialInstructions,
            "Address Type": address.addressType.rawValue,
            "Coordinates": geopoint
        ]

        dictionaries.append(dictionary)
    }
    
    return dictionaries
}

// MARK: - Genders
/** Return a string containing the gender specified by the given number*/
func getGender(from number: UInt)->String?{
    switch number{
    case 0:
        return "Male"
    case 1:
        return "Female"
    case 2:
        return "Unspecified"
    default:
        return nil
    }
}

/** Array containing acceptable genders*/
let genders = ["Male","Female","Unspecified"]

/** Return a number associated with the gender specified by the given string*/
func getGender(from string: String)->UInt?{
    switch string{
    case "Male":
        return 0
    case "Female":
        return 1
    case "Unspecified":
        return 2
    default:
        return nil
    }
}

/** Return a separated first and last name from the given string
 - Important: The full name has to have a space character separating the first and last names!
 - Returns: A two element large tuple where the first element is the first name (String) and the second is the last name (String) */
func parseFirstLastNames(fullName: String)->(String,String){
    let splitStrings = fullName.split(separator: " ")
    
    var firstName = ""
    var lastName = ""
    
    if splitStrings.count >= 1{
        firstName = String(splitStrings[0])
    }
    if splitStrings.count >= 2{
        lastName = String(splitStrings[1])
    }
    
    return(firstName, lastName)
}

// MARK: - Customer Class
/** Customer profile model that stores the customer's profile properties and updates the remote entry using local changes*/
public class Customer: User{
    /** Where do you live?*/
    var addresses: [Address]
    /** Default membership level for a new user is 1, anything higher is obtained through a subscription*/
    var membershipLevel: UInt8
    /** Indicator of whether or not the user has verified their email*/
    var emailVerified: Bool
    
    init(profile_picture: URL?, created: Date, updated: Date, user_id: String, username: String, email: String, password: String, name: String, firstName: String, lastName: String, phoneNumber: String, gender: String, DOB: Date, emailVerified: Bool, membershipLevel: UInt8, addresses: [Address]){
        self.membershipLevel = membershipLevel
        self.emailVerified = emailVerified
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
