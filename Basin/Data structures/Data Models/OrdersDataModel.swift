//
//  OrdersDataModel.swift
//  Stuy Wash N Dry
//
//  Created by Justin Cook on 3/30/22.
//
/** File with objects that allow laundromat orders and their data to be created, stored, and persisted*/
import UIKit
import Firebase

/** An item object that stores general parameters that allow it to be identified amongst other item objects*/
public class Item: NSObject, NSCopying{
    /** The menu that this item belongs to*/
    var menu: LaundromatMenu
    /** A photo / icon representing the item at hand that makes it easier to identify it while in a large list*/
    var photoURL: String? = nil
    /** An ID string that makes this object identifiable amongst other objects with the same characteristics*/
    let id: String
    /** The category that this item should be placed in*/
    var category: String
    /** The general name of this item*/
    var name: String
    /** The optional description for this item*/
    var itemDescription: String = ""
    /** A selection of separate choices the user can select from to customize this item further*/
    var itemChoices: Set<itemChoice> = []
    /** A count of how many duplicate items this item should represent,
     ex.) 10 sweatshirts = 1 of these items, named sweatshirt, with a count of 10*/
    var count: Int = 0
    /** The price of this item*/
    var price: Double
    /** The discount to be applied to this item's price*/
    var discount: Double = 0
    
    init(id: String, name: String, category: String, price: Double, menu: LaundromatMenu){
        self.id = id
        self.name = name
        self.category = category
        self.price = price
        self.menu = menu
    }
    
    /** Compare the names of these two items*/
    public static func < (lhs: Item, rhs: Item) -> Bool {
        let condition = lhs.name < rhs.name
        
        return condition
    }
    
    /** Compare the names of these two items*/
    public static func > (lhs: Item, rhs: Item) -> Bool {
        let condition = lhs.name > rhs.name
        
        return condition
    }
    
    public static func == (lhs: Item, rhs: Item) -> Bool {
        let condition = lhs.id == rhs.id && lhs.category == rhs.category && lhs.name == rhs.name && lhs.itemDescription == rhs.itemDescription && lhs.count == rhs.count && lhs.price == rhs.price && lhs.photoURL == rhs.photoURL && lhs.itemChoices == rhs.itemChoices
        return condition
    }
    
    /** Return a copy of this object that points to a new address in memory*/
    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = Item(id: id, name: name, category: category, price: price, menu: menu)
        copy.count = count
        copy.discount = discount
        copy.itemDescription = itemDescription
        copy.photoURL = photoURL
        
        var itemChoicesCopy: Set<itemChoice> = []
        
        /** Create a new copy of the item choices set in order to avoid editing objects referenced elsewhere*/
        for itemChoice in self.itemChoices{
            let itemChoiceCopy = itemChoice.copy() as! itemChoice
            
            itemChoicesCopy.update(with: itemChoiceCopy)
        }
        
        copy.itemChoices = itemChoicesCopy
        
        return copy
    }
    
    /** Set all of the choices to not selected*/
    func clearSelectedChoices(){
        for choice in itemChoices{
            choice.selected = false
        }
    }
    
    /** Return the subtotal of this item, computed from the quantity of this item and the choices selected, or just the given price*/
    func getSubtotal()->Double{
        var subtotal: Double = 0
        var itemChoiceSelected = false
        
        /** No item choices so just return the default price * the quantity*/
        guard itemChoices.isEmpty == false else {
            return ((price * Double(count)) - discount)
        }
        
        for choice in itemChoices{
            if choice.selected == true && choice.overridesTotalPrice == true{
                subtotal += (choice.price * Double(count))
                
                itemChoiceSelected = true
            }
            else if choice.selected == true && choice.overridesTotalPrice == false{
                subtotal += (choice.price * Double(count))
                
                itemChoiceSelected = true
            }
        }
        
        /** If no choices were selected then return the default price * the item quantity*/
        guard itemChoiceSelected == true else {
            return ((price * Double(count)) - discount)
        }
        
        return (subtotal - discount)
    }
}

/** Compare two sets of order items to see if they match or not
 True: These sets contain the same elements object wise, not hash wise, False: they don't*/
func compareItemChoiceSets(set1: Set<itemChoice>, set2: Set<itemChoice>)->Bool{
    var match = false
    
    for item1 in set1{
        /** Match this item with an item in set 2, if a match is found break out of loop 2 and move on to the next element, if no match is found then break out of loop 1 and return false*/
        for item2 in set2{
            if item1 == item2{
            match = true
            break
            }
            else{
            match = false
            }
        }
        
        if match == false{
            return match
        }
    }
    return match
}

