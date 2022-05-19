//
//  CartsDataModel.swift
//  Stuy Wash N Dry
//
//  Created by Justin Cook on 4/6/22.
//

import UIKit
import FirebaseAuth
import Firebase

/** FIle containing classes and methods that enable the functionality and persistence of Carts, objects that store the items that users want to add to their order and eventually check out with*/

/** Protocol allows the implementing class to listen for updates to the given cart object*/
@objc protocol CartDelegate{
    /** Implement to know when an item has been added to the cart*/
    @objc optional func cart(_ cart: Cart, didAdd item: OrderItem)
    /** Implement to know when an item has been removed from the cart*/
    @objc optional func cart(_ cart: Cart, didRemove item: OrderItem)
    /** Implement to know when an item has updated*/
    @objc optional func cart(_ cart: Cart, didUpdate item: OrderItem)
}

/** Errors to through when fetching, pushing, updating, or deleting cart objects*/
enum CartError: Error{
    case cartNotFound
    case pushFailed
    case updateFailed
    case deletionFailed
    
    var localizedDescription: String{
        switch self{
        case .cartNotFound:
            return NSLocalizedString("This cart was not found in the remote collection.", comment: "The given ID might be incorrect or the cart may not exist yet.")
        case .pushFailed:
            return NSLocalizedString("Fatal error: the cart associated with the given identifier could not be pushed to the remote collection at this time.", comment: "This failure might be because of networking issues, please try again.")
        case .updateFailed:
            return NSLocalizedString("Fatal error: the cart associated with the given identifier could not be updated.", comment: "This failure might be because of networking issues, please try again.")
        case .deletionFailed:
            return NSLocalizedString("Fatal error: the cart associated with the given identifier could not be deleted.", comment: "This failure might be because of networking issues, please try again.")
        }
    }
}

/** An array of cart items used to differentiate between the different order building sessions*/
var carts: Set<Cart> = []

/** Object that stores the items that users want to add to their order and eventually check out with*/
public class Cart: NSObject{
    /** Delegate declaration*/
    var delegate: CartDelegate?
    /** The identifier of this cart object, allows it to be identifiable amongst a collection of other carts*/
    var cartID: String
    /** The id of the user account for which this belongs to*/
    var userID: String
    /** The name of the laundromat this cart belongs to*/
    var laundromatName: String
    /** The laundromat associated with this cart's items*/
    var laundromatStoreID: String
    /** The items being stored inside of this cart*/
    var items: Set<OrderItem> = []
    /** When this cart was created*/
    var created: Date = .now
    /** When this cart was initialized*/
    var updated: Date = .now
    /** Determine if this cart was abandoned or not (if the cart has been persistent for over 6 hours then send a push notification to the user informing them that the cart has been abandoned) This will be used to trigger a cloud function that listens for events in the collection*/
    var abandoned: Bool = false
    /** The value of this cart before taxes and other fees are added*/
    var subtotal: Double = 0
    
    init(cartID: String, userID: String, laundromatStoreID: String, laundromatName: String) {
        self.cartID = cartID
        self.userID = userID
        self.laundromatStoreID = laundromatStoreID
        self.laundromatName = laundromatName
    }
    
    /** Return the total amount of items in the cart, items and their quantities*/
    func getTotalItemQuantity()->Int{
        var quantity: Int = 0
        for item in items {
            quantity += item.count
        }
        return quantity
    }
    
    /** Get the total count for this item, some items have the same everything except item choices so this is a good way to get the total count for specific items*/
    func getTotalCountFor(this item: OrderItem)->Int{
        var quantity: Int = 0
        
        for storedItem in self.items{
            if areTheseItemsSimilar(item1: item, item2: storedItem){
                quantity += storedItem.count
            }
        }
        
        return quantity
    }
    
    /** Clear out the cart of all similar instances of this item*/
    func clearAllInstancesOf(this item: OrderItem){
        for storedItem in self.items{
            if areTheseItemsSimilar(item1: item, item2: storedItem){
                self.removeThis(item: storedItem)
   
            }
        }
    }
    
