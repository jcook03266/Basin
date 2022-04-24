//
//  customTabbar.swift
//  Stuy Wash N Dry
//
//  Created by Justin Cook on 3/27/22.
//

import UIKit

/** Protocol allows the implementing class to listen for selection events for the given tabbar*/
@objc protocol JCTabbarDelegate{
    @objc optional func JCtabbar(_ tabbar: JCTabbar, didSelect item: JCTabbarItem)
}

/** This is a UIView subclass that mimics the function of a UITabbar by using a UIView and custom JCTabbarItems*/

/** Add underline overline*/
public class JCTabbar: UIView, UIGestureRecognizerDelegate{
    /** Array that store each button to be placed inside of the tabbar*/
    var tabbarButtons: [JCTabbarItem] = []{
        didSet{
            layoutButtons()
            
            /** Automatically select the first button as the currently selected button*/
            if tabbarButtons.isEmpty == false{
                setCurrentlySelectedItem(item: tabbarButtons.first!)
            }
        }
    }
    
    /** Determine whether or not to provide shadow around the tabbar*/
    var shadowEnabled: Bool = false{
        didSet{
            if shadowEnabled == false{
                removeShadow()
            }
            else{
                addShadow()
            }
        }
    }
    
    /** Specify whether or not to show the overline that's displayed above the tabbar items*/
    var overLineEnabled: Bool = false{
        didSet{
            if overLineEnabled == true{
                overlineTrack.alpha = 1
            }
            else{
                overlineTrack.alpha = 0
            }
        }
    }
    
    /** Delegate declaration*/
    var delegate: JCTabbarDelegate?
    /** Container UI, contains all of the subviews, the main view just acts as a potential shadow*/
    fileprivate var container: UIView = UIView()
    /** Stackview to hold and evenly space out the provided buttons*/
    fileprivate var buttonStackView: UIStackView = UIStackView()
    /** Overline UI, a small UIView that's displayed over the bar button items to inform the user that they've select one of them (this can be accessed an manipulated from another class freely)*/
    var overline = UIView()
    /** A background UIView that contains the overline view*/
    fileprivate var overlineTrack = UIView()
    var overlineHeight: CGFloat?{
        didSet{
            overline.frame.size.height = overlineHeight ?? 1
            overlineTrack.frame.size.height = overlineHeight ?? 1
        }
    }
    var overlineColor: UIColor?{
        didSet{
            overline.backgroundColor = overlineColor ?? .systemBlue
        }
    }
    var overlineTrackColor: UIColor?{
        didSet{
            overlineTrack.backgroundColor = overlineTrackColor ?? .lightGray
        }
    }
    /** Determine if the overline should be moved in a static or animated fashion*/
    var overlineAnimated: Bool = false
    /** Specify whether or not to paint circles over the item the user taps on*/
    var useVisualTaps: Bool = false
    /** The color of the border arround the visual taps*/
    var visualTapsAccentColor: UIColor?
    /** Allows the user to set the corner radius for this tabbar easily by changing the corner radius of both the shadow and the subview container*/
    var cornerRadius: CGFloat = 0{
        didSet{
            self.layer.cornerRadius = cornerRadius
            self.container.layer.cornerRadius = cornerRadius
        }
    }
    
    /** Keep track of the item currently selected in the bar*/
    fileprivate var currentlySelectedItem: JCTabbarItem?{
        didSet{
            if let currentlySelectedItem = currentlySelectedItem{
                currentlySelectedItem.isSelected()
            }
        }
    }
    
    /** The height of this view*/
    var height: CGFloat?
    
    /** Default initializer*/
    init(height: CGFloat?){
        self.height = height
        
        super.init(frame: .zero)
        
        construct()
    }
    
