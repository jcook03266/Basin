//
//  BusinessClientVC.swift
//  Stuy Wash N Dry
//
//  Created by Justin Cook on 3/3/22.
//

import UIKit

/** View controller that hosts all business client side operations*/
public class BusinessClientVC: UIViewController{
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
    }
    
    /** Set the specifics of this view controller*/
    func configure(){
        self.view.backgroundColor = bgColor
    }
    
}