    /** Add the given order item to the cart (must be unique)*/
    func addThis(item: OrderItem){
            /** If the item passed already exists in the cart then update the count of that item instead of adding another item*/
            for storedItem in self.items{
                if areTheseItemsIdentical(item1: item, item2: storedItem){
                    
                    /** Item count updated so inform the delegate that an update was made instead of an add*/
                    storedItem.count += item.count
                    updateSubtotal()
                    cart(self, didUpdate: storedItem)
                    return
                }
            }
        
            /** If the item isn't already in the cart then insert it and update the subtotal of this cart*/
            self.items.insert(item)
            updateSubtotal()
            cart(self, didAdd: item)
    }
    
    /** Called when a specific item stored in the cart has been updated (count has been updated)*/
    func updateThis(item: OrderItem){
        
        /** Update the quantity of this item stored*/
        for storedItem in self.items{
            if areTheseItemsIdentical(item1: item, item2: storedItem){
                storedItem.count = item.count
                updateSubtotal()
                cart(self, didUpdate: storedItem)
            }
        }
    }
    
    /** Update the value of the subtotal by looping over the total value of all of the items and their counts*/
    private func updateSubtotal(){
        var total: Double = 0.0
        for item in items{
            total += item.getSubtotal()
        }
        
        subtotal = total
    }
    
    /** Remove the given order item from the cart*/
    func removeThis(item: OrderItem){
        guard self.items.contains(item) else{
            ///print("Error: this item doesn't exist in the cart, so it can't be deleted.")
            return
        }
        
        for storedItem in self.items{
            if areTheseItemsIdentical(item1: item, item2: storedItem){
                self.items.remove(storedItem)
                updateSubtotal()
                cart(self, didRemove: storedItem)
            }
        }
    }
    
    /** Compute the discount for this item using the provided discount code*/
    func computeDiscount(discount: DiscountCode)->Double{
        var discountAmount: Double = 0
        
        /** Use the percentage if it's greater than 0, else use the discount value if it's greater than 0*/
        if discount.percentage > 0{
            var percentage: Double = discount.percentage
            
            /** If the discount's percentage is > 1 then divide by 100 to make it a percentage*/
            if discount.percentage > 1{
                percentage = (discount.percentage/100)
            }
            
            discountAmount = (self.subtotal * percentage)
        }
        else if discount.value > 0{
            discountAmount = discount.value
            
            /** Fail safe, the discount amount should not be larger than the subtotal*/
            if discountAmount > subtotal{
                discountAmount = 0
            }
        }
        
        return discountAmount
    }
    
    /** Implementing this delegate method*/
    fileprivate func cart(_ cart: Cart, didAdd item: OrderItem){
        delegate?.cart?(cart, didAdd: item)
    }
    
    /** Implementing this delegate method*/
    fileprivate func cart(_ cart: Cart, didRemove item: OrderItem){
        delegate?.cart?(cart, didRemove: item)
    }
    
    /** Implementing this delegate method*/
    fileprivate func cart(_ cart: Cart, didUpdate item: OrderItem){
        delegate?.cart?(cart, didUpdate: item)
    }
    
    public static func == (lhs: Cart, rhs: Cart) -> Bool {
        let condition = lhs.cartID == rhs.cartID && lhs.userID == rhs.userID && lhs.laundromatStoreID == rhs.laundromatStoreID && lhs.items == rhs.items && lhs.created == rhs.created && lhs.updated == rhs.updated && lhs.abandoned == rhs.abandoned && lhs.subtotal == rhs.subtotal
        return condition
    }
}

/** Generate a random ID using the hash of the current date and the userID associated with the cart*/
func generateCartID(with userID: String)->String{
    return "\(userID)\(Date.now.hashValue)"
}

