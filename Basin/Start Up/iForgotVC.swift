//
//  iForgotVC.swift
//  Stuy Wash N Dry
//
//  Created by Justin Cook on 2/8/22.
//

import UIKit
import Lottie
import Firebase
import FirebaseAuth

/** User login recovery scene*/
public class iForgot: UIViewController, UITextFieldDelegate{
    /** Status bar styling variables*/
    public override var preferredStatusBarStyle: UIStatusBarStyle{
        switch darkMode{
        case true:
            return .lightContent
        case false:
            return .darkContent
        }
    }
    public override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation{
        return .slide
    }
    /** Specify status bar display preference*/
    public override var prefersStatusBarHidden: Bool {
        return false
    }
    /** Status bar styling variables*/
    
    /** Simple way for the user to dismiss this VC*/
    var backButton: UIButton = UIButton()
    /** Textfield where the user will specify their email address and this string will then be verified to be a correct email address and then cross referenced with all the other email addresses in the user database*/
    var emailTextfield: UITextField = UITextField()
    /** The verified email to send the password reset request to*/
    var email: String = ""
    /** Button that will submit the password reset request*/
    var requestResetButton: UIButton = UIButton()
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        configure()
        addVisualSingleTapGestureRecognizer()
        supplementBackButton()
        createUI()
    }
    
    /** Configures and adds the back button to the view hierarchy*/
    func supplementBackButton(){
        let imageConfiguration = UIImage.SymbolConfiguration(weight: .regular)
        let image = UIImage(systemName: "arrow.backward", withConfiguration: imageConfiguration)
        
        backButton.frame.size.height = 50
        backButton.frame.size.width = backButton.frame.size.height
        backButton.backgroundColor = appThemeColor
        backButton.tintColor = .white
        backButton.setImage(image, for: .normal)
        backButton.layer.cornerRadius = backButton.frame.height/2
        backButton.isExclusiveTouch = true
        backButton.castDefaultShadow()
        backButton.layer.shadowColor = appThemeColor.darker.cgColor
        backButton.addTarget(self, action: #selector(backButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: backButton)
        backButton.alpha = 0
        backButton.isEnabled = false
        
        /** Everything else depends on this button's position so make sure this is positioned correctly*/
        backButton.frame.origin = CGPoint(x: 10, y: view.getStatusBarHeight() + 15)
        
        /** Scale up animation*/
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){[self] in
            backButton.transform = CGAffineTransform(scaleX: 0, y: 0)
            
            UIView.animate(withDuration: 1, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){ [self] in
                backButton.transform = CGAffineTransform(scaleX: 1, y: 1)
                backButton.alpha = 1
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1){[self] in
            backButton.isEnabled = true
        }
    }
    
    /** Supplement the user interface for this view controller*/
    func createUI(){
        let labelSize = CGSize(width: view.frame.width * 0.9, height: view.frame.height * 0.3)
        
        /** General information for the user to read*/
        let informationLabel = UILabel(frame: CGRect(x: 10, y: backButton.frame.minY, width: labelSize.width, height: labelSize.height))
        informationLabel.adjustsFontSizeToFitWidth = true
        informationLabel.adjustsFontForContentSizeCategory = false
        informationLabel.textAlignment = .left
        /** Maximum number of lines this label should display*/
        informationLabel.numberOfLines = 4
        informationLabel.lineBreakMode = .byClipping
        informationLabel.backgroundColor = .clear
        informationLabel.attributedText = attribute(this: "Don't worry,\nwe've got your back 💪 \nEnter the email address associated with your account", font: getCustomFont(name: .Bungee_Regular, size: 35, dynamicSize: false), subFont: getCustomFont(name: .Ubuntu_Regular, size: 25, dynamicSize: false), mainColor: appThemeColor, subColor: .lightGray, subString: "\nEnter the email address associated with your account")
        informationLabel.sizeToFit()
        
        /** Nice little animation to keep the user entertained*/
        let passwordForgotLottieAnimation = AnimationView.init(name: "cloudLock")
        passwordForgotLottieAnimation.frame.size = CGSize(width: view.frame.width * 0.7, height: view.frame.width * 0.7)
        passwordForgotLottieAnimation.animationSpeed = 1
        passwordForgotLottieAnimation.isExclusiveTouch = true
        passwordForgotLottieAnimation.shouldRasterizeWhenIdle = true
        passwordForgotLottieAnimation.contentMode = .scaleAspectFill
        passwordForgotLottieAnimation.isOpaque = false
        passwordForgotLottieAnimation.clipsToBounds = true
        passwordForgotLottieAnimation.backgroundColor = .clear
        passwordForgotLottieAnimation.loopMode = .loop
        passwordForgotLottieAnimation.backgroundBehavior = .pauseAndRestore
        passwordForgotLottieAnimation.clipsToBounds = false
        passwordForgotLottieAnimation.play(completion: nil)
        
        /** Specify the email address where the password reset request will be sent*/
        emailTextfield.frame.size.height = 50
        emailTextfield.frame.size.width = view.frame.width * 0.9
        emailTextfield.tintColor = appThemeColor
        emailTextfield.backgroundColor = .white
        emailTextfield.textColor = .black
        emailTextfield.layer.cornerRadius = emailTextfield.frame.height/2
        emailTextfield.adjustsFontForContentSizeCategory = true
        emailTextfield.font = getCustomFont(name: .Ubuntu_Regular, size: 15, dynamicSize: true)
        emailTextfield.attributedPlaceholder = NSAttributedString(string:"Enter your email address", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        /** Settings*/
        emailTextfield.textContentType = .emailAddress
        emailTextfield.keyboardType = .emailAddress
        emailTextfield.returnKeyType = .done
        emailTextfield.textAlignment = .left
        emailTextfield.delegate = self
        emailTextfield.autocorrectionType = .no
        emailTextfield.toolbarPlaceholder = "Email address"
        emailTextfield.keyboardAppearance = .light
        
        /** Shadow properties*/
        emailTextfield.layer.shadowColor = UIColor.darkGray.cgColor
        emailTextfield.layer.shadowOpacity = 0.25
        emailTextfield.layer.shadowRadius = 8
        emailTextfield.layer.shadowOffset = CGSize(width: 0, height: 2)
        emailTextfield.layer.shadowPath = UIBezierPath(roundedRect: emailTextfield.bounds, cornerRadius: emailTextfield.layer.cornerRadius).cgPath
        
        /** Border properties*/
        emailTextfield.clipsToBounds = true
        emailTextfield.layer.masksToBounds = false
        /** Set to .none, else the shadow and the rect bounds aren't rendered properly*/
        emailTextfield.borderStyle = .none
        emailTextfield.layer.borderColor = UIColor.darkGray.withAlphaComponent(0.25).cgColor
        emailTextfield.layer.borderWidth = 1
        
        /** Padding to prevent the text in the textfield from spilling outside of its borders*/
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: emailTextfield.frame.height/(1.5), height: emailTextfield.frame.height/(1.5)))
        
        /** Button with a mail system image inside to style the text field up a bit*/
        let leftButton = UIButton()
        leftButton.setImage(UIImage(systemName: "envelope.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        leftButton.frame.size = CGSize(width: emailTextfield.frame.height/(1.5), height: emailTextfield.frame.height/(1.5))
        leftButton.frame.origin = CGPoint(x: paddingView.frame.width/2 - leftButton.frame.width/2, y: paddingView.frame.height/2 - leftButton.frame.height/2)
        leftButton.backgroundColor = .white
        leftButton.tintColor = appThemeColor
        leftButton.layer.cornerRadius = leftButton.frame.height/2
        leftButton.contentMode = .scaleAspectFit
        leftButton.isUserInteractionEnabled = false
        leftButton.clipsToBounds = true
        
        paddingView.addSubview(leftButton)
        emailTextfield.leftView = paddingView
        emailTextfield.leftViewMode = .always
        
        requestResetButton.frame.size.height = 50
        requestResetButton.frame.size.width = view.frame.width * 0.8
        requestResetButton.backgroundColor = appThemeColor
        requestResetButton.tintColor = .white
        requestResetButton.setTitle("Reset Password", for: .normal)
        requestResetButton.layer.cornerRadius = requestResetButton.frame.height/2
        requestResetButton.isExclusiveTouch = true
        requestResetButton.castDefaultShadow()
        requestResetButton.setTitleColor(UIColor.white, for: .normal)
        requestResetButton.titleLabel?.adjustsFontForContentSizeCategory = true
        requestResetButton.titleLabel?.adjustsFontSizeToFitWidth = true
        requestResetButton.titleLabel?.font = getCustomFont(name: .Ubuntu_Regular, size: 18, dynamicSize: true)
        requestResetButton.layer.shadowColor = appThemeColor.darker.cgColor
        requestResetButton.layer.shadowRadius = 3
        requestResetButton.addTarget(self, action: #selector(requestResetButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: requestResetButton)
        disableRequestButton(animated: true)
        
        let secondaryInformationLabel = UILabel()
        secondaryInformationLabel.frame.size = CGSize(width: view.frame.width * 0.9, height: 40)
        secondaryInformationLabel.adjustsFontSizeToFitWidth = true
        secondaryInformationLabel.adjustsFontForContentSizeCategory = false
        secondaryInformationLabel.textAlignment = .center
        /** Maximum number of lines this label should display*/
        secondaryInformationLabel.numberOfLines = 1
        secondaryInformationLabel.lineBreakMode = .byClipping
        secondaryInformationLabel.backgroundColor = .clear
        secondaryInformationLabel.attributedText = attribute(this: "*A password reset request will be sent to this email", font: getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: false), subFont: getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: false), mainColor: .lightGray, subColor: .lightGray, subString: "")
        
        /** Layout theses subviews*/
        passwordForgotLottieAnimation.frame.origin = CGPoint(x: view.frame.width/2 - passwordForgotLottieAnimation.frame.width/2, y: view.frame.height/2 - (passwordForgotLottieAnimation.frame.height/2))
        
        informationLabel.frame.origin = CGPoint(x: 10, y: passwordForgotLottieAnimation.frame.minY - (informationLabel.frame.height))
        
        emailTextfield.frame.origin = CGPoint(x: view.frame.width/2 - emailTextfield.frame.width/2, y: passwordForgotLottieAnimation.frame.maxY)
        
        secondaryInformationLabel.frame.origin = CGPoint(x: view.frame.width/2 - secondaryInformationLabel.frame.width/2, y: emailTextfield.frame.maxY)
        
        requestResetButton.frame.origin = CGPoint(x: view.frame.width/2 - requestResetButton.frame.width/2, y: view.frame.maxY - requestResetButton.frame.height * 1.5)
        
        /*** If the screen's height is smaller than or equal to 600 pixels override the given position and force the back button to be higher than the information label*/
        if UIScreen.main.bounds.height <= 600{
            backButton.frame.origin = CGPoint(x: 10, y: informationLabel.frame.minY - (informationLabel.frame.height * 0.8))
        }
        
        view.addSubview(informationLabel)
        view.addSubview(passwordForgotLottieAnimation)
        view.addSubview(emailTextfield)
        view.addSubview(secondaryInformationLabel)
        view.addSubview(requestResetButton)
        view.addSubview(backButton)
    }
    
    /** Set the specifics of this view controller*/
    func configure(){
        self.view.backgroundColor = bgColor
    }
    
    /** Button press methods*/
    /** Submit the password reset request*/
    @objc func requestResetButtonPressed(sender: UIButton){
        forwardTraversalShake()
        
        if internetAvailable == true{
            Auth.auth().sendPasswordReset(withEmail: email) { [self] error in
                if let error = error{
                    print("Password reset request error: \(error.localizedDescription)")
                    
                    globallyTransmit(this: "A password reset request email could not be sent to \(email) right now, please try again", with: UIImage(systemName: "envelope.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
                }
                /** Action successful*/
                globallyTransmit(this: "A password reset request email was sent successfully to \(email)", with: UIImage(systemName: "envelope.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .green, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
                
                hideRequestButton(animated: true)
                    
                self.dismiss(animated: true, completion: nil)
            }
        }
        else{
            globallyTransmit(this: "A password reset request email can not be sent to \(email) right now, please connect to the internet", with: UIImage(systemName: "envelope.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
        }
    }
    
    @objc func backButtonPressed(sender: UIButton){
        backwardTraversalShake()
        
        /** Dismiss the keyboard if any*/
        view.endEditing(true)
        
        self.dismiss(animated: true, completion: nil)
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
    /** Button press methods*/
    
    /** A little something extra to keep things flashy*/
    /** Add the gesture recognizer to this view*/
    func addVisualSingleTapGestureRecognizer(){
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(viewSingleTapped))
        singleTap.numberOfTapsRequired = 1
        singleTap.numberOfTouchesRequired = 1
        view.addGestureRecognizer(singleTap)
    }
    
    /** Show where the user taps on the screen*/
    @objc func viewSingleTapped(sender: UITapGestureRecognizer){
        /** Snapchat esque circular fade in fade out animation signals where the user has tapped*/
        let circleView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width * 0.05, height: view.frame.width * 0.05))
        circleView.layer.cornerRadius = circleView.frame.height/2
        circleView.layer.borderWidth = 0.5
        circleView.layer.borderColor = appThemeColor.cgColor
        circleView.backgroundColor = UIColor.clear
        circleView.clipsToBounds = true
        circleView.center.x = sender.location(in: view).x
        circleView.center.y = sender.location(in: view).y
        circleView.transform = CGAffineTransform(scaleX: 0, y: 0)
        
        let inscribedCircleView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width * 0.05, height: view.frame.width * 0.05))
        inscribedCircleView.layer.cornerRadius = inscribedCircleView.frame.height/2
        switch darkMode {
        case true:
            inscribedCircleView.backgroundColor = UIColor.lightGray.lighter.withAlphaComponent(0.5)
        case false:
            inscribedCircleView.backgroundColor = UIColor.white.darker.withAlphaComponent(0.5)
        }
        inscribedCircleView.transform = CGAffineTransform(scaleX: 0, y: 0)
        circleView.addSubview(inscribedCircleView)
        
        view.addSubview(circleView)
        
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
        UIView.animate(withDuration: 0.5, delay: 0.6, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .allowUserInteraction]){
            inscribedCircleView.alpha = 0
        }
        UIView.animate(withDuration: 0.5, delay: 0.7, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .allowUserInteraction]){
            circleView.alpha = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1){
            circleView.removeFromSuperview()
        }
    }
    /** A little something extra to keep things flashy*/
    
    /** UITextfield delegate methods*/
    /** Dynamic styling of textfields*/
    
    /** Create a blue border around the textfield to inform the user that it's now in focus aka they're able to type in it*/
    func markTextFieldAsFocused(textField: UITextField){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            textField.layer.borderWidth = 2
            textField.layer.borderColor = appThemeColor.cgColor
        }
    }
    
    func restoreOriginalTextFieldStyling(textField: UITextField){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            textField.layer.borderColor = UIColor.darkGray.withAlphaComponent(0.25).cgColor
            textField.layer.borderWidth = 1
        }
    }
    
    func markTextFieldEntryAsIncorrect(textField: UITextField){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            textField.layer.borderColor = UIColor.red.withAlphaComponent(0.25).cgColor
            textField.layer.borderWidth = 1
        }
    }
    
    func markTextFieldEntryAsCorrect(textField: UITextField){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            textField.layer.borderColor = UIColor.green.withAlphaComponent(0.25).cgColor
            textField.layer.borderWidth = 1
        }
    }
    /** Dynamic styling of textfields*/
    
    /** Methods for displaying the password reset request button*/
    func disableRequestButton(animated: Bool){
        switch animated{
        case true:
            requestResetButton.isEnabled = false
            UIView.animate(withDuration: 0.5, delay: 0){[self] in
                requestResetButton.alpha = 0.5
            }
        case false:
            requestResetButton.isEnabled = false
            requestResetButton.alpha = 0.5
        }
    }
    
    func enableRequestButton(animated: Bool){
        switch animated{
        case true:
            requestResetButton.isEnabled = true
            UIView.animate(withDuration: 0.5, delay: 0){[self] in
                requestResetButton.alpha = 1
            }
        case false:
            requestResetButton.isEnabled = true
            requestResetButton.alpha = 1
        }
    }
    
    func hideRequestButton(animated: Bool){
        switch animated{
        case true:
            requestResetButton.isEnabled = false
            UIView.animate(withDuration: 0.5, delay: 0){[self] in
                requestResetButton.alpha = 0
            }
        case false:
            requestResetButton.isEnabled = false
            requestResetButton.alpha = 0
        }
    }
    /** Methods for displaying the password reset request button*/
    
    /** Triggered when the textfield is getting ready to end editing*/
    public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool{
        restoreOriginalTextFieldStyling(textField: textField)
        
        /** Validate the email address*/
        if textField == emailTextfield && textField.text != ""{
            switch isEmailValid(textField.text!){
            case true:
                /** If the email  hasn't changed then don't reenable the verification button*/
                guard email != emailTextfield.text else {
                    markTextFieldEntryAsCorrect(textField: textField)
                    break
                }
                
                disableRequestButton(animated: true)
                
                /** Clear the value of this var and set it after verification has been done*/
                email = ""
                
                /** Check to see if the given email exists for a user*/
                if internetAvailable == true{
                    checkIfEmailExistsInDatabase(email: textField.text!, completion: { [self](result) -> Void in
                        if result == true{
                            /** Set the var for the email string to the textfield's current value*/
                            email = textField.text!
                            
                            enableRequestButton(animated: true)
                            
                            markTextFieldEntryAsCorrect(textField: textField)
                            
                            successfulActionShake()
                        }
                        else{
                            globallyTransmit(this: "This email is doesn't exist in our records", with: UIImage(systemName: "envelope.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
                            
                            /** Reset the email textfield and variable*/
                            email = ""
                            
                            UIView.transition(with: textField, duration: 1, options: .curveEaseIn, animations: {
                                textField.text = ""
                            })
                            
                            markTextFieldEntryAsIncorrect(textField: textField)
                            
                            errorShake()
                        }
                    })
                }
                else{
                    globallyTransmit(this: "This email can't be verified right now, please connect to the internet", with: UIImage(systemName: "message.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: .clear, imageBorder: .none, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 3, selfDismiss: true)
                    
                    /** Reset the email textfield and variable*/
                    email = ""
                    UIView.transition(with: textField, duration: 1, options: .curveEaseIn, animations: {
                        textField.text = ""
                    })
                    
                    markTextFieldEntryAsIncorrect(textField: textField)
                    errorShake()
                }
            case false:
                /** The email doesn't meet the required REGEX criteria*/
                markTextFieldEntryAsIncorrect(textField: textField)
                
                disableRequestButton(animated: true)
                
                /** Clear the value of the email*/
                email = ""
                
                errorShake()
            }
        }
        else if textField == emailTextfield && textField.text == ""{
            /** The textfield shouldn't be empty so disable the request button until it's filled in with a valid input*/
            disableRequestButton(animated: true)
            
            /** Clear the value of the email*/
            email = ""
        }
        
        return true
    }
    
    /** Triggered when the textfield is getting ready to begin editting*/
    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool{
        
        markTextFieldAsFocused(textField: textField)
        
        return true
    }
    
    /**When a user presses the return or done etc key, then simply hide the keyboard*/
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        /** If internet isn't available don't even try to do anything*/
        guard internetAvailable == true else{
            textField.resignFirstResponder()
            return true
        }
        
        textField.resignFirstResponder()
        return true
    }
    /** UITextfield delegate methods*/
}
