//
//  StringExtension.swift
//  Inspec
//
//  Created by Justin Cook on 11/3/21.
//

import Foundation

extension String{
    
    /** Removes the last character(s) of the string if it's a blank character
    This is to prevent rejection when submitting text that's not supposed to contain trailing space characters
     
    - Returns: A string containing no trailing space characters
     */
    mutating func removeEmptyLastChar()->String{
        //Flip the string so that any blank chars are at the start of it
        var copyString = String(self.reversed())

        for (_, char) in copyString.enumerated(){
            //Remove the first char in the string until a non space char is reached
            if char == " "{
                copyString.remove(at: self.index(self.startIndex, offsetBy: 0))
            }
            else{
                break
            }
        }
        
        return String(copyString.reversed())
    }
    
    /** Removes all whitespace (space characters) from the string and returns the edited version*/
    func removeAllSpaceChars()->String{
        return self.filter { !$0.isWhitespace }
    }
    
    /** Parses a string containing comma separated values into an array of those values*/
    func parseCSVIntoArray()->[String]{
        var copyString = String()
        var array = [String]()
        
        for (index, char) in self.enumerated(){
            
            /** Don't append white space or commas into the copy string*/
            if char != " " && char != ","{
                copyString.append(char)
            }
            if char == ","{
                /** Reached a comma so append the value stored behind it*/
                /** Append the parsed string to the array and flush the appended chars from the copy string then start over with the new word separated by a comma (if any)*/
                array.append(copyString)
                copyString.removeAll()
            }
            else if index == self.count - 1{
                /** Reached the end of the string so append whatever is left*/
                array.append(copyString)
                copyString.removeAll()
            }
        }
        
        return array
    }
}

