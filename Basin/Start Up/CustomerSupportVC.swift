//
//  CustomerSupportVC.swift
//  Stuy Wash N Dry
//
//  Created by Justin Cook on 3/28/22.
//

import UIKit

/** View Controller that hosts a customer support chat client in which a user can interact with a customer service representative*/
public class CustomerSupportUserClient: UIViewController{
    public override func viewDidLoad() {
        configure()
        constructUI()
    }
    
    /** Construct the UI for this VC*/
    func constructUI(){
        self.view.backgroundColor = bgColor
    }
    
    func configure(){
    }
}

/** View Controller that hosts a customer support chat client in a customer support representative can talk to a user and assist them using the tools available to them*/
public class CustomerSupportRepresentativeClient: UIViewController{
    public override func viewDidLoad() {
        configure()
        constructUI()
    }
    
    /** Construct the UI for this VC*/
    func constructUI(){
        self.view.backgroundColor = bgColor
    }
    
    func configure(){
    }
}
