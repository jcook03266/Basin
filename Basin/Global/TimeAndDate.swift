//
//  TimeAndDate.swift
//  Stuy Wash N Dry
//
//  Created by Justin Cook on 3/28/22.
//

import UIKit

/** File that contains useful methods pertaining to time and dates*/

/** Specifies the four different periods of a day*/
public enum timeOfDay: String{
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"
    case night = "Night"
}

/** Determine what time of day it currently is*/
func whatTimeOfDayIsIt()->timeOfDay{
    var timeOfDay: timeOfDay!
    let currentDate = Date.now
    
    /** Create a formatter to format the date in a 12 hour format*/
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mma"
    
    let currentTimeString = formatter.string(from: currentDate)
    let currentTime = formatter.date(from: currentTimeString)!
    
    /** Morning*/
    let morningBeginning = formatter.date(from: "4:00AM")
    let morningEnd = formatter.date(from: "1:00PM")
    
    /** Afternoon*/
    let afternoonBeginning = formatter.date(from: "1:00PM")
    let afternoonEnd = formatter.date(from: "5:00PM")
    
    /** Evening*/
    let eveningBeginning = formatter.date(from: "5:00PM")
    let eveningEnd = formatter.date(from: "9:00PM")
    
    /** Night*/
    let nightBeginning = formatter.date(from: "9:00PM")
    /** To differentiate between morning and night midnight has to be considered*/
    let midnight = formatter.date(from: "12:00AM")
    let nightEnd = formatter.date(from: "4:00AM")
    
    /** Array full of all the date times so that checking if any are nil can be done without a hassle*/
    let allTimes: [Date?] = [currentTime,morningBeginning,morningEnd,afternoonBeginning,afternoonEnd,eveningBeginning,eveningEnd,nightBeginning,midnight,nightEnd]
    
    /** Check if any of the times are nil before proceeding*/
    for time in allTimes{
        guard time != nil else{
            return .morning
        }
    }
    
    if currentTime >= morningBeginning! && currentTime < morningEnd!{
        timeOfDay = .morning
    }
    else if currentTime >= afternoonBeginning! && currentTime < afternoonEnd!{
        timeOfDay = .afternoon
    }
    else if currentTime >= eveningBeginning! && currentTime < eveningEnd!{
        timeOfDay = .evening
    }
    else if currentTime >= nightBeginning! && currentTime >= midnight!{
        /** Night takes place over 2 days, so the current time must be between 9:00 PM and 12:00 AM*/
        timeOfDay = .night
    }
    else if currentTime >= midnight! && currentTime < nightEnd!{
        /** Night takes place over 2 days, so the current time must be between 12:00 AM and 4:00 AM*/
        timeOfDay = .night
    }
    else{
        /** Generic return type in case all else fails for some reason (highly unlikely)*/
        timeOfDay = .morning
    }
    
    return timeOfDay
}
