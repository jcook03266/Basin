//
//  DatabaseInterface.swift
//  Stuy Wash N Dry
//
//  Created by Justin Cook on 2/24/22.
//

import UIKit
import Firebase
import FirebaseCore
import FirebaseFirestore
import PhoneNumberKit
import FirebaseStorage
import FirebaseAuth
import CryptoKit
import CoreLocation

// MARK: - Global Vars
/** Various methods for interfacing with Firebase for this application*/
/** Global var used to inform the app delegate if an account is being created, if so then the account should be deleted if the user unexpectedly quits the application*/
var accountCreationInProgress: Bool = false
/** Authentication credentials are automatically linked*/
/** Credentials used during sign up if a user wants to continue with a third party sign up methods, if any of these are used then they are linked with the user's other auth credentails such as phone, email is already provided by these auth credentials, a verification email is not sent if a user signs up with a third party provider, and the user account is thus marked as email verified by default should these values not be nil*/
var tempGoogleAuthCredential: AuthCredential? = nil
var tempAppleAuthCredential: OAuthCredential? = nil
var tempFacebookAuthCredential: AuthCredential? = nil

/** User type userdefault persistence methods*/
/** Save the a string that identifies the type of user that's currently logged in, only three possible types exist [User, Business, Driver]*/
func setLoggedInUserType(userType: String){
    UserDefaults.standard.removeObject(forKey: "userType")
    UserDefaults.standard.synchronize()
    UserDefaults.standard.set(userType, forKey: "userType")
}

/** Clears the type of  the user logged in, this is mainly used when signing out the current user because the next user might not be the same*/
func clearLoggedInUserType(){
    UserDefaults.standard.removeObject(forKey: "userType")
    UserDefaults.standard.synchronize()
}

/** Get the type of user that's currently logged in [User, Business, Driver] or nil if no user is currently logged in*/
func getLoggedInUserType()->String?{
    var userType:String? = nil
    
    if let string = UserDefaults.standard.object(forKey: "userType") as? String{
        userType = string
    }
    
    return userType
}
/** User type userdefault persistence methods*/

enum AuthCredDeletionErrors: Error{
    case AuthNil
    case userNotFound
    case deletionFailed
    
    var localizedDescription: String{
        switch self{
        case .AuthNil:
            return NSLocalizedString("The provided phone authentication credential is nil.", comment: "To delete a user, please provide a valid credential.")
        case .userNotFound:
            return NSLocalizedString("The user associated with the provided credential was not found.", comment: "This user possibly doesn't exist, or was already deleted, or the given credential was incorrect.")
        case .deletionFailed:
            return NSLocalizedString("Fatal error: the user associated with the provided credentials could not be deleted.", comment: "This failure might be because of networking issues, please try again.")
        }
    }
}

// MARK: - Email verification
/** Check the specified collection (table) for the given email*/
func doesThisEmailExistAlready(email: String, in collection: String, completion: @escaping (Bool)-> ()){
    /** All emails are lower cased*/
    let caseInsensitiveEmail = email.lowercased()
    var exists = false
    
    let db = Firestore.firestore()
    
    /** Create a query reference to the following collection and create a query against the collection*/
    db.collection(collection).whereField("Email", isEqualTo: caseInsensitiveEmail).getDocuments(){ (querySnapshot, err) in
        if let err = err{
            print("Error getting documents: \(err)")
        }
        else{
            /**
             for document in querySnapshot!.documents{
             print("\(document.documentID) => \(document.data())")
             }
             */
            
            /** If a document exists with the given query criteria then the email exists already for a user in the given collection*/
            if querySnapshot!.isEmpty == false{
                exists = true
            }
            
        }
        completion(exists)
    }
}

/** Checks all user information dedicated collections in the database for the email queried*/
func checkIfEmailExistsInDatabase(email: String, completion: @escaping (Bool)-> ()){
    var finalResult = false
    
    /** Pyramid of doom on the main thread asynchronously to avoid blocking with network requests*/
    DispatchQueue.main.async{
        doesThisEmailExistAlready(email: email, in: "Customers", completion: { (result) -> Void in
            if result == true{
                finalResult = result
            }
            
            doesThisEmailExistAlready(email: email, in: "Business", completion: { (result) -> Void in
                if result == true{
                    finalResult = result
                }
                
                doesThisEmailExistAlready(email: email, in: "Drivers", completion: { (result) -> Void in
                    if result == true{
                        finalResult = result
                    }
                    
                    completion(finalResult)
                })
            })
        })
    }
}

// MARK: - Username verification
/** Check the specified collection (table) for the given username*/
func doesThisUsernameExistAlready(username: String, in collection: String, completion: @escaping (Bool)-> ()){
    var exists = false
    
    let db = Firestore.firestore()
    
    /** Create a query reference to the following collection and create a query against the collection*/
    db.collection(collection).whereField("Username", isEqualTo: username).getDocuments(){ (querySnapshot, err) in
        if let err = err{
            print("Error getting documents: \(err)")
        }
        else{
            /**
             for document in querySnapshot!.documents{
             print("\(document.documentID) => \(document.data())")
             }
             */
            
            /** If a document exists with the given query criteria then the username exists already for a user in the given collection*/
            if querySnapshot!.isEmpty == false{
                exists = true
            }
            
        }
        completion(exists)
    }
}