/** A separate pricing for a specific subset of the item */
public class itemChoice: NSObject, NSCopying{
    /** The category under which this choice belongs*/
    var category: String
    /** The name of this choice*/
    var name: String
    /** The price of this choice*/
    var price: Double
    /** If true then this choice overrides the total price for the item, if false then it's simply added to the total price*/
    var overridesTotalPrice: Bool
    /** A description of this item choice*/
    var choiceDescription: String
    /** Determine whether or not this choice is required by the user in order to add to cart*/
    var required: Bool
    /** The categorical limit for the amount of choices the user can select*/
    var limit: Int
    /** Determine whether or not this choice has been selected by the user*/
    var selected: Bool = false
    
    init(category: String, name: String, price: Double, overridesTotalPrice: Bool, choiceDescription: String, required: Bool, limit: Int){
        self.category = category
        self.name = name
        self.price = price
        self.overridesTotalPrice = overridesTotalPrice
        self.choiceDescription = choiceDescription
        self.required = required
        self.limit = limit
    }
    
    /** Compare the price of these two items*/
    public static func < (lhs: itemChoice, rhs: itemChoice) -> Bool {
        let condition = lhs.price < rhs.price
        
        return condition
    }
    
    /** Compare the price of these two items*/
    public static func > (lhs: itemChoice, rhs: itemChoice) -> Bool {
        let condition = lhs.price > rhs.price
        
        return condition
    }
    
    public static func == (lhs: itemChoice, rhs: itemChoice) -> Bool {
        let condition = lhs.name == rhs.name && lhs.category == rhs.category && lhs.overridesTotalPrice == rhs.overridesTotalPrice && lhs.choiceDescription == rhs.choiceDescription && lhs.required == rhs.required && lhs.price == rhs.price && lhs.limit == rhs.limit && lhs.selected == rhs.selected
        return condition
    }
    
    /** Return a copy of this object that points to a new address in memory*/
    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = itemChoice(category: category, name: name, price: price, overridesTotalPrice: overridesTotalPrice, choiceDescription: choiceDescription, required: required, limit: limit)
        copy.selected = selected
        
        return copy
    }
}

/** A generic laundry item that's a part of an order specified by the user*/
public class OrderItem: Item{
    /** Optional textual specification of how this item should be handled that will be read by an employee*/
    var specialInstructions: String = ""
    /** A count of how many duplicate items this item should represent,
     ex.) 10 sweatshirts = 1 of these items, named sweatshirt, with a count of 10, this property by default is computed but can be set*/
    ///lazy var averageItemWeight: Double = calculateAverageWeight()
    /** The statistical average weight of this item [in pounds b/c America], this is used to compute the total weight unless the user specifies the total weight on their own*/
    ///var statisticalAverageWeight: Double
    
    /** Generic constructor*/
    override init(id: String, name: String, category: String, price: Double, menu: LaundromatMenu){
        ///self.statisticalAverageWeight = statisticalAverageWeight
        
        super.init(id: id, name: name, category: category, price: price, menu: menu)
    }
    
    /** Return a copy of this object that points to a new address in memory*/
    public override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! Item
        let newCopy = OrderItem(id: copy.id, name: copy.name, category: copy.category, price: copy.price, menu: copy.menu)
        newCopy.count = copy.count
        newCopy.discount = copy.discount
        newCopy.itemDescription = copy.itemDescription
        newCopy.photoURL = copy.photoURL
        newCopy.itemChoices = copy.itemChoices
        newCopy.specialInstructions = specialInstructions
        
        return newCopy
    }
    
    /** Calculate the totalWeight of this item given the criteria at hand*/
    /**private func calculateAverageWeight()->Double{
     return Double(statisticalAverageWeight * Double(count))
     }*/
}

/** Status codes to simplify identifying the current state of the order*/
public enum OrderStatusCode: Int{
    /** Order has been placed and the payment is awaiting confirmation of success*/
    case paidAwaitingConfirmation = 0
    
    /** Error codes, either the payment of the order has failed or another fatal error has occurred and the order has been voided [it won't propagate to the database as that's only for successful orders]*/
    case paymentFailureOrderVoided = -1
    case otherFailureOrderVoided = -2
    
    /** Order placed, payment went through now continue with which ever option the customer chose [pickup or drop off service]*/
    case orderPlacedSuccessfully = 1
    
    /** The order is now ready for pickup by a driver or has been dropped off by the customer after a successful order placement code*/
    case readyForPickupByDriver = 2
    case orderDroppedOffByCustomer = 3
    
    /** The order is now in progress and will be marked as complete by an employee when the process is done*/
    case inProgress = 4
    
    /** The order is ready for pick up by a customer if they've chosen to do so or delivery if they've chosen that option as well, the user can specify whether they want pick up or delivery for when the order is placed and ready, separately*/
    case readyForPickupByCustomer = 5
    case readyForDelivery = 6
    
    /** These two codes are used to inform the user that the order is in transit and the destination of that order*/
    case orderInTransitToLaundromat = 7
    case orderInTransitToCustomer = 8
    
    /** The order has been delivered or has been picked up, successful transaction*/
    case delivered = 9
    case orderPickedUp = 10
}



