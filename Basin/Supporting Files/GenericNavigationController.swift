//
//  GenericNavigationController.swift
//  Stuy Wash N Dry
//
//  Created by Justin Cook on 3/24/22.
//

import UIKit

/** Generic navigation controller class that allows for the styling of the status bar*/
public class GenericNavigationController: UINavigationController{
/** Status bar styling variables*/
public override var preferredStatusBarStyle: UIStatusBarStyle{
    switch darkMode{
    case true:
        return .lightContent
    case false:
        return .darkContent
    }
}
public override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation{
    return .slide
}
/** Specify status bar display preference*/
public override var prefersStatusBarHidden: Bool {
    return false
}
/** Status bar styling variables*/
}
