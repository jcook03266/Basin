//
//  UniversalProperties.swift
//  Stuy Wash N Dry
//
//  Created by Justin Cook on 2/5/22.
//

import UIKit
import SkeletonView
import Network
import PhoneNumberKit
import Lottie
import Nuke

/** Simple File that contains many global variables and methods used throughout the application*/
/**Google AdMob variables*/
let bannerViewAdUnitID = "ca-app-pub-3940256099942544/2934735716"//TEST ID REPLACE
/**Network Monitoring and UI*/
var monitor: NWPathMonitor = NWPathMonitor()
var internetAvailable = true
/**Custom Colors*/
var Systemgray6: UIColor = UIColor(red: 28/255, green: 28/255, blue: 30/255, alpha: 1)
/**Darkmode functionality*/
var darkMode: Bool = false/**check if darkmode is active or not on load*/
var bgColor: UIColor = UIColor.white/**Default lightmode color*/
var secondaryBgColor: UIColor = UIColor.black/**Default lightmode secondary color*/
var fontColor: UIColor = UIColor.black/**Default font color for light mode*/
var secondaryfontcolor: UIColor = UIColor.gray/**Default secondary font color for light mode*/
var darkModeBgColor: UIColor = Systemgray6
var lightModeBgColor: UIColor = UIColor.white
var darkModeFontColor: UIColor = UIColor.white
var lightModeFontColor: UIColor = Systemgray6
var appThemeColor: UIColor = UIColor(red: 92/255, green: 189/255, blue: 246/255, alpha: 1)

/** A phone kit object on standby since instantiation of one is expensive*/
var readyPhoneKit = PhoneNumberKit()

/** Check to see if advertisements should be displayed*/
func shouldDisplayAds()->Bool{
    var showAdverts = true
    
    /** If the user has purchased the remove phone ads item then dont show ads to them (this isn't cross-platform, for android they have to buy it again)*/
    
    return showAdverts
}

/**Load the state of the darkmode switch*/
func loadDarkmodestate(){
    darkMode = true
    if let bool = UserDefaults.standard.object(forKey: "Darkmode") as? Bool{
        darkMode = bool
    }
}

/**Save the state of the darkmode switch*/
func saveDarkmodestate(){
    UserDefaults.standard.removeObject(forKey: "Darkmode")
    UserDefaults.standard.synchronize()
    UserDefaults.standard.set(darkMode, forKey: "Darkmode")
}

/**Check to see if darkmode is on or not*/
func checkDarkmode(){
    loadDarkmodestate()
    if(darkMode == true){bgColor = darkModeBgColor; fontColor = darkModeFontColor; secondaryfontcolor = UIColor.lightGray; secondaryBgColor = UIColor.black}else{bgColor = lightModeBgColor; fontColor = lightModeFontColor; secondaryfontcolor = UIColor.darkGray; secondaryBgColor = UIColor.black}
}
/**Darkmode functionality*/

/** Onboarding completion userdefault persistence methods*/
/** Don't show the onboarding flow anymore if the user has signed up or signed in at least once*/
func userCompletedOnboarding(){
    UserDefaults.standard.removeObject(forKey: "onboardingComplete")
    UserDefaults.standard.synchronize()
    UserDefaults.standard.set(true, forKey: "onboardingComplete")
}

/** Determine if the user has completed the onboarding flow befor*/
func didUserCompletedOnboarding()->Bool{
    var completed = false
    
    if let bool = UserDefaults.standard.object(forKey: "onboardingComplete") as? Bool{
        completed = bool
    }
    
    return completed
}
/** Onboarding completion userdefault persistence methods*/

/** Custom animated loading indicator*/
var loadingIndicator: AnimationView = AnimationView()
/** Custom loading indicator with a lottie animation displayed at the given coordinate point
 - Parameter location: The location in the scene where this loading indicator will be displayed
 - Parameter duration: The duration of the appearance transformation animation for the loading indicator when it scales up from 0 to 1
 - Parameter size: The size of the loading indicator, width and height are the same*/