    /** Piece the UI elements together*/
    private func construct(){
        self.backgroundColor = .clear
        self.frame.size.width = UIScreen.main.bounds.width
        /** 83 is the default height of the tabbar on iPhone X models*/
        self.frame.size.height = height ?? 83
        
        container.frame = self.frame
        container.backgroundColor = bgColor
        
        buttonStackView.frame = self.frame
        buttonStackView.backgroundColor = .clear
        buttonStackView.alignment = .center
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = 10
        /** Allow the buttons to be tapped*/
        buttonStackView.isUserInteractionEnabled = true
        buttonStackView.semanticContentAttribute = .forceLeftToRight
        
        overlineTrack.frame = CGRect(x: 0, y: self.frame.minY, width: self.frame.width, height: overlineHeight ?? 1)
        overlineTrack.alpha = 0
        overlineTrack.backgroundColor = overlineTrackColor ?? .lightGray
        overline.backgroundColor = overlineColor ?? .systemBlue
        
        /** Add all subviews to the view hierarchy*/
        self.addSubview(container)
        container.addSubview(buttonStackView)
        container.addSubview(overlineTrack)
        overlineTrack.addSubview(overline)
    }
    
    /** Specify the currently selected tabbar item*/
    func setCurrentlySelectedItem(item: JCTabbarItem){
        guard tabbarButtons.contains(item) else{
            print("Error: This item is not contained inside of the tabbar's managed items")
            return
        }
        /** Deselect any of the other buttons*/
        for button in tabbarButtons{
            if button != item{
                button.isNotSelected()
            }
        }
        
        currentlySelectedItem = item
        JCtabbar(self, didSelect: currentlySelectedItem!)
        
        /** Make the underline the size of the first button's content and position it directly underneath that first button*/
        overline.frame.size.width = (buttonStackView.frame.width / CGFloat(tabbarButtons.count)) - buttonStackView.spacing
        overline.frame.size.height = overlineHeight ?? 1
        
        /** Positon of the underline*/
        if overlineAnimated{
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
                overline.frame.origin = CGPoint(x: item.frame.minX, y: 0)
            }
        }
        else{
            overline.frame.origin = CGPoint(x: item.frame.minX, y: 0)
        }
    }
    
    /** Layout the given buttons as subviews*/
    private func layoutButtons(){
        guard tabbarButtons.isEmpty == false else {
            return
        }
        
        /** Add this button to the container and space it out evenly*/
        for button in tabbarButtons{
            
            button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
            button.isExclusiveTouch = true
            addDynamicButtonGR(button: button)
            addCircleVisualTapGestureRecognizer(to: button)
            
            /** Prevent duplicate buttons from being added by mistake*/
            if !buttonStackView.arrangedSubviews.contains(button){
                buttonStackView.addArrangedSubview(button)
                
                /** Lock the button's height to a specified height*/
                let heightConstraint = NSLayoutConstraint(item: button, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: (buttonStackView.frame.height * 0.8))
                button.addConstraints([heightConstraint])
                
                /** Specify the height constraint and calculate the width of the buttons, this must be done in real time as sizeToFit is delayed*/
                let newHeight = (buttonStackView.frame.height * 0.8)
                let newWidth = (buttonStackView.frame.width / CGFloat(tabbarButtons.count)) - buttonStackView.spacing
                
                /** Resize the subviews to fit appropriately within the container*/
                if let imageView = button.itemImageView{
                    imageView.sizeToFit()
                    
                    if let _ = button.titleLabel{
                        imageView.frame.origin = CGPoint(x: newWidth/2 - imageView.frame.width/2, y: 0)
                    }
                    else{
                        imageView.frame.origin = CGPoint(x: newWidth/2 - imageView.frame.width/2, y: newHeight/2 - imageView.frame.height/2)
                    }
                }
                
                if let titleLabel = button.itemTitleLabel{
                    titleLabel.sizeToFit()
                    
                    if let imageView = button.itemImageView{
                        titleLabel.frame.origin = CGPoint(x: newWidth/2 - titleLabel.frame.width/2, y: imageView.frame.maxY)
                    }
                    else{
                        titleLabel.frame.origin = CGPoint(x: newWidth/2 - titleLabel.frame.width/2, y: newHeight/2 - titleLabel.frame.height/2)
                    }
                }
            }
        }
    }
    
    /** Detect when the button has been tapped*/
    @objc func buttonTapped(sender: JCTabbarItem){
        /** Inform the user that they have selected the current button*/
        setCurrentlySelectedItem(item: sender)
    }
    
    /** Add a tap gesture recognizer to a tabbar item which paints a transparent circle in the center of the item when the user taps the view and removes it when the user releases their finger*/
    func addCircleVisualTapGestureRecognizer(to item: JCTabbarItem){
        let tap = UILongPressGestureRecognizer(target: self, action: #selector(itemTouched))
        tap.delegate = self
        tap.minimumPressDuration = 0.01
        item.addGestureRecognizer(tap)
    }
    
    /** Allow the button taps to be recognized along with the secondary tap gesture recognizer*/
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
    
    /** Dictionary to store references to both the painted circle and the item in question, the item is the key and the painted circle is the value*/
    var touchedItems: [UIView : UIView] = [:]
    
    @objc func itemTouched(sender: UILongPressGestureRecognizer){
        guard useVisualTaps == true else {
            return
        }
        guard let touchedItem = sender.view as? JCTabbarItem else{
            return
        }
        
        /** Switch through the different states and respond accordingly*/
        switch sender.state{
        case .possible:
            paintCircle(in: touchedItem)
        case .began:
            paintCircle(in: touchedItem)
        case .changed:
            resizePaintedCircle(in: touchedItem, with: CGFloat(computeDistanceBetween(this: sender.view!.center, and: sender.location(in: self))))
        case .ended:
            removePaintedCircle(from: touchedItem)
            /** The user touched this item*/
            setCurrentlySelectedItem(item: touchedItem)
        case .cancelled:
            removePaintedCircle(from: touchedItem)
        case .failed:
            removePaintedCircle(from: touchedItem)
        @unknown default:
            removePaintedCircle(from: touchedItem)
        }
    }
    
    /** Use Pythag to compute the distance between these two points*/
    func computeDistanceBetween(this point: CGPoint, and thisOtherPoint: CGPoint)->Float{
        return Float(sqrtf(squareThis(value: Float(point.x - thisOtherPoint.x)) + squareThis(value: Float(point.y - thisOtherPoint.y))))
    }
    
    /** Simple squaring function where the value is multiplied by itself to square it*/
    func squareThis(value: Float)->Float{
        return (value * value)
    }
    
    /** Resize the painted circle in the item depending on where the user's finger is, this is used to scale the item up and down for more interactive behavior*/
    func resizePaintedCircle(in item: JCTabbarItem, with translation: CGFloat){
        /** Use the magnitude of the translation vector in order to translate regardless of the direction of the user's finger, negative or positive*/
        /** Make sure the translation isn't too small or too large so that the circle doesn't scale crazily*/
        guard translation/10 >= 0 && translation/10 <= 2 else {
            return
        }
        
        if let circleView = touchedItems[item]{
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .allowUserInteraction]){
                circleView.transform = CGAffineTransform(scaleX: (translation/10), y: (translation/10))
            }
        }
    }
    
    /** Paint a transparent circle in the center of the given view*/
    func paintCircle(in item: JCTabbarItem){
        /** Snapchat esque circular fade in fade out animation signals where the user has tapped*/
        let circleView = UIView(frame: CGRect(x: 0, y: 0, width: item.frame.width * 0.5, height: item.frame.width * 0.5))
        circleView.layer.cornerRadius = circleView.frame.height/2
        circleView.layer.borderWidth = 0.25
        circleView.layer.borderColor = visualTapsAccentColor?.cgColor ?? UIColor.systemBlue.cgColor
        circleView.backgroundColor = UIColor.clear
        circleView.clipsToBounds = true
        circleView.frame.origin = CGPoint(x: item.frame.width/2 - circleView.frame.width/2, y: item.frame.height/2 - circleView.frame.height/2)
        circleView.transform = CGAffineTransform(scaleX: 0, y: 0)
        
        /** A circumscribed circle inside the parent circle*/
        let inscribedCircleView = UIView(frame: CGRect(x: 0, y: 0, width: item.frame.width * 0.5, height: item.frame.width * 0.5))
        inscribedCircleView.layer.cornerRadius = inscribedCircleView.frame.height/2
        switch darkMode {
        case true:
            inscribedCircleView.backgroundColor = UIColor.lightGray.lighter.withAlphaComponent(0.25)
        case false:
            inscribedCircleView.backgroundColor = UIColor.white.darker.withAlphaComponent(0.25)
        }
        inscribedCircleView.transform = CGAffineTransform(scaleX: 0, y: 0)
        
        /** Scale up and scale down animation*/
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .allowUserInteraction]){
            circleView.transform = CGAffineTransform(scaleX: 2, y: 2)
        }
        UIView.animate(withDuration: 0.5, delay: 0.1, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .allowUserInteraction]){
            inscribedCircleView.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        UIView.animate(withDuration: 0.5, delay: 0.4, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .allowUserInteraction]){
            circleView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            inscribedCircleView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        }
        
        /** Add the circles to the item's view hierarchy*/
        circleView.addSubview(inscribedCircleView)
        item.addSubview(circleView)
        
        touchedItems[item] = circleView
    }
    
    /** Remove the circle from the given view (if it exists in the dictionary)*/
    func removePaintedCircle(from item: JCTabbarItem){
        if let circleView = touchedItems[item]{
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .allowUserInteraction]){
                circleView.alpha = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                circleView.removeFromSuperview()
            }
            touchedItems.removeValue(forKey: circleView)
        }
    }
    
    /** Adds standard gesture recognizers to button that scale the button when the user's finger enters or leaves the surface of the button*/
    func addDynamicButtonGR(button: UIButton){
        button.addTarget(self, action: #selector(buttonTI), for: .touchUpInside)
        button.addTarget(self, action: #selector(buttonTD), for: .touchDown)
        button.addTarget(self, action: #selector(buttonDE), for: .touchDragExit)
        button.addTarget(self, action: #selector(buttonDEN), for: .touchDragEnter)
    }
    
    /** Fired when user touches inside the button, this is used to reset the scale of the button when the touch down event ends*/
    @objc func buttonTI(sender: UIButton){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
            lightHaptic()
        }
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
    }
    
    /** Generic recognizer that scales the button down when the user touches their finger down on it*/
    @objc func buttonTD(sender: UIButton){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
            lightHaptic()
        }
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }
    
    /** Generic recognizer that scales the button up when the user drags their finger into it*/
    @objc func buttonDEN(sender: UIButton){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }
    
    /** Generic recognizer that scales the button up when the user drags their finger out inside of it*/
    @objc func buttonDE(sender: UIButton){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
            lightHaptic()
        }
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
    }
    
    /** Implementing this delegate method*/
    fileprivate func JCtabbar(_ tabbar: JCTabbar, didSelect item: JCTabbarItem){
        delegate?.JCtabbar?(tabbar, didSelect: item)
    }
    
    /** Supplement a shadow with the given criteria*/
    func setShadow(shadowColor: CGColor, ShadowOpacity: Float, ShadowRadius: CGFloat){
        self.clipsToBounds = false        
        self.layer.shadowColor = shadowColor
        self.layer.shadowOpacity =  ShadowOpacity
        self.layer.shadowRadius = ShadowRadius
        self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: self.layer.cornerRadius).cgPath
    }
    
    /** Allow the shadow to be seen*/
    func addShadow(){
        self.clipsToBounds = false
    }
    
    /** Remove the shadow of the tabbar*/
    func removeShadow(){
        self.clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/** UIButton subclass that encapsulates a UIImageview and a label, this view acts as an item for the custom tabbar view*/
public class JCTabbarItem: UIButton{
    /** The (optional) name of the item that will be displayed below its image which is also used to describe its context*/
    var title: String? = nil{
        didSet{
            fillItemViews()
        }
    }
    /** The (optional) image to display over the name of the item that is used to describe its context*/
    var image: UIImage? = nil{
        didSet{
            fillItemViews()
        }
    }
    /** The tint color of all views in this item*/
    override public var tintColor: UIColor?{
        didSet{
            selectedTintColor = tintColor
        }
    }
    
    /** The tint color to display for the item when it's selected*/
    var selectedTintColor: UIColor?
    
    /** The tint color to display for the item when it's not selected*/
    var notSelectedTintColor: UIColor?{
        didSet{
            changeTintColors()
        }
    }
    
    var badgeBackgroundColor: UIColor?{
        didSet{
            changeBadgeBackgroundColor()
        }
    }
    
    var badgeFontColor: UIColor?{
        didSet{
            changeBadgeFontColor()
        }
    }
    
    var badgeFont: UIFont?{
        didSet{
            changeBadgeFont()
        }
    }
    
    /** Imageview to display the optional image of this item*/
    fileprivate var itemImageView: UIImageView!
    /** Title label to display the optional title of this item*/
    fileprivate var itemTitleLabel: UILabel!
    /** UILabel used to convery information pertaining to this specific item's context, in a small form factor*/
    fileprivate var itemBadge: PaddedLabel!
    
    /** Basic initializer for this item, the item will be automatically resized once added to a tabbar so initializing its frame will do nothing as it is already given an arbitrary size*/
    init(){
        super.init(frame: .zero)
        
        construct()
    }
    
    /** Initialize all of the potential subviews for this item should the user add an image or text*/
    fileprivate func construct(){
        /** Generic square*/
        self.frame.size = CGSize(width: 90, height: 90)
        self.backgroundColor = .clear
        self.isExclusiveTouch = true
        self.clipsToBounds = false
        
        itemImageView = UIImageView()
        itemImageView.backgroundColor = .clear
        itemImageView.frame.size.width = self.frame.width
        itemImageView.frame.size.height = (self.frame.height * 0.7)
        itemImageView.contentMode = .scaleAspectFit
        itemImageView.clipsToBounds = true
        
        itemTitleLabel = UILabel()
        itemTitleLabel.backgroundColor = .clear
        itemTitleLabel.frame.size.width = self.frame.width
        itemTitleLabel.frame.size.height = (self.frame.height * 0.3)
        itemTitleLabel.font = getCustomFont(name: .Ubuntu_Regular, size: 12, dynamicSize: true)
        itemTitleLabel.textAlignment = .center
        itemTitleLabel.adjustsFontForContentSizeCategory = true
        itemTitleLabel.adjustsFontSizeToFitWidth = true
        itemTitleLabel.clipsToBounds = true
        
        /** Add some padding around the label to prevent its text from leaking out of its bounds*/
        itemBadge = PaddedLabel(withInsets: 1, 1, 2, 2)
        itemBadge.frame.size = CGSize(width: self.frame.width/2, height: self.frame.height * 0.3)
        itemBadge.textAlignment = .center
        itemBadge.adjustsFontForContentSizeCategory = true
        itemBadge.adjustsFontSizeToFitWidth = true
        itemBadge.layer.cornerRadius = itemBadge.frame.height/2
        itemBadge.clipsToBounds = true
        /** This view will be unhidden when the badge is displayed*/
        itemBadge.alpha = 0
        itemBadge.isHidden = true
        
        /** Allow touches to pass through these views and to the parent view*/
        itemImageView.isUserInteractionEnabled = false
        itemTitleLabel.isUserInteractionEnabled = false
        itemBadge.isUserInteractionEnabled = false
        
        /** Layout these subviews in placeholder positions*/
        itemImageView.frame.origin = CGPoint(x: self.frame.width/2 - itemImageView.frame.width/2, y: 0)
        itemTitleLabel.frame.origin = CGPoint(x: self.frame.width/2 - itemTitleLabel.frame.width/2, y: itemImageView.frame.maxY)
        itemBadge.frame.origin = CGPoint(x: self.frame.width - itemBadge.frame.width/2, y: self.frame.minY)
        
        self.addSubview(itemImageView)
        self.addSubview(itemTitleLabel)
        self.addSubview(itemBadge)
    }
    
    fileprivate func displayBadge(with text: String, animated: Bool, animation: JCTabbarItemBadgeAnimation?, animationDuration: CGFloat?){
        itemBadge.alpha = 1
        itemBadge.isHidden = false
        
        guard animated == false || animation == nil || animationDuration == nil else {
            /** Do the static movement*/
            return
        }
        /** Do the standard animation movement*/
        
    }
    
    fileprivate func removeBadge(animated: Bool, animation: JCTabbarItemBadgeAnimation?, animationDuration: CGFloat?){
        itemBadge.alpha = 0
        itemBadge.isHidden = true
        
        guard animated == false || animation == nil || animationDuration == nil else {
            /** Do the static movement*/
            return
        }
        /** Do the standard animation movement*/
        
    }
    
    /** The item's default tint color for when it has been deselected and returned to its normal state*/
    fileprivate func isNotSelected(){
        UIView.animate(withDuration: 0.5, delay: 0){ [self] in
            if let imageView = itemImageView{
                imageView.tintColor = notSelectedTintColor ?? .lightGray
                
                /** Change the image (if any) displayed by the imageview to display an image with the following tint color*/
                if let image = imageView.image{
                    imageView.image = image.withTintColor(notSelectedTintColor ?? .lightGray)
                }
            }
            if let titleLabel = itemTitleLabel{
                titleLabel.tintColor = notSelectedTintColor ?? .lightGray
                titleLabel.textColor = notSelectedTintColor ?? .lightGray
            }
        }
    }
    
    /** The item's selected tint color for when it has been selected by a user*/
    fileprivate func isSelected(){
        UIView.animate(withDuration: 0.5, delay: 0){ [self] in
            if let imageView = itemImageView{
                imageView.tintColor = selectedTintColor ?? .systemBlue
                
                /** Change the image (if any) displayed by the imageview to display an image with the following tint color*/
                if let image = imageView.image{
                    imageView.image = image.withTintColor(selectedTintColor ?? .systemBlue)
                }
            }
            if let titleLabel = itemTitleLabel{
                titleLabel.tintColor = selectedTintColor ?? .systemBlue
                titleLabel.textColor = selectedTintColor ?? .systemBlue
            }
        }
    }
    
    /** Change the tint color of the subviews whenever a global change occurs*/
    fileprivate func changeTintColors(){
        if let imageView = itemImageView{
            imageView.tintColor = notSelectedTintColor ?? .lightGray
            
            /** Change the image (if any) displayed by the imageview to display an image with the following tint color*/
            if let image = imageView.image{
                imageView.image = image.withTintColor(notSelectedTintColor ?? .lightGray)
            }
        }
        if let titleLabel = itemTitleLabel{
            titleLabel.tintColor = notSelectedTintColor ?? .lightGray
            titleLabel.textColor = notSelectedTintColor ?? .lightGray
        }
    }
    
    /** Change the background color of the badge*/
    fileprivate func changeBadgeBackgroundColor(){
        if let badge = itemBadge{
            badge.backgroundColor = badgeBackgroundColor ?? .systemBlue
        }
    }
    
    /** Change the font color of the badge*/
    fileprivate func changeBadgeFontColor(){
        if let badge = itemBadge{
            badge.textColor = badgeFontColor ?? .white
        }
    }
    
    /** Change the font  of the badge*/
    fileprivate func changeBadgeFont(){
        if let badge = itemBadge{
            badge.font = badgeFont ?? getCustomFont(name: .Ubuntu_Regular, size: 12, dynamicSize: true)
        }
    }
    
    /** Provide the image and text for the subviews of this item when given*/
    fileprivate func fillItemViews(){
        if let givenImage = image{
            itemImageView.image = givenImage
        }
        if let givenTitle = title{
            itemTitleLabel.text = givenTitle
        }
    }
    
    /** Various animation types for the tabbar item badge display and hide animation*/
    fileprivate enum JCTabbarItemBadgeAnimation: Int{
        /** Scales the badge up to 1 with a transform when animating it into the scene and reverses this with a scale down transform when animating it out of the scene*/
        case pop = 0
        /** Fades the badge in when animating it into the scene and reverses this with a fadeout when animating it out of the scene*/
        case fade = 1
        /** Slides the badge in from behind the item when animating it into the scene and reverses this path when animating it out of the scene*/
        case slide = 2
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
