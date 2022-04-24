//
//  attributeThisString.swift
//  Inspec
//
//  Created by Justin Cook on 7/15/21.
//

import Foundation
import SwiftUI

extension UIViewController{
    /** Convert a string into a mutable attributed string with a substring customized by the given parameters
     Uses single substring*/
    func attribute(this String: String, font: UIFont, mainColor: UIColor, subColor: UIColor, subString: String)->NSMutableAttributedString{
        
        /**Stylize the entire string*/
        let attributedString = NSMutableAttributedString(string: String, attributes: [NSAttributedString.Key.font : font, .foregroundColor: mainColor])
        
        ///If the string contains the substring then stylize the substring
        if(String.contains(subString)){
            attributedString.setAttributes([NSAttributedString.Key.font : font, NSAttributedString.Key.foregroundColor: subColor], range: (String as NSString).range(of: subString))
        }
        else if(subString != ""){
            print("Attributed String Error: Substring not found")///Error handling
        }
        return attributedString
    }
    
    /** Allow a secondary font to be applied to the substring*/
    func attribute(this String: String, font: UIFont, subFont: UIFont, mainColor: UIColor, subColor: UIColor, subString: String)->NSMutableAttributedString{
        
        /**Stylize the entire string*/
        let attributedString = NSMutableAttributedString(string: String, attributes: [NSAttributedString.Key.font : font, .foregroundColor: mainColor])
        
        ///If the string contains the substring then stylize the substring
        if(String.contains(subString)){
            attributedString.setAttributes([NSAttributedString.Key.font : subFont, NSAttributedString.Key.foregroundColor: subColor], range: (String as NSString).range(of: subString))
        }
        else if(subString != ""){
            print("Attributed String Error: Substring not found")///Error handling
        }
        return attributedString
    }
    
    /** Convert a string into a mutable attributed string with a substring customized by the given parameters
     Uses multiple substrings*/
    func attribute(this String: String, font: UIFont, mainColor: UIColor, subColor: UIColor, subStrings: [String])->NSMutableAttributedString{
        
        ///Stylize the entire string
        let attributedString = NSMutableAttributedString(string: String, attributes: [NSAttributedString.Key.font : font, .foregroundColor: mainColor])
        
        ///If the string contains the substring then stylize the substring
        for subString in subStrings{
            if(String.contains(subString)){
                attributedString.setAttributes([NSAttributedString.Key.font: font, .foregroundColor: subColor], range: (String as NSString).range(of: subString))
            }
            else if(subString != ""){
                print("Attributed String Error: Substring not found")///Error handling
            }
        }
        return attributedString
    }
    
    /** Allow a secondary font to be applied to the substrings*/
    func attribute(this String: String, font: UIFont, subFont: UIFont, mainColor: UIColor, subColor: UIColor, subStrings: [String])->NSMutableAttributedString{
        
        ///Stylize the entire string
        let attributedString = NSMutableAttributedString(string: String, attributes: [NSAttributedString.Key.font : font, .foregroundColor: mainColor])
        
        ///If the string contains the substring then stylize the substring
        for subString in subStrings{
            if(String.contains(subString)){
                attributedString.setAttributes([NSAttributedString.Key.font: subFont, .foregroundColor: subColor], range: (String as NSString).range(of: subString))
            }
            else if(subString != ""){
                print("Attributed String Error: Substring not found")///Error handling
            }
        }
        return attributedString
    }
    