func displayLoadingIndicator(at location: CGPoint, duration: CGFloat, size: CGFloat){
    /** Display this asynchronously as it's not rendered without that*/
    DispatchQueue.main.asyncAfter(deadline: .now()){
        loadingIndicator = AnimationView.init(name: "Basin RC Lottie White")
        loadingIndicator.frame.size = CGSize(width: size, height: size)
        loadingIndicator.frame.origin = location
        
        loadingIndicator.animationSpeed = 1
        loadingIndicator.backgroundBehavior = .pauseAndRestore
        loadingIndicator.isExclusiveTouch = true
        loadingIndicator.shouldRasterizeWhenIdle = true
        loadingIndicator.contentMode = .scaleAspectFill
        loadingIndicator.isOpaque = false
        loadingIndicator.clipsToBounds = true
        loadingIndicator.backgroundColor = .clear
        loadingIndicator.loopMode = .loop
        loadingIndicator.clipsToBounds = false
        loadingIndicator.transform = CGAffineTransform(scaleX: 0, y: 0)
        
        loadingIndicator.play(completion: nil)
        
        /** Transform the size of the animation view from 0 to 1*/
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 1, options: .curveEaseIn){
            loadingIndicator.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        
        UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.addSubview(loadingIndicator)
    }
}

/** Removes the custom loading indicator*/
func removeLoadingIndicator(){
    /** Transform the size of the animation view from 0 to 1*/
    UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 1, options: .curveEaseIn){
        loadingIndicator.transform = CGAffineTransform(scaleX: 0.0000001, y: 0.0000001)
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
        loadingIndicator.removeFromSuperview()
    }
}
/** Custom animated loading indicator*/

/** Return a string containing the gender specified by the given number*/
func getGender(from number: UInt)->String?{
    switch number{
    case 0:
        return "Male"
    case 1:
        return "Female"
    case 2:
        return "Unspecified"
    default:
        return nil
    }
}

/** Array containing acceptable genders*/
let genders = ["Male","Female","Unspecified"]

/** Return a number associated with the gender specified by the given string*/
func getGender(from string: String)->UInt?{
    switch string{
    case "Male":
        return 0
    case "Female":
        return 1
    case "Unspecified":
        return 2
    default:
        return nil
    }
}

/** Parse the given phone number object into a CSV containing the country code and the national number like so: [country code, national number]*/
func parsePhoneNumberIntoCSV(phoneNumber: PhoneNumber)->String{
    return "\(phoneNumber.countryCode),\(phoneNumber.nationalNumber)"
}

/** Convert from a csv string to a phone number (if possible)*/
func convertFromCSVtoPhoneNumber(number: String)->PhoneNumber?{
    /** Phone number object to be parsed from the two comma separated values*/
    var phoneNumber: PhoneNumber? = nil
    
    /** The two values stored in one string separated by a comma*/
    var nationalNumber = ""
    var countryCode = ""
    
    /** Indicates if the comma that separates the two values in the string has been reached, if so then store everything after that comma in the second variable*/
    var commaReached = false
    
    /** Check to see if the number string even contains a comma before doing anything else*/
    guard number.contains(",") == true else {
        return phoneNumber
    }
    
    for char in number{
        if char != "," && commaReached == false{
            countryCode.append(char)
        }
        else if char == ","{
            commaReached = true
        }
        else{
            nationalNumber.append(char)
        }
    }
    
    /** Make sure the two separated values are actually numbers before creating expensive objects*/
    guard UInt64(countryCode) != nil && UInt64(nationalNumber) != nil else {
        return phoneNumber
    }
    
    /** Init a phone number kit object to parse the phone number*/
    let phoneNumberKit = PhoneNumberKit()
    
    /** Ensure that an ISO 639 compliant region code exists for the given country code*/
    guard let regionCode = phoneNumberKit.mainCountry(forCode: UInt64(countryCode)!) else {
        return phoneNumber
    }
    
    do {
        try phoneNumber = phoneNumberKit.parse(nationalNumber, withRegion: regionCode, ignoreType: true)
    } catch{
        print("Phone number could not be parsed: \(error)")
    }
    
    return phoneNumber
}