/** Checks all user information dedicated collections in the database for the username queried*/
func checkIfUsernameExistsInDatabase(username: String, completion: @escaping (Bool)-> ()){
    var finalResult = false
    
    /** Pyramid of doom on the main thread asynchronously to avoid blocking with network requests*/
    DispatchQueue.main.async{
        doesThisUsernameExistAlready(username: username, in: "Customers", completion: { (result) -> Void in
            if result == true{
                finalResult = result
            }
            
            doesThisUsernameExistAlready(username: username, in: "Business", completion: { (result) -> Void in
                if result == true{
                    finalResult = result
                }
                
                doesThisUsernameExistAlready(username: username, in: "Drivers", completion: { (result) -> Void in
                    if result == true{
                        finalResult = result
                    }
                    
                    completion(finalResult)
                })
            })
        })
    }
}

// MARK: - Phone number verification
/** Check the specified collection (table) for the given phone number object*/
func doesThisPhoneNumberExistAlready(phoneNumber: PhoneNumber, in collection: String, completion: @escaping (Bool)-> ()){
    var exists = false
    
    /** Parse the phone number object into a CSV containing the country code and the national number like so: [country code, national number]*/
    let phoneNumberCSV = parsePhoneNumberIntoCSV(phoneNumber: phoneNumber)
    
    let db = Firestore.firestore()
    
    /** Create a query reference to the following collection and create a query against the collection*/
    db.collection(collection).whereField("Phone Number", isEqualTo: phoneNumberCSV).getDocuments(){ (querySnapshot, err) in
        if let err = err{
            print("Error getting documents: \(err)")
        }
        else{
            /**
             for document in querySnapshot!.documents{
             print("\(document.documentID) => \(document.data())")
             }
             */
            
            /** If a document exists with the given query criteria then the phone number exists already for a user in the given collection*/
            if querySnapshot!.isEmpty == false{
                exists = true
            }
            
        }
        completion(exists)
    }
}

/** Checks all user information dedicated collections in the database for the phone number queried*/
func checkIfPhoneNumberExistsInDatabase(phoneNumber: PhoneNumber, completion: @escaping (Bool)-> ()){
    var finalResult = false
    
    /** Pyramid of doom on the main thread asynchronously to avoid blocking with network requests*/
    DispatchQueue.main.async{
        doesThisPhoneNumberExistAlready(phoneNumber: phoneNumber, in: "Customers", completion: { (result) -> Void in
            if result == true{
                finalResult = result
            }
            
            doesThisPhoneNumberExistAlready(phoneNumber: phoneNumber, in: "Business", completion: { (result) -> Void in
                if result == true{
                    finalResult = result
                }
                
                doesThisPhoneNumberExistAlready(phoneNumber: phoneNumber, in: "Drivers", completion: { (result) -> Void in
                    if result == true{
                        finalResult = result
                    }
                    
                    completion(finalResult)
                })
            })
        })
    }
}

// MARK: - Upload Profile Picture
/** Uploads the given profile picture to the appropriate firebase cloud storage bucket and directory
 - Parameter image: The image to be converted to the .jpeg format and uploaded to the given directory with the supplemented fileName
 - Parameter directory: The directory where this file will be placed, a blank string or no string will place this file in the root directory
 - Parameter fileName: The name of this file, it's important to have a unique name as conflicting names will result in the upload task failing
 - Parameter imageCompressionQuality: The desired compression for the supplemented image (Range: 1 best quality, 0 lowest quality)
 - Returns: Completion event that supplements the uploaded file's URL
 */
func uploadThisImage(image: UIImage, directory: String, fileName: String, imageCompressionQuality: CGFloat, completion: @escaping (URL?)-> ()){
    DispatchQueue.main.async{
        /** Force the input values to be compliant with the compression quality's standard range*/
        var quality = imageCompressionQuality
        if imageCompressionQuality > 1{
            quality = 1
        }
        else if imageCompressionQuality < 0{
            quality = 0
        }
        
        /** File to upload is already suplemented, convert this into a JPEG with moderate compression*/
        let fileData = image.jpegData(compressionQuality: quality)
        
        /**
         Unique custom file name example: This is very unique because it uses two unique parameters, a unique username and a hash of the current date, these two in conjunction with one another render the probability of conflicts occurring as nearly 0%
         "pfp_user_\(username)_\(Date.now.hashValue)"*/
        
        /** The file type of this image is a jpeg, so the extension is as such*/
        var filePath = "\(directory)/\(fileName).jpeg"
        /** If no directory is specified then the file will be placed in the root folder*/
        if directory == ""{
            filePath = "\(fileName).jpeg"
        }
        
        /**Create a root reference*/
        let storage = Storage.storage(url: "gs://stuy-wash-n-dry/")
        let storageRef = storage.reference()
        
        /** Create a reference to the file you want to upload*/
        let userPFPRef = storageRef.child(filePath)
        
        guard fileData != nil else {
            print("Error: Image invalid, cannot be converted to jpeg")
            return
        }
        
        let metadataType = StorageMetadata()
        metadataType.contentType = "image/jpeg"
        
        /** Upload the file data to the path*/
        userPFPRef.putData(fileData!, metadata: metadataType) { metadata, error in
            
            guard let metadata = metadata else {
                /**Uh-oh, an error occurred!*/
                print("Error: file metadata cannot be retrieved")
                return
            }
            print(metadata)
            
            /** Metadata contains file metadata such as size, content-type.*/
            ///let size = metadata.size
            
            /** The URL of the file is accessible after a successful upload.*/
            userPFPRef.downloadURL { (url, error) in
                guard let downloadURL = url else {
                    /**Uh-oh, an error occurred!*/
                    print("Error: file URL cannot be retrieved")
                    return
                }
                print(downloadURL)
                completion(downloadURL)
            }
        }
    }
}

