//
//  LottieAnimationContainer.swift
//  Stuy Wash N Dry
//
//  Created by Justin Cook on 2/5/22.
//

import UIKit
import Lottie

/** UIView that hosts a lottie animation view inside of it with numerous ease of use methods to custom and edit important parameters on the fly*/
public class lottieAnimationView: UIView{
    /**The speed of the animation*/
    var animationSpeed: CGFloat = 0.0
    /**The view hosted within this view that will be responsible for displaying Lottie SVG JSON animations*/
    var animationView: AnimationView
    
    init(frame: CGRect, animationView: AnimationView, animationSpeed: CGFloat) {
        self.animationView = animationView
        self.animationSpeed = animationSpeed
        super.init(frame: frame)
        
        setUpAppearance()
        setAnimationViewProperties()
    }
    
    /** Set the appearance of this view*/
    private func setUpAppearance(){
        backgroundColor = UIColor.clear
    }
    
    /** Sets the default properties for the animation view's behavior*/
    public func setAnimationViewProperties(){
        /** When the app goes to the background, pause the animation view whilst storing the completion block and then run this original code once the app restores from the background*/
        animationView.animationSpeed = animationSpeed
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.isExclusiveTouch = true
        animationView.shouldRasterizeWhenIdle = true
        animationView.contentMode = .scaleAspectFit
        animationView.isOpaque = false
        animationView.clipsToBounds = true
        animationView.backgroundColor = self.backgroundColor
        animationView.frame = self.frame
        self.addSubview(animationView)
    }
    
    /** Returns the duration of the animation (in seconds)*/
    public func getAnimationDuration()->TimeInterval{
        return animationView.animation!.duration
    }
    
    /** Specifies the mode of the animation, whether it's play once, loop auto reverse etc.*/
    public func animationLoopMode(mode: LottieLoopMode){
        animationView.loopMode = mode
    }
    
    /** Start the animation from its current state with an optional completion block that triggers an action upon the animation's completion*/
    public func startAnimation(with completionBlock: LottieCompletionBlock?){
        animationView.play(completion: completionBlock)
    }
    
    /** Pauses the animation at its current frame*/
    public func pauseAnimation(){
        animationView.pause()
    }
    
    /** Stop the animation and resets the view to the original frame*/
    public func resetAnimation(){
        animationView.stop()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

