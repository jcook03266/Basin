//
//  LocationsDataModel.swift
//  Stuy Wash N Dry
//
//  Created by Justin Cook on 3/24/22.
//

import Foundation
import Firebase
import PhoneNumberKit
import CoreLocation

/** Fetched laundromat locations from the database*/
var laundromats: [Laundromat] = []

/** Simple file that contains a data model that can store fetched information for the laundromat locations*/
public class Location{
    var address: Address
    var coordinates: GeoPoint
    
    init(address: Address, coordinates: GeoPoint){
        self.address = address
        self.coordinates = coordinates
    }
}

public class Laundromat: Location, Hashable{
    /** Identification string of this location, used to fetch more data such as reviews and ratings*/
    var storeID: String
    /** Shortened names make identifying locations simpler for users*/
    var nickName: String
    /** The hours for which this location will be open*/
    var operatingHours: [String : String]
    /** The contact phone number for this laundromat*/
    var phoneNumber: PhoneNumber
    /** Array of URL strings that reference photos of this laundromat's physical location*/
    var photos: [String]
    /** The ID of the document that stores the menu for this location's dry cleaning options*/
    var dryCleaningMenuDocumentID: String
    /** The ID of the document that stores the menu for this location's regular washing options*/
    var washingMenuDocumentID: String
    
    /** Create a hash value for this object so that it can be uniquely identified*/
    public func hash(into hasher: inout Hasher){
        hasher.combine(self.storeID)
    }
    
    init(address: Address, coordinates: GeoPoint, storeID: String, nickName: String, operatingHours: [String : String], phoneNumber: PhoneNumber, photos: [String], dryCleaningMenuDocumentID: String,  washingMenuDocumentID: String){
        self.storeID = storeID
        self.nickName = nickName
        self.operatingHours = operatingHours
        self.phoneNumber = phoneNumber
        self.photos = photos
        self.dryCleaningMenuDocumentID = dryCleaningMenuDocumentID
        self.washingMenuDocumentID = washingMenuDocumentID
        
        super.init(address: address, coordinates: coordinates)
    }
    
    public static func == (lhs: Laundromat, rhs: Laundromat) -> Bool {
        let condition = lhs.storeID == rhs.storeID && lhs.nickName == rhs.nickName && lhs.operatingHours == rhs.operatingHours && lhs.phoneNumber == rhs.phoneNumber && lhs.photos == rhs.photos && lhs.dryCleaningMenuDocumentID == rhs.dryCleaningMenuDocumentID && lhs.washingMenuDocumentID == rhs.washingMenuDocumentID
        return condition
    }
}

/** Methods for fetching the laundromat locations from the database*/
/** Only getter methods are allowed, no updating is to be done from the client side on the laundromat location data*/

/** Fetch a specific laundromat with the given ID*/
func fetchThisLaundromat(with id: String, completion: @escaping (Laundromat?)-> ()){
    let db = Firestore.firestore()
    
    db.collection("Laundromats").document(id).getDocument{ (querySnapshot, err) in
        if let err = err{
            print("Error getting document: \(err)")
        }
        else{
            var laundromat: Laundromat? = nil
            
            guard querySnapshot?.exists == true else{
                return
            }
            
            let dictionary = querySnapshot!.data()!
            let document = querySnapshot!
            
            /** Parse the CSV phone number string*/
            let phoneNumber = convertFromCSVtoPhoneNumber(number: dictionary["Phone Number"] as! String)
            
            guard phoneNumber != nil else {
                completion(nil)
                return
            }
            
            /** Parse the address map into an address object*/
            let addressMap = dictionary["Address"] as! [String : Any]
            let address = Address(borough: getBoroughFor(this: (addressMap["Zip Code"] as! Int)) ?? .Brookyln, zipCode: UInt(addressMap["Zip Code"] as! Int), alias: addressMap["Alias"] as! String, streetAddress1: addressMap["Address 1"] as! String, streetAddress2: addressMap["Address 2"] as! String, specialInstructions: addressMap["Instructions"] as! String, addressType: .retail)
            
            /** Parse the two menu IDs from the menu map*/
            let menuMap = dictionary["Menus"] as! [String : Any]
            let dryCleaningMenuID = menuMap["Dry Cleaning"] as! String
            let washingMenuID = menuMap["Washing"] as! String
            
            laundromat = Laundromat(address: address, coordinates: dictionary["Coordinates"] as! GeoPoint, storeID: document.documentID, nickName: dictionary["Nickname"] as! String, operatingHours: dictionary["Operating Hours"] as! [String : String], phoneNumber: phoneNumber!, photos: dictionary["Photos"] as! [String], dryCleaningMenuDocumentID: dryCleaningMenuID, washingMenuDocumentID: washingMenuID)
            
            completion(laundromat)
        }
    }
}