/** Converts the given integer (in seconds) into a minutes based count down time clock string of the format [0:00]*/
func convertToCountDown(duration: UInt)->String{
    var time = ""
    var minutes: UInt = 0
    var seconds: UInt = 0
    
    /** Anything less than 60 should just be presented as seconds*/
    if duration >= 60{
        /** Multiples of 60 seconds are minutes*/
        minutes = duration/60
        
        /** Remainder will be the time in seconds*/
        seconds = duration%60
    }
    else{
        seconds = duration
    }
    
    /** Add a trailing zero to the seconds string if the number of seconds isn't two digits*/
    var secondsString = String(seconds)
    if seconds < 10{
        secondsString = "0\(seconds)"
    }
    
    /** Represent time with minutes first, then semi colon, and then seconds last with a mandatory trailing zero*/
    time = "\(minutes):\(secondsString)"
    
    return time
}

/** Useful Subclasses and extensions*/
class PaddedLabel: UILabel {
    var topInset: CGFloat
    var bottomInset: CGFloat
    var leftInset: CGFloat
    var rightInset: CGFloat
    
    required init(withInsets top: CGFloat, _ bottom: CGFloat, _ left: CGFloat, _ right: CGFloat) {
        self.topInset = top
        self.bottomInset = bottom
        self.leftInset = left
        self.rightInset = right
        super.init(frame: CGRect.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawText(in: rect.inset(by: insets))
    }
    
    override var intrinsicContentSize: CGSize {
        get {
            var contentSize = super.intrinsicContentSize
            contentSize.height += topInset + bottomInset
            contentSize.width += leftInset + rightInset
            return contentSize
        }
    }
}

/** Embed a UIView inside of another UIView that acts as a dynamic shadow for that subview*/
public class UIShadowView: UIView{
    
    init(subview: UIView, shadowColor: UIColor, shadowRadius: CGFloat, shadowOpacity: Float){
        super.init(frame: subview.frame)
        self.layer.shadowColor = shadowColor.cgColor
        self.layer.shadowOpacity = shadowOpacity
        self.layer.shadowRadius = shadowRadius
        self.layer.shadowPath = UIBezierPath(roundedRect: subview.bounds, cornerRadius: subview.layer.cornerRadius).cgPath
        self.backgroundColor = UIColor.clear
        self.addSubview(subview)
    }
    
    func setShadowOffset(shadowOffset: CGSize){
        self.layer.shadowOffset = shadowOffset
    }
    func setShadowOpacity(shadowOpacity: Float){
        self.layer.shadowOpacity = shadowOpacity
    }
    func setShadowRadius(shadowRadius: CGFloat){
        self.layer.shadowRadius = shadowRadius
    }
    func setShadowColor(shadowColor: UIColor){
        self.layer.shadowColor = shadowColor.cgColor
    }
    
    /** Remove the shadow properties from this UIView*/
    func removeShadow(){
        self.layer.shadowOpacity = 0
        self.layer.shadowColor = UIColor.clear.cgColor
        self.layer.shadowRadius = 0
        self.layer.shadowOffset = CGSize(width: 0, height: 0)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UIButton{
    /** Cast a shadow on the button using custom parameters*/
    func castShadow(shadowColor: UIColor, shadowRadius: CGFloat, shadowOpacity: Float, shadowOffset: CGSize){
        self.layer.shadowRadius = shadowRadius
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowOpacity = shadowOpacity
        self.clipsToBounds = true
        self.layer.masksToBounds = false
        self.layer.shadowOffset = shadowOffset
        self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: self.layer.cornerRadius).cgPath
    }
    
    /** Cast a shadow on the button using default presets*/
    func castDefaultShadow(){
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowRadius = 1
        self.layer.shadowOpacity = 1
        self.clipsToBounds = true
        self.layer.masksToBounds = false
        self.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: self.layer.cornerRadius).cgPath
    }
    