/** Push this cart object to the remote collection*/
func pushThisCart(cart: Cart){
    let db = Firestore.firestore()
    
    var items: [[String : Any]] = []
    
    for item in cart.items{
        /** Compile all of the item choices (if any)*/
        var itemChoicesData: [[String : Any]] = []
        
        for choice in item.itemChoices{
            let choiceData: [String: Any] = [
                "Category": choice.category,
                "Name": choice.name,
                "Overrides Total": choice.overridesTotalPrice,
                "Required": choice.required,
                "Limit": choice.limit,
                "Description": choice.choiceDescription,
                "Selected": choice.selected,
                "Price": choice.price]
            
            itemChoicesData.append(choiceData)
        }
        
        /** Parse the basic menu data (excluding items) for this item, using these stubs you can reference the complete menu elsewhere*/
        let itemLaundromatMenuData: [String : Any] = [
            "ID": item.menu.id,
            "Category": item.menu.category,
            "Created": item.menu.created,
            "Updated": item.menu.updated
        ]
        
        let itemData: [String : Any] = [
            "ID": item.id,
            "Special Instructions": item.specialInstructions,
            "Photo": item.photoURL as Any,
            "Category": item.category,
            "Name": item.name,
            "Choices": itemChoicesData,
            "Count": item.count,
            "Laundromat Menu": itemLaundromatMenuData,
            "Description": item.itemDescription,
            "Discount": item.discount,
            "Price": item.price]
        
        items.append(itemData)
    }
    
    let data: [String : Any] = [
        "User ID": cart.userID,
        "Laundromat Store ID": cart.laundromatStoreID,
        "Laundromat Name": cart.laundromatName,
        "Items": items,
        "Created": cart.created,
        "Updated": cart.updated,
        "Abandoned": cart.abandoned,
        "Subtotal": cart.subtotal,
    ]
    
    /** Add a new document to the carts collection with a custom document ID*/
    db.collection("Carts").document(cart.cartID).setData(data){ error in
        if let error = error{
            print("Error adding document to Carts collection: \(error)")
        }
        else{
            print("Document added to Carts collection with ID: \(cart.cartID)")
        }
    }
}

/** Update the given cart's data in the remote collection*/
func updateThisCart(cart: Cart){
    let db = Firestore.firestore()
    
    var items: [[String : Any]] = []
    
    for item in cart.items{
        /** Compile all of the item choices (if any)*/
        var itemChoicesData: [[String : Any]] = []
        
        for choice in item.itemChoices{
            let choiceData: [String: Any] = [
                "Category": choice.category,
                "Name": choice.name,
                "Overrides Total": choice.overridesTotalPrice,
                "Required": choice.required,
                "Limit": choice.limit,
                "Description": choice.choiceDescription,
                "Selected": choice.selected,
                "Price": choice.price]
            
            itemChoicesData.append(choiceData)
        }
        
        /** Parse the basic menu data (excluding items) for this item, using these stubs you can reference the complete menu elsewhere*/
        let itemLaundromatMenuData: [String : Any] = [
            "ID": item.menu.id,
            "Category": item.menu.category,
            "Created": item.menu.created,
            "Updated": item.menu.updated
        ]
        
        let itemData: [String : Any] = [
            "ID": item.id,
            "Special Instructions": item.specialInstructions,
            "Photo": item.photoURL as Any,
            "Category": item.category,
            "Name": item.name,
            "Choices": itemChoicesData,
            "Count": item.count,
            "Laundromat Menu": itemLaundromatMenuData,
            "Description": item.itemDescription,
            "Discount": item.discount,
            "Price": item.price]
        
        items.append(itemData)
    }
    
    /** The update to this cart will refresh the updated field's date with the date at the time of the update*/
    db.collection("Carts").document(cart.cartID).updateData(["Items": items,"Updated": Date.now,"Abandoned": cart.abandoned,"Subtotal": cart.subtotal]){ error in
        if let error = error{
            print("Error updating document in Carts collection: \(error)")
        }
        else{
            print("Document with ID: \(cart.cartID) updated in Carts collection")
        }
    }
}

/** Delete this cart object from the remote collection and from the local collection*/
func deleteThisCart(cart: Cart){
    let db = Firestore.firestore()
    
    db.collection("Carts").document(cart.cartID).delete { error in
        if let error = error{
            print("Error: Deletion could not be done at this time \(error.localizedDescription)")
        }
        /** Deletion successful*/
    }
    
    carts.remove(cart)
}