    /** Recolor and underline a string and return attributed text*/
    func attribute(this String: String, font: UIFont, mainColor: UIColor, subColor: UIColor, subStrings: [String], style: underlineStyle?, underlinedSubStrings: [String], underlinedStringColor: UIColor)->NSMutableAttributedString{
        
        ///Stylize the entire string
        let attributedString = NSMutableAttributedString(string: String, attributes: [NSAttributedString.Key.font : font, .foregroundColor: mainColor])
        
        ///If the string contains the substring then stylize the substring
        for subString in subStrings{
            if(String.contains(subString)){
                attributedString.setAttributes([NSAttributedString.Key.font: font, .foregroundColor: subColor], range: (String as NSString).range(of: subString))
            }
            else if(subString != ""){
                print("Attributed String Error: Substring not found")///Error handling
            }
        }
        
        if(style != nil){
            var underlineStyle = NSUnderlineStyle.single.rawValue
            switch style {
            case .single:
                underlineStyle = NSUnderlineStyle.single.rawValue
            case .thick:
                underlineStyle = NSUnderlineStyle.thick.rawValue
            case .double:
                underlineStyle = NSUnderlineStyle.double.rawValue
            case .dashed:
                underlineStyle = NSUnderlineStyle.patternDash.union(.single).rawValue
            case .dashDot:
                underlineStyle = NSUnderlineStyle.patternDashDot.union(.single).rawValue
            case .dashDotDot:
                underlineStyle = NSUnderlineStyle.patternDashDotDot.union(.single).rawValue
            case .dotted:
                underlineStyle = NSUnderlineStyle.patternDot.union(.single).rawValue
            case .byWord:
                underlineStyle = NSUnderlineStyle.byWord.rawValue
            case .none:
                break
            }
            for subString in underlinedSubStrings{
                attributedString.addAttribute(NSMutableAttributedString.Key.underlineStyle, value: underlineStyle, range: (String as NSString).range(of: subString))
                attributedString.addAttribute(NSMutableAttributedString.Key.underlineColor, value: underlinedStringColor, range: (String as NSString).range(of: subString))
            }
        }
        return attributedString
    }
    
    /** Allow a secondary font to be applied to the substrings*/
    func attribute(this String: String, font: UIFont, subFont: UIFont, mainColor: UIColor, subColor: UIColor, subStrings: [String], style: underlineStyle?, underlinedSubStrings: [String], underlinedStringColor: UIColor)->NSMutableAttributedString{
        
        ///Stylize the entire string
        let attributedString = NSMutableAttributedString(string: String, attributes: [NSAttributedString.Key.font : font, .foregroundColor: mainColor])
        
        ///If the string contains the substring then stylize the substring
        for subString in subStrings{
            if(String.contains(subString)){
                attributedString.setAttributes([NSAttributedString.Key.font: subFont, .foregroundColor: subColor], range: (String as NSString).range(of: subString))
            }
            else if(subString != ""){
                print("Attributed String Error: Substring not found")///Error handling
            }
        }
        
        if(style != nil){
            var underlineStyle = NSUnderlineStyle.single.rawValue
            switch style {
            case .single:
                underlineStyle = NSUnderlineStyle.single.rawValue
            case .thick:
                underlineStyle = NSUnderlineStyle.thick.rawValue
            case .double:
                underlineStyle = NSUnderlineStyle.double.rawValue
            case .dashed:
                underlineStyle = NSUnderlineStyle.patternDash.union(.single).rawValue
            case .dashDot:
                underlineStyle = NSUnderlineStyle.patternDashDot.union(.single).rawValue
            case .dashDotDot:
                underlineStyle = NSUnderlineStyle.patternDashDotDot.union(.single).rawValue
            case .dotted:
                underlineStyle = NSUnderlineStyle.patternDot.union(.single).rawValue
            case .byWord:
                underlineStyle = NSUnderlineStyle.byWord.rawValue
            case .none:
                break
            }
            for subString in underlinedSubStrings{
                attributedString.addAttribute(NSMutableAttributedString.Key.underlineStyle, value: underlineStyle, range: (String as NSString).range(of: subString))
                attributedString.addAttribute(NSMutableAttributedString.Key.underlineColor, value: underlinedStringColor, range: (String as NSString).range(of: subString))
            }
        }
        return attributedString
    }
}

extension UIView{
    /** Convert a string into a mutable attributed string with a substring customized by the given parameters
     Uses single substring*/
    func attribute(this String: String, font: UIFont, mainColor: UIColor, subColor: UIColor, subString: String)->NSMutableAttributedString{
        
        ///Stylize the entire string
        let attributedString = NSMutableAttributedString(string: String, attributes: [NSAttributedString.Key.font : font, .foregroundColor: mainColor])
        
        ///If the string contains the substring then stylize the substring
        if(String.contains(subString)){
            attributedString.setAttributes([NSAttributedString.Key.font: font, .foregroundColor: subColor], range: (String as NSString).range(of: subString))
        }
        else{
            ///print("Attributed String Error: Substring not found")//Error handling
        }
        return attributedString
    }
    