    /** Remove the shadow properties from this button*/
    func removeShadow(){
        self.layer.shadowOpacity = 0
        self.layer.shadowColor = UIColor.clear.cgColor
        self.layer.shadowRadius = 0
        self.layer.shadowOffset = CGSize(width: 0, height: 0)
    }
}

extension UITextView{
    /** Specify the alignment attribute for the following attributed text*/
    func setAttributedTextAlignment(alignment: NSTextAlignment){
        if let text = self.attributedText{
            let attributedText = NSMutableAttributedString(attributedString: text)
            
            let style = NSMutableParagraphStyle()
            
            style.alignment = alignment
            attributedText.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: NSMakeRange(0, text.string.count))
            self.attributedText = attributedText
        }
    }
    
    
    /** Set line spacing*/
    func setAttributedTextLineSpacing(lineSpacing: CGFloat){
        if let text = self.attributedText{
            let attributedText = NSMutableAttributedString(attributedString: text)
            
            let style = NSMutableParagraphStyle()
            
            style.lineSpacing = lineSpacing
            attributedText.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: NSMakeRange(0, text.string.count))
            self.attributedText = attributedText
        }
    }
}

extension UILabel{
    /** Specify the alignment attribute for the following attributed text*/
    func setAttributedTextAlignment(alignment: NSTextAlignment){
        if let text = self.attributedText{
            let attributedText = NSMutableAttributedString(attributedString: text)
            
            let style = NSMutableParagraphStyle()
            
            style.alignment = alignment
            attributedText.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: NSMakeRange(0, text.string.count))
            self.attributedText = attributedText
        }
    }
    
    /** Set line spacing*/
    func setAttributedTextLineSpacing(lineSpacing: CGFloat) {
        if let text = self.attributedText{
            let attributedText = NSMutableAttributedString(attributedString: text)
            
            let style = NSMutableParagraphStyle()
            
            style.lineSpacing = lineSpacing
            attributedText.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: NSMakeRange(0, text.string.count))
            self.attributedText = attributedText
        }
    }
    
    /** Cast a shadow on the UILabel using custom parameters*/
    func castShadow(shadowColor: UIColor, shadowRadius: CGFloat, shadowOpacity: Float, shadowOffset: CGSize){
        self.clipsToBounds = true
        self.layer.masksToBounds = false
        self.layer.shadowColor = shadowColor.cgColor
        self.layer.shadowRadius = shadowRadius
        self.layer.shadowOpacity = shadowOpacity
        self.layer.shadowOffset = shadowOffset
        self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: self.layer.cornerRadius).cgPath
    }
    
    /** Cast a shadow on the UILabel using default presets*/
    func castDefaultShadow(){
        self.clipsToBounds = true
        self.layer.masksToBounds = false
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowRadius = 1
        self.layer.shadowOpacity = 0.5
        self.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: self.layer.cornerRadius).cgPath
    }
    
    /** Remove the shadow properties from this UILabel*/
    func removeShadow(){
        self.layer.shadowOpacity = 0
        self.layer.shadowColor = UIColor.clear.cgColor
        self.layer.shadowRadius = 0
        self.layer.shadowOffset = CGSize(width: 0, height: 0)
    }
}

extension UITextField {
    func setLeftPaddingPoints(_ amount:CGFloat){
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
    func setRightPaddingPoints(_ amount:CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.rightView = paddingView
        self.rightViewMode = .always
    }
}

/**Extension of View controller class that implements UIGestureRecognizerDelegate*/
extension UIViewController: UIGestureRecognizerDelegate, UIScrollViewDelegate{
    
    /** Start monitoring network conditions on a background thread*/
    func startNetworkMonitor(){
        monitor.start(queue: DispatchQueue.global(qos: .background))
        
        monitor.pathUpdateHandler = {[self] path in
            switch path.status{
            case .satisfied:
                /** Only display this prompt after the internet connection was disrupted and then reconnected*/
                if internetAvailable == false{
                    /** Update the UI only from the main thread*/
                    DispatchQueue.main.async {
                        internetAvailablePrompt()
                    }
                }
            case .unsatisfied:
                DispatchQueue.main.async {
                    internetUnavailablePrompt()
                }
            case .requiresConnection:
                DispatchQueue.main.async {
                    internetUnavailablePrompt()
                }
            @unknown default:
                break
            }
        }
    }
    
    /** Stop monitoring network conditions on a background thread*/
    func stopNetworkMonitor(){
        monitor.cancel()
    }
    