/** Status code that simplify tracking the delivery process*/
public enum DeliveryStatusCode: Int{
    /** Driver is going to the pick up location*/
    case enrouteToPickup = 0
    /** Pick up successful*/
    case pickedUp = 1
    /** Pick up failed, */
    case failure = 2
    
    /** Pick up successful now in transit*/
    case inProgress = 3
    
    /** The destination could not be reached, return the order back to its origin point*/
    case deliveryFailed = 4
    /** The delivery was returned back to its origin point, another delivery will be attempted later*/
    case returnedToOrigin = 5
    
    /** The delivery was dropped off at the destination, awaiting photographic proof of delivery*/
    case droppedOff = 6
    /** The delivery driver provided photo evidence that the order was dropped off, now the delivery is complete*/
    case confirmationPhotoProvided = 7
    
    /** Delivered successfully*/
    case successful =  9
}

/** Generate a unique ID string that uses random numbers, letters, a hash of the current time, and also an optional ID string such as a customer's UID*/
func computeGenericUID(with id: String?)->String{
    let ints = [1,2,3,4,5,6,7,8,9]
    return "\(id ?? "")\(ints.randomElement()!)\(Date.now.hashValue)\(ints.randomElement()!)"
}

/** An object used to identify the pickup and drop off of an order object, the origin and destination addresses, the driver, the pickup date and time as well as the delivery date and time*/
public class Delivery{
    /** String used to identify this delivery object*/
    let id: String
    /** The driver for this delivery*/
    var driver: Driver
    /** Track the status of this delivery*/
    var deliveryStatusCode: DeliveryStatusCode
    /** When the status of this delivery was last updated*/
    var deliveryStatusLastUpdated: Date
    /** The date and time when this delivery was picked up*/
    let pickUpDate: Date
    /** The date and time when this delivery was completed (dropped off), specified when the delivery is complete*/
    var deliveryDate: Date? = nil
    /** Where this delivery was picked up*/
    var originAddress: Address
    /** Where this delivery is going*/
    var destinationAddress: Address
    /** A photo of the order that will be used as proof of the delivery, specified when the delivery is about to be completed, the order will not be complete unless the delivery confirmation photo is provided*/
    var deliveryConfirmationPhotoURL: URL? = nil
    /** The order being transported and delivered*/
    var order: Order
    
    init(id: String, driver: Driver, deliveryStatusCode: DeliveryStatusCode, deliveryStatusLastUpdated: Date, pickUpDate: Date, originAddress: Address, destinationAddress: Address, order: Order){
        self.id = id
        self.driver = driver
        self.deliveryStatusCode = deliveryStatusCode
        self.deliveryStatusLastUpdated = deliveryStatusLastUpdated
        self.pickUpDate = pickUpDate
        self.originAddress = originAddress
        self.destinationAddress = destinationAddress
        self.order = order
    }
}