    /** Convert a string into a mutable attributed string with a substring customized by the given parameters
     Uses multiple substrings*/
    func attribute(this String: String, font: UIFont, mainColor: UIColor, subColor: UIColor, subStrings: [String])->NSMutableAttributedString{
        
        ///Stylize the entire string
        let attributedString = NSMutableAttributedString(string: String, attributes: [NSAttributedString.Key.font : font, .foregroundColor: mainColor])
        
        ///If the string contains the substring then stylize the substring
        for subString in subStrings{
            if(String.contains(subString)){
                attributedString.setAttributes([NSAttributedString.Key.font: font, .foregroundColor: subColor], range: (String as NSString).range(of: subString))
            }
            else if(subString != ""){
                print("Attributed String Error: Substring not found")///Error handling
            }
        }
        return attributedString
    }
}

extension String{
    
    /** Convert a string into a mutable attributed string with a substring customized by the given parameters
     Uses single substring*/
    func attribute(subString: String, font: UIFont, mainColor: UIColor, subColor: UIColor)->NSMutableAttributedString{
        
        ///Stylize the entire string
        let attributedString = NSMutableAttributedString(string: self, attributes: [NSAttributedString.Key.font : font, .foregroundColor: mainColor])
        
        ///If the string contains the substring then stylize the substring
        if(self.contains(subString)){
            attributedString.setAttributes([NSAttributedString.Key.font: font, .foregroundColor: subColor], range: (self as NSString).range(of: subString))
        }
        else if(subString != ""){
            print("Attributed String Error: Substring not found")///Error handling
        }
        return attributedString
    }
    
    /** Convert a string into a mutable attributed string with a substring customized by the given parameters
     Uses multiple substrings*/
    func attribute(subStrings: [String], font: UIFont, mainColor: UIColor, subColor: UIColor)->NSMutableAttributedString{
        
        ///Stylize the entire string
        let attributedString = NSMutableAttributedString(string: self, attributes: [NSAttributedString.Key.font : font, .foregroundColor: mainColor])
        
        ///If the string contains the substring then stylize the substring
        for subString in subStrings{
            if(self.contains(subString)){
                attributedString.setAttributes([NSAttributedString.Key.font: font, .foregroundColor: subColor], range: (self as NSString).range(of: subString))
            }
            else if(subString != ""){
                print("Attributed String Error: Substring not found")///Error handling
            }
        }
        return attributedString
    }
    
    /** Remove a substring from a string and return the string as an attributed string*/
    func crop(this subString: String)->String{
        let attributedString = NSMutableAttributedString(string: self)
        
        if(self.contains(subString)){
            attributedString.deleteCharacters(in: (self as NSString).range(of: subString))
        }
        else if(subString != ""){
            print("Attributed String Error: Substring not found")///Error handling
        }
        return attributedString.string
    }
    
    mutating func removeAllAfter(this subString: String)->String{
        if(self.contains(subString)){
            self.removeSubrange(self.range(of: subString)!.upperBound..<self.endIndex)
        }
        else if(subString != ""){
            print("String Error: Substring not found")///Error handling
        }
        return self
    }
    
    /** Underline the text in a specific string and return an attributed text*/
    func underLineText(subString: String, font: UIFont, style: underlineStyle, mainColor: UIColor, subColor: UIColor)-> NSMutableAttributedString{
        let attributedText = NSMutableAttributedString(string: self, attributes: [NSAttributedString.Key.font : font, .foregroundColor: mainColor])
        
        var underlineStyle = NSUnderlineStyle.single.rawValue
        switch style {
        case .single:
            underlineStyle = NSUnderlineStyle.single.rawValue
        case .thick:
            underlineStyle = NSUnderlineStyle.thick.rawValue
        case .double:
            underlineStyle = NSUnderlineStyle.double.rawValue
        case .dashed:
            underlineStyle = NSUnderlineStyle.patternDash.rawValue
        case .dashDot:
            underlineStyle = NSUnderlineStyle.patternDashDot.rawValue
        case .dashDotDot:
            underlineStyle = NSUnderlineStyle.patternDashDotDot.rawValue
        case .dotted:
            underlineStyle = NSUnderlineStyle.patternDot.rawValue
        case .byWord:
            underlineStyle = NSUnderlineStyle.byWord.rawValue
        }
        
        attributedText.addAttribute(NSMutableAttributedString.Key.underlineStyle, value: underlineStyle, range: (self as NSString).range(of: subString))
        return attributedText
    }
}

/** Style of the underline for attributed text */
enum underlineStyle: Int{
    case single = 1
    case thick = 2
    case double = 3
    case dashed = 4
    case dashDot = 5
    case dashDotDot = 6
    case dotted = 7
    case byWord = 8
}
