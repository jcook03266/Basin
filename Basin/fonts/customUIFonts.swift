//
//  fontPicker.swift
//  Inspec
//
//  Created by Justin Cook on 11/5/21.
//

import SwiftUI

//Global methods for selecting custom fonts
extension UIFont{

}
/** Scaled fonts for dynamic font types that scale to the user's specified font size preference*/
let fontMetrics = UIFontMetrics(forTextStyle: .body)

/** Easy method of selecting a custom font*/
public func getCustomFont(name: customFonts, size: CGFloat, dynamicSize: Bool)->UIFont{
    var customFontName = UIFont.systemFont(ofSize: 0).fontName
    var customUIFont: UIFont
    
    switch name{
    case .Ubuntu_bold:
        customFontName = customFonts.Ubuntu_bold.rawValue
    case .Ubuntu_BoldItalic:
        customFontName = customFonts.Ubuntu_BoldItalic.rawValue
    case .Ubuntu_Italic:
        customFontName = customFonts.Ubuntu_Italic.rawValue
    case .Ubuntu_Light:
        customFontName = customFonts.Ubuntu_Light.rawValue
    case .Ubuntu_LightItalic:
        customFontName = customFonts.Ubuntu_LightItalic.rawValue
    case .Ubuntu_Medium:
        customFontName = customFonts.Ubuntu_Medium.rawValue
    case .Ubuntu_MediumItalic:
        customFontName = customFonts.Ubuntu_MediumItalic.rawValue
    case .Ubuntu_Regular:
        customFontName = customFonts.Ubuntu_Regular.rawValue
    case .PressStart2P_Regular:
        customFontName = customFonts.PressStart2P_Regular.rawValue
    case .Bungee_Regular:
        customFontName = customFonts.Bungee_Regular.rawValue
    }
    
    /** If the custom UI Font can't be used then revert back to a default system font*/
    if UIFont(name: customFontName, size: size) != nil{
        customUIFont = UIFont(name: customFontName, size: size)!
    }
    else{
        customUIFont = UIFont.systemFont(ofSize: size)
    }
    
    /** Enable dynamic font scaling*/
    if dynamicSize == true{
        customUIFont = fontMetrics.scaledFont(for: customUIFont)
    }
    
    return customUIFont
}

/** Enum shortcut for all the custom fonts supported by this project*/
public enum customFonts: String{
    case Ubuntu_bold = "Ubuntu-Bold"
    case Ubuntu_BoldItalic = "Ubuntu-BoldItalic"
    case Ubuntu_Italic = "Ubuntu-Italic"
    case Ubuntu_Light = "Ubuntu-Light"
    case Ubuntu_LightItalic = "Ubuntu-LightItalic"
    case Ubuntu_Medium = "Ubuntu-Medium"
    case Ubuntu_MediumItalic = "Ubuntu-MediumItalic"
    case Ubuntu_Regular = "Ubuntu-Regular"
    case PressStart2P_Regular = "PressStart2P-Regular"
    case Bungee_Regular = "Bungee-Regular"
}


