//
//  TermsofService.swift
//  Stuy Wash N Dry
//
//  Created by Justin Cook on 3/11/22.
//

import UIKit
import SafariServices

/** View controller that hosts text describing the app's terms of service, terms of use, and privacy policy*/
public class TermsofServiceVC: UIViewController, UITextFieldDelegate, UITextViewDelegate{
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
    
    /** Textview that will host all of the textual content represented on this page*/
    var contentTextView: UITextView = UITextView()
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        configure()
        supplementBackButton()
        createUI()
    }
    
    /** Configures and adds the back button to the view hierarchy*/
    func supplementBackButton(){
        let imageConfiguration = UIImage.SymbolConfiguration(weight: .regular)
        let image = UIImage(systemName: "arrow.down", withConfiguration: imageConfiguration)
        
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
        backButton.addTarget(self, action: #selector(buttonTD), for: .touchDown)
        backButton.addTarget(self, action: #selector(buttonDE), for: .touchDragExit)
        backButton.alpha = 0
        backButton.isEnabled = false
        
        /** Everything else depends on this button's position so make sure this is positioned correctly*/
        backButton.frame.origin = CGPoint(x: 10, y: 15)
        
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
    
    func createUI(){
        let panhandleView = UIView()
        panhandleView.frame.size = CGSize(width: view.frame.width/5, height: 5)
        panhandleView.clipsToBounds = true
        panhandleView.layer.cornerRadius = panhandleView.frame.height/2
        panhandleView.backgroundColor = .lightGray
        panhandleView.frame.origin = CGPoint(x: view.frame.width/2 - panhandleView.frame.width/2, y: panhandleView.frame.height * 3)
        
        contentTextView.frame.size = CGSize(width: view.frame.width * 0.95, height: view.frame.height - backButton.frame.maxY)
        contentTextView.adjustsFontForContentSizeCategory = true
        contentTextView.backgroundColor = bgColor
        contentTextView.tintColor = appThemeColor
        /** Add a little padding to the bottom of the textview to prevent text from being hidden outside of the view port*/
        contentTextView.contentInset = UIEdgeInsets(top: contentTextView.frame.height * 0.05, left: 0, bottom: contentTextView.frame.height * 0.1, right: 0)
        
        /** Terms of service, privacy policy terms of use etc.*/
        var text = ""
        text += "Terms of Service"
        text += "\n\nLast Updated: 03/12/22"
        text += "\n\nAGREEMENT TO TERMS"
        text += "\n\nThese Terms of Service constitute a legally binding agreement made between you, whether personally or on behalf of an entity (“you”) and [business entity name] (“we,” “us” or “our”), concerning your access to and use of the [website name.com] website as well as any other media form, media channel, mobile website or mobile application related, linked, or otherwise connected thereto (collectively, the “Site”)."
        text += "\n\nYou agree that by accessing the Site, you have read, understood, and agree to be bound by all of these Terms of Service. If you do not agree with all of these Terms of Service, then you are expressly prohibited from using the Site and you must discontinue use immediately."
        text += "\n\nSupplemental Terms of Service or documents that may be posted on the Site from time to time are hereby expressly incorporated herein by reference. We reserve the right, in our sole discretion, to make changes or modifications to these Terms of Service at any time and for any reason."
        text += "\n\nWe will alert you about any changes by updating the “Last updated” date of these Terms of Service, and you waive any right to receive specific notice of each such change."
        text += "\n\nTerms of Use"
        text += "\n\nThese Terms of Service constitute a legally binding agreement made between you, whether personally or on behalf of an entity (“you”) and [business entity name] (“we,” “us” or “our”), concerning your access to and use of the [website name.com] website as well as any other media form, media channel, mobile website or mobile application related, linked, or otherwise connected thereto (collectively, the “Site”)."
        text += "\n\nYou agree that by accessing the Site, you have read, understood, and agree to be bound by all of these Terms of Service. If you do not agree with all of these Terms of Service, then you are expressly prohibited from using the Site and you must discontinue use immediately."
        text += "\n\nSupplemental Terms of Service or documents that may be posted on the Site from time to time are hereby expressly incorporated herein by reference. We reserve the right, in our sole discretion, to make changes or modifications to these Terms of Service at any time and for any reason."
        text += "\n\nWe will alert you about any changes by updating the “Last updated” date of these Terms of Service, and you waive any right to receive specific notice of each such change."
        text += "\n\nPrivacy Policy"
        text += "\n\nThese Terms of Service constitute a legally binding agreement made between you, whether personally or on behalf of an entity (“you”) and [business entity name] (“we,” “us” or “our”), concerning your access to and use of the [website name.com] website as well as any other media form, media channel, mobile website or mobile application related, linked, or otherwise connected thereto (collectively, the “Site”)."
        text += "\n\nYou agree that by accessing the Site, you have read, understood, and agree to be bound by all of these Terms of Service. If you do not agree with all of these Terms of Service, then you are expressly prohibited from using the Site and you must discontinue use immediately."
        text += "\n\nSupplemental Terms of Service or documents that may be posted on the Site from time to time are hereby expressly incorporated herein by reference. We reserve the right, in our sole discretion, to make changes or modifications to these Terms of Service at any time and for any reason."
        text += "\n\nWe will alert you about any changes by updating the “Last updated” date of these Terms of Service, and you waive any right to receive specific notice of each such change."
        
        let attributedText = attribute(this: text, font: getCustomFont(name: .Ubuntu_Regular, size: 16, dynamicSize: true), subFont: getCustomFont(name: .Ubuntu_bold, size: 30, dynamicSize: true), mainColor: fontColor.darker, subColor: appThemeColor, subStrings:
        ["Terms of Service","\nTerms of Use","\nPrivacy Policy"])
        
        /** Add other attributes to different parts of the text*/
        attributedText.addAttributes([.font: getCustomFont(name: .Ubuntu_bold, size: 18, dynamicSize: true), .foregroundColor: appThemeColor], range: attributedText.mutableString.range(of: "\nAGREEMENT TO TERMS"))
        
        contentTextView.attributedText = attributedText
        
        /** Settings for URLs inside the text*/
        contentTextView.isEditable = false
        contentTextView.isSelectable = true
        contentTextView.dataDetectorTypes = [.all]
        contentTextView.linkTextAttributes = [.foregroundColor: appThemeColor]
        /** Open the links in the safari web view controller*/
        contentTextView.delegate = self
        
        /** Create a top and bottom gradient to fade the content in and out of the scrollview*/
        let topGradient = CAGradientLayer()
        topGradient.frame = CGRect(x: 0, y: backButton.frame.maxY, width: contentTextView.bounds.width, height: 40)
        topGradient.colors = [bgColor.cgColor,bgColor.withAlphaComponent(0).cgColor]
        
        let bottomGradient = CAGradientLayer()
        bottomGradient.frame = CGRect(x: 0, y: view.frame.maxY - 50, width: contentTextView.bounds.width, height: 50)
        bottomGradient.colors = [bgColor.withAlphaComponent(0).cgColor,bgColor.cgColor]
        
        /** Layout these subviews*/
        contentTextView.frame.origin = CGPoint(x: view.frame.width/2 - contentTextView.frame.width/2, y: backButton.frame.maxY)
        
        view.addSubview(contentTextView)
        view.layer.addSublayer(topGradient)
        view.layer.addSublayer(bottomGradient)
        view.addSubview(backButton)
        view.addSubview(panhandleView)
    }
    
    /** Button press methods*/
    /** Submit the password reset request*/
    @objc func backButtonPressed(sender: UIButton){
        backwardTraversalShake()
        
        self.dismiss(animated: true, completion: nil)
    }
    
    /** Generic recognizer that scales the button down when the user touches their finger down on it*/
    @objc func buttonTD(sender: UIButton){
        lightHaptic()
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }
    
    /** Generic recognizer that scales the button up when the user drags their finger out inside of it*/
    @objc func buttonDE(sender: UIButton){
        lightHaptic()
        UIView.animate(withDuration: 0.5, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
    }
    /** Button press methods*/
    
    /** Delegate methods for textview*/
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        /** Open any links in textview inside of this application*/
        let vc = SFSafariViewController(url: URL)
        vc.modalPresentationStyle = .formSheet
        self.present(vc, animated: true, completion: nil)
        
        return false
    }
    /** Delegate methods for textview*/
    
    /** Set the specifics of this view controller*/
    func configure(){
        self.view.backgroundColor = bgColor
    }
}