/** Fetch all the laundromats within the given radius of the given coordinate point, doing this minimizes the amount of data needed to be fetched, instead of loading up 200 irrelevant locations, you can load up 5 and save both time, energy, and money by doing so, if the set is blank this means no laundromats are within the specified radius of the reference coordinate*/
func fetchLaundromatsInThisRadius(radius: CGSize, coordinatePoint: CLLocation, completion: @escaping (Set<Laundromat>)-> ()){
    
    /** Idea: Add the laundromats to the existing laundromat array only if their IDs don't match already existing laundromats (to keep things unique), these are added because these will be reflected in the UI (maybe if a search area button is established kind of like airbnb)*/
}

/** Fetch all the laundromat locations and return them in a completion method*/
func fetchAllLaundromats(completion: @escaping (Set<Laundromat>)-> ()){
    let db = Firestore.firestore()
    
    db.collection("Laundromats").getDocuments(){ (querySnapshot, err) in
        if let err = err{
            print("Error getting documents: \(err)")
        }
        else{
            var laundromats: Set<Laundromat> = []
            
            /** Make sure the documents in this collection actually exist*/
            guard querySnapshot?.documents.isEmpty == false else{
                return completion(laundromats)
            }
            
            /** Documents exist*/
            for document in querySnapshot!.documents{
                
                let dictionary = document.data()
                
                /** Parse the CSV phone number string*/
                let phoneNumber = convertFromCSVtoPhoneNumber(number: dictionary["Phone Number"] as! String)
                
                guard phoneNumber != nil else {
                    break
                }
                
                /** Parse the address map into an address object*/
                let addressMap = dictionary["Address"] as! [String : Any]
                let address = Address(borough: getBoroughFor(this: (addressMap["Zip Code"] as! Int)) ?? .Brookyln, zipCode: UInt(addressMap["Zip Code"] as! Int), alias: addressMap["Alias"] as! String, streetAddress1: addressMap["Address 1"] as! String, streetAddress2: addressMap["Address 2"] as! String, specialInstructions: addressMap["Instructions"] as! String, addressType: .retail)
                
                /** Parse the two menu IDs from the menu map*/
                let menuMap = dictionary["Menus"] as! [String : Any]
                let dryCleaningMenuID = menuMap["Dry Cleaning"] as! String
                let washingMenuID = menuMap["Washing"] as! String
                
                let laundromat = Laundromat(address: address, coordinates: dictionary["Coordinates"] as! GeoPoint, storeID: document.documentID, nickName: dictionary["Nickname"] as! String, operatingHours: dictionary["Operating Hours"] as! [String : String], phoneNumber: phoneNumber!, photos: dictionary["Photos"] as! [String], dryCleaningMenuDocumentID: dryCleaningMenuID, washingMenuDocumentID: washingMenuID)
                
                laundromats.update(with: laundromat)
            }
            
            completion(laundromats)
        }
}
}

/** Fetch the menu document for the given document id, parse the menu's data and return it in object form*/
func fetchThisMenu(menuDocumentID: String, completion: @escaping (LaundromatMenu?)-> ()){
    let db = Firestore.firestore()
    
    db.collection("Menus").document(menuDocumentID).getDocument(){ (querySnapshot, err) in
        if let err = err{
            print("Error getting documents: \(err)")
        }
        else{
            var laundromatMenu: LaundromatMenu? = nil
            
            /** Make sure the document exists in this collection*/
            guard querySnapshot?.exists == true else{
                return completion(laundromatMenu)
            }
            
            let dictionary = querySnapshot!.data()!
            
            laundromatMenu = LaundromatMenu(id: querySnapshot!.documentID, category: dictionary["Category"] as! String, created: (dictionary["Created"] as! Timestamp).dateValue(), updated: (dictionary["Updated"] as! Timestamp).dateValue())
            
            /** Parse all of the items in the fetched item map*/
            let itemsMaps = dictionary["Items"] as! [[String : Any]]
            for itemsMap in itemsMaps{
                
                /** Create the main order items to append to the menu*/
                let orderItem = OrderItem(id: itemsMap["ID"] as! String, name: itemsMap["Name"] as! String, category: itemsMap["Category"] as! String, price: itemsMap["Price"] as! Double, menu: laundromatMenu!)
                orderItem.itemDescription = itemsMap["Description"] as! String
                orderItem.photoURL = itemsMap["Photo"] as? String
                
                /** Parse the item choices map*/
                let itemChoiceMaps = itemsMap["Choices"] as! [[String: Any]]
                for itemChoiceMap in itemChoiceMaps{
                    /** Don't try to parse an empty map, errors will occur*/
                    if itemChoiceMap.isEmpty == true{break}
                    
                    let itemChoice = itemChoice(category: itemChoiceMap["Category"] as! String, name: itemChoiceMap["Name"] as! String, price: itemChoiceMap["Price"] as! Double, overridesTotalPrice: itemChoiceMap["Overrides Total"] as! Bool, choiceDescription: itemChoiceMap["Description"] as! String, required: itemChoiceMap["Required"] as! Bool, limit: itemChoiceMap["Limit"] as! Int)
                    
                    orderItem.itemChoices.update(with: itemChoice)
                }
                
                laundromatMenu?.items.update(with: orderItem)
            }
            
            completion(laundromatMenu)
        }
        
}
}