/** Push the following data to the given menu document*/
func pushWashingDataToMenuCollection(){
    /** DB reference*/
    let db = Firestore.firestore()
    
    let menuRef = db.collection("Menus").document("HIrET34NiR3lDX5hlre7")
    
    let items: [[String : Any]] = [
        ["ID":"0",
         "Photo":"",
         "Category":"Bedding",
         "Name":"Comforters",
         "Choices": [["Category":"Size Selection",
                      "Name":"King-Size",
                      "Overrides Total": true,
                      "Required": true,
                      "Limit": 1,
                      "Description":"",
                      "Price": 12.00],
                     ["Category":"Size Selection",
                      "Name":"Queen-Size",
                      "Overrides Total": true,
                      "Required": true,
                      "Limit": 1,
                      "Description":"",
                      "Price": 10.00],
                     ["Category":"Size Selection",
                      "Name":"Twin-Size",
                      "Overrides Total": true,
                      "Required": true,
                      "Limit": 1,
                      "Description":"",
                      "Price": 8.00],
                     ["Category":"Comforter Type",
                      "Name":"Regular",
                      "Overrides Total": false,
                      "Required": true,
                      "Limit": 1,
                      "Description":"",
                      "Price": 0.00],
                     ["Category":"Comforter Type",
                      "Name":"Goose-Down",
                      "Overrides Total": false,
                      "Required": true,
                      "Limit": 1,
                      "Description":"",
                      "Price": 25.00]
                    ],
         "Description":"",
         "Price": 12.00],
        ["ID":"2",
         "Photo":"",
         "Category":"Bedding",
         "Name":"Blankets",
         "Choices": [["Category":"Size Selection",
                      "Name":"Large",
                      "Overrides Total": true,
                      "Required": true,
                      "Limit": 1,
                      "Description":"",
                      "Price": 10.00],
                     ["Category":"Size Selection",
                      "Name":"Medium",
                      "Overrides Total": true,
                      "Required": true,
                      "Limit": 1,
                      "Description":"",
                      "Price": 8.00],
                     ["Category":"Size Selection",
                      "Name":"Small",
                      "Overrides Total": true,
                      "Required": true,
                      "Limit": 1,
                      "Description":"",
                      "Price": 6.00]
                    ],
         "Description":"",
         "Price": 10.00],
        ["ID":"3",
         "Photo":"",
         "Category":"Bedding",
         "Name":"Weighted Blankets",
         "Choices": [[:]],
         "Description":"",
         "Price": 12.00],
        ["ID":"4",
         "Photo":"",
         "Category":"Bedding",
         "Name":"Duvets",
         "Choices": [[:]],
         "Description":"",
         "Price": 12.00],
        ["ID":"5",
         "Photo":"",
         "Category":"Bedding",
         "Name":"Duvet Covers",
         "Choices": [[:]],
         "Description":"",
         "Price": 15.00],
        ["ID":"6",
         "Photo":"",
         "Category":"Bedding",
         "Name":"Pillows",
         "Choices": [["Category":"Size Selection",
                      "Name":"King-Size",
                      "Overrides Total": true,
                      "Required": true,
                      "Limit": 1,
                      "Description":"",
                      "Price": 6.00],
                     ["Category":"Size Selection",
                      "Name":"Regular-Size",
                      "Overrides Total": true,
                      "Required": true,
                      "Limit": 1,
                      "Description":"",
                      "Price": 4.00]
                    ],
         "Description":"",
         "Price": 6.00],
        ["ID":"7",
         "Photo":"",
         "Category":"Bedding",
         "Name":"Mattress Covers",
         "Choices": [[:]],
         "Description":"",
         "Price": 5.50],
        ["ID":"8",
         "Photo":"",
         "Category":"Sneakers",
         "Name":"Sneakers",
         "Choices": [["Category":"Cleaning Services",
                      "Name":"Deep-Cleaning",
                      "Overrides Total": true,
                      "Required": true,
                      "Limit": 1,
                      "Description":"",
                      "Price": 45.00],
                     ["Category":"Cleaning Services",
                      "Name":"Premium-Cleaning",
                      "Overrides Total": true,
                      "Required": true,
                      "Limit": 1,
                      "Description":"",
                      "Price": 60.00],
                     ["Category":"Cleaning Services",
                      "Name":"Standard-Cleaning",
                      "Overrides Total": true,
                      "Required": true,
                      "Limit": 1,
                      "Description":"",
                      "Price": 35.00]
                    ],
         "Description":"",
         "Price": 45.00],
        ["ID":"9",
         "Photo":"",
         "Category":"Rugs",
         "Name":"Rugs",
         "Choices": [["Category":"Size Selection",
                      "Name":"Large",
                      "Overrides Total": true,
                      "Required": true,
                      "Limit": 1,
                      "Description":"",
                      "Price": 10.00],
                     ["Category":"Size Selection",
                      "Name":"Medium",
                      "Overrides Total": true,
                      "Required": true,
                      "Limit": 1,
                      "Description":"",
                      "Price": 7.00],
                     ["Category":"Size Selection",
                      "Name":"Small",
                      "Overrides Total": true,
                      "Required": true,
                      "Limit": 1,
                      "Description":"",
                      "Price": 4.00]
                    ],
         "Description":"",
         "Price": 10.00],
        ["ID":"10",
         "Photo":"",
         "Category":"Pets",
         "Name":"Pet Beds",
         "Choices": [["Category":"Size Selection",
                      "Name":"Large",
                      "Overrides Total": true,
                      "Required": true,
                      "Limit": 1,
                      "Description":"",
                      "Price": 15.00],
                     ["Category":"Size Selection",
                      "Name":"Medium",
                      "Overrides Total": true,
                      "Required": true,
                      "Limit": 1,
                      "Description":"",
                      "Price": 12.00],
                     ["Category":"Size Selection",
                      "Name":"Small",
                      "Overrides Total": true,
                      "Required": true,
                      "Limit": 1,
                      "Description":"",
                      "Price": 9.00]
                    ],
         "Description":"",
         "Price": 15.00],
        ["ID":"11",
         "Photo":"",
         "Category":"Coats and Jackets",
         "Name":"Trench Coats",
         "Choices": [[:]],
         "Description":"",
         "Price": 18.00],
        ["ID":"12",
         "Photo":"",
         "Category":"Coats and Jackets",
         "Name":"Wool Coats",
         "Choices": [[:]],
         "Description":"",
         "Price": 15.00],
        ["ID":"13",
         "Photo":"",
         "Category":"Coats and Jackets",
         "Name":"Outter Jackets",
         "Choices": [[:]],
         "Description":"",
         "Price": 10.00],
        ["ID":"14",
         "Photo":"",
         "Category":"Coats and Jackets",
         "Name":"Goose-Down Coats",
         "Choices": [[:]],
         "Description":"",
         "Price": 25.00],
        ["ID":"15",
         "Photo":"",
         "Category":"Coats and Jackets",
         "Name":"Blazers",
         "Choices": [[:]],
         "Description":"",
         "Price": 7.50],
        ["ID":"16",
         "Photo":"",
         "Category":"Coats and Jackets",
         "Name":"Sports Jackets",
         "Choices": [[:]],
         "Description":"",
         "Price": 7.50],
        ["ID":"17",
         "Photo":"",
         "Category":"Regular Clothes",
         "Name":"Sweatsuits",
         "Choices": [[:]],
         "Description":"",
         "Price": 12.00],
        ["ID":"18",
         "Photo":"",
         "Category":"Regular Clothes",
         "Name":"Shirts",
         "Choices": [[:]],
         "Description":"",
         "Price": 5.50],
        ["ID":"19",
         "Photo":"",
         "Category":"Regular Clothes",
         "Name":"Blouses",
         "Choices": [[:]],
         "Description":"",
         "Price": 5.50],
        ["ID":"20",
         "Photo":"",
         "Category":"Regular Clothes",
         "Name":"Pants",
         "Choices": [[:]],
         "Description":"",
         "Price": 8.00],
        ["ID":"21",
         "Photo":"",
         "Category":"Formal Clothes",
         "Name":"Formal Gowns",
         "Choices": [[:]],
         "Description":"",
         "Price": 25.00],
        ["ID":"22",
         "Photo":"",
         "Category":"Formal Clothes",
         "Name":"Dresses",
         "Choices": [[:]],
         "Description":"",
         "Price": 10.00],
        ["ID":"23",
         "Photo":"",
         "Category":"Bathroom",
         "Name":"Shower Curtains",
         "Choices": [[:]],
         "Description":"",
         "Price": 4.00],
        ["ID":"24",
         "Photo":"",
         "Category":"Living-Room",
         "Name":"Sofa Covers",
         "Choices": [[:]],
         "Description":"",
         "Price": 25.00]
    ]
    
    /** Set the items array of the menu to include the following item objects*/
    menuRef.updateData(["Items" : items])
    { err in
        if let err = err {
            print("Error updating document: \(err)")
        } else {
            print("Document successfully updated")
        }
    }
}

