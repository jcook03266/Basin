//
//  ShoppingCartVC.swift
//  Stuy Wash N Dry
//
//  Created by Justin Cook on 3/28/22.
//

import UIKit

/** View controller in which the user will be able to view their order and proceed with checkout, the shopping cart is persistent and will be saved upon the user exiting the application, a push notification will remind the user that they have items in their shopping cart still after the app has been terminated whilst there are items in said cart*/
public class ShoppingCartVC: UIViewController{
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
