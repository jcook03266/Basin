//
//  InterstitialLoadingScreen.swift
//  Basin
//
//  Created by Justin Cook on 5/25/22.
//

import UIKit
import Lottie

/** Full screen UIView controller with a lottie animation that acts as a loading screen when activity is currently going on*/
public class InterstitialLoadingScreen: UIViewController{
    /** UI Components*/
    var lottieView: AnimationView!
    
    /** Properties*/
    /** Status bar styling variables*/
    public override var preferredStatusBarStyle: UIStatusBarStyle{
        /** This scene is dark so use a light color*/
        return .lightContent
    }
    public override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation{
        return .slide
    }
    /** Specify status bar display preference*/
    public override var prefersStatusBarHidden: Bool {
        return false
    }
    /** Status bar styling variables*/
    /** The background color of this view controller*/
    var contextBackgroundColor: UIColor = .black
    /** The name of the lottie file to be embedded in the lottie view*/
    var lottieFile: String = "Basin RC Lottie"
    /** The preferred size of the animation view*/
    var lottieViewSize: CGSize{
        return CGSize(width: self.view.frame.width/2, height: self.view.frame.width/2)
    }
    
    init(){
        super.init(nibName: nil, bundle: nil)
    }
    
    public override func viewDidLoad(){
        construct()
    }
    
    /** Compile all UI components together*/
    private func construct(){
        self.view.backgroundColor = contextBackgroundColor
        
        lottieView = AnimationView.init(name: lottieFile)
        lottieView.frame.size = lottieViewSize
        lottieView.animationSpeed = 1
        lottieView.backgroundBehavior = .pauseAndRestore
        lottieView.shouldRasterizeWhenIdle = true
        lottieView.contentMode = .scaleAspectFill
        lottieView.isOpaque = false
        lottieView.clipsToBounds = true
        lottieView.backgroundColor = .clear
        lottieView.loopMode = .loop
        /** Let touches pass through this subview*/
        lottieView.isUserInteractionEnabled = false
        lottieView.play()
        
        /** Layout subviews*/
        lottieView.centerInsideOf(this: self.view)
        self.view.addSubview(lottieView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/** Full screen UIView with a lottie animation that acts as a loading screen when activity is currently going on, this is for when a view controller can't be presented as too much is going on and blocking its presentation*/
public class InterstitialLoadingScreenView: UIView{
    /** UI Components*/
    var lottieView: AnimationView!
    
    /** Properties*/
    /** The background color of this view controller*/
    var contextBackgroundColor: UIColor = .black
    /** The name of the lottie file to be embedded in the lottie view*/
    var lottieFile: String = "Basin RC Lottie"
    /** The preferred size of the animation view*/
    var lottieViewSize: CGSize{
        return CGSize(width: self.frame.width/2, height: self.frame.width/2)
    }
    
    init(){
        /** Set the dimensions of this view to the device's current bounds*/
        let screenDimensions = UIScreen.main.bounds
        
        super.init(frame: CGRect(x: 0, y: 0, width: screenDimensions.width, height: screenDimensions.height))
        
        construct()
    }
    
    /** Compile all UI components together*/
    private func construct(){
        self.backgroundColor = contextBackgroundColor.withAlphaComponent(0.5)
        
        lottieView = AnimationView.init(name: lottieFile)
        lottieView.frame.size = lottieViewSize
        lottieView.animationSpeed = 1
        lottieView.backgroundBehavior = .pauseAndRestore
        lottieView.shouldRasterizeWhenIdle = true
        lottieView.contentMode = .scaleAspectFill
        lottieView.isOpaque = false
        lottieView.clipsToBounds = true
        lottieView.backgroundColor = .clear
        lottieView.loopMode = .loop
        /** Let touches pass through this subview*/
        lottieView.isUserInteractionEnabled = false
        lottieView.play()
        
        /** Layout subviews*/
        lottieView.centerInsideOf(this: self)
        self.addSubview(lottieView)
        self.alpha = 0
        
        appear(animated: true)
    }
    
    /** Show this view in a static or cross dissolve animated fashion*/
    func appear(animated: Bool){
        /** Add above all other views in the current window*/
        addToWindow(view: self)
        
        switch animated{
        case true:
            UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseIn]){[self] in
                    alpha = 1
            }
        case false:
            alpha = 1
        }
    }
    
    /** Dismiss this view in a static or cross dissolve animated fashion*/
    func dismiss(animated: Bool){
        switch animated{
        case true:
            UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseIn]){[self] in
                    alpha = 0
            }
        case false:
            alpha = 0
        }
        
        /** Remove from the view hierarchy*/
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){[self] in
            self.removeFromSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