func pushDryCleaningDataToMenuCollection(){
    /** DB reference*/
    let db = Firestore.firestore()
    
    let menuRef = db.collection("Menus").document("qivrCpzNHuxH05BMAzOq")
    
    let items: [[String : Any]] = [
        ["ID":"0",
         "Photo":"",
         "Category":"Bedding",
         "Name":"Comforters",
         "Choices": [["Category":"Size Selection",
                      "Name":"King-Size",
                      "Overrides Total": true,
                      "Required": true,
                      "Limit": 1,
                      "Description":"",
                      "Price": 12.00],
                     ["Category":"Size Selection",
                      "Name":"Queen-Size",
                      "Overrides Total": true,
                      "Required": true,
                      "Limit": 1,
                      "Description":"",
                      "Price": 10.00],
                     ["Category":"Size Selection",
                      "Name":"Twin-Size",
                      "Overrides Total": true,
                      "Required": true,
                      "Limit": 1,
                      "Description":"",
                      "Price": 8.00],
                     ["Category":"Comforter Type",
                      "Name":"Regular",
                      "Overrides Total": false,
                      "Required": true,
                      "Limit": 1,
                      "Description":"",
                      "Price": 0.00],
                     ["Category":"Comforter Type",
                      "Name":"Goose-Down",
                      "Overrides Total": false,
                      "Required": true,
                      "Limit": 1,
                      "Description":"",
                      "Price": 25.00]
                    ],
         "Description":"",
         "Price": 12.00],
        ["ID":"2",
         "Photo":"",
         "Category":"Bedding",
         "Name":"Blankets",
         "Choices": [["Category":"Size Selection",
                      "Name":"Large",
                      "Overrides Total": true,
                      "Required": true,
                      "Limit": 1,
                      "Description":"",
                      "Price": 10.00],
                     ["Category":"Size Selection",
                      "Name":"Medium",
                      "Overrides Total": true,
                      "Required": true,
                      "Limit": 1,
                      "Description":"",
                      "Price": 8.00],
                     ["Category":"Size Selection",
                      "Name":"Small",
                      "Overrides Total": true,
                      "Required": true,
                      "Limit": 1,
                      "Description":"",
                      "Price": 6.00]
                    ],
         "Description":"",
         "Price": 10.00],
        ["ID":"3",
         "Photo":"",
         "Category":"Bedding",
         "Name":"Weighted Blankets",
         "Choices": [[:]],
         "Description":"",
         "Price": 12.00],
        ["ID":"4",
         "Photo":"",
         "Category":"Bedding",
         "Name":"Duvets",
         "Choices": [[:]],
         "Description":"",
         "Price": 12.00],
        ["ID":"5",
         "Photo":"",
         "Category":"Bedding",
         "Name":"Duvet Covers",
         "Choices": [[:]],
         "Description":"",
         "Price": 15.00],
        ["ID":"6",
         "Photo":"",
         "Category":"Bedding",
         "Name":"Linen Duvet Covers",
         "Choices": [[:]],
         "Description":"",
         "Price": 18.00],
        ["ID":"7",
         "Photo":"",
         "Category":"Bedding",
         "Name":"Pillows",
         "Choices": [["Category":"Size Selection",
                      "Name":"King-Size",
                      "Overrides Total": true,
                      "Required": true,
                      "Limit": 1,
                      "Description":"",
                      "Price": 6.00],
                     ["Category":"Size Selection",
                      "Name":"Regular-Size",
                      "Overrides Total": true,
                      "Required": true,
                      "Limit": 1,
                      "Description":"",
                      "Price": 4.00]
                    ],
         "Description":"",
         "Price": 6.00],
        ["ID":"8",
         "Photo":"",
         "Category":"Coats and Jackets",
         "Name":"Trench Coats",
         "Choices": [[:]],
         "Description":"",
         "Price": 18.00],
        ["ID":"9",
         "Photo":"",
         "Category":"Coats and Jackets",
         "Name":"Wool Coats",
         "Choices": [[:]],
         "Description":"",
         "Price": 15.00],
        ["ID":"10",
         "Photo":"",
         "Category":"Coats and Jackets",
         "Name":"Outter Jackets",
         "Choices": [[:]],
         "Description":"",
         "Price": 10.00],
        ["ID":"11",
         "Photo":"",
         "Category":"Coats and Jackets",
         "Name":"Goose-Down Coats",
         "Choices": [[:]],
         "Description":"",
         "Price": 25.00],
        ["ID":"12",
         "Photo":"",
         "Category":"Coats and Jackets",
         "Name":"Blazers",
         "Choices": [[:]],
         "Description":"",
         "Price": 7.50],
        ["ID":"13",
         "Photo":"",
         "Category":"Coats and Jackets",
         "Name":"Sports Jackets",
         "Choices": [[:]],
         "Description":"",
         "Price": 7.50],
        ["ID":"14",
         "Photo":"",
         "Category":"Regular Clothes",
         "Name":"Sweatsuit",
         "Choices": [[:]],
         "Description":"",
         "Price": 12.00],
        ["ID":"15",
         "Photo":"",
         "Category":"Regular Clothes",
         "Name":"T-Shirts",
         "Choices": [[:]],
         "Description":"",
         "Price": 4.50],
        ["ID":"16",
         "Photo":"",
         "Category":"Regular Clothes",
         "Name":"Ties",
         "Choices": [[:]],
         "Description":"",
         "Price": 4.00],
        ["ID":"17",
         "Photo":"",
         "Category":"Regular Clothes",
         "Name":"Vests",
         "Choices": [[:]],
         "Description":"",
         "Price": 5.00],
        ["ID":"18",
         "Photo":"",
         "Category":"Regular Clothes",
         "Name":"Sweaters",
         "Choices": [[:]],
         "Description":"",
         "Price": 8.00],
        ["ID":"19",
         "Photo":"",
         "Category":"Regular Clothes",
         "Name":"Skirts",
         "Choices": [[:]],
         "Description":"",
         "Price": 6.50],
        ["ID":"20",
         "Photo":"",
         "Category":"Regular Clothes",
         "Name":"Shorts",
         "Choices": [[:]],
         "Description":"",
         "Price": 4.00],
        ["ID":"21",
         "Photo":"",
         "Category":"Regular Clothes",
         "Name":"Shirts",
         "Choices": [[:]],
         "Description":"",
         "Price": 5.50],
        ["ID":"22",
         "Photo":"",
         "Category":"Regular Clothes",
         "Name":"Blouses",
         "Choices": [[:]],
         "Description":"",
         "Price": 5.50],
        ["ID":"23",
         "Photo":"",
         "Category":"Bedding",
         "Name":"Sheets",
         "Choices": [[:]],
         "Description":"",
         "Price": 15.00],
        ["ID":"24",
         "Photo":"",
         "Category":"Regular Clothes",
         "Name":"Shawls",
         "Choices": [[:]],
         "Description":"",
         "Price": 5.50],
        ["ID":"25",
         "Photo":"",
         "Category":"Regular Clothes",
         "Name":"Scarves",
         "Choices": [[:]],
         "Description":"",
         "Price": 4.50],
        ["ID":"26",
         "Photo":"",
         "Category":"Regular Clothes",
         "Name":"Polo Shirts",
         "Choices": [[:]],
         "Description":"",
         "Price": 7.00],
        ["ID":"27",
         "Photo":"",
         "Category":"Regular Clothes",
         "Name":"Pants",
         "Choices": [[:]],
         "Description":"",
         "Price": 8.00],
        ["ID":"28",
         "Photo":"",
         "Category":"Regular Clothes",
         "Name":"Overalls",
         "Choices": [[:]],
         "Description":"",
         "Price": 10.00],
        ["ID":"29",
         "Photo":"",
         "Category":"Regular Clothes",
         "Name":"Jumpsuits",
         "Choices": [[:]],
         "Description":"",
         "Price": 12.00],
        ["ID":"30",
         "Photo":"",
         "Category":"Regular Clothes",
         "Name":"Bodysuits",
         "Choices": [[:]],
         "Description":"",
         "Price": 5.00],
        ["ID":"31",
         "Photo":"",
         "Category":"Regular Clothes",
         "Name":"Aprons",
         "Choices": [[:]],
         "Description":"",
         "Price": 6.00],
        ["ID":"32",
         "Photo":"",
         "Category":"Regular Clothes",
         "Name":"Hoodies & Pull Overs",
         "Choices": [[:]],
         "Description":"",
         "Price": 12.00],
        ["ID":"33",
         "Photo":"",
         "Category":"Living-Room",
         "Name":"Sofa Covers",
         "Choices": [[:]],
         "Description":"",
         "Price": 25.00],
        ["ID":"34",
         "Photo":"",
         "Category":"Living-Room",
         "Name":"Cushion Covers",
         "Choices": [["Category":"Size Selection",
                      "Name":"Small",
                      "Overrides Total": true,
                      "Required": true,
                      "Limit": 1,
                      "Description":"",
                      "Price": 20.00],
                     ["Category":"Size Selection",
                      "Name":"Medium",
                      "Overrides Total": true,
                      "Required": true,
                      "Limit": 1,
                      "Description":"",
                      "Price": 22.50],
                     ["Category":"Size Selection",
                      "Name":"Large",
                      "Overrides Total": true,
                      "Required": true,
                      "Limit": 1,
                      "Description":"",
                      "Price": 25.00]
                    ],
         "Description":"",
         "Price": 20.00],
        ["ID":"35",
         "Photo":"",
         "Category":"Formal Clothes",
         "Name":"Suits",
         "Choices": [["Category":"Suit Type",
                      "Name":"Two-Piece Suit",
                      "Overrides Total": true,
                      "Required": true,
                      "Limit": 1,
                      "Description":"",
                      "Price": 20.00],
                     ["Category":"Suit Type",
                      "Name":"Three-Piece Suit",
                      "Overrides Total": true,
                      "Required": true,
                      "Limit": 1,
                      "Description":"",
                      "Price": 25.00]
                    ],
         "Description":"",
         "Price": 20.00],
        ["ID":"36",
         "Photo":"",
         "Category":"Formal Clothes",
         "Name":"Choir Robes",
         "Choices": [[:]],
         "Description":"",
         "Price": 20.00],
        ["ID":"37",
         "Photo":"",
         "Category":"Formal Clothes",
         "Name":"Formal Gowns",
         "Choices": [[:]],
         "Description":"",
         "Price": 25.00],
        ["ID":"38",
         "Photo":"",
         "Category":"Formal Clothes",
         "Name":"Dresses",
         "Choices": [[:]],
         "Description":"",
         "Price": 25.00]
    ]
    
    /** Set the items array of the menu to include the following item objects*/
    menuRef.updateData(["Items" : items])
    { err in
        if let err = err {
            print("Error updating document: \(err)")
        } else {
            print("Document successfully updated")
        }
    }
}