    /** Notifies the user that their internet connection is unavailable and that they can't proceed with any networking sensitive operations*/
    func internetUnavailablePrompt(){
        globallyTransmit(this: "Internet Connection Unavailable", with: UIImage(systemName: "wifi.slash", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: .clear, imageBorder: .none, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 3, selfDismiss: true)
        
        internetAvailable = false
    }
    
    /** Notifies the user that an internet connection has been established and that they can now proceed with any networking sensitive operations*/
    func internetAvailablePrompt(){
        globallyTransmit(this: "Internet Connection Established", with: UIImage(systemName: "wifi.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: .clear, imageBorder: .none, blurEffect: true, accentColor: .green, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 3, selfDismiss: true)
        
        internetAvailable = true
    }
}

extension UISearchBar {
    func updateHeight(height: CGFloat, radius: CGFloat) {
        let image: UIImage? = UIImage.imageWithColor(color: UIColor.clear, size: CGSize(width: 1, height: height))
        setSearchFieldBackgroundImage(image, for: .normal)
        for subview in self.subviews {
            for subSubViews in subview.subviews {
                if #available(iOS 13.0, *) {
                    for child in subSubViews.subviews {
                        if let textField = child as? UISearchTextField {
                            textField.layer.cornerRadius = radius
                            textField.clipsToBounds = true
                        }
                    }
                    continue
                }
                if let textField = subSubViews as? UITextField {
                    textField.layer.cornerRadius = radius
                    textField.clipsToBounds = true
                }
            }
        }
    }
}

private extension UIImage {
    static func imageWithColor(color: UIColor, size: CGSize) -> UIImage? {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(rect)
        guard let image: UIImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return nil
        }
        UIGraphicsEndImageContext()
        return image
    }
}

extension UIView{
    /**Render the current UIView as a UIImage and then pass this back to the caller
     attribution is optional*/
    func renderAsImage(attribution: attributionType) -> UIImage{
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        var render: UIImage? = nil
        
        let attributionHeight: CGFloat = 40
        
        switch attribution{
        case .transparent:
            let background = UIView()
            background.frame.size.height = self.frame.width * 0.15
            background.frame.size.width = self.frame.width * 0.15
            background.clipsToBounds = true
            background.layer.cornerRadius = background.frame.height/2
            background.backgroundColor = UIColor.black.withAlphaComponent(0.8)
            background.frame.origin = CGPoint(x: self.frame.minX + 5, y: self.frame.height - background.frame.height * 1.05)
            
            let originalCornerRad = self.layer.cornerRadius
            self.layer.cornerRadius = 0
            
            let appLogoAttribution = UIImageView()
            appLogoAttribution.image = UIImage(imageLiteralResourceName: "StuyWashNDryCutSVGLogo")
            appLogoAttribution.contentMode = .scaleAspectFit
            appLogoAttribution.clipsToBounds = true
            appLogoAttribution.backgroundColor = UIColor.clear
            appLogoAttribution.frame = CGRect(x: 0, y: background.frame.height/2 - (background.frame.height)/2, width: background.frame.height, height: background.frame.height)
            
            background.addSubview(appLogoAttribution)
            self.addSubview(background)
            
            render = renderer.image{rendererContext in drawHierarchy(in: bounds, afterScreenUpdates: true)}
            
            background.removeFromSuperview()
            self.layer.cornerRadius = originalCornerRad
            
        case .generic:
            let background = UIView()
            background.frame.size.height = attributionHeight
            background.frame.size.width = self.frame.width
            background.clipsToBounds = true
            background.backgroundColor = UIColor.black
            background.frame.origin = CGPoint(x: self.frame.width/2 - background.frame.width/2, y: self.frame.height - background.frame.height)
            
            let originalCornerRad = self.layer.cornerRadius
            self.layer.cornerRadius = 0
            
            let appLogoAttribution = UIImageView()
            appLogoAttribution.image = UIImage(imageLiteralResourceName: "StuyWashNDryCutSVGLogo")
            appLogoAttribution.contentMode = .scaleAspectFit
            appLogoAttribution.clipsToBounds = true
            appLogoAttribution.backgroundColor = UIColor.clear
            appLogoAttribution.frame = CGRect(x: 0, y: background.frame.height/2 - (attributionHeight)/2, width: attributionHeight, height: attributionHeight)
            
            let attribution = UILabel()
            attribution.frame.size.height = attributionHeight
            attribution.frame.size.width = self.frame.width * 0.5
            attribution.adjustsFontSizeToFitWidth = true
            attribution.clipsToBounds = true
            attribution.text = ""
            attribution.textColor = UIColor.white
            attribution.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: false)
            attribution.textAlignment = .left
            attribution.frame.origin = CGPoint(x: appLogoAttribution.frame.maxX, y: background.frame.height/2 - attribution.frame.height/2)
            
            background.addSubview(attribution)
            background.addSubview(appLogoAttribution)
            self.addSubview(background)
            
            render = renderer.image{rendererContext in drawHierarchy(in: bounds, afterScreenUpdates: true)}
            
            background.removeFromSuperview()
            self.layer.cornerRadius = originalCornerRad
            
        case .none:
            let originalCornerRad = self.layer.cornerRadius
            self.layer.cornerRadius = 0
            
            render = renderer.image{rendererContext in drawHierarchy(in: bounds, afterScreenUpdates: true)}
            
            self.layer.cornerRadius = originalCornerRad
        }
        return render!
    }
    
