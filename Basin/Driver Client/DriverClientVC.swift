//
//  DriverClientVC.swift
//  Stuy Wash N Dry
//
//  Created by Justin Cook on 3/3/22.
//

import UIKit

/** View controller that hosts all driver client side operations*/
public class DriverClientVC: UIViewController{
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
    }
    
    /** Set the specifics of this view controller*/
    func configure(){
        self.view.backgroundColor = bgColor
    }
    
}
