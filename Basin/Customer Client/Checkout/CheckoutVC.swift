//
//  CheckoutVC.swift
//  Basin
//
//  Created by Justin Cook on 5/15/22.
//

import UIKit
import Stripe
import Firebase

/** Very important VC that takes the user's sensitive information to create an order object and a payment with a payment processing API such as stripe to finalize the transaction, this is the most important view controller from a user privacy perspective and should be treated as such*/

public class CheckoutVC: UIViewController, STPPaymentCardTextFieldDelegate, UINavigationBarDelegate{
    
    /** Data*/
    /** The cart that will be used to create the order*/
    var cart: Cart
    
    /** UI Elements*/
    /** Navigation UI*/
    /** Navigation bar and navigation item*/
    var navBar = UINavigationBar()
    var navItem = UINavigationItem()
    /** Simple way for the user to dismiss this VC*/
    var backButton: UIButton = UIButton()
    /** Bar button item that hosts the back button*/
    var backButtonItem = UIBarButtonItem()
    
    /** Functional UI*/
    /** Scrollview in which the content below the image view will be hosted, this makes it simpler to view this content on smaller devices*/
    var scrollView: UIScrollView!
    /** Stack view that permits dynamic content in the scrollview*/
    var stackView: UIStackView!
    
    /** Payment*/
    /** UI Textfield element that the user will utilize in order to enter their payment information*/
    private var cardTextField: STPPaymentCardTextField!
    private var completePaymentButton: UIButton!
    
    init(cart: Cart){
        self.cart = cart
        
        super.init(nibName: nil, bundle: nil)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        constructUI()
        configure()
        setCustomNavUI()
    }
    