    /** Render the UIView as an image with generic attribution at the bottom of the image with a specified size of 40pts*/
    func renderWithGenericImageAttribution()->UIImage{
        /** The container of the UIView that will give it the extra length necessary to show the extra attribution at the bottom*/
        let containerView = UIView(frame: self.frame)
        containerView.frame.size.height = self.frame.height + 40
        
        /** The original superview (if any) of this view, this is where the view will be returned after the picture is taken*/
        let superView = self.superview
        
        containerView.addSubview(self)
        let image = containerView.renderAsImage(attribution: .generic)
        
        superView?.addSubview(self)
        
        return image
    }
    
    /**
     Render the UIView as an image without generic attribution at the bottom of the image
     This method renders the view as is before the screen updates and so it is the fastest way to produce a snapshot of the currentview
     - Note: Paid users can share images with or without attribution, non-paid users don't have this option*/
    func renderWithoutGenericImageAttribution()->UIImage{
        return self.renderAsImage(attribution: .none)
    }
    
    /**Specifiy the type of attribution required by a UIView with shortened cases instead of strings*/
    enum attributionType: Int{
        /** Slightly transparent attribution, mainly for images so that most of the content is still visible*/
        case transparent = 0
        /**Specifies that the selected view should have no attribution*/
        case none = 1
        /**Specifies generic attribution for any type of view*/
        case generic = 2
    }
    
    /** Function used to compute the height of the status bar by using the safe area inset of the view*/
    func getStatusBarHeight()->CGFloat{
        var topInset = self.safeAreaInsets.top
        
        /** If the top inset isn't available then just assume a height close to the actual height of the top inset*/
        if topInset == 0{
            topInset = 40
        }
        
        return topInset
    }
    
    /**Dashed Border Methods*/
    func addDashedBorder(strokeColor: UIColor, fillColor: UIColor, lineWidth: CGFloat, lineDashPattern: [NSNumber], cornerRadius: CGFloat){
        let shapeLayer:CAShapeLayer = CAShapeLayer()
        let frameSize = self.frame.size
        let shapeRect = CGRect(x: 0, y: 0, width: frameSize.width, height: frameSize.height)
        
        shapeLayer.bounds = shapeRect
        shapeLayer.position = CGPoint(x: frameSize.width/2, y: frameSize.height/2)
        shapeLayer.fillColor = fillColor.cgColor
        shapeLayer.strokeColor = strokeColor.cgColor
        shapeLayer.lineWidth = lineWidth
        shapeLayer.lineJoin = CAShapeLayerLineJoin.round
        shapeLayer.lineDashPattern = lineDashPattern
        shapeLayer.path = UIBezierPath(roundedRect: shapeRect, cornerRadius: cornerRadius).cgPath
        shapeLayer.name = "DashedBorder"
        
        self.layer.addSublayer(shapeLayer)
    }
    
