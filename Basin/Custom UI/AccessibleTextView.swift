//
//  AccessibleTextView.swift
//  Stuy Wash N Dry
//
//  Created by Justin Cook on 2/5/22.
//

import UIKit
import AVFoundation
import Combine

/** UITextView subclass that enables accessibility controls in a separate view controller*/
class AccessibleTextView: UITextView, AVSpeechSynthesizerDelegate, UIContextMenuInteractionDelegate{
    /** View controller from which the expanded text view context will be presented from*/
    var presentingViewController: UIViewController
    var useContextMenu: Bool!
    
    /** UI Elements specific to this object*/
    fileprivate var exitButton = UIButton()
    fileprivate var textToSpeechButton = UIButton()
    fileprivate var increaseTextSizeButton = UIButton()
    fileprivate var decreaseTextSizeButton = UIButton()
    /** Changes the background color of the textview to any color provided by the color wheel */
    fileprivate var changeBackgroundColor = UIButton()
    /** Changes the text color of the textview to any color provided by the color wheel */
    fileprivate var changeTextColor = UIButton()
    /** Store the original text color, background color, view frame, and font size in order to restore the textview back to its superview unchanged*/
    fileprivate var originalBackgroundColor: UIColor!
    fileprivate var originalTextColor: UIColor!
    fileprivate var originalFontSize: CGFloat!
    fileprivate var originalFrame: CGRect!
    /** The view in which the textview will be hosted alongside its accessibility controls*/
    fileprivate var textViewContainer: UIView!
    /** Threshold value for the scale of the pinch gesture at which the accessible view controller will be triggered*/
    fileprivate var pinchGestureScaleThreshold: CGFloat = 1.5
    /** Bool used to determine when the textview is being presented in the accessible reader or not*/
    fileprivate var beingPresented = false
    
    
    init(frame: CGRect, presentingViewController: UIViewController, useContextMenu: Bool){
        self.presentingViewController = presentingViewController
        self.useContextMenu = useContextMenu
        
        super.init(frame: frame, textContainer: nil)
        self.addInteraction(UIContextMenuInteraction(delegate: self))
    }
    
    /** Basic view controller for instantiating the object in order to access some of its methods*/
    init(){
        self.presentingViewController = UIViewController()
        
        super.init(frame: .zero, textContainer: nil)
    }
    
