//
//  BusinessDataModel.swift
//  Stuy Wash N Dry
//
//  Created by Justin Cook on 2/10/22.
//

import UIKit
/** Custom data model class and various other utils used to represent and store the information associated with Business client entities*/

// MARK: - Business Client Class
/** Driver profile model that stores the customer's profile properties and updates the remote entry using local changes*/
public class BusinessClient: User{
    var employee_id: String
    /** Where do you live?*/
    var address: Address
    
    init(created: Date, updated: Date, user_id: String, employee_id: String, username: String, email: String, password: String, name: String, firstName: String, lastName: String, phoneNumber: String, gender: String, DOB: Date, profile_picture: URL?, address: Address){
        self.employee_id = employee_id
        self.address = address
        
        super.init(created: created, updated: updated, profile_picture: profile_picture, user_id: user_id, username: username, email: email, password: password, name: name, firstName: firstName, lastName: lastName, phoneNumber: phoneNumber, gender: gender, DOB: DOB)
    }
}
