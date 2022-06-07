//
//  Shortcuts.swift
//  Basin
//
//  Created by Justin Cook on 5/14/22.
//

import UIKit

/** A bunch of short cut extensions to make life easier*/

extension UILabel{
    /** Centers text and makes the font size adjustable*/
    func centeredTextDynamicFontSize(){
        self.textAlignment = .center
        self.adjustsFontSizeToFitWidth = true
        self.adjustsFontForContentSizeCategory = true
    }
}

extension UIView{
    /** Center this uiview inside of the given parent view*/
    func centerInsideOf(this parentView: UIView){
        self.frame.origin = CGPoint(x: parentView.frame.width/2 - self.frame.width/2, y: parentView.frame.height/2 - self.frame.height/2)
    }
}

extension Set{
    /** Convert the set into an array*/
    func toArray()->[Any]{
        guard self.isEmpty == false else{
            return []
        }
        
        var array: [Any] = []
        
        for val in self{
            array.append(val)
        }
        
        return array
    }
}

/** Array methods*/
/** - Returns: An array of lowercased strings*/
func lowerCase(this array: [String])->[String]{
    guard array.isEmpty == false else {
        return []
    }
    
    var newArray: [String] = []
    
    for string in array{
        newArray.append(string.lowercased())
    }
    
    return newArray
}

/** - Returns: An array of uppercased strings*/
func upperCase(this array: [String])->[String]{
    guard array.isEmpty == false else {
        return []
    }
    
    var newArray: [String] = []
    
    for string in array{
        newArray.append(string.uppercased())
    }
    
    return newArray
}
/** Array methods*/

/** Add the given view to the current window scene (only 1 for iOS, maybe more for iPadOS)*/
func addToWindow(view: UIView){
    let scenes = UIApplication.shared.connectedScenes
    let windowScene = scenes.first as? UIWindowScene
    let window = windowScene!.windows.first!
    window.addSubview(view)
}

/** Get the safe area insets top value of the current window scene*/
func getStatusBarHeight()->CGFloat{
    let scenes = UIApplication.shared.connectedScenes
    let windowScene = scenes.first as? UIWindowScene
    let window = windowScene?.windows.first
    
    return window?.safeAreaInsets.top ?? 0
}