    /** Context menu that can be used to copy the contents of the text view as well as trigger the accessible reader view controller*/
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration?{
        guard beingPresented == false else{
            return nil
        }
        
        let viewController = AccessibleReaderDetailView(frame: UIScreen.main.bounds, referenceTextView: self)
        viewController.hidesBottomBarWhenPushed = true
        
        var children: [UIMenuElement] = []
        
        let copy = UIAction(title: "Copy text", image: UIImage(systemName: "doc.on.clipboard.fill")){ action in
            lightHaptic()
            
            UIPasteboard.general.string = self.text
            
            globallyTransmit(this: "Text copied to clipboard", with: UIImage(systemName: "doc.on.clipboard.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: .clear, imageBorder: .none, blurEffect: true, accentColor: .lightGray, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: true), using: .rightStrip, animated: true, duration: 3, selfDismiss: true)
        }
        let accessibleReader = UIAction(title: "Accessible Reader", image: UIImage(systemName: "figure.wave.circle.fill")){ [self] action in
            lightHaptic()
            
            presentingViewController.present(viewController, animated: true, completion: nil)
            presentingViewController.show(viewController, sender: self)
        }
        
        if useContextMenu == true{
        children.append(accessibleReader)
        children.append(copy)
        }
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: {return viewController}){ _ in
            UIMenu(title: "Interactions", children: children)
        }
    }
    
    /** Show the view controller when the context menu animation is done*/
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        animator.addCompletion{ [self] in
            if let viewController = animator.previewViewController{
                presentingViewController.show(viewController, sender: self)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/** Display an accessible textview in a 'focused' larger container*/
class AccessibleReaderDetailView: UIViewController, UIContextMenuInteractionDelegate, UIColorPickerViewControllerDelegate{
    /** The textview that will be used as a reference for the properties of the textview contained by this view controller*/
    var referenceTextView: AccessibleTextView
    /** The custom textview that copies the properties of the textview from the passed textview*/
    private var textView = UITextView()
    private var exitButton = UIButton()
    private var buttonBar: underlinedButtonBar!
    private var buttons: [UIButton] = []
    
    /** Original properties of the textview*/
    private var originalBackgroundColor: UIColor!
    private var originalHighlightColor: UIColor!
    private var originalFontColor: UIColor!
    private var originalFontSize: CGFloat!
    private var originalFont: UIFont!
    
    /** Determines whether or not text to speech is enabled*/
    private var TTSEnabled = false
    /** Used to inform the color picker delegate which color property to change when a color is selected*/
    private var backgroundColorBeingEdited = false
    private var fontColorBeingEdited = false
    private var highlightColorBeingEdited = false
    /**Global declaration, to keep the color picker subscription alive*/
    private var cancellable: AnyCancellable?
    private var editedBackgroundColor: UIColor!
    private var editedHighlightColor: UIColor!
    private var editedFontColor: UIColor!
    private var editedFontSize: CGFloat!
    private var editedFont: UIFont!
    
    /** Bools that allow fonts to be combined*/
    private var fontBolded = false
    private var fontItalicized = false
    
    /** Timer used to set the title of buttons whenever a the +/- font size buttons are pressed to represent the current font size*/
    private var plusTextSizeButtontimer = Timer()
    private var minusTextSizeButtontimer = Timer()
    
    /** Text to speech properties*/
    /** The text being spoken by the synth*/
    private var utterance: AVSpeechUtterance!
    /** The type of voice used by the synthesizer*/
    private var voice: AVSpeechSynthesisVoice?
    /** The rate at which the synth speaks, this can omitted if a natural speaking rate is desired*/
    private var utteranceRate: CGFloat!
    /** Object that synthesizes text to speech*/
    private var synthesizer = AVSpeechSynthesizer()
    
    init(frame: CGRect, referenceTextView: AccessibleTextView) {
        self.referenceTextView = referenceTextView
        
        super.init(nibName: nil, bundle: nil)
        self.view.frame = frame
    }
    
    func setNotificationCenter(){
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    /**Notification from delegate that says whether the app has exited from the foreground and into the background or not*/
    @objc func appMovedToBackground() {
        /** Stop the synth only when it's actually speaking*/
        if synthesizer.isSpeaking == true{
        stopSynth()
        }
    }
    
    /**Notification from delegate that says whether the app has reentered from the background and into the foreground or not*/
    @objc func appMovedToForeground() {
    }
    
    override func viewWillAppear(_ animated: Bool){
        setProperties()
        setCustomNavUI()
        setNotificationCenter()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if synthesizer.isSpeaking == true{
        stopSynth()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        /** Restore the tabbar if the previous vc is using it or not (doesn't matter as that vc handles its appearance)*/
        tabBarController?.tabBar.isHidden = false
    }
    
    override func viewDidLoad(){
        buildUI()
    }
    
    private func buildUI(){
        let viewBounds = UIScreen.main.bounds
        
        var color = UIColor()
        switch darkMode{
        case true:
            color = .black
        case false:
            color = .white
        }
        
        self.view.backgroundColor = color
        
        /** Copy constructor*/
        textView.text = referenceTextView.text
        textView.backgroundColor = color
        textView.font = referenceTextView.font
        textView.isSelectable = referenceTextView.isSelectable
        textView.textColor = referenceTextView.textColor
        textView.isEditable = referenceTextView.isEditable
        textView.isScrollEnabled = referenceTextView.isScrollEnabled
        textView.textAlignment = referenceTextView.textAlignment
        textView.tintColor = UIColor.systemYellow
        textView.showsVerticalScrollIndicator = referenceTextView.showsVerticalScrollIndicator
        textView.showsHorizontalScrollIndicator = referenceTextView.showsHorizontalScrollIndicator
        textView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 200, right: 0)
        
        originalBackgroundColor = textView.backgroundColor
        originalHighlightColor = textView.tintColor
        originalFontSize = textView.font!.pointSize
        originalFontColor = textView.textColor
        originalFont = textView.font!
        
        editedBackgroundColor = textView.backgroundColor
        editedHighlightColor = textView.tintColor
        editedFontSize = textView.font!.pointSize
        editedFontColor = textView.textColor
        editedFont = textView.font!
        
        textView.frame.size = CGSize(width: self.view.frame.width * 0.9, height: self.view.frame.height * 1)
        
        let textToSpeechButton = UIButton()
        textToSpeechButton.setTitle("", for: .normal)
        textToSpeechButton.setTitleColor(fontColor, for: .normal)
        textToSpeechButton.titleLabel?.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: false)
        textToSpeechButton.titleLabel?.adjustsFontSizeToFitWidth = true
        var imageConfiguration = UIImage.SymbolConfiguration(weight: .regular)
        var image = UIImage(systemName: "waveform.and.mic", withConfiguration: imageConfiguration)
        textToSpeechButton.tintColor = fontColor
        textToSpeechButton.setImage(image, for: .normal)
        textToSpeechButton.isExclusiveTouch = true
        textToSpeechButton.backgroundColor = color
        textToSpeechButton.addTarget(self, action: #selector(textToSpeechButtonPressed), for: .touchDown)
        
        let plusTextSizeButton = UIButton()
        plusTextSizeButton.setTitle("", for: .normal)
        plusTextSizeButton.setTitleColor(fontColor, for: .normal)
        plusTextSizeButton.titleLabel?.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: false)
        plusTextSizeButton.titleLabel?.adjustsFontSizeToFitWidth = true
        imageConfiguration = UIImage.SymbolConfiguration(weight: .regular)
        image = UIImage(systemName: "plus.circle.fill", withConfiguration: imageConfiguration)
        plusTextSizeButton.tintColor = fontColor
        plusTextSizeButton.setImage(image, for: .normal)
        plusTextSizeButton.isExclusiveTouch = true
        plusTextSizeButton.backgroundColor = color
        plusTextSizeButton.addTarget(self, action: #selector(plusTextSizeButtonPressed), for: .touchDown)
        
        let minusTextSizeButton = UIButton()
        minusTextSizeButton.setTitle("", for: .normal)
        minusTextSizeButton.setTitleColor(fontColor, for: .normal)
        minusTextSizeButton.titleLabel?.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: false)
        minusTextSizeButton.titleLabel?.adjustsFontSizeToFitWidth = true
        imageConfiguration = UIImage.SymbolConfiguration(weight: .regular)
        image = UIImage(systemName: "minus.circle.fill", withConfiguration: imageConfiguration)
        minusTextSizeButton.tintColor = fontColor
        minusTextSizeButton.setImage(image, for: .normal)
        minusTextSizeButton.isExclusiveTouch = true
        minusTextSizeButton.backgroundColor = color
        minusTextSizeButton.addTarget(self, action: #selector(minusTextSizeButtonPressed), for: .touchDown)
        
        let editFontButton = UIButton()
        editFontButton.setTitle("", for: .normal)
        editFontButton.setTitleColor(fontColor, for: .normal)
        editFontButton.titleLabel?.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: false)
        editFontButton.titleLabel?.adjustsFontSizeToFitWidth = true
        imageConfiguration = UIImage.SymbolConfiguration(weight: .regular)
        image = UIImage(systemName: "bold.italic.underline", withConfiguration: imageConfiguration)
        editFontButton.tintColor = fontColor
        editFontButton.setImage(image, for: .normal)
        editFontButton.isExclusiveTouch = true
        editFontButton.backgroundColor = color
        editFontButton.addTarget(self, action: #selector(editFontButtonPressed), for: .touchDown)
        
        let editBackgroundButton = UIButton()
        editBackgroundButton.setTitle("", for: .normal)
        editBackgroundButton.setTitleColor(fontColor, for: .normal)
        editBackgroundButton.titleLabel?.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: false)
        editBackgroundButton.titleLabel?.adjustsFontSizeToFitWidth = true
        imageConfiguration = UIImage.SymbolConfiguration(weight: .regular)
        image = UIImage(systemName: "paintpalette.fill", withConfiguration: imageConfiguration)
        editBackgroundButton.tintColor = fontColor
        editBackgroundButton.setImage(image, for: .normal)
        editBackgroundButton.isExclusiveTouch = true
        editBackgroundButton.backgroundColor = color
        editBackgroundButton.addTarget(self, action: #selector(editColorButtonPressed), for: .touchDown)
        
        let resetButton = UIButton()
        resetButton.setTitle("", for: .normal)
        resetButton.setTitleColor(fontColor, for: .normal)
        resetButton.titleLabel?.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: false)
        resetButton.titleLabel?.adjustsFontSizeToFitWidth = true
        imageConfiguration = UIImage.SymbolConfiguration(weight: .regular)
        image = UIImage(systemName: "arrowshape.turn.up.backward.2.circle.fill", withConfiguration: imageConfiguration)
        resetButton.tintColor = fontColor
        resetButton.setImage(image, for: .normal)
        resetButton.isExclusiveTouch = true
        resetButton.backgroundColor = color
        resetButton.addTarget(self, action: #selector(resetButtonPressed), for: .touchDown)
        resetButton.backgroundColor = color
        
        /** Add context menu for the following buttons*/
        let minusTextSizeButtonInteraction = UIContextMenuInteraction(delegate: self)
        minusTextSizeButton.addInteraction(minusTextSizeButtonInteraction)
        
        let plusTextSizeButtonInteraction = UIContextMenuInteraction(delegate: self)
        plusTextSizeButton.addInteraction(plusTextSizeButtonInteraction)
        
        let textToSpeechButtonInteraction = UIContextMenuInteraction(delegate: self)
        textToSpeechButton.addInteraction(textToSpeechButtonInteraction)
        
        let editFontButtonInteraction = UIContextMenuInteraction(delegate: self)
        editFontButton.addInteraction(editFontButtonInteraction)
        
        let editBackgroundButtonInteraction = UIContextMenuInteraction(delegate: self)
        editBackgroundButton.addInteraction(editBackgroundButtonInteraction)
        
        buttons.append(textToSpeechButton)
        buttons.append(plusTextSizeButton)
        buttons.append(minusTextSizeButton)
        buttons.append(editFontButton)
        buttons.append(editBackgroundButton)
        buttons.append(resetButton)
        
        buttonBar = underlinedButtonBar(buttons: buttons, width: viewBounds.width, height: 40, underlineColor: fontColor, underlineTrackColor: UIColor.clear, underlineHeight: 2, backgroundColor: color, animated: true)
        
        /** Add shadow to the button bar*/
        buttonBar.clipsToBounds = false
        buttonBar.layer.shadowColor = UIColor.darkGray.cgColor
        buttonBar.layer.shadowOpacity = 0.15
        buttonBar.layer.shadowRadius = 8
        buttonBar.layer.shadowPath = UIBezierPath(rect: buttonBar.bounds).cgPath
        
        buttonBar.frame.origin = CGPoint(x: 0, y: 0)
        
        textView.frame.origin = CGPoint(x: self.view.frame.width/2 - (self.view.frame.width * 0.9)/2, y: buttonBar.height)
        
        /** Add a pinch gesture recognizer for added functionality*/
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(textViewPinched))
        textView.addGestureRecognizer(pinchGestureRecognizer)
        
        view.addSubview(textView)
        view.addSubview(buttonBar)
    }
    
    /**Customize the nav and tab bars for this view*/
    func setCustomNavUI(){
        /**Tab bar and nav bar customization*/
        let standardAppearance = UINavigationBarAppearance()
        let standardTabbarAppearance = UITabBarAppearance()
        
        standardAppearance.configureWithOpaqueBackground()
        standardTabbarAppearance.configureWithOpaqueBackground()
        standardAppearance.shadowColor = UIColor.lightGray
        
        navigationItem.leftItemsSupplementBackButton = true
        
        var color = UIColor()
        switch darkMode{
        case true:
            color = .black
        case false:
            color = .white
        }
        
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: fontColor]
        navigationController?.navigationBar.tintColor = fontColor
        
        standardAppearance.backgroundColor = color
        standardAppearance.largeTitleTextAttributes = [.foregroundColor: fontColor, NSAttributedString.Key.font: getCustomFont(name: .Ubuntu_bold, size: 30, dynamicSize: false)]
        standardAppearance.titleTextAttributes = [.foregroundColor: fontColor, NSAttributedString.Key.font: getCustomFont(name: .Ubuntu_bold, size: 16, dynamicSize: false)]
        
        standardTabbarAppearance.backgroundColor = color
        
        /**Customize the navigation items if any are present*/
        if(navigationItem.rightBarButtonItems?.count != nil){
            for index in 0..<self.navigationItem.rightBarButtonItems!.count{
                navigationItem.rightBarButtonItems?[index].tintColor = fontColor
            }
        }
        if(navigationItem.leftBarButtonItems?.count != nil){
            for index in 0..<self.navigationItem.leftBarButtonItems!.count{
                navigationItem.leftBarButtonItems?[index].tintColor = fontColor
            }
        }
        
        tabBarController?.tabBar.standardAppearance = standardTabbarAppearance
        if #available(iOS 15.0, *) {
            tabBarController?.tabBar.scrollEdgeAppearance = standardTabbarAppearance
        } else {
            //Fallback on earlier versions, no other solutions
        }
        navigationController?.navigationBar.standardAppearance = standardAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = standardAppearance
    }
    
    /** Specifies custom UI states for this view controller*/
    func setProperties(){
        self.title = "Reader"
        tabBarController?.tabBar.isHidden = true
    }
    
    /** Button handlers*/
    @objc func textToSpeechButtonPressed(sender: UIButton){
        lightHaptic()
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.alpha = 0.8
            sender.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }
        UIView.animate(withDuration: 0.25, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.alpha = 1
            sender.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        
        buttonBar.moveUnderLineTo(this: sender)
        buttonBar.resizeTheUnderlineFor(this: sender)
    }
    @objc func plusTextSizeButtonPressed(sender: UIButton){
        lightHaptic()
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.alpha = 0.8
            sender.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }
        UIView.animate(withDuration: 0.25, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.alpha = 1
            sender.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        
        /** Max font size is 100*/
        if (editedFontSize + 1) <= 100{
            editedFontSize += 1
        }
        
        sender.setTitle(editedFontSize.description, for: .normal)
        
        UIView.transition(with: textView, duration: 0.25, options: .transitionCrossDissolve, animations: { [self] in
            textView.font! = textView.font!.withSize(editedFontSize)
        })
        
        /** Reset the title*/
        plusTextSizeButtontimer.invalidate()
        plusTextSizeButtontimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false){ [self] _ in
            sender.setTitle("", for: .normal)
            if buttonBar.currentlySelectedButton == sender{
                buttonBar.moveUnderLineTo(this: sender)
                buttonBar.resizeTheUnderlineFor(this: sender)
            }
        }
        
        buttonBar.moveUnderLineTo(this: sender)
        buttonBar.resizeTheUnderlineFor(this: sender)
    }
    @objc func minusTextSizeButtonPressed(sender: UIButton){
        lightHaptic()
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.alpha = 0.8
            sender.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }
        UIView.animate(withDuration: 0.25, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.alpha = 1
            sender.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        
        /** Minimum font size is 1*/
        if (editedFontSize - 1) >= 1{
            editedFontSize -= 1
        }
        
        sender.setTitle(editedFontSize.description, for: .normal)
        
        UIView.transition(with: textView, duration: 0.25, options: .transitionCrossDissolve, animations: { [self] in
            textView.font! = textView.font!.withSize(editedFontSize)
        })
        
        /** Reset the title*/
        minusTextSizeButtontimer.invalidate()
        minusTextSizeButtontimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false){ [self] _ in
            sender.setTitle("", for: .normal)
            if buttonBar.currentlySelectedButton == sender{
                buttonBar.moveUnderLineTo(this: sender)
                buttonBar.resizeTheUnderlineFor(this: sender)
            }
        }
        
        buttonBar.moveUnderLineTo(this: sender)
        buttonBar.resizeTheUnderlineFor(this: sender)
    }
    @objc func editFontButtonPressed(sender: UIButton){
        lightHaptic()
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.alpha = 0.8
            sender.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }
        UIView.animate(withDuration: 0.25, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.alpha = 1
            sender.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        
        buttonBar.moveUnderLineTo(this: sender)
        buttonBar.resizeTheUnderlineFor(this: sender)
    }
    @objc func editColorButtonPressed(sender: UIButton){
        lightHaptic()
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.alpha = 0.8
            sender.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }
        UIView.animate(withDuration: 0.25, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.alpha = 1
            sender.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        
        buttonBar.moveUnderLineTo(this: sender)
        buttonBar.resizeTheUnderlineFor(this: sender)
    }
    
