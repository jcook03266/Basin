//
//  underlinedButtonBar.swift
//  Inspec
//
//  Created by Justin Cook on 12/11/21.
//

import Foundation
import UIKit

/** A UIView that hosts an array of buttons that have an 'underline' UIView beneath them which moves from button to button when the user presses on them*/
public class underlinedButtonBar: UIView{
    var buttons: [UIButton]
    var animated: Bool
    var height: CGFloat
    var width: CGFloat
    var underline = UIView()
    var underlineTrack = UIView()
    var underlineHeight: CGFloat
    var underlineColor: UIColor
    var underlineTrackColor: UIColor
    var currentlySelectedButton: UIButton!
    
    /** Each button will be positioned inside of this stackview horizontally with adequate spacing in between them*/
    var stackView = UIStackView()
    
    init(buttons: [UIButton], width: CGFloat, height: CGFloat, underlineColor: UIColor, underlineTrackColor: UIColor, underlineHeight: CGFloat, backgroundColor: UIColor, animated: Bool){
        self.buttons = buttons
        self.width = width
        self.height = height
        self.underlineColor = underlineColor
        self.underlineTrackColor = underlineTrackColor
        self.underlineHeight = underlineHeight
        self.animated = animated
        super.init(frame: CGRect(x: 0, y: 0, width: width, height: height))
        self.backgroundColor = backgroundColor
        
        constructUI()
    }
    
    func constructUI(){
        stackView = UIStackView(frame: self.frame)
        stackView.frame.size.height = stackView.frame.height - underlineHeight
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        stackView.spacing = 10
        //Note: This doesn't autoresize the views to fill the stackview, don't use it
        //stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isUserInteractionEnabled = true
        stackView.semanticContentAttribute = .forceLeftToRight
        
        for button in buttons{
            /** Prevent duplicate buttons from being added by mistake b/c we can't always have nice things*/
            if !stackView.arrangedSubviews.contains(button){
                stackView.addArrangedSubview(button)
            }
        }
        
        underlineTrack.frame = CGRect(x: 0, y: stackView.frame.maxY, width: width, height: underlineHeight)
        
        underlineTrack.backgroundColor = underlineTrackColor
        underline.backgroundColor = underlineColor
        
        /** Wait until all view sizes are computed to set the position of the underline*/
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6){[self] in
            /** Coerce the view stored at this index in the stackview into being a UIButton because that's what's only being stored in this stackview anyways*/
            let button = stackView.arrangedSubviews[0] as! UIButton
            
            currentlySelectedButton = button
            
            /** Make the underline the size of the first button's content and position it directly underneath that first button*/
            underline.frame.size.width = button.intrinsicContentSize.width
            underline.frame.size.height = underlineHeight
            
            /** This is the offset from the minX of the button's frame to center of its content*/
            let offSet = button.frame.minX + (button.frame.width/2 - button.intrinsicContentSize.width/2)
            underline.frame.origin = CGPoint(x: offSet, y: 0)
        }
        
        self.addSubview(stackView)
        self.addSubview(underlineTrack)
        underlineTrack.addSubview(underline)
    }
    
    /** Moves the underline to the specified butto IF the button is in the button array*/
    func moveUnderLineTo(this passedButton: UIButton){
        for (index, _) in stackView.arrangedSubviews.enumerated(){
            let button = stackView.arrangedSubviews[index] as! UIButton
            let offSet = button.frame.minX + (button.frame.width/2 - button.intrinsicContentSize.width/2)
            
            if passedButton == button{
                currentlySelectedButton = button
                if animated{
                    UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
        
                        underline.frame.size.width = button.intrinsicContentSize.width
                        underline.frame.origin = CGPoint(x: offSet, y: 0)
                    }
                }
                else{
                    underline.frame.size.width = button.intrinsicContentSize.width
                    underline.frame.origin = CGPoint(x: offSet, y: 0)
                }
            }
        }
    }
    
    /** Resizes the underline to correspond to the passedButton's intrinsic width*/
    func resizeTheUnderlineFor(this passedButton: UIButton){
        for (index, _) in stackView.arrangedSubviews.enumerated(){
            let button = stackView.arrangedSubviews[index] as! UIButton
            
            if passedButton == button{
                if animated{
                    UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
                        underline.frame.size.width = button.intrinsicContentSize.width
                    }
                }
                else{
                    underline.frame.size.width = button.intrinsicContentSize.width
                }
            }
        }
    }
    
    /** Returns the index of a passed button in the stackview's arranged subview if it's present*/
    func getIndexOf(this passedButton: UIButton)->Int?{
        var this_index: Int? = nil
        for (index, button) in stackView.arrangedSubviews.enumerated(){
            if passedButton == button{
                this_index = index
            }
        }
        return this_index
    }
    
    /** Returns the offset of the passed button in the stackview*/
    func getOffsetOf(this passedButton: UIButton)->CGFloat?{
        var this_offSet: CGFloat? = nil
        for (index, _) in stackView.arrangedSubviews.enumerated(){
            let button = stackView.arrangedSubviews[index] as! UIButton
            let offSet = button.frame.minX + (button.frame.width/2 - button.intrinsicContentSize.width/2)
            
            if passedButton == button{
                this_offSet = offSet
            }
        }
        
        return this_offSet
    }
    
    /** Returns the offset of the first button in the stackview*/
    func getOffsetOfFirstButton()->CGFloat{
        return getOffsetOf(this: self.buttons[0])!
    }
    
    /** Returns the totals distance from the first element to the last element*/
    func getTotalDistance()->CGFloat{
        let firstButton = stackView.arrangedSubviews[0] as! UIButton
        let lastButton = stackView.arrangedSubviews[stackView.arrangedSubviews.count-1] as! UIButton
        
        let firstOffset = firstButton.frame.minX + (firstButton.frame.width/2 - firstButton.intrinsicContentSize.width/2)
        let lastOffset = lastButton.frame.minX + (lastButton.frame.width/2 - lastButton.intrinsicContentSize.width/2)
        
        /** The distance between the first and last offset is the total distance needed to be covered by the underline if animated to move with the swipe of the user*/
        return (lastOffset - firstOffset)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
