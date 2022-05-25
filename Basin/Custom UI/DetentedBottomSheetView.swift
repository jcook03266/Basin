//
//  DetentedBottomSheetView.swift
//  Basin
//
//  Created by Justin Cook on 3/18/22.
//

import UIKit

/** UIView subclass that hosts a subview that can be transformed vertically to multiple detents (resting points) as specified*/
public class DetentedBottomSheetView: UIView, UIScrollViewDelegate, UIGestureRecognizerDelegate{
    /** An array containing values for the view controller to rest at on the screen.*/
    var detents: [CGFloat]!{
        didSet{
            /** If the caller changes the values in the detents array then sort these alerted values*/
            detents.sort()
        }
    }
    /** The UIView to be hosted inside of this dynamic viewcontroller*/
    var subview: UIView!
    /** The default value of the detent*/
    var startingDetent: CGFloat? = nil{
        didSet{
            self.frame.origin.y = startingDetent ?? UIScreen.main.bounds.height/2
            currentDetent = startingDetent ?? UIScreen.main.bounds.height/2
        }
    }
    
    /** Determine whether or not to make the background color of the pan handle darker whenever it is selected*/
    var panHandleHighlightsWhenSelected: Bool = true
    
    /** Control whether or not the 'Pan Handle' view at the top of the view hierarchy is displayed, this is true by default*/
    var displayPanHandle: Bool = true{
        didSet{
            switch displayPanHandle{
            case true:
                panHandle.alpha = 1
            case false:
                panHandle.alpha = 0
            }
        }
    }
    /**The corner radius of the bottom sheet*/
    var cornerRadius: CGFloat = 40{
        didSet{
            self.layer.cornerRadius = cornerRadius
        }
    }
    /**The corner radius of the bottom sheet's pan Handle*/
    var panHandleCornerRadius: CGFloat = 5/2{
        didSet{
            panHandle.layer.cornerRadius = cornerRadius
        }
    }
    
    /** Disable interaction with the pan gesture recognizer that allows the user to move the view across the screen*/
    var disablePullDown: Bool = false{
        didSet{
            if disablePullDown == true{
                panGestureRecognizer.isEnabled = false
            }
            else{
                panGestureRecognizer.isEnabled = true
            }
        }
    }
    
    /** Keep track of the current detent the sheet is perched on*/
    fileprivate var currentDetent: CGFloat? = nil
    
    /** Private UI Elements for this subclass*/
    /** Container that holds the subview content in a visible layer, the main UIView object acts as a shadow*/
    fileprivate let container = UIView()
    /** Secondary area in which the user can touch inside of in order to move this view up and down manually*/
    fileprivate let panArea = UIView()
    /** small rounded UIView displayed at the top of the sheet*/
    fileprivate let panHandle = UIView()
    fileprivate let panHandleHeight: CGFloat = 5
    /** An embedded scrollview hosts the inserted subview and allows dynamic content to be displayed beyond the bounds of the container*/
    let scrollView = UIScrollView()
    /** Gesture recognizer allows the user to move the UIView between its specified detents manually*/
    fileprivate var panGestureRecognizer = UIPanGestureRecognizer()
    
    /** Default constructor for this class, used to instantiate an object of this type without specifying parameters*/
    init(){
        self.detents = []
        self.subview = UIView()
        super.init(frame: .zero)
    }
    
    /**
     - Parameter Detents: An array containing values for the view controller to rest at on the screen.
     - Parameter Subview: The UIView to be hosted inside of this dynamic viewcontroller
     */
    init(detents: [CGFloat], subview: UIView){
        self.detents = detents
        self.subview = subview
        super.init(frame: .zero)
        
        self.detents.sort()
        configure()
    }
    
    /** Configure the UI Elements and pan gesture recognizer details*/
    func configure(){
        /** The size of this view will be the size of the device screen*/
        self.frame = UIScreen.main.bounds
        self.backgroundColor = .clear
        self.isExclusiveTouch = true
        self.layer.cornerRadius = cornerRadius
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowOpacity = 0.5
        self.layer.shadowRadius = 2
        self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: self.layer.cornerRadius).cgPath
        self.clipsToBounds = false
        