    /** Reset all properties to their default values*/
    @objc func resetButtonPressed(sender: UIButton){
        lightHaptic()
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.alpha = 0.8
            sender.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }
        UIView.animate(withDuration: 0.25, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.alpha = 1
            sender.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        
        globallyTransmit(this: "Original settings restored", with: UIImage(systemName: "arrow.2.circlepath.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: UIColor.lightGray, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .bottomCenterStrip, animated: true, duration: 3, selfDismiss: true)
        
        editedBackgroundColor = originalBackgroundColor
        editedFontSize = originalFontSize
        editedFontColor = originalFontColor
        editedHighlightColor = originalHighlightColor
        editedFont = originalFont
        
        fontBolded = false
        fontItalicized = false
        
        buttons[1].setTitle(editedFontSize.description, for: .normal)
        
        /** Reset the title*/
        plusTextSizeButtontimer.invalidate()
        plusTextSizeButtontimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false){ [self] _ in
            buttons[1].setTitle("", for: .normal)
        }
        
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){ [self] in
            textView.backgroundColor = editedBackgroundColor
            view.backgroundColor = editedBackgroundColor
            textView.textColor = editedFontColor
            textView.tintColor = editedHighlightColor
        }
        
        UIView.transition(with: textView, duration: 0.25, options: .transitionCrossDissolve, animations: { [self] in
            textView.font! = editedFont
        })
        
        buttonBar.moveUnderLineTo(this: sender)
        buttonBar.resizeTheUnderlineFor(this: sender)
    }
    /** Button handler methods*/
    