// MARK: - Auto-Gen ID
/** Autogenerate an employeeID for Drivers*/
func autoGenDriverEmployeeID()->String{
    var ID: String = ""
    
    let numbers = "0123456789"
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    
    ID.append(letters.randomElement()!)
    ID.append(numbers.randomElement()!)
    ID.append(numbers.randomElement()!)
    ID.append(letters.randomElement()!)
    ID.append(letters.randomElement()!)
    ID.append(numbers.randomElement()!)
    ID.append(letters.randomElement()!)
    ID.append(letters.randomElement()!)
    ID.append(numbers.randomElement()!)
    
    return ID
}

/** Autogenerate an employeeID for Business Clients*/
func autoGenBusinessClientEmployeeID()->String{
    var ID: String = ""
    
    let numbers = "0123456789"
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    
    ID.append(numbers.randomElement()!)
    ID.append(letters.randomElement()!)
    ID.append(letters.randomElement()!)
    ID.append(numbers.randomElement()!)
    ID.append(letters.randomElement()!)
    ID.append(numbers.randomElement()!)
    ID.append(numbers.randomElement()!)
    ID.append(letters.randomElement()!)
    ID.append(letters.randomElement()!)
    
    return ID
}

// MARK: - Sign Out
/** Signs out the current user (if any)*/
func signOutCurrentUser(){
    do {
        try Auth.auth().signOut()
    } catch let signOutError as NSError {
        print("Error signing out: %@", signOutError)
    }
    clearLoggedInUserType()
}

// MARK: - User Profile Picture
/** Updates the user's profile picture by deleting the old one and uploading the new one with a fresh unique file name, followed by updating the profile picture field in the corresponding collection*/
func updateUserProfilePicture(){
}

/** Removes the user's profile picture from the storage (if any) and sets the field in the collection entry to "", the default static resource for the profile picture will be used instead*/
func removeUserProfilePicture(){
}

/** Remove the supplemented profile picture from the cloud storage container at the specified path*/
func deleteUserProfilePicture(at path: String){
    /**Create a root reference*/
    let storage = Storage.storage(url: "gs://stuy-wash-n-dry/")
    
    /** Return if the path isn't a valid URL*/
    guard URL(string: path) != nil else {
        print("Error: This path is not a valid URL")
        return
    }

    storage.reference(forURL: path).delete { error in
        if let error = error{
            print("Error encountered while deleting profile picture from cloud storage: \(error.localizedDescription)")
        }
        print("File at \(path) deleted successfully")
    }
}

// MARK: - Delete User
/** Deletes the current user from the authentication provider table as well as the database (if present)*/
func deleteCurrentUser(){
    let user = getCurrentUser()
    
    /** You can't delete empty space*/
    guard user != nil else {
        return
    }
    
    let email = user?.email
    
    /** Delete the user's data in the database (if any)*/
    
    /** The user has to have an email, this is mandatory for their account in the database, if no email is present then this means the user hasn't completed the sign-up process*/
    guard email != nil else {
        user!.delete(completion: { error in
            if let error = error{
                print("Error encountered while deleting current user account: \(error.localizedDescription)")
            }
            /** User successfully deleted*/
            
            signOutCurrentUser()
        })
        return
    }
    
    /** All emails are lower cased*/
    let caseInsensitiveEmail = email!.lowercased()
    
    let db = Firestore.firestore()
    
    /** Create a query reference to the following collection and create a query against the collection*/
    /** Delete the user from the customers collection if they're present there*/
    db.collection("Customers").whereField("Email", isEqualTo: caseInsensitiveEmail).getDocuments(){ (querySnapshot, err) in
        if let err = err{
            print("Error getting documents: \(err.localizedDescription)")
        }
        else{
            
            guard querySnapshot?.documents.isEmpty == false else {
                /** This user doesn't exist, nothing to delete here*/
                print("User not found in 'Customers' collection")
                return
            }
            
            let document = querySnapshot?.documents.first?.reference
            
            /** Delete the user's profile picture from the cloud store*/
            /** Retrieve the field containing the url for the profile picture*/
            let dictionary = querySnapshot?.documents.first?.data()
             
            if let pictureURL = (dictionary!["Profile Picture"] as? String){
                deleteUserProfilePicture(at: pictureURL)
            }
   
            document?.delete(completion: { error in
                if let error = error{
                    print("Error encountered while deleting document in 'Customers' collection \(error.localizedDescription)")
                }
                print("User successfully deleted from 'Customers' collection")
                
                user!.delete(completion: { error in
                    if let error = error{
                        print("Error encountered while deleting current user account: \(error.localizedDescription)")
                    }
                    /** User successfully deleted*/
                    
                    signOutCurrentUser()
                })
            })
        }
    }
    
    /** Delete the user from the drivers collection if they're present there*/
    db.collection("Drivers").whereField("Email", isEqualTo: caseInsensitiveEmail).getDocuments(){ (querySnapshot, err) in
        if let err = err{
            print("Error getting documents: \(err.localizedDescription)")
        }
        else{
            
            guard querySnapshot?.documents.isEmpty == false else {
                /** This user doesn't exist, nothing to delete here*/
                print("User not found in 'Drivers' collection")
                return
            }
            
            let document = querySnapshot?.documents.first?.reference
            document?.delete(completion: { error in
                if let error = error{
                    print("Error encountered while deleting document in 'Drivers' collection \(error.localizedDescription)")
                }
                print("User successfully deleted from 'Drivers' collection")
                
                user!.delete(completion: { error in
                    if let error = error{
                        print("Error encountered while deleting current user account: \(error.localizedDescription)")
                    }
                    /** User successfully deleted*/
                    
                    signOutCurrentUser()
                })
            })
        }
    }
    
    /** Delete the user from the business collection if they're present there*/
    db.collection("Business").whereField("Email", isEqualTo: caseInsensitiveEmail).getDocuments(){ (querySnapshot, err) in
        if let err = err{
            print("Error getting documents: \(err.localizedDescription)")
        }
        else{
            
            guard querySnapshot?.documents.isEmpty == false else {
                /** This user doesn't exist, nothing to delete here*/
                print("User not found in 'Business' collection")
                return
            }
            
            let document = querySnapshot?.documents.first?.reference
            document?.delete(completion: { error in
                if let error = error{
                    print("Error encountered while deleting document in 'Business' collection \(error.localizedDescription)")
                }
                print("User successfully deleted from 'Business' collection")
                
                user!.delete(completion: { error in
                    if let error = error{
                        print("Error encountered while deleting current user account: \(error.localizedDescription)")
                    }
                    /** User successfully deleted*/
                    
                    signOutCurrentUser()
                })
            })
        }
    }
}