        /** The host view will match the background color of its hosted subview to make both seem as one UI element*/
        container.backgroundColor = subview.backgroundColor
        container.clipsToBounds = true
        container.layer.cornerRadius = self.layer.cornerRadius
        container.frame = self.frame
        container.isExclusiveTouch = true
        
        panArea.frame.size = CGSize(width: self.frame.width, height: 50)
        panArea.clipsToBounds = true
        panArea.backgroundColor = .clear
        panArea.isExclusiveTouch = true
        
        panHandle.frame.size = CGSize(width: self.frame.width/6, height: panHandleHeight)
        panHandle.clipsToBounds = true
        panHandle.layer.cornerRadius = panHandleCornerRadius
        panHandle.backgroundColor = .lightGray
        
        scrollView.frame = self.frame
        scrollView.clipsToBounds = true
        scrollView.backgroundColor = .clear
        scrollView.canCancelContentTouches = false
        scrollView.delegate = self
        switch darkMode{
        case true:
            scrollView.indicatorStyle = .white
        case false:
            scrollView.indicatorStyle = .black
        }
        
        /** Setting gesture recognizers*/
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureHandler))
        panGestureRecognizer.delegate = self
        panGestureRecognizer.cancelsTouchesInView = true
        container.addGestureRecognizer(panGestureRecognizer)
        
        /** Layout these subviews*/
        panHandle.frame.origin = CGPoint(x: self.frame.width/2 - panHandle.frame.width/2, y: panHandle.frame.height)
        
        /** If there are no detents provided then the default first position of the view is at the halfway mark of the screen*/
        self.frame.origin = CGPoint(x: 0, y: detents.first ?? self.frame.height/2)
        
        /** Add everything to the view hierarchy*/
        self.addSubview(container)
        container.addSubview(scrollView)
        scrollView.addSubview(subview)
        container.addSubview(panArea)
        panArea.addSubview(panHandle)
        
        /** Set constraints for the scrollview to match the bounds of the parent view*/
        scrollView.translatesAutoresizingMaskIntoConstraints = true
        scrollView.leadingAnchor.constraint(equalTo: subview.leadingAnchor, constant: 0).isActive = true
        scrollView.topAnchor.constraint(equalTo: subview.topAnchor, constant: panArea.frame.maxY).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: subview.trailingAnchor, constant: 0).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: subview.bottomAnchor, constant: 0).isActive = true
        
        /** Constrain the hosted subview to scroll view*/
        subview.translatesAutoresizingMaskIntoConstraints = true
        subview.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        subview.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        subview.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
        /** Make a 30pt gap between the bottom of the scrollview and the content view inside the scrollview*/
        subview.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -30).isActive = true
    }
    
    /** Allow simultaneous gesture recognition, or cancel them so that one gesture can be recognized at a time in a convoluted gesture recognition tree*/
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        false
    }
    
    /** Pan Gesture Handler*/
    @objc func panGestureHandler(sender: UIPanGestureRecognizer){
        let translation = sender.translation(in: self)
        let verticalOffset = translation.y
        
        /** The reference point for the translation of this sheet is the current detent that it's perched on*/
        let sheetTop = currentDetent ?? detents.first ?? 0
        
        /** The current vertical position of the sheet*/
        let currentSheetTop = self.frame.origin.y
        
        /** Highlight the pan handle when the user begins their pan gesture*/
        if sender.state == .began && panHandleHighlightsWhenSelected == true{
            lightHaptic()
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .beginFromCurrentState]){[self] in
            panHandle.frame.size.width = self.frame.width/5
            panHandle.backgroundColor = appThemeColor
            panHandle.frame.origin = CGPoint(x: self.frame.width/2 - panHandle.frame.width/2, y: panHandle.frame.height)
        }
        }
  
        /** Move*/
        if sender.state == .changed || sender.state == .began || sender.state == .possible{
            /** First term -> Upperbound for the sheet, it can't move higher than this value - 10pts*/
            /** && Second term -> Lowerbound for the sheet, it can't move lower than this value + 10pts*/
            if (sheetTop + verticalOffset) > (detents.first! - 10) && (sheetTop + verticalOffset) < (detents.last! + 10){
                
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .beginFromCurrentState]){[self] in
                    self.frame.origin.y = sheetTop + verticalOffset
                }
            }
        }
        
        /** Rest*/
        if sender.state == .ended || sender.state == .cancelled || sender.state == .failed{
            /** Restore the pan handle's original styling when the user ends their pan gesture*/
                lightHaptic()
            UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .beginFromCurrentState]){[self] in
                panHandle.frame.size.width = self.frame.width/6
                panHandle.backgroundColor = .lightGray
                panHandle.frame.origin = CGPoint(x: self.frame.width/2 - panHandle.frame.width/2, y: panHandle.frame.height)
            }
            
            /** Determine the closest detent to the current position*/
            var closestDetent = detents.first!
            /** To find the closest detent you must find the one which gives the lowest offset when you subtract the vertical offset from that detents position and then do absolute value to get the magnitude of that distance*/
            var lowestOffsetFromDetent = detents.first!
            
            for detent in detents{
                if lowestOffsetFromDetent > (CGFloat(fabsf(Float(currentSheetTop - detent)))){
                    lowestOffsetFromDetent = CGFloat(fabsf(Float(currentSheetTop - detent)))
                    closestDetent = detent
                    currentDetent = closestDetent
                }
            }
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .beginFromCurrentState]){[self] in
                frame.origin.y = closestDetent
            }
        }
    }
    
    /** Tap Gesture Handler*/
    @objc func panHandlePanGestureHandler(sender: UIPanGestureRecognizer){
        switch sender.state{
        case .began:
            lightHaptic()
            UIView.animate(withDuration: 0.5, delay: 0){[self] in
                panHandle.backgroundColor = appThemeColor
            }
        case .possible:
            UIView.animate(withDuration: 0.5, delay: 0){[self] in
                panHandle.backgroundColor = appThemeColor
            }
        case .changed:
            UIView.animate(withDuration: 0.5, delay: 0){[self] in
                panHandle.backgroundColor = appThemeColor
            }
        case .ended:
            lightHaptic()
            UIView.animate(withDuration: 0.5, delay: 0){[self] in
                panHandle.backgroundColor = .lightGray
            }
        case .cancelled:
            UIView.animate(withDuration: 0.5, delay: 0){[self] in
                panHandle.backgroundColor = .lightGray
            }
        case .failed:
            UIView.animate(withDuration: 0.5, delay: 0){[self] in
                panHandle.backgroundColor = .lightGray
            }
        @unknown default:
            panHandle.backgroundColor = .lightGray
        }
    }
    
    /** Move the bottom sheet to the given point in a static or animated fashion*/
    func moveTo(verticalPosition: CGFloat, animated: Bool){
        switch animated{
        case true:
            UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .beginFromCurrentState]){[self] in
                frame.origin.y = verticalPosition
                currentDetent = verticalPosition
            }
        case false:
            frame.origin.y = verticalPosition
            currentDetent = verticalPosition
        }
    }
    
    /** Move the bottom sheet to the starting(default) detent specified in a static or animated fashion*/
    func moveToStartingDetent(animated: Bool){
        switch animated{
        case true:
            UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .beginFromCurrentState]){[self] in
                frame.origin.y = startingDetent ?? 0
                currentDetent = startingDetent ?? 0
            }
        case false:
            frame.origin.y = startingDetent ?? 0
            currentDetent = startingDetent ?? 0
        }
    }
    
    /** Hide the sheet below the screen's rendered content*/
    func hide(animated: Bool){
        self.isUserInteractionEnabled = false
        
        switch animated{
        case true:
            UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .beginFromCurrentState]){[self] in
                frame.origin.y = self.frame.height * 1.25
            }
        case false:
            frame.origin.y = self.frame.height * 1.25
        }
    }
    
    /** Display the sheet at the last detent it was positioned at in a static or animated fashion*/
    func show(animated: Bool){
        self.isUserInteractionEnabled = true
        
        switch animated{
        case true:
            UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .beginFromCurrentState]){[self] in
                frame.origin.y = currentDetent ?? 0
            }
        case false:
            frame.origin.y = currentDetent ?? 0
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