/** Fetch a copy of this specific cart object*/
func fetchThisCart(cart: Cart, completion: @escaping (Cart?)-> ()){
    let db = Firestore.firestore()
    
    db.collection("Carts").document(cart.cartID).getDocument(){ (querySnapshot, err) in
        if let err = err{
            print("Error getting document: \(err)")
            completion(nil)
        }
        else{
            /** Document successfully retrieved*/
            let document = querySnapshot!
            
            guard document.data() != nil else {
                return
            }
            
            let dictionary = document.data()!
            var cartItems: Set<OrderItem> = []
            
            /** Parse this cart object*/
            let cart = Cart(cartID: document.documentID, userID: dictionary["User ID"] as! String, laundromatStoreID: dictionary["Laundromat Store ID"] as! String, laundromatName: dictionary["Laundromat Name"] as! String)
            cart.created = (dictionary["Created"] as! Timestamp).dateValue()
            cart.updated = (dictionary["Updated"] as! Timestamp).dateValue()
            cart.subtotal = dictionary["Subtotal"] as! Double
            cart.abandoned = dictionary["Abandoned"] as! Bool
            
            /** Parse the cart items*/
            let itemsMaps = dictionary["Items"] as! [[String : Any]]
            
            for itemsMap in itemsMaps{
                /** Get the laundromat menu dictionary*/
                let laundromatMenu = itemsMap["Laundromat Menu"] as! [String : Any]
                
                /** Create the main order items to append to the menu*/
                let orderItem = OrderItem(id: itemsMap["ID"] as! String, name: itemsMap["Name"] as! String, category: itemsMap["Category"] as! String, price: itemsMap["Price"] as! Double, menu: LaundromatMenu(id: laundromatMenu["ID"] as! String, category: laundromatMenu["Category"] as! String, created: (laundromatMenu["Created"] as! Timestamp).dateValue(), updated: (laundromatMenu["Updated"] as! Timestamp).dateValue()))
                
                orderItem.specialInstructions = itemsMap["Special Instructions"] as! String
                orderItem.discount = itemsMap["Discount"] as! Double
                orderItem.count = itemsMap["Count"] as! Int
                orderItem.itemDescription = itemsMap["Description"] as! String
                orderItem.photoURL = itemsMap["Photo"] as? String
                
                /** Parse the item choices map*/
                let itemChoiceMaps = itemsMap["Choices"] as! [[String: Any]]
                for itemChoiceMap in itemChoiceMaps{
                    /** Don't try to parse an empty map, errors will occur*/
                    if itemChoiceMap.isEmpty == true{break}
                    
                    let itemChoice = itemChoice(category: itemChoiceMap["Category"] as! String, name: itemChoiceMap["Name"] as! String, price: itemChoiceMap["Price"] as! Double, overridesTotalPrice: itemChoiceMap["Overrides Total"] as! Bool, choiceDescription: itemChoiceMap["Description"] as! String, required: itemChoiceMap["Required"] as! Bool, limit: itemChoiceMap["Limit"] as! Int)
                    itemChoice.selected = itemChoiceMap["Selected"] as? Bool ?? false
                    
                    orderItem.itemChoices.update(with: itemChoice)
                }
                
                cartItems.update(with: orderItem)
            }
            cart.items = cartItems
            
            /** If this cart already exists in the cart set then that prior entry is overwritten by this new member*/
            carts.update(with: cart)
            
            completion(cart)
        }
    }
}