// MARK: - Get Current User
/** Get the currently signed in user (if any)*/
func getCurrentUser()->FirebaseAuth.User?{
    var currentUser: FirebaseAuth.User? = nil
    
    if let user = Auth.auth().currentUser{
        currentUser = user
    }
    
    return currentUser
}

// MARK: - Push New User
/** Push and pull methods for User profiles*/
/** Pushes the given customer object to the customer user profile collection
 - Returns: Completion handler with the complete customer object fitted with the documentID for the user's profile as the userID*/
func pushCustomerUserToCollection(customer: Customer, completion: @escaping (Customer)-> ()){
    /** DB reference*/
    let db = Firestore.firestore()
    
    /** Create an email password login credential and link it to the current user*/
    let emailCred = EmailAuthProvider.credential(withEmail: customer.email, password: customer.password)
    
    /** The current user is guaranteed to not be nil because it's mandatory for the user to provide a phone login*/
    /** If a current user already exists then simply link the credential with that user instead of signing in*/
    if let user = Auth.auth().currentUser{
        user.link(with: emailCred, completion: { authResult, error in
            if let error = error{
                globallyTransmit(this: "Account creation failed, please try again", with: UIImage(systemName: "person.crop.circle.badge.exclamationmark.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
                
                print("Error creating user: \(error)")
            }
            else{
                print("User created successfully")
                
                /**print(authResult!)*/
                
                /** Update the user's display name and profile photo URL upon creation*/
                let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                changeRequest?.displayName = customer.firstName
                changeRequest?.photoURL = customer.profile_picture
                changeRequest?.commitChanges { error in
                    if let error = error{
                        print("Error ocurred: \(error)")
                    }
                }
                
                /** Verify the current user's email address if their email isn't already verified, or if they haven't used a third-party provider when signing up, only customers can use third-party accounts to login*/
                if Auth.auth().currentUser?.isEmailVerified == false && tempAppleAuthCredential == nil && tempGoogleAuthCredential == nil && tempFacebookAuthCredential == nil{
                    
                    Auth.auth().currentUser?.sendEmailVerification(completion:{ (error) in
                        if let error = error{
                            /** Some weird error, prompt the user to verify their email later on via the settings menu*/
                            print("Verification email error: \(error.localizedDescription)")
                            
                            globallyTransmit(this: "A verification email could not be sent at this time, please verify your email address in the settings menu later", with: UIImage(systemName: "envelope.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: appThemeColor, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .coverStatusBar, animated: true, duration: 4, selfDismiss: true)
                        }
                        /** Email successfully sent*/
                        globallyTransmit(this: "A verification email has been sent to your email address", with: UIImage(systemName: "envelope.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: appThemeColor, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .coverStatusBar, animated: true, duration: 4, selfDismiss: true)
                        
                    })
                }
                
                customer.user_id = authResult!.user.uid
                
                /** Create a document with an ID corresponding to the userID of the authenticated user account*/
                db.collection("Customers").document(customer.user_id).setData([
                    "Email": customer.email,
                    "Username": customer.username,
                    "Password": customer.password,
                    "Phone Number": customer.phoneNumber,
                    "First Name": customer.firstName,
                    "Last Name": customer.lastName,
                    "Name": customer.name,
                    "DOB": customer.DOB,
                    "Created": customer.created,
                    "Updated": customer.updated,
                    "Gender": getGender(from: customer.gender)!,
                    "Addresses": addressToMap(addresses: customer.addresses),
                    "Profile Picture": customer.profile_picture?.description ?? "",
                    "Membership Level": customer.membershipLevel,
                    "Email Verified": customer.emailVerified
                ]){
                    err in
                    if let err = err{
                        print("Error adding document to Customers collection: \(err)")
                    }
                    else{
                        print("Document added to Customers collection with ID: \(customer.user_id)")
                        
                        /** Add the coordinates for the customer's addresses*/
                        for address in customer.addresses{
                            updateTheCoordinatesOfThisCustomerAddress(address: address, customer: customer)
                        }
                        
                        completion(customer)
                    }
                }
            }
        })
    }
}

/** Pushes the given business client object to the customer user profile collection*/
func pushBusinessClientUserToCollection(businessClient: BusinessClient, completion: @escaping (BusinessClient)-> ()){
    /** DB reference*/
    let db = Firestore.firestore()
    
    /** Create an email password login credential and link it to the current user*/
    let emailCred = EmailAuthProvider.credential(withEmail: businessClient.email, password: businessClient.password)
    
    /** If a current user already exists then simply link the credential with that user instead of signing in*/
    if let user = Auth.auth().currentUser{
        user.link(with: emailCred, completion: { authResult, error in
            if let error = error{
                globallyTransmit(this: "Account creation failed, please try again", with: UIImage(systemName: "person.crop.circle.badge.exclamationmark.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
                
                print("Error creating user: \(error)")
            }
            else{
                print("User created successfully")
                
                /**print(authResult!)*/
                
                /** Update the user's display name and profile photo URL upon creation*/
                let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                changeRequest?.displayName = businessClient.firstName
                changeRequest?.photoURL = businessClient.profile_picture
                changeRequest?.commitChanges { error in
                    if let error = error{
                        print("Error ocurred: \(error)")
                    }
                }
                
                /** Verify the current user's email address*/
                if Auth.auth().currentUser?.isEmailVerified == false{
                    
                    Auth.auth().currentUser?.sendEmailVerification(completion:{ (error) in
                        if let error = error{
                            /** Some weird error, prompt the user to verify their email later on via the settings menu*/
                            print("Verification email error: \(error.localizedDescription)")
                            
                            globallyTransmit(this: "A verification email could not be sent at this time, please verify your email address in the settings menu later", with: UIImage(systemName: "envelope.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: appThemeColor, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .coverStatusBar, animated: true, duration: 4, selfDismiss: true)
                        }
                        /** Email successfully sent*/
                        globallyTransmit(this: "A verification email has been sent to your email address", with: UIImage(systemName: "envelope.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: appThemeColor, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .coverStatusBar, animated: true, duration: 4, selfDismiss: true)
                        
                    })
                }
                
                businessClient.user_id = authResult!.user.uid
                
                /** Create a document with an ID corresponding to the userID of the authenticated user account*/
                db.collection("Business").document(businessClient.user_id).setData([
                    "Email": businessClient.email,
                    "Username": businessClient.username,
                    "Password": businessClient.password,
                    "Phone Number": businessClient.phoneNumber,
                    "First Name": businessClient.firstName,
                    "Last Name": businessClient.lastName,
                    "Name": businessClient.name,
                    "DOB": businessClient.DOB,
                    "Created": businessClient.created,
                    "Updated": businessClient.updated,
                    "Gender": getGender(from: businessClient.gender)!,
                    "Address": addressToDictionary(address: businessClient.address),
                    "Employee ID": autoGenBusinessClientEmployeeID(),
                    "Profile Picture": businessClient.profile_picture?.description ?? ""
                ]){
                    err in
                    if let err = err{
                        print("Error adding document to Business collection: \(err)")
                    }
                    else{
                        print("Document added to Business collection with ID: \(businessClient.user_id)")
                        
                        updateTheCoordinatesOfThisEmployeeAddress(address: businessClient.address, employee: businessClient)
                        
                        completion(businessClient)
                    }
                }
            }
        })
    }
}

/** Pushes the given driver object to the customer user profile collection*/
func pushDriverUserToCollection(driver: Driver, completion: @escaping (Driver)-> ()){
    /** DB reference*/
    let db = Firestore.firestore()
    
    /** Create an email password login credential and link it to the current user*/
    let emailCred = EmailAuthProvider.credential(withEmail: driver.email, password: driver.password)
    
    /** If a current user already exists then simply link the credential with that user instead of signing in*/
    if let user = Auth.auth().currentUser{
        user.link(with: emailCred, completion: {authResult, error in
            if let error = error{
                globallyTransmit(this: "Account creation failed, please try again", with: UIImage(systemName: "person.crop.circle.badge.exclamationmark.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
                
                print("Error creating user: \(error)")
            }
            else{
                print("User created successfully")
                
                /**print(authResult!)*/
                
                /** Update the user's display name and profile photo URL upon creation*/
                let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                changeRequest?.displayName = driver.firstName
                changeRequest?.photoURL = driver.profile_picture
                changeRequest?.commitChanges { error in
                    if let error = error{
                        print("Error ocurred: \(error)")
                    }
                }
                
                /** Verify the current user's email address*/
                if Auth.auth().currentUser?.isEmailVerified == false{
                    
                    Auth.auth().currentUser?.sendEmailVerification(completion:{ (error) in
                        if let error = error{
                            /** Some weird error, prompt the user to verify their email later on via the settings menu*/
                            print("Verification email error: \(error.localizedDescription)")
                            
                            globallyTransmit(this: "A verification email could not be sent at this time, please verify your email address in the settings menu later", with: UIImage(systemName: "envelope.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: appThemeColor, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .coverStatusBar, animated: true, duration: 4, selfDismiss: true)
                        }
                        /** Email successfully sent*/
                        globallyTransmit(this: "A verification email has been sent to your email address", with: UIImage(systemName: "envelope.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: appThemeColor, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .coverStatusBar, animated: true, duration: 4, selfDismiss: true)
                        
                    })
                }
                
                driver.user_id = authResult!.user.uid
                
                /** Create a document with an ID corresponding to the userID of the authenticated user account*/
                db.collection("Drivers").document(driver.user_id).setData([
                    "Email": driver.email,
                    "Username": driver.username,
                    "Password": driver.password,
                    "Phone Number": driver.phoneNumber,
                    "First Name": driver.firstName,
                    "Last Name": driver.lastName,
                    "Name": driver.name,
                    "DOB": driver.DOB,
                    "Created": driver.created,
                    "Updated": driver.updated,
                    "Gender": getGender(from: driver.gender)!,
                    "Address": addressToDictionary(address: driver.address),
                    "Employee ID": autoGenDriverEmployeeID(),
                    "Vehicle Type": "",
                    "Profile Picture": driver.profile_picture?.description ?? ""
                ]){
                    err in
                    if let err = err{
                        print("Error adding document to Drivers collection: \(err)")
                    }
                    else{
                        print("Document added to Drivers collection with ID: \(driver.user_id)")
                        
                        updateTheCoordinatesOfThisDriverAddress(address: driver.address, driver: driver)
                        
                        completion(driver)
                    }
                }
            }
        })
    }
}

// MARK: - Get User Login
/** Get the user data from the customer collection associated with the given third party auth provider's email address. Only customers can use third-party providers to login therefore the default collection referenced is Customers*/
func fetchCustomerLoginUsingThirdParty(userEmail: String?, completion: @escaping (UserLogin?)-> ()){
    
    guard userEmail != nil else {
        print("Critical error: The current user doesn't have an email address.")
        return
    }
    
    /** All emails are lower cased*/
    let caseInsensitiveEmail = userEmail!
    
    let db = Firestore.firestore()
    
    /** Create a query reference to the following collection and create a query against the collection*/
    db.collection("Customers").whereField("Email", isEqualTo: caseInsensitiveEmail).getDocuments(){ (querySnapshot, err) in
        if let err = err{
            print("Error getting documents: \(err)")
        }
        else{
            var userLogin: UserLogin? = nil
            
            /** Check if the email actually exists*/
            guard querySnapshot?.documents.isEmpty == false else {
                globallyTransmit(this: "This third-party account isn't associated with a user in our records", with: UIImage(systemName: "envelope.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 3, selfDismiss: true)
                
                /** This user is unauthorized as it has an incomplete data profile across the backend, remove it immediately*/
                deleteCurrentUser()
                
                return completion(userLogin)
            }
            
            for document in querySnapshot!.documents{
                
                let dictionary = document.data()
                
                userLogin = UserLogin(userID: document.documentID,
                                      username: dictionary["Username"] as! String,
                                      phoneNumber: dictionary["Phone Number"] as! String,
                                      email: dictionary["Email"] as! String,
                                      password: dictionary["Password"] as! String)
            }
            
            completion(userLogin)
        }
    }
}

/** Fetch the login information for a user using a username password combination*/
func fetchThisLogin(from collection: String, username: String, password: String, employeeID: String?, completion: @escaping (UserLogin?)-> ()){
    let db = Firestore.firestore()
    
    /** Create a query reference to the following collection and create a query against the collection*/
    db.collection(collection).whereField("Username", isEqualTo: username).getDocuments(){ (querySnapshot, err) in
        if let err = err{
            print("Error getting documents: \(err)")
        }
        else{
            var userLogin: UserLogin? = nil
            
            /** Check if the username actually exists*/
            guard querySnapshot?.documents.isEmpty == false else {
                globallyTransmit(this: "That username doesn't exist in our records", with: UIImage(systemName: "person.crop.circle.badge.questionmark.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 3, selfDismiss: true)
                
                return completion(userLogin)
            }
            
            for document in querySnapshot!.documents{
                
                let dictionary = document.data()
                
                /** Check if the password matches*/
                guard password == (dictionary["Password"] as! String) else {
                    globallyTransmit(this: "Incorrect password", with: UIImage(systemName: "lock.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 3, selfDismiss: true)
                    return completion(userLogin)
                }
                
                /** Check if the employee ID matches*/
                if employeeID != nil{
                    guard employeeID == (dictionary["Employee ID"] as! String) else {
                        globallyTransmit(this: "Incorrect identification code", with: UIImage(systemName: "person.text.rectangle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 3, selfDismiss: true)
                        return completion(userLogin)
                    }
                }
                
                userLogin = UserLogin(userID: document.documentID,
                                      username: dictionary["Username"] as! String,
                                      phoneNumber: dictionary["Phone Number"] as! String,
                                      email: dictionary["Email"] as! String,
                                      password: dictionary["Password"] as! String)
            }
            
            completion(userLogin)
        }
    }
}

/** Fetch the login information for a user using a phoneNumber password combination*/
func fetchThisLogin(from collection: String, phoneNumber: String, password: String, employeeID: String?, completion: @escaping (UserLogin?)-> ()){
    let db = Firestore.firestore()
    
    /** Create a query reference to the following collection and create a query against the collection*/
    db.collection(collection).whereField("Phone Number", isEqualTo: phoneNumber).whereField("Password", isEqualTo: password).getDocuments(){ (querySnapshot, err) in
        if let err = err{
            print("Error getting documents: \(err)")
        }
        else{
            var userLogin: UserLogin? = nil
            
            /** Check if the phone number actually exists*/
            guard querySnapshot?.documents.isEmpty == false else {
                globallyTransmit(this: "That phone number doesn't exist in our records", with: UIImage(systemName: "iphone.slash.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 3, selfDismiss: true)
                return completion(userLogin)
            }
            
            for document in querySnapshot!.documents{
                
                let dictionary = document.data()
                
                /** Check if the password matches*/
                guard password == (dictionary["Password"] as! String) else {
                    globallyTransmit(this: "Incorrect password", with: UIImage(systemName: "lock.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 3, selfDismiss: true)
                    return completion(userLogin)
                }
                
                /** Check if the employee ID matches*/
                if employeeID != nil{
                    guard employeeID == (dictionary["Employee ID"] as! String) else {
                        globallyTransmit(this: "Incorrect identification code", with: UIImage(systemName: "person.text.rectangle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 3, selfDismiss: true)
                        return completion(userLogin)
                    }
                }
                
                userLogin = UserLogin(userID: document.documentID,
                                      username: dictionary["Username"] as! String,
                                      phoneNumber: dictionary["Phone Number"] as! String,
                                      email: dictionary["Email"] as! String,
                                      password: dictionary["Password"] as! String)
            }
            
            completion(userLogin)
        }
    }
}

/** Fetch the login information for a user using an email password combination*/
func fetchThisLogin(from collection: String, email: String, password: String, employeeID: String?, completion: @escaping (UserLogin?)-> ()){
    /** All emails are lower cased*/
    let caseInsensitiveEmail = email.lowercased()
    
    let db = Firestore.firestore()
    
    /** Create a query reference to the following collection and create a query against the collection*/
    db.collection(collection).whereField("Email", isEqualTo: caseInsensitiveEmail).whereField("Password", isEqualTo: password).getDocuments(){ (querySnapshot, err) in
        if let err = err{
            print("Error getting documents: \(err)")
        }
        else{
            var userLogin: UserLogin? = nil
            
            /** Check if the email actually exists*/
            guard querySnapshot?.documents.isEmpty == false else {
                globallyTransmit(this: "That email doesn't exist in our records", with: UIImage(systemName: "envelope.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 3, selfDismiss: true)
                return completion(userLogin)
            }
            
            for document in querySnapshot!.documents{
                
                let dictionary = document.data()
                
                /** Check if the password matches*/
                guard password == (dictionary["Password"] as! String) else {
                    globallyTransmit(this: "Incorrect password", with: UIImage(systemName: "lock.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 3, selfDismiss: true)
                    return completion(userLogin)
                }
                
                /** Check if the employee ID matches*/
                if employeeID != nil{
                    guard employeeID == (dictionary["Employee ID"] as! String) else {
                        globallyTransmit(this: "Incorrect identification code", with: UIImage(systemName: "person.text.rectangle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 3, selfDismiss: true)
                        return completion(userLogin)
                    }
                }
                
                userLogin = UserLogin(userID: document.documentID,
                                      username: dictionary["Username"] as! String,
                                      phoneNumber: dictionary["Phone Number"] as! String,
                                      email: dictionary["Email"] as! String,
                                      password: dictionary["Password"] as! String)
            }
            
            completion(userLogin)
        }
    }
}

// MARK: - Sign In The User
/** Use the given input [email, phone, username] and password to detect if an account matches the given credentials, and then sign in using the associated email and password combination from the given collection
 - Returns: AuthDataResult which provides details on the signed in user (if any)*/
func signInUsing(input: String, password: String, employeeID: String?, collection: String, completion: @escaping (AuthDataResult?)-> ()){
    
    switch classifyInput(input: input){
    case "username":
        /** Find the user profile associated with this username and password and then use the email and password to sign in*/
        fetchThisLogin(from: collection, username: input, password: password, employeeID: employeeID) { (userLogin) in
            /** If a user login doesn't exist then the account doesn't exist*/
            guard userLogin != nil else {
                return completion(nil)
            }
            
            Auth.auth().signIn(withEmail: userLogin!.email, password: userLogin!.password, completion: {(result,error) in
                if let error = error{
                    print(error)
                    completion(nil)
                }
                else{
                    print("Sign in successful for user: \(result!.user.description)")
                    completion(result)
                }
            })
        }
    case "email":
        /** Sign in like normal with the email and password*/
        Auth.auth().signIn(withEmail: input, password: password, completion: {(result,error)  in
            if let error = error{
                print(error)
                completion(nil)
            }
            else{
                print("Sign in successful for user: \(result!.user.description)")
                completion(result)
            }
        })
    case "phone":
        /** Turn the given phone number into a CSV with the default country code of 1 for the "US"*/
        let phoneNumberCSV = "1,\(input)"
        
        /** Find the user profile associated with this number and password and then use the email and password to sign in*/
        fetchThisLogin(from: collection, phoneNumber: phoneNumberCSV, password: password, employeeID: employeeID) { (userLogin) in
            /** If a user login doesn't exist then the account doesn't exist*/
            guard userLogin != nil else {
                return completion(nil)
            }
            
            Auth.auth().signIn(withEmail: userLogin!.email, password: userLogin!.password, completion: {(result,error) in
                if let error = error{
                    print(error)
                    completion(nil)
                }
                else{
                    print("Sign in successful for user: \(result!.user.description)")
                    completion(result)
                }
            })
        }
    default:
        break
    }
    
}

// MARK: - Pull User Data
/** Pulls all data for this customer from the customer profile collection and formulates a customer object from that data*/
func pullThisCustomer(customerID: String, completion: @escaping (Customer?)-> ()){
    let db = Firestore.firestore()
    let collectionPath = "Customers"
    
    db.collection(collectionPath).document(customerID).getDocument(){
        (querySnapshot, err) in
            if let err = err{
                print("Error getting document: \(err)")
                completion(nil)
            }
            else{
                guard querySnapshot!.data() != nil else {
                    print("Error the document is empty!")
                    completion(nil)
                    return
                }
                
                let dictionary = querySnapshot!.data()!
                
                let profilePictureURL = URL(string: dictionary["Profile Picture"] as! String)
                let userID = querySnapshot!.documentID
                
                /** A user has to be signed in to read data*/
                guard Auth.auth().currentUser != nil else {
                    completion(nil)
                    return
                }
                
                let verifiedEmail = Auth.auth().currentUser!.isEmailVerified
                let fullName = dictionary["Name"] as! String
                let firstName = dictionary["First Name"] as! String
                let lastName = dictionary["Last Name"] as! String
                let gender = getGender(from: dictionary["Gender"] as! UInt)!
                let addressMap = dictionary["Addresses"] as! [[String : Any]]
                
                var addresses: [Address] = []
                
                for address in addressMap {
                    let zipCode = address["Zip Code"] as! Int
                    let borough = getBoroughFrom(string: address["Borough"] as! String)!
                    let addressType = AddressType(rawValue: address["Address Type"] as! Int) ?? AddressType.other
                    let coordinates = address["Coordinates"] as? GeoPoint
                     
                    let parsedAddress = Address(borough: borough, zipCode: UInt(exactly: zipCode)!, alias: address["Alias"] as! String, streetAddress1: address["Address 1"] as! String, streetAddress2: address["Address 2"] as! String, specialInstructions: address["Instructions"] as! String, addressType: addressType)
                    
                    if coordinates != nil{
                    parsedAddress.coordinates = geopointToCLLocationCoordinate(geopoint: coordinates!)
                    }
                    else{
                    parsedAddress.coordinates = nil
                    }

                    /**
                    parsedAddress.country = ["Country"] as! String
                    parsedAddress.state = ["State"] as! String
                    parsedAddress.city = ["City"] as! String
                     */
                    
                    addresses.append(parsedAddress)
                }
   
                let customer = Customer(profile_picture: profilePictureURL, created: (dictionary["Created"] as! Timestamp).dateValue(), updated: (dictionary["Updated"] as! Timestamp).dateValue(), user_id: userID, username: dictionary["Username"] as! String, email: dictionary["Email"] as! String, password: dictionary["Password"] as! String, name: fullName, firstName: firstName, lastName: lastName, phoneNumber: dictionary["Phone Number"] as! String, gender: gender, DOB: (dictionary["DOB"] as! Timestamp).dateValue(), emailVerified: verifiedEmail, membershipLevel: dictionary["Membership Level"] as! UInt8, addresses: addresses)
                
                completion(customer)
            }
    }
}

/** Pulls all data for this business client from the business client profile collection and formulates a business client object from that data*/
func pullThisEmployee(businessClientID: String){
    
}

/** Pulls all data for this driver from the driver profile collection and formulates a driver object from that data*/
func pullThisDriver(driverID: String){
    
}
/** Push and pull methods for User profiles*/

// MARK: - Update Address
/** Update the user's current address(es)*/
func updateAddressesOfThisCustomer(customer: Customer){
    let db = Firestore.firestore()
    let collectionPath = "Customers"
    let mappedAddresses = addressToMap(addresses: customer.addresses)
    
    db.collection(collectionPath).document(customer.user_id).updateData(["Addresses" : mappedAddresses])
}

func updateAddressOfThisEmployee(employee: BusinessClient){
    let db = Firestore.firestore()
    let collectionPath = "Business"
    let mappedAddress = addressToDictionary(address: employee.address)
    
    db.collection(collectionPath).document(employee.user_id).updateData(["Addresses" : mappedAddress])
}

func updateAddressOfThisDriver(driver: Driver){
    let db = Firestore.firestore()
    let collectionPath = "Drivers"
    let mappedAddress = addressToDictionary(address: driver.address)
    
    db.collection(collectionPath).document(driver.user_id).updateData(["Addresses" : mappedAddress])
}
