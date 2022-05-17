//
//  ShoppingCartsListVC.swift
//  Basin
//
//  Created by Justin Cook on 5/15/22.
//

import UIKit

/** VC In which a list of all shopping carts are displayed*/
public class ShoppingCartsListVC: UIViewController{
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