/** Fetch all cart objects associated with the current Auth userID*/
func fetchCarts(){
    carts.removeAll()
    
    if Auth.auth().currentUser != nil{
        let user = Auth.auth().currentUser!
        
        let db = Firestore.firestore()
        
        /** Fetch all of the carts associated with this user's ID*/
        db.collection("Carts").whereField("User ID", isEqualTo: user.uid).getDocuments(){ (querySnapshot, err) in
            if let err = err{
                print("Error getting documents: \(err)")
            }
            else{
                /** Documents successfully retrieved*/
                let documents = querySnapshot!.documents
                
                for document in documents{
                    let dictionary = document.data()
                    
                    var cartItems: Set<OrderItem> = []
                    
                    /** Parse each cart object*/
                    let cart = Cart(cartID: document.documentID, userID: dictionary["User ID"] as! String, laundromatStoreID: dictionary["Laundromat Store ID"] as! String, laundromatName: dictionary["Laundromat Name"] as! String)
                    cart.created = (dictionary["Created"] as! Timestamp).dateValue()
                    cart.updated = (dictionary["Updated"] as! Timestamp).dateValue()
                    cart.subtotal = dictionary["Subtotal"] as! Double
                    cart.abandoned = dictionary["Abandoned"] as! Bool
                    
                    /** Parse the cart items*/
                    let itemsMaps = dictionary["Items"] as! [[String : Any]]
                    
                    for itemsMap in itemsMaps{
                        /** Get the laundromat menu dictionary*/
                        let laundromatMenu = itemsMap["Laundromat Menu"] as! [String : Any]
                        
                        /** Create the main order items to append to the menu*/
                        let orderItem = OrderItem(id: itemsMap["ID"] as! String, name: itemsMap["Name"] as! String, category: itemsMap["Category"] as! String, price: itemsMap["Price"] as! Double, menu: LaundromatMenu(id: laundromatMenu["ID"] as! String, category: laundromatMenu["Category"] as! String, created: (laundromatMenu["Created"] as! Timestamp).dateValue(), updated: (laundromatMenu["Updated"] as! Timestamp).dateValue()))
                        
                        orderItem.specialInstructions = itemsMap["Special Instructions"] as! String
                        orderItem.discount = itemsMap["Discount"] as! Double
                        orderItem.count = itemsMap["Count"] as! Int
                        orderItem.itemDescription = itemsMap["Description"] as! String
                        orderItem.photoURL = itemsMap["Photo"] as? String
                        
                        /** Parse the item choices map*/
                        let itemChoiceMaps = itemsMap["Choices"] as! [[String: Any]]
                        for itemChoiceMap in itemChoiceMaps{
                            /** Don't try to parse an empty map, errors will occur*/
                            if itemChoiceMap.isEmpty == true{break}
                            
                            let itemChoice = itemChoice(category: itemChoiceMap["Category"] as! String, name: itemChoiceMap["Name"] as! String, price: itemChoiceMap["Price"] as! Double, overridesTotalPrice: itemChoiceMap["Overrides Total"] as! Bool, choiceDescription: itemChoiceMap["Description"] as! String, required: itemChoiceMap["Required"] as! Bool, limit: itemChoiceMap["Limit"] as! Int)
                            itemChoice.selected = itemChoiceMap["Selected"] as? Bool ?? false
                            
                            orderItem.itemChoices.update(with: itemChoice)
                        }
                        
                        cartItems.update(with: orderItem)
                    }
                    cart.items = cartItems
                    carts.update(with: cart)
                }
            }
        }
    }
    else{
        print("Error: Carts can't be fetched, a user isn't currently logged in.")
    }
}

/** Create a unique cart for the given laundromat and user, if a cart already exists for this laundromat then delete it and replace it with this one*/
func createACartForThis(laundromat: Laundromat, user: FirebaseAuth.User)->Cart{
    let cart = Cart(cartID: generateCartID(with: user.uid), userID: user.uid, laundromatStoreID: laundromat.storeID, laundromatName: laundromat.nickName)
    
    let result = doesACartExistForThis(laundromat: laundromat)
    if result.0 == true{
        ///print("A cart already exists for this laundromat, deleting and replacing it with a new one.")
        
        deleteThisCart(cart: result.1!)
        
        pushThisCart(cart: cart)
        carts.update(with: cart)
    }
    else{
        pushThisCart(cart: cart)
        carts.update(with: cart)
    }
    
    return cart
}

/** Determine if a cart exists for this, if not then instantiate one*/
func doesACartExistForThis(laundromat: Laundromat)->(Bool,Cart?){
    var bool = false
    var cart: Cart? = nil
    
    if carts.isEmpty == false{
        for element in carts{
            if element.laundromatStoreID == laundromat.storeID{
                cart = element
                bool = true
            }
        }
    }
    
    return (bool,cart)
}