/** A laundromat menu object that stores an array of order items and associates all of this items with a specific laundromat location when this menu is referenced by each laundromat*/
public class LaundromatMenu: Equatable{
    /** The document identifier associated with this menu*/
    let id: String
    /** The category this menu item belongs to*/
    var category: String
    /** When this menu was created*/
    let created: Date
    /** When this menu was last updated*/
    var updated: Date
    /** The items stored within this menu*/
    var items: Set<OrderItem> = []
    
    init(id: String, category: String, created: Date, updated: Date){
        self.id = id
        self.category = category
        self.created = created
        self.updated = updated
    }
    
    /** Clear the items set of this menu by restoring them to their original values*/
    func clear(){
        for item in items{
            
            if item.itemChoices.isEmpty == false{
                for choice in item.itemChoices{
                    choice.selected = false
                }
            }
            
            item.count = 0
            item.specialInstructions = ""
        }
    }
    
    public static func == (lhs: LaundromatMenu, rhs: LaundromatMenu) -> Bool {
        let condition = lhs.id == rhs.id && lhs.category == rhs.category && lhs.created == rhs.created && lhs.updated == rhs.updated && lhs.items == rhs.items
        return condition
    }
}

/** The delivery method for the order, contactless or in-person*/
public enum OrderDeliveryPreference: Int{
    case inPerson = 1
    case contactless = 2
}

