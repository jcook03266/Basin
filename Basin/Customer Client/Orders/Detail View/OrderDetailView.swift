//
//  OrderDetailView.swift
//  Stuy Wash N Dry
//
//  Created by Justin Cook on 3/29/22.
//
import UIKit

/** Detail view controller for the past order cells that allows the user to see their past order and use it to reorder*/
public class PastOrderDetailVC: UIViewController{
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

/** Detail view controller for the current order cells that allows the user to see their current order's progress and make any changes if necessary*/
public class CurrentOrderDetailVC: UIViewController{
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
