//
//  LottieButton.swift
//  Basin
//
//  Created by Justin Cook on 3/25/22.
//

import UIKit
import Lottie

/** Custom UIButton View subclass that supports a lottie animation view subview*/
public class LottieButton: UIButton{
    /** The lottie file to be initialized and embedded in this button*/
    var lottieFile: String
    var lottieView: AnimationView!
    
    init(frame: CGRect, lottieFile: String){
        self.lottieFile = lottieFile
        
        super.init(frame: frame)
        
        construct()
    }
    
    /** Construct the properties of this UIButton View*/
    func construct(){
        lottieView = AnimationView.init(name: lottieFile)
        lottieView.frame.size = CGSize(width: self.frame.width, height: self.frame.height)
        lottieView.frame.origin = .zero
        lottieView.animationSpeed = 1
        lottieView.backgroundBehavior = .pauseAndRestore
        lottieView.shouldRasterizeWhenIdle = true
        lottieView.contentMode = .scaleAspectFill
        lottieView.isOpaque = false
        lottieView.backgroundColor = .clear
        lottieView.loopMode = .playOnce
        lottieView.clipsToBounds = false
        /** Let touches pass through this subview*/
        lottieView.isUserInteractionEnabled = false
        
        self.addSubview(lottieView)
    }
    
    /** Play the animation from the given frame to the next given frame with the provided loop mode and animation speed
     - Parameter startFrame: The literal frame of the animation that you wish to start from
     - Parameter endFrame: The literal frame of the animation that you wish to end the animation at
     - Parameter loopMode: The looping behavior of the animation
     - Parameter animationSpeed: The speed of the animation */
    func playAnimation(from startFrame: AnimationFrameTime, to endFrame: AnimationFrameTime, with loopMode: LottieLoopMode?, animationSpeed: CGFloat){
        guard lottieView != nil else {
            return
        }
        lottieView.animationSpeed = animationSpeed
        
        lottieView.play(fromFrame: startFrame, toFrame: endFrame, loopMode: loopMode, completion: nil)
    }
    
    /** Set the animation to this point in its frame sequence*/
    func setAnimationFrameTo(this frame: AnimationFrameTime){
        guard lottieView != nil else {
            return
        }
        
        lottieView.play(fromFrame: frame, toFrame: frame, loopMode: .playOnce, completion: nil)
    }
    
    /** Set the animation to this point in its progress timeline*/
    func setAnimationProgressTo(this progress: AnimationProgressTime){
        guard lottieView != nil else {
            return
        }
        
        lottieView.play(fromProgress: progress, toProgress: progress, loopMode: .playOnce, completion: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
