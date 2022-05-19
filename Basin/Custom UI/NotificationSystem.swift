//
//  NotificationSystem.swift
//  Inspec
//
//  Created by Justin Cook on 1/18/22.
//

import UIKit

/** Creates a message encapsulated by a UIView with accentuating graphics to draw the user's attention to the context at hand
 - Parameter message: A string with text describing the context of this message, namely why it was presented (ex. a deletion or addition).
 - Parameter image: An optional image that will be presented alongside the message to add further graphical fidelity and context to the message.
 - Parameter backgroundColor: The background color of the view encapsulating the message
 - Parameter imageBackgroundColor: Optional background color of the imageView housing the optional image passed to the method (default: Black if optional == nil)
 - Parameter accentColor: The color of any graphical accents present in the view such as borders
 - Parameter fontColor: Color of the font used to display the given message string
 - Parameter font: The font used to display the given message string
 - Parameter bodyType: Attribute specifying the body, position, and animation type for the transmission notification
 - Parameter animated: Determines whether or not the message is animated appearing into the current scene
 - Parameter duration: The duration for which this message will be displayed on the screen
 - Parameter selfDismiss: Determines whether or not the message is self dismissed or user dismissed via swiping
 */
func globallyTransmit(this message: String, with image: UIImage?, backgroundColor: UIColor, imageBackgroundColor: UIColor?, imageBorder: transmissionImageBorder, blurEffect: Bool, accentColor: UIColor, fontColor: UIColor, font: UIFont, using bodyType: transmissionType, animated: Bool, duration: CGFloat, selfDismiss: Bool){
    
    let screenDimensions = UIScreen.main.bounds
    /** Status bar height = value else 0 via coalescence*/
    let statusBarHeight = getStatusBarHeight()
    
    let blurEffectView = UIVisualEffectView()
    blurEffectView.effect = UIBlurEffect(style: darkMode ? .dark : .light)
    
    blurEffectView.frame = CGRect(x: 0, y: 0, width: 0, height: 60)
    blurEffectView.backgroundColor = backgroundColor.withAlphaComponent(0.8)
    blurEffectView.clipsToBounds = true
    
    let shadowView = UIView(frame: blurEffectView.frame)
    shadowView.clipsToBounds = false
    shadowView.layer.cornerRadius = 8
    shadowView.layer.shadowColor = UIColor.black.cgColor
    shadowView.layer.shadowOpacity = 0.15
    shadowView.layer.shadowRadius = 8
    shadowView.layer.shadowOffset = CGSize(width: 0, height: 2)
    
    let container = notificationContainer(frame: blurEffectView.frame, parentView: shadowView, notificationType: bodyType)
    container.layer.cornerRadius = 8
    blurEffectView.contentView.addSubview(container)
    
    let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: container.frame.height/2, height: container.frame.height/2))
    imageView.image = image
    imageView.clipsToBounds = true
    imageView.contentMode = .scaleAspectFit
    imageView.tintColor = accentColor
    imageView.backgroundColor = imageBackgroundColor
    
    let label = PaddedLabel(withInsets: 0, 0, 5, 5)
    label.frame = CGRect(x: 0, y: 0, width: 0, height: container.frame.height)
    label.clipsToBounds = true
    label.text = message
    label.font = font
    label.textColor = fontColor
    label.numberOfLines = 0
    label.lineBreakMode = .byClipping
    label.adjustsFontSizeToFitWidth = true
    label.adjustsFontForContentSizeCategory = true
    
    /** Set the orientation, dimension, and position of the message view*/
    switch bodyType {
    case .leftStrip:
        /** Original position is set to the far left of the screen, out of any renderable context*/
        shadowView.frame.size.width = screenDimensions.width * 0.95
        container.frame.size.width = shadowView.frame.width
        
        /** Small rectangle placed in the corner of the view to grab the user's attention with its accent color*/
        let rectangle = UIView(frame: CGRect(x: container.frame.maxX - 8, y: 0, width: 8, height: container.frame.height))
        rectangle.clipsToBounds = true
        rectangle.backgroundColor = accentColor
        container.addSubview(rectangle)
        
        label.textAlignment = .right
        label.frame.size.width = container.frame.width - (imageView.frame.width + 10)
        
        /** Resize the container to fit the dynamic content in the text label */
        DispatchQueue.main.async{
            label.sizeToFit()
            container.frame.size.height = label.bounds.size.height + 40
            blurEffectView.frame.size.height = container.frame.height
            shadowView.frame.size.height = container.frame.height
            rectangle.frame.size.height = container.frame.height
            imageView.frame.size.height = container.frame.height/2
            imageView.frame.size.width = imageView.frame.height
            
            shadowView.frame.origin = CGPoint(x: screenDimensions.minX - shadowView.frame.width, y: statusBarHeight)
            
            imageView.frame.origin = CGPoint(x: rectangle.frame.minX - (imageView.frame.width + 0), y: container.frame.height/2 - imageView.frame.height/2)
            label.frame.origin = CGPoint(x: imageView.frame.minX - label.frame.width, y: container.frame.height/2 - label.frame.height/2)
        }
        
        if animated{
            /** Animate the view appearing and then disappearing*/
            DispatchQueue.main.asyncAfter(deadline: .now()){
                UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [.curveEaseIn, .allowUserInteraction]){
                    shadowView.frame.origin = CGPoint(x: screenDimensions.minX - (shadowView.frame.width * 0.01), y: statusBarHeight)
                }
                
                /** Automatically dismiss the message after the specified amount of time*/
                if selfDismiss == true{
                DispatchQueue.main.asyncAfter(deadline: .now() + (duration)){
                UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [.curveEaseIn, .allowUserInteraction]){
                    shadowView.frame.origin = CGPoint(x: screenDimensions.minX - shadowView.frame.width, y: statusBarHeight)
                }
                }
                }
            }
        }
        else{
            shadowView.frame.origin = CGPoint(x: screenDimensions.minX - (shadowView.frame.width * 0.01), y: statusBarHeight)
        }
    case .rightStrip:
        /** Original position is set to the far right of the screen, out of any renderable context*/
        shadowView.frame.size.width = screenDimensions.width * 0.95
        container.frame.size.width = shadowView.frame.width
        
        /** Small rectangle placed in the corner of the view to grab the user's attention with its accent color*/
        let rectangle = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: container.frame.height))
        rectangle.clipsToBounds = true
        rectangle.backgroundColor = accentColor
        container.addSubview(rectangle)
        
        label.textAlignment = .left
        label.frame.size.width = container.frame.width - (imageView.frame.width + 10)
        
        /** Resize the container to fit the dynamic content in the text label */
        DispatchQueue.main.async{
            label.sizeToFit()
            container.frame.size.height = label.bounds.size.height + 40
            blurEffectView.frame.size.height = container.frame.height
            shadowView.frame.size.height = container.frame.height
            rectangle.frame.size.height = container.frame.height
            imageView.frame.size.height = container.frame.height/2
            imageView.frame.size.width = imageView.frame.height
            
            shadowView.frame.origin = CGPoint(x: screenDimensions.maxX, y: statusBarHeight)
            
            imageView.frame.origin = CGPoint(x: rectangle.frame.maxX + 0, y: container.frame.height/2 - imageView.frame.height/2)
            label.frame.origin = CGPoint(x: imageView.frame.maxX, y: container.frame.height/2 - label.frame.height/2)
        }
        
        if animated{
            /** Animate the view appearing and then disappearing*/
            DispatchQueue.main.asyncAfter(deadline: .now()){
                UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [.curveEaseIn, .allowUserInteraction]){
                    shadowView.frame.origin = CGPoint(x: screenDimensions.maxX - shadowView.frame.width * 0.99, y: statusBarHeight)
                }
                
                /** Automatically dismiss the message after the specified amount of time*/
                if selfDismiss == true{
                DispatchQueue.main.asyncAfter(deadline: .now() + (duration)){
                UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [.curveEaseIn, .allowUserInteraction]){
                    shadowView.frame.origin = CGPoint(x: screenDimensions.maxX, y: statusBarHeight)
                }
                }
                }
            }
        }
        else{
            shadowView.frame.origin = CGPoint(x: screenDimensions.maxX - shadowView.frame.width * 0.99, y: statusBarHeight)
        }
    case .centerStrip:
        /** Original position is set to the center of the screen, above the status bar, and out of any renderable context*/
        shadowView.frame.size.width = screenDimensions.width * 0.95
        container.frame.size.width = shadowView.frame.width
        
        shadowView.frame.origin = CGPoint(x: screenDimensions.width/2 - shadowView.frame.width/2, y: screenDimensions.minY - shadowView.frame.height)
        
        label.textAlignment = .left
        label.frame.size.width = container.frame.width - (imageView.frame.width + 10)
        
        /** Small progressview placed at the bottom of the view to grab the user's attention with its accent color*/
        let progressView = UIProgressView(frame: CGRect(x: 0, y: container.frame.height - 4, width: container.frame.width, height: 4))
        progressView.clipsToBounds = true
        progressView.trackTintColor = UIColor.clear
        progressView.progressTintColor = accentColor
        progressView.progress = 0
        container.addSubview(progressView)
        
        /** Resize the container to fit the dynamic content in the text label */
        DispatchQueue.main.async{
            label.sizeToFit()
            container.frame.size.height = label.bounds.size.height + 40
            blurEffectView.frame.size.height = container.frame.height
            shadowView.frame.size.height = container.frame.height
            container.layer.cornerRadius = container.frame.height/3
            progressView.frame.origin.y = container.frame.height - 4
            imageView.frame.size.height = container.frame.height/2
            imageView.frame.size.width = imageView.frame.height
            
            /** Layout subview to prevent animation glitches*/
            progressView.layoutIfNeeded()
            
            label.frame.origin = CGPoint(x: imageView.frame.maxX + 5, y: container.frame.height/2 - label.frame.height/2)
            imageView.frame.origin = CGPoint(x: 5, y: container.frame.height/2 - imageView.frame.height/2)
        }
        
        if animated{
            /** Animate the view appearing and then disappearing*/
            DispatchQueue.main.asyncAfter(deadline: .now()){
                UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [.curveEaseIn, .allowUserInteraction]){
                    shadowView.frame.origin = CGPoint(x: screenDimensions.width/2 - shadowView.frame.width/2, y: statusBarHeight)
                }
                
                /** Automatically dismiss the message after the specified amount of time*/
                if selfDismiss == true{
                /** Use dispatch queue instead of the delay parameter in order to enable user interaction while animations are in progress and delayed*/
                DispatchQueue.main.asyncAfter(deadline: .now() + (duration)){
                    UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [.curveEaseIn, .allowUserInteraction]){
                        shadowView.frame.origin = CGPoint(x: screenDimensions.width/2 - shadowView.frame.width/2, y: screenDimensions.minY - shadowView.frame.height)
                    }
                }
                }
                UIView.animate(withDuration: duration, delay: 0, options: [.allowUserInteraction]){
                    progressView.setProgress(1, animated: true)
                }
            }
        }
        else{
            shadowView.frame.origin = CGPoint(x: screenDimensions.width/2 - shadowView.frame.width/2, y: statusBarHeight)
            progressView.setProgress(1, animated: false)
        }
    case .bottomCenterStrip:
        /** Original position is set to the center of the screen, above the status bar, and out of any renderable context*/
        shadowView.frame.size.width = screenDimensions.width * 0.95
        container.frame.size.width = shadowView.frame.width
        
        shadowView.frame.origin = CGPoint(x: screenDimensions.width/2 - shadowView.frame.width/2, y: screenDimensions.maxY + shadowView.frame.height)
        
        label.textAlignment = .left
        label.frame.size.width = container.frame.width - (imageView.frame.width + 10)
        
        /** Small progressview placed at the bottom of the view to grab the user's attention with its accent color*/
        let progressView = UIProgressView(frame: CGRect(x: 0, y: container.frame.height - 4, width: container.frame.width, height: 4))
        progressView.clipsToBounds = true
        progressView.trackTintColor = UIColor.clear
        progressView.progressTintColor = accentColor
        progressView.progress = 0
        container.addSubview(progressView)
        
        /** Resize the container to fit the dynamic content in the text label */
        DispatchQueue.main.async{
            label.sizeToFit()
            container.frame.size.height = label.bounds.size.height + 40
            blurEffectView.frame.size.height = container.frame.height
            shadowView.frame.size.height = container.frame.height
            container.layer.cornerRadius = container.frame.height/3
            progressView.frame.origin.y = container.frame.height - 4
            imageView.frame.size.height = container.frame.height/2
            imageView.frame.size.width = imageView.frame.height
            
            /** Layout subview to prevent animation glitches*/
            progressView.layoutIfNeeded()
            
            label.frame.origin = CGPoint(x: imageView.frame.maxX + 5, y: container.frame.height/2 - label.frame.height/2)
            imageView.frame.origin = CGPoint(x: 5, y: container.frame.height/2 - imageView.frame.height/2)
        }
        
        if animated{
            /** Animate the view appearing and then disappearing*/
            DispatchQueue.main.asyncAfter(deadline: .now()){
                UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [.curveEaseIn, .allowUserInteraction]){
                    shadowView.frame.origin = CGPoint(x: screenDimensions.width/2 - shadowView.frame.width/2, y: screenDimensions.height - (shadowView.frame.height * 1.5))
                }
                
                /** Automatically dismiss the message after the specified amount of time*/
                if selfDismiss == true{
                /** Use dispatch queue instead of the delay parameter in order to enable user interaction while animations are in progress and delayed*/
                DispatchQueue.main.asyncAfter(deadline: .now() + (duration)){
                    UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [.curveEaseIn, .allowUserInteraction]){
                        shadowView.frame.origin = CGPoint(x: screenDimensions.width/2 - shadowView.frame.width/2, y: screenDimensions.maxY + shadowView.frame.height)
                    }
                }
                }
                UIView.animate(withDuration: duration, delay: 0, options: [.allowUserInteraction]){
                    progressView.setProgress(1, animated: true)
                }
            }
        }
        else{
            shadowView.frame.origin = CGPoint(x: screenDimensions.width/2 - shadowView.frame.width/2, y: screenDimensions.height - (shadowView.frame.height * 1.5))
            progressView.setProgress(1, animated: false)
        }
    case .coverStatusBar:
        shadowView.frame.size.width = screenDimensions.width
        shadowView.frame.size.height = shadowView.frame.height + statusBarHeight
        container.frame.size.width = shadowView.frame.width
        container.frame.size.height = shadowView.frame.height
        /** Original position is set to the center of the screen, above the status bar, and out of any renderable context*/
        shadowView.frame.origin = CGPoint(x: 0, y: screenDimensions.minY - shadowView.frame.height)
        
        /** Get rid of the curve on the corner of the view*/
        container.layer.cornerRadius = 0
        shadowView.layer.cornerRadius = container.layer.cornerRadius
        
        container.backgroundColor = container.backgroundColor?.withAlphaComponent(0.9)
        
        label.textAlignment = .left
        label.frame.size.width = container.frame.width - (imageView.frame.width + 10)
        
        /** Small progressview placed at the bottom of the view to grab the user's attention with its accent color*/
        let progressView = UIProgressView(frame: CGRect(x: 0, y: container.frame.height - 4, width: container.frame.width, height: 4))
        progressView.clipsToBounds = true
        progressView.trackTintColor = UIColor.clear
        progressView.progressTintColor = accentColor
        progressView.progress = 0
        container.addSubview(progressView)
        
        /** Resize the container to fit the dynamic content in the text label */
        DispatchQueue.main.async{
            label.sizeToFit()
            container.frame.size.height = label.bounds.size.height + statusBarHeight + 20
            blurEffectView.frame.size.height = container.frame.height
            shadowView.frame.size.height = container.frame.height
            progressView.frame.origin.y = container.frame.height - 4
            imageView.frame.size.height = container.frame.height/2
            imageView.frame.size.width = imageView.frame.height
            
            /** Layout subview to prevent animation glitches*/
            progressView.layoutIfNeeded()
            
            label.frame.origin = CGPoint(x: imageView.frame.maxX + 5, y: statusBarHeight)
            imageView.frame.origin = CGPoint(x: 5, y: 0)
            imageView.center.y = label.center.y
        }
        
        if animated{
            /** Animate the view appearing and then disappearing*/
            DispatchQueue.main.asyncAfter(deadline: .now()){
                UIView.animate(withDuration: 1, delay: 0, options: [.allowUserInteraction]){
                    shadowView.frame.origin = CGPoint(x: 0, y: screenDimensions.minY)
                }
                
                /** Automatically dismiss the message after the specified amount of time*/
                if selfDismiss == true{
                DispatchQueue.main.asyncAfter(deadline: .now() + (duration)){
                UIView.animate(withDuration: 1, delay: 0, options: [.allowUserInteraction]){
                    shadowView.frame.origin = CGPoint(x: 0, y: screenDimensions.minY - shadowView.frame.height)
                }
                }
                }
                UIView.animate(withDuration: duration, delay: 0, options: [.allowUserInteraction]){
                    progressView.setProgress(1, animated: true)
                }
            }
        }
        else{
            shadowView.frame.origin = CGPoint(x: 0, y: screenDimensions.minY)
            progressView.setProgress(1, animated: false)
        }
    case .coverTabbar:
        shadowView.frame.size.width = screenDimensions.width
        shadowView.frame.size.height = shadowView.frame.height + statusBarHeight/2
        container.frame.size.height = shadowView.frame.height
        container.frame.size.width = shadowView.frame.width
        /** Original position is set to the center of the screen, below the tabbar, and out of any renderable context*/
        shadowView.frame.origin = CGPoint(x: 0, y: screenDimensions.height)
        
        /** Get rid of the curve on the corner of the view*/
        container.layer.cornerRadius = 0
        shadowView.layer.cornerRadius = container.layer.cornerRadius
        
        container.backgroundColor = container.backgroundColor?.withAlphaComponent(0.9)
        
        imageView.frame.origin = CGPoint(x: imageView.frame.width * 0.25, y: 0)
        
        label.textAlignment = .left
        label.frame.size.width = container.frame.width - (imageView.frame.width + 10)

        /** Small progressview placed at the bottom of the view to grab the user's attention with its accent color*/
        let progressView = UIProgressView(frame: CGRect(x: 0, y: 0, width: container.frame.width, height: 4))
        progressView.clipsToBounds = true
        progressView.trackTintColor = UIColor.clear
        progressView.progressTintColor = accentColor
        progressView.progress = 0
        container.addSubview(progressView)
        
        /** Resize the container to fit the dynamic content in the text label */
        DispatchQueue.main.async{
            label.sizeToFit()
            container.frame.size.height = label.bounds.size.height + statusBarHeight + 20
            blurEffectView.frame.size.height = container.frame.height
            shadowView.frame.size.height = container.frame.height
            imageView.frame.size.height = container.frame.height/2
            imageView.frame.size.width = imageView.frame.height
            
            /** Layout subview to prevent animation glitches*/
            progressView.layoutIfNeeded()
            
            label.frame.origin = CGPoint(x: imageView.frame.maxX + 5, y: container.frame.height/2 - imageView.frame.height/2)
            imageView.frame.origin = CGPoint(x: 5, y: 0)
            imageView.center.y = label.center.y
        }
        
        if animated{
            /** Animate the view appearing and then disappearing*/
            DispatchQueue.main.asyncAfter(deadline: .now()){
                UIView.animate(withDuration: 1, delay: 0, options: [.allowUserInteraction]){
                    shadowView.frame.origin = CGPoint(x: 0, y: screenDimensions.height - shadowView.frame.height)
                }
                
                /** Automatically dismiss the message after the specified amount of time*/
                if selfDismiss == true{
                DispatchQueue.main.asyncAfter(deadline: .now() + (duration)){
                UIView.animate(withDuration: 1, delay: 0, options: [.allowUserInteraction]){
                    shadowView.frame.origin = CGPoint(x: 0, y: screenDimensions.height)
                }
                }
                }
                UIView.animate(withDuration: duration, delay: 0, options: [.allowUserInteraction]){
                    progressView.setProgress(1, animated: true)
                }
            }
        }
        else{
            shadowView.frame.origin = CGPoint(x: 0, y: screenDimensions.height - shadowView.frame.height)
            progressView.setProgress(1, animated: false)
        }
    }
    
    /** Add all subviews together then add the final product to the application's shared windows*/
    container.addSubview(label)
    /** If no image is provided then don't add the imageview to the view hierarchy*/
    if image != nil{
        container.addSubview(imageView)
    }
    
    DispatchQueue.main.async{
    /** Changes that take effect after everything else is set*/
    shadowView.layer.shadowPath = UIBezierPath(roundedRect: shadowView.bounds, cornerRadius: shadowView.layer.cornerRadius).cgPath
    blurEffectView.layer.cornerRadius = container.layer.cornerRadius
    }
    
    switch imageBorder{
    case .circle:
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = accentColor.cgColor
        imageView.layer.cornerRadius = imageView.frame.height/2
    case .square:
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = accentColor.cgColor
    case .squircle:
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = accentColor.cgColor
        imageView.layer.cornerRadius = imageView.frame.height/5
    case .borderLessCircle:
        imageView.layer.cornerRadius = imageView.frame.height/2
    case .borderlessSquare:
        imageView.layer.borderWidth = 0
    case .borderlessSquircle:
        imageView.layer.cornerRadius = imageView.frame.height/5
    case .none:
        imageView.layer.borderWidth = 0
    }
    
    DispatchQueue.main.async{
    switch blurEffect {
    case true:
        blurEffectView.frame.size.height = container.frame.height
        blurEffectView.frame.size.width = container.frame.width
        shadowView.addSubview(blurEffectView)
    case false:
        container.backgroundColor = backgroundColor.withAlphaComponent(0.8)
        container.clipsToBounds = true
        container.layer.cornerRadius = blurEffectView.layer.cornerRadius
        shadowView.addSubview(container)
    }
    }
    
    addToWindow(view: shadowView)
    
    /** Automatically remove the view from memory*/
    if selfDismiss == true{
    /** Remove this view hierarchy from its superview and free up memory*/
    DispatchQueue.main.asyncAfter(deadline: .now() + (duration + 2)){
        for subview in shadowView.subviews{
            subview.removeFromSuperview()
        }
        shadowView.removeFromSuperview()
    }
    }
}