/** The pick up method for the order, contactless or in-person*/
public enum OrderPickupPreference: Int{
    case inPerson = 1
    case contactless = 2
}

/** An identifiable collection of order items objects that is also attached to a customer data model*/
public class Order{
    /** Customer information [Who placed this order]*/
    /** The ID of the customer object that placed this order*/
    var customerID: String
    /** The payment method the customer uses to pay for this order*/
    var customerPaymentMethodID: String
    /** Customer information [Who placed this order]*/
    
    /** An ID string that makes this object identifiable amongst other objects with the same characteristics*/
    let id: String
    /** The general name of this item*/
    var name: String
    /** The time and date when this order was placed*/
    var dateOrderPlaced: Date
    /** The code used to determine the status of this order*/
    var orderStatusCode: OrderStatusCode = .paidAwaitingConfirmation
    /** When this order's status was last updated*/
    var orderStatusLastUpdated: Date = .now
    /** The pick up method for the order, contactless or in-person*/
    var orderPickupPreference: OrderPickupPreference = .inPerson
    /** The delivery method for the order, contactless or in-person*/
    var orderDeliveryPreference: OrderDeliveryPreference = .inPerson
    /** An optional descri*/
    var note: String = ""
    /** The collection of items attached to this order*/
    var items: Set<OrderItem> = []
    /** The total price of this order based off of the total price of the items, state tax and the delivery fee for the driver, this value can be set*/
    lazy var totalPrice: Double = calculateTotalPrice()
    /** The total of this order before taking into account fees and taxes*/
    lazy var subtotal: Double = calculateSubtotal()
    /** Various taxes and fees*/
    lazy var salesTax: Double = calculateSalesTax()
    lazy var deliveryFee: Double = calculateDeliveryFee()
    lazy var serviceFee: Double = calculateServiceFee()
    /** The promotional code that will be used to discount this order*/
    var orderDiscountCode: DiscountCode? = nil
    
