//
//  GoodVibrations.swift
//  Inspec
//
//  Created by Justin Cook on 2/3/22.
//

import UIKit
import CoreHaptics

/** Various different haptic feedback patterns that inform the user of certain app behaviors*/

/**
 Haptic feedback with a specified delay, intensity, style, and impact repetition pattern
 - Parameter style: The feel of the impact, rigid soft etc.
 - Parameter intensity: The force of the impact 0-1 being an example of this range.
 - Parameter delay: The delay between repetitions (if any).
 - Parameter repetitions: The number of impacts that occur sequentially one after the other.
 
 - Usage Case: Can be used to Inform the user that no more options are available, usually performed when a search result turns up no results
 */
func delayedHaptic(with style: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat, delay: Double, repetitions: Int){
    let haptic = UIImpactFeedbackGenerator(style: style)
    
    /** Handle a single impact event if no repetitions are specified*/
    guard repetitions > 0 else{
        if delay > 0{
            Timer.scheduledTimer(withTimeInterval: (delay), repeats: false){ _ in
                haptic.impactOccurred(intensity: intensity)
            }
        }
        else{
            haptic.impactOccurred(intensity: intensity)
        }
        return
    }
    
    for int in 0..<repetitions{
        if delay > 0{
            Timer.scheduledTimer(withTimeInterval: (delay * Double(int)), repeats: false){ _ in
                haptic.impactOccurred(intensity: intensity)
            }
        }
        else{
            haptic.impactOccurred(intensity: intensity)
        }
    }
}

/**
 Haptic feedback with a specified delay, range of intensities, style, and impact repetition pattern
 - Parameter style: The feel of the impact, rigid soft etc.
 - Parameter intensityRange: The force of the impact 0-1 being an example of this range.
 - Parameter sequenceOrder: The order of the impact intensities in the range that will be fed to the haptic system.
 - Parameter delay: The delay between repetitions (if any).
 - Parameter repetitions: The number of impacts that occur sequentially one after the other.
 */
func sequentialHaptic(with style: UIImpactFeedbackGenerator.FeedbackStyle, intensityRange: ClosedRange<Int>, sequenceOrder: sequenceOrder, delay: Double, repetitions: Int){
    let haptic = UIImpactFeedbackGenerator(style: style)
    var lowerBound = 0
    var upperBound = 0
    var strideIncrement = 1
    
    /** Flip the range if the sequence is descending and decrement using stride*/
    switch sequenceOrder{
    case .ascending:
        lowerBound = intensityRange.lowerBound
        upperBound = intensityRange.upperBound
    case .descending:
        strideIncrement = -1
        lowerBound = intensityRange.upperBound
        upperBound = intensityRange.lowerBound
    }
    
    /** Handle a single impact event if no repetitions are specified*/
    guard repetitions > 0 else{
        for intensity in stride(from: lowerBound, through: upperBound, by: strideIncrement){
            if delay > 0{
                Timer.scheduledTimer(withTimeInterval: (delay), repeats: false){ _ in
                    haptic.impactOccurred(intensity: CGFloat(intensity))
                }
            }
            else{
                haptic.impactOccurred(intensity: CGFloat(intensity))
            }
        }
        return
    }
    
    for int in 0..<repetitions{
        for intensity in stride(from: lowerBound, through: upperBound, by: strideIncrement){
            if delay > 0{
                Timer.scheduledTimer(withTimeInterval: (delay * Double(int)), repeats: false){ _ in
                    haptic.impactOccurred(intensity: CGFloat(intensity))
                }
            }
            else{
                haptic.impactOccurred(intensity: CGFloat(intensity))
            }
        }
    }
}

/** Enum defining two states of a sequence's order, ascending and descending*/
enum sequenceOrder: Int{
    case ascending = 0
    case descending = 1
}

/** Heavy Punchy haptic feedback that can be used for a critical action such as a deletion*/
func deletionActionHaptic(){
    sequentialHaptic(with: .rigid, intensityRange: ClosedRange(uncheckedBounds: (lower: 50, upper: 100)), sequenceOrder: .ascending, delay: 0.1, repetitions: 3)
}

/** Fire this when you reload say a tableview in order to inform the user that a reload was triggered*/
func reloadEventHaptic(){
    sequentialHaptic(with: .medium, intensityRange: ClosedRange(uncheckedBounds: (lower: 100, upper: 200)), sequenceOrder: .ascending, delay: 0, repetitions: 1)
}

/** Generic triple shake to inform the user of a cancellation or an unsuccessful action*/
func unsuccessfulActionHaptic(){
    delayedHaptic(with: .rigid, intensity: 100, delay: 0.1, repetitions: 3)
}

/** Generic double shake that informs the user of a successful action, kind of like a check mark with a two step motion*/
func successfulActionShake(){
    delayedHaptic(with: .heavy, intensity: 100, delay: 0.5, repetitions: 2)
}

/** The one haptic you don't want to feel, this occurs when a specified error is triggered*/
func errorShake(){
    sequentialHaptic(with: .heavy, intensityRange: ClosedRange(uncheckedBounds: (lower: 90, upper: 100)), sequenceOrder: .ascending, delay: 0.1, repetitions: 2)
}

/** Haptic that signals a forwards movement*/
func forwardTraversalShake(){
    sequentialHaptic(with: .medium, intensityRange: ClosedRange(uncheckedBounds: (lower: 50, upper: 100)), sequenceOrder: .ascending, delay: 0, repetitions: 1)
}

/** Haptic that signals a backwards movement*/
func backwardTraversalShake(){
    sequentialHaptic(with: .medium, intensityRange: ClosedRange(uncheckedBounds: (lower: 50, upper: 100)), sequenceOrder: .descending, delay: 0, repetitions: 1)
}

/** Generics*/
/**Heavy haptic feedback (Vibration)*/
func heavyHaptic(){
    let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .heavy)
    impactFeedbackgenerator.prepare()
    impactFeedbackgenerator.impactOccurred()
}
/**Medium haptic feedback*/
func mediumHaptic(){
    let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .medium)
    impactFeedbackgenerator.prepare()
    impactFeedbackgenerator.impactOccurred()
}
/**Light haptic feedback*/
func lightHaptic(){
    let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .light)
    impactFeedbackgenerator.prepare()
    impactFeedbackgenerator.impactOccurred()
}
/** Generics*/