/** Subclass of UIView that can be used to host the contents of a notification such as a global transmission that can be dismissed via swiping*/
class notificationContainer: UIView, UIGestureRecognizerDelegate{
    /** Used to determine what type of swipe to use in order to dismiss the notification*/
    var notificationType: transmissionType
    /** The parent container of this container*/
    var parentView: UIView
    
    init(frame: CGRect, parentView: UIView, notificationType: transmissionType){
        self.notificationType = notificationType
        self.parentView = parentView
        super.init(frame: frame)
        
        /** Recognize swipes on the notification that can be used to dismiss it*/
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(transmissionSwiped))
        panGestureRecognizer.delegate = self
        self.addGestureRecognizer(panGestureRecognizer)
    }
    
    /** Swipe gesture handler using a pan gesture recognizer because the swipe gesture isn't as precise*/
    @objc func transmissionSwiped(sender: UIPanGestureRecognizer){
        let translation = sender.translation(in: self)
        var swipeDirection: UISwipeGestureRecognizer.Direction?
        
        /** Determine the direction of the swipe with moderate precision to allow for a margin of error of +/- 20*/
        if translation.x > 0 && translation.y <= 20 && translation.y >= -20{
            swipeDirection = .right
        }
        else if translation.x < 0 && translation.y <= 20 && translation.y >= -20{
            swipeDirection = .left
        }
        else if translation.y > 0 && translation.x <= 20 && translation.x >= -20{
            swipeDirection = .down
        }
        else if translation.y < 0 && translation.x <= 20 && translation.x >= -20{
            swipeDirection = .up
        }
        
        guard swipeDirection != nil else{
            return
        }
        
        switch swipeDirection!{
        case .up:
            if notificationType == .coverStatusBar || notificationType == .centerStrip{
            dismiss()
            }
            else{break}
        case .down:
            if notificationType == .coverTabbar || notificationType == .bottomCenterStrip{
            dismiss()
            }
            else{break}
        case .left:
            if notificationType == .leftStrip{
            dismiss()
            }
            else{break}
        case .right:
            if notificationType == .rightStrip{
            dismiss()
            }
            else{break}
        default:
            break
        }
    }
    
    /** Dismisses the UIView in a type appropriate fashion [Don't allow user interaction with the view after this is triggered]*/
    func dismiss(){
        let screenDimensions = UIScreen.main.bounds
        
        switch notificationType{
        case .leftStrip:
            /** Animate the view appearing and then disappearing*/
            DispatchQueue.main.asyncAfter(deadline: .now()){
                UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [.curveEaseIn]){
                    self.parentView.frame.origin = CGPoint(x: screenDimensions.minX - self.parentView.frame.width, y: getStatusBarHeight())
                }
            }
        case .rightStrip:
            /** Animate the view appearing and then disappearing*/
            DispatchQueue.main.asyncAfter(deadline: .now()){
                UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [.curveEaseIn]){
                    self.parentView.frame.origin = CGPoint(x: screenDimensions.maxX, y: getStatusBarHeight())
                }
            }
        case .centerStrip:
            /** Animate the view appearing and then disappearing*/
            DispatchQueue.main.asyncAfter(deadline: .now()){
                UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [.curveEaseIn]){
                    self.parentView.frame.origin = CGPoint(x: screenDimensions.width/2 - self.parentView.frame.width/2, y: screenDimensions.minY - self.parentView.frame.height)
                }
            }
        case .bottomCenterStrip:
            /** Animate the view appearing and then disappearing*/
            DispatchQueue.main.asyncAfter(deadline: .now()){
                UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [.curveEaseIn]){
                    self.parentView.frame.origin = CGPoint(x: screenDimensions.width/2 - self.parentView.frame.width/2, y: screenDimensions.maxY + self.parentView.frame.height)
                }
            }
        case .coverStatusBar:
            /** Animate the view appearing and then disappearing*/
            DispatchQueue.main.asyncAfter(deadline: .now()){
                UIView.animate(withDuration: 1, delay: 0){
                    self.parentView.frame.origin = CGPoint(x: 0, y: screenDimensions.minY - self.frame.height)
                }
            }
        case .coverTabbar:
            /** Animate the view appearing and then disappearing*/
            DispatchQueue.main.asyncAfter(deadline: .now()){
                UIView.animate(withDuration: 1, delay: 0){
                    self.parentView.frame.origin = CGPoint(x: 0, y: screenDimensions.height)
                }
            }
        }
        delete()
    }
    
    /** Dismiss the current notification*/
    fileprivate func delete(){
        /** Remove this view hierarchy from its superview and free up memory*/
        DispatchQueue.main.asyncAfter(deadline: .now() + 3){
            for subview in self.subviews{
                subview.removeFromSuperview()
            }
            self.removeFromSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/** Specifies the body, position, and animation type for the transmission notification*/
enum transmissionType: Int{
    case leftStrip = 0
    case rightStrip = 1
    case centerStrip = 2
    case bottomCenterStrip = 3
    case coverStatusBar = 4
    case coverTabbar = 5
}

/** Specify the border type for the transmission message's image*/
enum transmissionImageBorder: Int{
    case circle = 0
    case square = 1
    case squircle = 2
    case borderLessCircle = 3
    case borderlessSquare = 4
    case borderlessSquircle = 5
    case none = 6
}