    /** Construct all UI elements*/
    func constructUI(){
        self.view.backgroundColor = darkMode ? .black : bgColor
        
        cardTextField = STPPaymentCardTextField(frame: CGRect(x: 0, y: 0, width: self.view.frame.width * 0.9, height: 40))
        cardTextField.backgroundColor = bgColor
        cardTextField.layer.cornerRadius = cardTextField.frame.height/2
        cardTextField.delegate = self
        cardTextField.textColor = fontColor
        
        completePaymentButton = UIButton(frame: CGRect(x: 0, y: 0, width: self.view.frame.width * 0.9, height: 60))
        completePaymentButton.backgroundColor = appThemeColor
        completePaymentButton.setTitleColor(.white, for: .normal)
        completePaymentButton.setTitle(" Place Order", for: .normal)
        completePaymentButton.titleLabel?.font = getCustomFont(name: .Ubuntu_Regular, size: 16, dynamicSize: true)
        completePaymentButton.contentHorizontalAlignment = .center
        completePaymentButton.titleLabel?.adjustsFontSizeToFitWidth = true
        completePaymentButton.titleLabel?.adjustsFontForContentSizeCategory = true
        completePaymentButton.layer.cornerRadius = completePaymentButton.frame.height/2
        completePaymentButton.isExclusiveTouch = true
        completePaymentButton.isEnabled = true
        completePaymentButton.castDefaultShadow()
        completePaymentButton.layer.shadowColor = UIColor.darkGray.cgColor
        completePaymentButton.tintColor = .white
        completePaymentButton.setImage(UIImage(systemName: "creditcard.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        completePaymentButton.addTarget(self, action: #selector(completePaymentButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: completePaymentButton)
        
        /** Layout these subviews*/
        cardTextField.centerInsideOf(this: self.view)
        completePaymentButton.frame.origin = CGPoint(x: self.view.frame.width/2 - completePaymentButton.frame.width/2, y: self.view.frame.maxY - (completePaymentButton.frame.height * 1.5))
        
        self.view.addSubview(completePaymentButton)
        self.view.addSubview(cardTextField)
    }
    
    /** Trigger the complete payment method only if internet is available*/
    @objc func completePaymentButtonPressed(sender: UIButton){
        if internetAvailable == true{
            forwardTraversalShake()
            
            completePayment()
        }
        else{
            /** Internet unavailable, can't proceed, inform the user that they must have an internet connection to continue*/
            errorShake()
            
            globallyTransmit(this: "Please connect to the internet in order to place your order", with: UIImage(systemName: "wifi.slash", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: .clear, imageBorder: .none, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 3, selfDismiss: true)
        }
    }
    
    private func completePayment(){
        getClientSecret(using: .card, currency: .usd) { [self] string in
            
            /** Make sure the string isn't nil or empty*/
            guard let clientSecret = string, string != "" else{
                globallyTransmit(this: "Your payment could not be processed at this time, please try again", with: UIImage(systemName: "creditcard.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: .clear, imageBorder: .none, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 3, selfDismiss: true)
                
                return
            }
        
        /**Collect card details*/
        let cardParams = cardTextField.cardParams
        let paymentMethodParams = STPPaymentMethodParams(card: cardParams, billingDetails: nil, metadata: nil)
        let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
        paymentIntentParams.paymentMethodParams = paymentMethodParams
        
        /**Submit the payment*/
        let paymentHandler = STPPaymentHandler.shared()
        paymentHandler.confirmPayment(paymentIntentParams, with: self) { (status, paymentIntent, error) in
            switch (status){
            case .failed:
                print("Payment failed \(error?.localizedDescription ?? "")")
                break
            case .canceled:
                print("Payment canceled \(error?.localizedDescription ?? "")")
                break
            case .succeeded:
                print("Payment Succeeded \(paymentIntent?.description ?? "")")
                break
            @unknown default:
                fatalError()
                break
            }
        }
        }
    }
    
    /** Configure this view controller*/
    func configure(){
        backButton.frame.size.height = 35
        backButton.frame.size.width = backButton.frame.size.height
        backButton.backgroundColor = bgColor
        backButton.tintColor = fontColor
        backButton.setImage(UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        backButton.layer.cornerRadius = backButton.frame.height/2
        backButton.isExclusiveTouch = true
        backButton.castDefaultShadow()
        backButton.layer.shadowColor = UIColor.darkGray.cgColor
        backButton.addTarget(self, action: #selector(backButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: backButton)
        backButton.alpha = 1
        backButton.isEnabled = true
        backButtonItem.customView = backButton
        
        navBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 90))
        navBar.delegate = self
        navBar.prefersLargeTitles = false
        /** Specify the title of this view controller*/
        navItem.title = "Checkout"
        navItem.leftBarButtonItem = backButtonItem
        navItem.rightBarButtonItems = []
        navItem.largeTitleDisplayMode = .never
        navBar.setItems([navItem], animated: false)
        
        self.view.addSubview(navBar)
        navBar.translatesAutoresizingMaskIntoConstraints = false
        navBar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        navBar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        navBar.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
        navBar.heightAnchor.constraint(equalToConstant: navBar.frame.height).isActive = true
    }
    
    /**Customize the nav and tab bars for this view*/
    func setCustomNavUI(){
        /**Prevent the scrollview from snapping into place when integrating with large title nav bar*/
        self.extendedLayoutIncludesOpaqueBars = true
        /**nav bar customization*/
        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.configureWithOpaqueBackground()
        /**Make the shadow clear*/
        standardAppearance.shadowColor = UIColor.clear
        
        /** Background and font is clear when the scrollview is at the top*/
        standardAppearance.backgroundColor = .clear
        standardAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.clear, NSAttributedString.Key.font: getCustomFont(name: .Ubuntu_Medium, size: 30, dynamicSize: true)]
        standardAppearance.titleTextAttributes = [.foregroundColor: UIColor.clear, NSAttributedString.Key.font: getCustomFont(name: .Ubuntu_Medium, size: 18, dynamicSize: true)]
        
        navItem.leftItemsSupplementBackButton = true
        switch darkMode{
        case true:
            navBar.barTintColor = bgColor
            navBar.titleTextAttributes = [.foregroundColor: fontColor]
            navBar.tintColor = fontColor
            
            /**Customize the navigation items if any are present*/
            if(navItem.rightBarButtonItems?.count != nil){
                for index in 0..<self.navItem.rightBarButtonItems!.count{
                    navItem.rightBarButtonItems?[index].tintColor = fontColor
                }
            }
            if(navItem.leftBarButtonItems?.count != nil){
                for index in 0..<self.navItem.leftBarButtonItems!.count{
                    navItem.leftBarButtonItems?[index].tintColor = fontColor
                }
            }
            
        case false:
            navBar.barTintColor = bgColor
            navBar.titleTextAttributes = [.foregroundColor: UIColor.white]
            navBar.tintColor = UIColor.white
            
            /**Customize the navigation items if any are present*/
            if(navItem.rightBarButtonItems?.count != nil){
                for index in 0..<self.navItem.rightBarButtonItems!.count{
                    navItem.rightBarButtonItems?[index].tintColor = UIColor.white
                }
            }
            if(navItem.leftBarButtonItems?.count != nil){
                for index in 0..<self.navItem.leftBarButtonItems!.count{
                    navItem.leftBarButtonItems?[index].tintColor = UIColor.white
                }
            }
        }
        navBar.standardAppearance = standardAppearance
        navBar.scrollEdgeAppearance = standardAppearance
    }
    
    /** Button press methods*/
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
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CheckoutVC: STPAuthenticationContext{
    public func authenticationPresentingViewController() -> UIViewController {
        return self
    }
}