    /** Gesture recognizer*/
    @objc func textViewPinched(sender: UIPinchGestureRecognizer){
        let scale = sender.scale
        
        if sender.state == .ended{
            /** Zoom in*/
            if scale >= 1{
                /** Max font size is 100*/
                if (editedFontSize + 1) <= 100{
                    editedFontSize += 1
                }
                
                buttons[1].setTitle(editedFontSize.description, for: .normal)
                
                /** Reset the title*/
                plusTextSizeButtontimer.invalidate()
                plusTextSizeButtontimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false){ [self] _ in
                    buttons[1].setTitle("", for: .normal)
                }
                
                UIView.transition(with: textView, duration: 0.25, options: .transitionCrossDissolve, animations: { [self] in
                    textView.font! = textView.font!.withSize(editedFontSize)
                })
            }
            /** Zoom out*/
            else if scale < 1{
                /** Minimum font size is 1*/
                if (editedFontSize - 1) >= 1{
                    editedFontSize -= 1
                }
                
                buttons[2].setTitle(editedFontSize.description, for: .normal)
                
                /** Reset the title*/
                minusTextSizeButtontimer.invalidate()
                minusTextSizeButtontimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false){ [self] _ in
                    buttons[2].setTitle("", for: .normal)
                }
                
                UIView.transition(with: textView, duration: 0.25, options: .transitionCrossDissolve, animations: { [self] in
                    textView.font! = textView.font!.withSize(editedFontSize)
                })
            }
        }
    }
    /** Gesture recognizer*/
    
    /** Restarts the synthesizer*/
    func restartSynth(){
        synthesizer.stopSpeaking(at: .immediate)
        utterance = AVSpeechUtterance(string: textView.text)
        
        if voice == nil{
            voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        
        buttons[0].setImage(UIImage(systemName: "waveform.path.badge.minus", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        
        utterance.voice = voice!
        synthesizer.speak(utterance)
        
        globallyTransmit(this: "Text to speech session restarted", with: UIImage(systemName: "arrow.2.circlepath.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: UIColor.green, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 3, selfDismiss: true)
    }
    
    /** Stops the synth*/
    func stopSynth(){
        synthesizer.stopSpeaking(at: .immediate)
        buttons[0].setImage(UIImage(systemName: "waveform.and.mic", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        TTSEnabled = false
        
        globallyTransmit(this: "Text to speech session ended", with: UIImage(systemName: "waveform.path.badge.minus", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: UIColor.red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 3, selfDismiss: true)
    }
    
    /** Context Menus for various extra actions*/
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        var children: [UIMenuElement] = []
        var menuTitle = "Interaction"
        
        /** Text to speech button*/
        if interaction.view == buttons[0]{
            menuTitle = "Text to speech options"
            
            let start = UIAction(title: "Start text to speech", image: UIImage(systemName: "play.circle.fill")){ [self] action in
                lightHaptic()
                
                globallyTransmit(this: "Text to speech session in progress", with: UIImage(systemName: "waveform.and.mic", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: UIColor.green, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 3, selfDismiss: true)
                
                buttons[0].setImage(UIImage(systemName: "waveform.path.badge.minus", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
                
                /** If the synth isn't paused then start from the beginning*/
                if synthesizer.isPaused == false{
                    utterance = AVSpeechUtterance(string: textView.text)
                    
                    /** If a voice isn't specified then revert back to the default option*/
                    if voice == nil{
                        voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.siri_male_en-US_compact")
                    }
                    
                    utterance.voice = voice!
                    synthesizer.speak(utterance)
                }
                else{
                    synthesizer.continueSpeaking()
                }
                
                TTSEnabled = true
            }
            
            let stop = UIAction(title: "Stop text to speech", image: UIImage(systemName: "stop.circle.fill")){ [self] action in
                lightHaptic()
                
                stopSynth()
            }
            
            let pause = UIAction(title: "Pause text to speech", image: UIImage(systemName: "pause.circle.fill")){ [self] action in
                lightHaptic()
                
                globallyTransmit(this: "Text to speech session paused", with: UIImage(systemName: "pause.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: UIColor.lightGray, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 3, selfDismiss: true)
                
                buttons[0].setImage(UIImage(systemName: "waveform.and.mic", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
                synthesizer.pauseSpeaking(at: .immediate)
            }
            
            let resume = UIAction(title: "Resume text to speech", image: UIImage(systemName: "play.circle.fill")){ [self] action in
                lightHaptic()
                
                globallyTransmit(this: "Text to speech session resumed", with: UIImage(systemName: "play.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: UIColor.green, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 3, selfDismiss: true)
                
                buttons[0].setImage(UIImage(systemName: "waveform.path.badge.minus", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
                
                synthesizer.continueSpeaking()
            }
            
            let restart = UIAction(title: "Restart text to speech", image: UIImage(systemName: "arrow.counterclockwise.circle.fill")){ [self] action in
                lightHaptic()
                
                restartSynth()
            }
            
            var regionalVoices_Male: [UIMenuElement] = []
            
            let voice_1 = UIAction(title: "Aaron English-US"){ [self] action in
                lightHaptic()
                voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.siri_male_en-US_compact")
                /** If the text to speak is currently playing then stop and restart it using the new voice option set*/
                if TTSEnabled == true{
                    restartSynth()
                }
            }
            let voice_2 = UIAction(title: "Daniel: English-GB"){ [self] action in
                lightHaptic()
                voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Daniel-compact")
                if TTSEnabled == true{
                    restartSynth()
                }
            }
            let voice_3 = UIAction(title: "Gordon: English-AU"){ [self] action in
                lightHaptic()
                voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.siri_male_en-AU_compact")
                if TTSEnabled == true{
                    restartSynth()
                }
            }
            let voice_4 = UIAction(title: "Rishi: English-IN"){ [self] action in
                lightHaptic()
                voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Rishi-compact")
                if TTSEnabled == true{
                    restartSynth()
                }
            }
            let voice_5 = UIAction(title: "Daniel: French-FR"){ [self] action in
                lightHaptic()
                voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.siri_male_fr-FR_compact")
                if TTSEnabled == true{
                    restartSynth()
                }
            }
            let voice_6 = UIAction(title: "Hattori: Japanese-JP"){ [self] action in
                lightHaptic()
                voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.siri_male_ja-JP_compact")
                if TTSEnabled == true{
                    restartSynth()
                }
            }
            let voice_7 = UIAction(title: "Martin: Deutsch-DE"){ [self] action in
                lightHaptic()
                voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.siri_male_de-DE_compact")
                if TTSEnabled == true{
                    restartSynth()
                }
            }
            
            regionalVoices_Male.append(voice_1)
            regionalVoices_Male.append(voice_2)
            regionalVoices_Male.append(voice_3)
            regionalVoices_Male.append(voice_4)
            regionalVoices_Male.append(voice_5)
            regionalVoices_Male.append(voice_6)
            regionalVoices_Male.append(voice_7)
            
            var regionalVoices_Female: [UIMenuElement] = []
            
            let f_Voice_1 = UIAction(title: "Samantha: English-US"){ [self] action in
                lightHaptic()
                voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Samantha-compact")
                if TTSEnabled == true{
                    restartSynth()
                }
            }
            let f_Voice_2 = UIAction(title: "Martha: English-GB"){ [self] action in
                lightHaptic()
                voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.siri_female_en-GB_compact")
                if TTSEnabled == true{
                    restartSynth()
                }
            }
            let f_Voice_3 = UIAction(title: "Catherine: English-AU"){ [self] action in
                lightHaptic()
                voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.siri_female_en-AU_compact")
                if TTSEnabled == true{
                    restartSynth()
                }
            }
            let f_Voice_4 = UIAction(title: "Mónica: Español-ES"){ [self] action in
                lightHaptic()
                voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Monica-compact")
                if TTSEnabled == true{
                    restartSynth()
                }
            }
            let f_Voice_5 = UIAction(title: "Paulina: Español-MX"){ [self] action in
                lightHaptic()
                voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Paulina-compact")
                if TTSEnabled == true{
                    restartSynth()
                }
            }
            let f_Voice_6 = UIAction(title: "Marie: French-FR"){ [self] action in
                lightHaptic()
                voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.siri_female_fr-FR_compact")
                if TTSEnabled == true{
                    restartSynth()
                }
            }
            let f_Voice_7 = UIAction(title: "Kyoko: Japanese-JP"){ [self] action in
                lightHaptic()
                voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Kyoko-compact")
                if TTSEnabled == true{
                    restartSynth()
                }
            }
            let f_Voice_8 = UIAction(title: "Milena: Russian-RU"){ [self] action in
                lightHaptic()
                voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Milena-compact")
                if TTSEnabled == true{
                    restartSynth()
                }
            }
            let f_Voice_9 = UIAction(title: "Helena: Deutsch-DE"){ [self] action in
                lightHaptic()
                voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.siri_female_de-DE_compact")
                if TTSEnabled == true{
                    restartSynth()
                }
            }
            let f_Voice_10 = UIAction(title: "Sara: Danish-DK"){ [self] action in
                lightHaptic()
                voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Sara-compact")
                if TTSEnabled == true{
                    restartSynth()
                }
            }
            let f_Voice_11 = UIAction(title: "Lekha: Hindi-IN"){ [self] action in
                lightHaptic()
                voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Lekha-compact")
                if TTSEnabled == true{
                    restartSynth()
                }
            }
            
            regionalVoices_Female.append(f_Voice_1)
            regionalVoices_Female.append(f_Voice_2)
            regionalVoices_Female.append(f_Voice_3)
            regionalVoices_Female.append(f_Voice_4)
            regionalVoices_Female.append(f_Voice_5)
            regionalVoices_Female.append(f_Voice_6)
            regionalVoices_Female.append(f_Voice_7)
            regionalVoices_Female.append(f_Voice_8)
            regionalVoices_Female.append(f_Voice_9)
            regionalVoices_Female.append(f_Voice_10)
            regionalVoices_Female.append(f_Voice_11)
            
            let maleVoices = UIMenu(title: "Male Voices", children: regionalVoices_Male)
            let femaleVoices = UIMenu(title: "Female Voices", children: regionalVoices_Female)
            
            let selectVoice = UIMenu(title: "T.T.S. Voice Options", image: UIImage(systemName: "globe.americas.fill"), children: [maleVoices,femaleVoices])
            
            
            /** If the text to speech is currently talking then show these two option*/
            if TTSEnabled == true{
                if synthesizer.isPaused == true{
                    children.append(resume)
                }
                else{
                    children.append(pause)
                }
                children.append(restart)
                children.append(stop)
            }
            else{
                children.append(start)
            }
            
            children.append(selectVoice)
        }
        
        /** Plus text size button*/
        if interaction.view == buttons[1]{
            menuTitle = "Increase text size options"
            let add_2 = UIAction(title: "+2"){ [self] action in
                lightHaptic()
                
                /** Max font size is 100*/
                if (editedFontSize + 2) <= 100{
                    editedFontSize += 2
                }
                
                let sender = interaction.view as! UIButton
                
                sender.setTitle(editedFontSize.description, for: .normal)
                
                UIView.transition(with: textView, duration: 0.25, options: .transitionCrossDissolve, animations: { [self] in
                    textView.font! = textView.font!.withSize(editedFontSize)
                })
                
                /** Reset the title*/
                plusTextSizeButtontimer.invalidate()
                plusTextSizeButtontimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false){ [self] _ in
                    sender.setTitle("", for: .normal)
                    if buttonBar.currentlySelectedButton == sender{
                        buttonBar.moveUnderLineTo(this: sender)
                        buttonBar.resizeTheUnderlineFor(this: sender)
                    }
                }
            }
            let add_5 = UIAction(title: "+5"){ [self] action in
                lightHaptic()
                
                /** Max font size is 100*/
                if (editedFontSize + 5) <= 100{
                    editedFontSize += 5
                }
                
                let sender = interaction.view as! UIButton
                
                sender.setTitle(editedFontSize.description, for: .normal)
                
                UIView.transition(with: textView, duration: 0.25, options: .transitionCrossDissolve, animations: { [self] in
                    textView.font! = textView.font!.withSize(editedFontSize)
                })
                
                /** Reset the title*/
                plusTextSizeButtontimer.invalidate()
                plusTextSizeButtontimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false){ [self] _ in
                    sender.setTitle("", for: .normal)
                    if buttonBar.currentlySelectedButton == sender{
                        buttonBar.moveUnderLineTo(this: sender)
                        buttonBar.resizeTheUnderlineFor(this: sender)
                    }
                }
            }
            let add_10 = UIAction(title: "+10"){ [self] action in
                lightHaptic()
                
                /** Max font size is 100*/
                if (editedFontSize + 10) <= 100{
                    editedFontSize += 10
                }
                
                let sender = interaction.view as! UIButton
                
                sender.setTitle(editedFontSize.description, for: .normal)
                
                UIView.transition(with: textView, duration: 0.25, options: .transitionCrossDissolve, animations: { [self] in
                    textView.font! = textView.font!.withSize(editedFontSize)
                })
                
                /** Reset the title*/
                plusTextSizeButtontimer.invalidate()
                plusTextSizeButtontimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false){ [self] _ in
                    sender.setTitle("", for: .normal)
                    if buttonBar.currentlySelectedButton == sender{
                        buttonBar.moveUnderLineTo(this: sender)
                        buttonBar.resizeTheUnderlineFor(this: sender)
                    }
                }
            }
            let max = UIAction(title: "Maximum"){ [self] action in
                lightHaptic()
                
                /** Max font size is 100*/
                editedFontSize = 100
                
                let sender = interaction.view as! UIButton
                
                sender.setTitle(editedFontSize.description, for: .normal)
                
                UIView.transition(with: textView, duration: 0.25, options: .transitionCrossDissolve, animations: { [self] in
                    textView.font! = textView.font!.withSize(editedFontSize)
                })
                
                /** Reset the title*/
                plusTextSizeButtontimer.invalidate()
                plusTextSizeButtontimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false){ [self] _ in
                    sender.setTitle("", for: .normal)
                    if buttonBar.currentlySelectedButton == sender{
                        buttonBar.moveUnderLineTo(this: sender)
                        buttonBar.resizeTheUnderlineFor(this: sender)
                    }
                }
            }
            children.append(add_2)
            children.append(add_5)
            children.append(add_10)
            children.append(max)
        }
        
        /** Minus text size button*/
        if interaction.view == buttons[2]{
            menuTitle = "Decrease text size options"
            
            let subtract_2 = UIAction(title: "-2"){ [self] action in
                lightHaptic()
                
                /** Minimum font size is 1*/
                if (editedFontSize - 2) >= 1{
                    editedFontSize -= 2
                }
                
                let sender = interaction.view as! UIButton
                
                sender.setTitle(editedFontSize.description, for: .normal)
                
                UIView.transition(with: textView, duration: 0.25, options: .transitionCrossDissolve, animations: { [self] in
                    textView.font! = textView.font!.withSize(editedFontSize)
                })
                
                /** Reset the title*/
                minusTextSizeButtontimer.invalidate()
                minusTextSizeButtontimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false){ [self] _ in
                    sender.setTitle("", for: .normal)
                    if buttonBar.currentlySelectedButton == sender{
                        buttonBar.moveUnderLineTo(this: sender)
                        buttonBar.resizeTheUnderlineFor(this: sender)
                    }
                }
            }
            let subtract_5 = UIAction(title: "-5"){ [self] action in
                lightHaptic()
                
                /** Minimum font size is 1*/
                if (editedFontSize - 5) >= 1{
                    editedFontSize -= 5
                }
                
                let sender = interaction.view as! UIButton
                
                sender.setTitle(editedFontSize.description, for: .normal)
                
                UIView.transition(with: textView, duration: 0.25, options: .transitionCrossDissolve, animations: { [self] in
                    textView.font! = textView.font!.withSize(editedFontSize)
                })
                
                /** Reset the title*/
                minusTextSizeButtontimer.invalidate()
                minusTextSizeButtontimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false){ [self] _ in
                    sender.setTitle("", for: .normal)
                    if buttonBar.currentlySelectedButton == sender{
                        buttonBar.moveUnderLineTo(this: sender)
                        buttonBar.resizeTheUnderlineFor(this: sender)
                    }
                }
            }
            let subtract_10 = UIAction(title: "-10"){ [self] action in
                lightHaptic()
                
                /** Minimum font size is 1*/
                if (editedFontSize - 10) >= 1{
                    editedFontSize -= 10
                }
                
                let sender = interaction.view as! UIButton
                
                sender.setTitle(editedFontSize.description, for: .normal)
                
                UIView.transition(with: textView, duration: 0.25, options: .transitionCrossDissolve, animations: { [self] in
                    textView.font! = textView.font!.withSize(editedFontSize)
                })
                
                /** Reset the title*/
                minusTextSizeButtontimer.invalidate()
                minusTextSizeButtontimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false){ [self] _ in
                    sender.setTitle("", for: .normal)
                    if buttonBar.currentlySelectedButton == sender{
                        buttonBar.moveUnderLineTo(this: sender)
                        buttonBar.resizeTheUnderlineFor(this: sender)
                    }
                }
            }
            let min = UIAction(title: "Minimum"){ [self] action in
                lightHaptic()
                
                /** Minimum font size is 1*/
                editedFontSize = 1
                
                let sender = interaction.view as! UIButton
                
                sender.setTitle(editedFontSize.description, for: .normal)
                
                UIView.transition(with: textView, duration: 0.25, options: .transitionCrossDissolve, animations: { [self] in
                    textView.font! = textView.font!.withSize(editedFontSize)
                })
                
                /** Reset the title*/
                minusTextSizeButtontimer.invalidate()
                minusTextSizeButtontimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false){ [self] _ in
                    sender.setTitle("", for: .normal)
                    if buttonBar.currentlySelectedButton == sender{
                        buttonBar.moveUnderLineTo(this: sender)
                        buttonBar.resizeTheUnderlineFor(this: sender)
                    }
                }
            }
            children.append(subtract_2)
            children.append(subtract_5)
            children.append(subtract_10)
            children.append(min)
        }
        
        /** Change font button*/
        if interaction.view == buttons[3]{
            menuTitle = "Font options"
            
            let boldFont = UIAction(title: "Bold"){ [self] action in
                lightHaptic()
                
                if fontBolded == false && fontItalicized == false{
                editedFont = getCustomFont(name: .Ubuntu_bold, size: editedFontSize, dynamicSize: false)
                fontBolded = true
                }
                else if fontBolded == false && fontItalicized == true{
                editedFont = getCustomFont(name: .Ubuntu_BoldItalic, size: editedFontSize, dynamicSize: false)
                fontBolded = true
                }
                else if fontBolded == true && fontItalicized == false{
                editedFont = getCustomFont(name: .Ubuntu_Regular, size: editedFontSize, dynamicSize: false)
                fontBolded = false
                }
                else if fontBolded == true && fontItalicized == true{
                editedFont = getCustomFont(name: .Ubuntu_Italic, size: editedFontSize, dynamicSize: false)
                fontBolded = false
                }
                
                UIView.transition(with: textView, duration: 0.25, options: .transitionCrossDissolve, animations: { [self] in
                    textView.font = editedFont
                })
            }
            let italicFont = UIAction(title: "Italicized"){ [self] action in
                lightHaptic()
                
                if fontBolded == false && fontItalicized == false{
                editedFont = getCustomFont(name: .Ubuntu_Italic, size: editedFontSize, dynamicSize: false)
                fontItalicized = true
                }
                else if fontBolded == true && fontItalicized == false{
                editedFont = getCustomFont(name: .Ubuntu_BoldItalic, size: editedFontSize, dynamicSize: false)
                    fontItalicized = true
                }
                else if fontBolded == false && fontItalicized == true{
                editedFont = getCustomFont(name: .Ubuntu_Regular, size: editedFontSize, dynamicSize: false)
                    fontItalicized = false
                }
                else if fontBolded == true && fontItalicized == true{
                editedFont = getCustomFont(name: .Ubuntu_bold, size: editedFontSize, dynamicSize: false)
                    fontItalicized = false
                }
                
                UIView.transition(with: textView, duration: 0.25, options: .transitionCrossDissolve, animations: { [self] in
                    textView.font = editedFont
                })
            }
            let regularFont = UIAction(title: "Regular"){ [self] action in
                lightHaptic()
               
                fontBolded = false
                fontItalicized = false
                editedFont = getCustomFont(name: .Ubuntu_Regular, size: editedFontSize, dynamicSize: false)
                
                UIView.transition(with: textView, duration: 0.25, options: .transitionCrossDissolve, animations: { [self] in
                    textView.font = editedFont
                })
            }
        
            children.append(boldFont)
            children.append(italicFont)
            children.append(regularFont)
        }
        
        /** Change background color button*/
        if interaction.view == buttons[4]{
            menuTitle = "Color property options"
            
            let changeBgColor = UIAction(title: "Background color"){ [self] action in
                lightHaptic()
                
                fontColorBeingEdited = false
                highlightColorBeingEdited = false
                backgroundColorBeingEdited = true
                
                let colorPicker = UIColorPickerViewController()
                colorPicker.delegate = self
                
                /**Subscribing selectedColor property changes*/
                self.cancellable = colorPicker.publisher(for: \.selectedColor)
                    .sink { color in
                        
                        /**Changing view color on main thread*/
                        DispatchQueue.main.async{
                            //self.editedBackgroundColor = color
                            
                            //self.view.backgroundColor = editedBackgroundColor
                            //self.textView.backgroundColor = editedBackgroundColor
                        }
                    }
                
                self.present(colorPicker, animated: true, completion: nil)
            }
            let changeFontColor = UIAction(title: "Font color"){ [self] action in
                lightHaptic()
                
                backgroundColorBeingEdited = false
                highlightColorBeingEdited = false
                fontColorBeingEdited = true
                
                let colorPicker = UIColorPickerViewController()
                colorPicker.delegate = self
                
                /** If the view controller is cancelled then the color preselected can be used by default*/
                /**Subscribing selectedColor property changes*/
                self.cancellable = colorPicker.publisher(for: \.selectedColor)
                    .sink { color in
                        
                        /**Changing view color on main thread*/
                        DispatchQueue.main.async{
                        }
                    }
                
                self.present(colorPicker, animated: true, completion: nil)
            }
            let changeHighlightColor = UIAction(title: "Highlight color"){ [self] action in
                lightHaptic()
                
                backgroundColorBeingEdited = false
                fontColorBeingEdited = false
                highlightColorBeingEdited = true
                
                let colorPicker = UIColorPickerViewController()
                colorPicker.delegate = self
                
                /** If the view controller is cancelled then the color preselected can be used by default*/
                /**Subscribing selectedColor property changes*/
                self.cancellable = colorPicker.publisher(for: \.selectedColor)
                    .sink { color in
                        
                        /**Changing view color on main thread*/
                        DispatchQueue.main.async{
                        }
                    }
                
                self.present(colorPicker, animated: true, completion: nil)
            }
            
            children.append(changeBgColor)
            children.append(changeFontColor)
            children.append(changeHighlightColor)
        }
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil){ _ in
            UIMenu(title: menuTitle, children: children)
        }
    }
    
    /** Make the background of the context menu origin view clear instead of black*/
    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview?{
        let previewTarget = UIPreviewTarget(container: self.view, center: interaction.view!.center)
        let previewParams = UIPreviewParameters()
        previewParams.backgroundColor = .clear
        
        return UITargetedPreview(view: interaction.view!, parameters: previewParams, target: previewTarget)
    }
    
    /** Color picker methods for selecting a new color for either the background or font of the textview*/
    /**Called once you have finished picking the color*/
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        
        if fontColorBeingEdited == true{
            fontColorBeingEdited = false
        }
        else if backgroundColorBeingEdited == true{
            backgroundColorBeingEdited = false
        }
        else if highlightColorBeingEdited == true{
            highlightColorBeingEdited = false
        }
    }
    
    /**Called on every color selection done in the picker*/
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        
        if fontColorBeingEdited == true{
            self.editedFontColor = viewController.selectedColor
            
            self.textView.textColor = editedFontColor
        }
        else if backgroundColorBeingEdited == true{
            self.editedBackgroundColor = viewController.selectedColor
            
            self.view.backgroundColor = editedBackgroundColor
            self.textView.backgroundColor = editedBackgroundColor
        }
        else if highlightColorBeingEdited == true{
            self.editedHighlightColor = viewController.selectedColor
            
            self.textView.tintColor = editedHighlightColor
        }
    }
    /** Color picker methods for selecting a new color for either the background or font of the textview*/
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