    /** Generic constructor*/
    init(id: String, name: String, customerID: String, customerPaymentMethodID: String, dateOrderPlaced: Date) {
        self.id = id
        self.name = name
        
        /** Customer Info*/
        self.customerID = customerID
        self.customerPaymentMethodID = customerPaymentMethodID
        self.dateOrderPlaced = dateOrderPlaced
    }
    
    /** Specify the state tax for the given region to include in the total price of the order*/
    private func getStateTaxPercentage()->Double{
        /** NYS Tax is 8.8%*/
        return 0.088
    }
    
    /** Compute the total sales tax using the subtotal of this order*/
    private func calculateSalesTax()->Double{
        return (subtotal * getStateTaxPercentage()).customRound(.up, precision: .hundredths)
    }
    
    /** Specify the delivery fee to add for this order*/
    private func calculateDeliveryFee()->Double{
        /** Calculate the delivery fee based on the distance of the user from the selected store and the amount of drivers currently available (> distance = > fee, < drivers = > fee)*/
        var deliveryFee: Double = 0
        
        return deliveryFee.customRound(.up, precision: .hundredths)
    }
    
    /** Specify the service fee for this order based on*/
    private func calculateServiceFee()->Double{
        var serviceFee: Double = 0
        
        return serviceFee.customRound(.up, precision: .hundredths)
    }
    
    /** Calculate the value of this order without taxes and fees*/
    private func calculateSubtotal()->Double{
        var subtotal: Double = 0
        
        /** Items without required item choices are added using their given price, items with required item choices are added on the basis of their chosen selection, if an item is added with a requirement for a choice selection but doesn't have that selection then that item is removed from the order as a fail safe*/
        for item in items{
            subtotal += item.getSubtotal()
        }
        
        return subtotal.customRound(.up, precision: .hundredths)
    }
    
    ///Add a different item to the cart depending on the selection of the item choices, compare the item with the items in the cart, if the item is different (comparable) which it should be when the item selection choice is different, in the detail view for the item there should be a button for add to cart and also a stepper and when the user adds to cart compare this item with the other items in the cart and increment the count of those items or make another new item with the given
    
    /** Get the total price of this order by adding the price of each item together**/
    private func calculateTotalPrice()->Double{
        var totalPrice: Double = 0.0
        
        /** The final value is rounded up to the nearest penny (hundredths place), along with the other values*/
        totalPrice = subtotal + deliveryFee + salesTax + serviceFee
        
        return totalPrice.customRound(.up, precision: .hundredths)
    }
}

/** Simple struct for storing discount code data, */
struct DiscountCode{
    /** The name of this promotional code*/
    let codeName: String
    /** The value of this promotional code*/
    let value: Double
    /** The percentage of the item's subtotal discounted by this promotional code*/
    let percentage: Double
    /** The minimum value of the order's subtotal that must be reached before the discount is applied*/
    let minimumOrderValue: Double
    /** The service category in which this discount code must be used [All, Washing, Dry Cleaning]etc.*/
    let itemCategory: String
    /** When this promotional code expires*/
    let expirationDate: Date
    /** The name of this discount that front-end users will see*/
    let displayName: String
    /** An optional description of this promotional code*/
    let description: String = ""
}

/** Fetch the discount code with the given name*/
func fetchDiscountCode(){
    
}

/** Make sure the discount code hasnt expired*/
func isDiscountValid(){
    
}
/** When the user enters a valid promo code update the value of the order with that discount code and then reload the prices displayed in any labels */