    func updateDashedBorder(cornerRadius: CGFloat, strokeColor: UIColor){
        guard self.layer.sublayers != nil else{
            return
        }
        
        var dashedBorderLayer = CAShapeLayer()
        for layer in self.layer.sublayers!{
            if(layer.name == "DashedBorder"){
                dashedBorderLayer = layer as! CAShapeLayer
            }
        }
        
        guard dashedBorderLayer.name != nil else{
            return
        }
        
        let frameSize = self.frame.size
        let shapeRect = CGRect(x: 0, y: 0, width: frameSize.width, height: frameSize.height)
        dashedBorderLayer.bounds = shapeRect
        dashedBorderLayer.strokeColor = strokeColor.cgColor
        dashedBorderLayer.position = CGPoint(x: frameSize.width/2, y: frameSize.height/2)
        dashedBorderLayer.path = UIBezierPath(roundedRect: shapeRect, cornerRadius: cornerRadius).cgPath
    }
    
    /** This gives the dashed border the marching ants effect where the lines are moving continuously*/
    func animateDashedBorder(){
        guard self.layer.sublayers != nil else{
            return
        }
        
        var dashedBorderLayer = CAShapeLayer()
        for layer in self.layer.sublayers!{
            if(layer.name == "DashedBorder"){
                dashedBorderLayer = layer as! CAShapeLayer
            }
        }
        
        let lineDashAnimation = CABasicAnimation(keyPath: "lineDashPhase")
        lineDashAnimation.fromValue = 0
        lineDashAnimation.toValue = dashedBorderLayer.lineDashPattern?.reduce(0) { $0 + $1.intValue }
        lineDashAnimation.duration = 1
        lineDashAnimation.repeatCount = Float.greatestFiniteMagnitude
        
        dashedBorderLayer.add(lineDashAnimation, forKey: "AntsMarchingAnimation")
    }
    
    func pauseDashedBorderAnimation(){
        guard self.layer.sublayers != nil else{
            return
        }
        
        var dashedBorderLayer = CAShapeLayer()
        for layer in self.layer.sublayers!{
            if(layer.name == "DashedBorder"){
                dashedBorderLayer = layer as! CAShapeLayer
            }
        }
        
        guard dashedBorderLayer.animation(forKey: "AntsMarchingAnimation") != nil else{
            return
        }
        dashedBorderLayer.pauseAnimation()
    }
    
    func startDashedBorderAnimation(){
        guard self.layer.sublayers != nil else{
            return
        }
        
        var dashedBorderLayer = CAShapeLayer()
        for layer in self.layer.sublayers!{
            if(layer.name == "DashedBorder"){
                dashedBorderLayer = layer as! CAShapeLayer
            }
        }
        
        guard dashedBorderLayer.animation(forKey: "AntsMarchingAnimation") != nil else{
            return
        }
        
        dashedBorderLayer.resumeAnimation()
    }
    
    /** Converts the dashed border into a single lined border and removes all prior animations assigned to the dashed border shape layer*/
    func convertDashedBorderToStraightBorder(){
        guard self.layer.sublayers != nil else{
            return
        }
        
        var dashedBorderLayer = CAShapeLayer()
        for layer in self.layer.sublayers!{
            if(layer.name == "DashedBorder"){
                dashedBorderLayer = layer as! CAShapeLayer
            }
        }
        
        pauseDashedBorderAnimation()
        dashedBorderLayer.removeAllAnimations()
        
        dashedBorderLayer.lineDashPattern = [1,0]
    }
    /**Dashed Border Methods*/
}

extension CALayer
{
    func pauseAnimation() {
        if isPaused() == false {
            let pausedTime = convertTime(CACurrentMediaTime(), from: nil)
            speed = 0.0
            timeOffset = pausedTime
        }
    }
    
    func resumeAnimation() {
        if isPaused() {
            let pausedTime = timeOffset
            speed = 1.0
            timeOffset = 0.0
            beginTime = 0.0
            let timeSincePause = convertTime(CACurrentMediaTime(), from: nil) - pausedTime
            beginTime = timeSincePause
        }
    }
    
    func isPaused() -> Bool {
        return speed == 0
    }
}

/** Creates a UIView with persistent animations that can be paused and resumed automatically depending on the state of the app*/
class ViewWithPersistentAnimations : UIView {
    private var persistentAnimations: [String: CAAnimation] = [:]
    private var persistentSpeed: Float = 0.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    func commonInit() {
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func didBecomeActive() {
        self.restoreAnimations(withKeys: Array(self.persistentAnimations.keys))
        self.persistentAnimations.removeAll()
        if self.persistentSpeed == 1.0 { //if layer was plaiyng before backgorund, resume it
            self.layer.resumeAnimation()
        }
    }
    
    @objc func willResignActive() {
        self.persistentSpeed = self.layer.speed
        
        self.layer.speed = 1.0 //in case layer was paused from outside, set speed to 1.0 to get all animations
        self.persistAnimations(withKeys: self.layer.animationKeys())
        self.layer.speed = self.persistentSpeed //restore original speed
        
        self.layer.pauseAnimation()
    }
    
    func persistAnimations(withKeys: [String]?) {
        withKeys?.forEach({ (key) in
            if let animation = self.layer.animation(forKey: key) {
                self.persistentAnimations[key] = animation
            }
        })
    }
    
    func restoreAnimations(withKeys: [String]?) {
        withKeys?.forEach { key in
            if let persistentAnimation = self.persistentAnimations[key] {
                self.layer.add(persistentAnimation, forKey: key)
            }
        }
    }
}


extension UIButton: Nuke_ImageDisplaying {
    public func nuke_display(image: PlatformImage?, data: Data?) {
        self.setImage(image, for: .normal)
    }
}

/** Convert from miles to meters and meters to miles*/
func getMiles(from meters: CGFloat) -> CGFloat{
    return meters * 0.000621371192
}

func getMeters(from miles: CGFloat) -> CGFloat{
    return miles * 1609.344
}

/** Abbreviate the number of digits represented by the float, and also convert the miles to feet after a certain threshold is reached, namely < 1 mile
 - Parameters miles: The amount of miles (as a float)
 - Parameters feetAbbreviation: The ending to use if the final result is in feet
 - Parameters milesAbbreviation: The ending to use if the final result is in feet
 */
func abbreviateMiles(miles: CGFloat, feetAbbreviation: String, milesAbbreviation: String) -> String{
    var abbreviatedString = ""
    
    if miles >= 1{
        abbreviatedString = "\((String(format: "%.2f", miles))) \(milesAbbreviation)"
    }
    else{
        /** 0.9 miles * 5280 =  4752 feet, 5280 feet= 1 mile*/
        let feet = miles * 5280
        abbreviatedString = "\((String(format: "%.2f", feet))) \(feetAbbreviation)"
    }
    
    return abbreviatedString
}

/** Abbreviate the number of digits represented by the float, and also convert the miles to feet after a certain threshold is reached, namely < 1 mile
 - Parameters meters: The amount of meters (as a float)
 - Parameters metersAbbreviation: The ending to use if the final result is in meters
 - Parameters kilometersAbbreviation: The ending to use if the final result is in kilometers
 */
func abbreviateMeters(meters: CGFloat, metersAbbreviation: String, kilometersAbbreviation: String) -> String{
    var abbreviatedString = ""
    
    if meters >= 1000{
        /** 1 kilometer = 1000 meters*/
        let kilometers = meters/1000
        abbreviatedString = "\((String(format: "%.2f", kilometers))) \(kilometersAbbreviation)"
    }
    else{
        abbreviatedString = "\((String(format: "%.2f", meters))) \(metersAbbreviation)"
    }
    
    return abbreviatedString
}

///Specify the decimal place to round to using an enum
public enum RoundingPrecision {
    case ones
    case tenths
    case hundredths
    case thousands
}

extension Double {
    ///Round to the specific decimal place
    func customRound(_ rule: FloatingPointRoundingRule, precision: RoundingPrecision = .ones) -> Double {
        switch precision {
        case .ones: return (self * Double(1)).rounded(rule) / 1
        case .tenths: return (self * Double(10)).rounded(rule) / 10
        case .hundredths: return (self * Double(100)).rounded(rule) / 100
        case .thousands: return (self * Double(1000)).rounded(rule) / 1000
        }
    }
}

/** Useful Subclasses and extensions*/


