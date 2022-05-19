//
//  LaundromatLocationView.swift
//  Stuy Wash N Dry
//
//  Created by Justin Cook on 3/25/22.
//

import UIKit
import Lottie
import PhoneNumberKit
import Firebase

/** UIView that displays general information about a laundromat*/
public class LaundromatLocationView: UIView, UIGestureRecognizerDelegate{
    /** The subview inside of this view, it hosts all of the other subsequent views*/
    var container: UIView!
    /** Carousel to display the laundromat's images*/
    var imageCarousel: imageCarousel!
    var laundromatData: Laundromat
    var laundromatPhotoURLs: [URL] = []
    var presentingVC: UIViewController
    /** Label containing the shortened name of the location*/
    var nicknameLabel: UILabel!
    /** Label containing the address of the location*/
    var addressLabel: UILabel!
    /** Clickable button containing the phone number of the location*/
    var phoneNumberButton: UIButton!
    /** Label containing the operating hours of the location*/
    var operatingHoursLabel: PaddedLabel!
    /** Labeling containing the opening or closing hours of the location depending on the current time*/
    var openingClosingHoursLabel: PaddedLabel!
    /** Label containing the distance of the location from the user's current location*/
    var distanceLabel: UILabel!
    /** Lottie animation view with an animated heart that animates when the user taps on the lottie view to favorite this specific laundromat location*/
    var favoriteButton: LottieButton!
    /** Check to see if a record exists for this item in the list of favorited laundromats*/
    lazy var favorited: Bool = isFavorited()
    /** View that shows the average ratings for the given laundromat, fetched from the database*/
    var averageRatings: RatingsCircleProgressView!
    /** Label expressing the total reviews for this laundromat*/
    var totalReviewsLabel: PaddedLabel!
    /** Tap gesture recognizer used to open the address data in the default maps app*/
    var tapGestureRecognizer: UITapGestureRecognizer!
    /** Decorative line dividing the bottom of the image carousel from the rest of the content*/
    var dividingLine: UIView!
    
    init(frame: CGRect, laundromatData: Laundromat, presentingVC: UIViewController){
        self.laundromatData = laundromatData
        self.presentingVC = presentingVC
        
        super.init(frame: frame)
        
        createUI()
    }
    
    /** Create the user interface of this view with the data passed*/
    private func createUI(){
        /** Specify a maximum font size*/
        self.maximumContentSizeCategory = .large
        
        /** Slightly shrink the size of this view so that it sits inside of the frame it was designated*/
        /** This view acts as a shadow for its enclosed subview*/
        self.frame.size = CGSize(width: self.frame.width * 0.95, height: self.frame.height * 0.95)
        self.backgroundColor = .clear
        self.layer.cornerRadius = self.frame.height * 0.05
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowOpacity = 0.25
        self.layer.shadowRadius = 3
        self.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.layer.masksToBounds = true
        self.clipsToBounds = false
        
        container = UIView(frame: self.frame)
        container.backgroundColor = bgColor
        container.layer.cornerRadius = self.layer.cornerRadius
        container.clipsToBounds = true
        
        laundromatPhotoURLs = stringToURL(stringArray: laundromatData.photos)
        
        imageCarousel = Basin.imageCarousel(frame: CGRect(x: 0, y: 0, width: container.frame.width, height: container.frame.height * 0.6), images: nil, urls: laundromatPhotoURLs, useURLs: true, contentBackgroundColor: UIColor.clear, animatedTransition: true, transitionDuration: 0.25, infiniteScroll: true, showDetailViewOnTap: true, showContextMenu: true, presentingVC: presentingVC, showPageControl: true, pageControlActiveDotColor: appThemeColor, pageControlInactiveDotColor: UIColor.lightGray.lighter, pageControlPosition: .bottom, loadOnce: true, showImageTrackerLabel: true, imageTrackerLabelPosition: .lowerRight, imageViewContentMode: .scaleAspectFill)
        imageCarousel.autoMove(timeInterval: 10, animationDuration: 1, animated: true, repeating: true)
        /** Disable the page control because it triggers the selection delegate method for the host tableview or collectionview when tapped (weird behavior from apple, could probably fix this by embedding it in another UIView but whatever)*/
        imageCarousel.getPageControl().isEnabled = false
        
        dividingLine = UIView(frame: CGRect(x: 0, y: 0, width: container.frame.width, height: 4))
        dividingLine.backgroundColor = appThemeColor
        dividingLine.clipsToBounds = true
        
        nicknameLabel = UILabel()
        nicknameLabel.frame.size = CGSize(width: self.frame.width * 0.9, height: 40)
        nicknameLabel.font = getCustomFont(name: .Ubuntu_Medium, size: 16, dynamicSize: true)
        nicknameLabel.backgroundColor = .clear
        nicknameLabel.textColor = fontColor
        nicknameLabel.textAlignment = .left
        nicknameLabel.adjustsFontForContentSizeCategory = true
        nicknameLabel.adjustsFontSizeToFitWidth = true
        
        /** Attributed string with a system image in the front*/
        let nicknameLabelImageAttachment = NSTextAttachment()
        nicknameLabelImageAttachment.image = UIImage(systemName: "building.2.fill")?.withTintColor(.darkGray)
        
        let nicknameLabelAttributedString = NSMutableAttributedString()
        nicknameLabelAttributedString.append(NSAttributedString(attachment: nicknameLabelImageAttachment))
        nicknameLabelAttributedString.append(NSMutableAttributedString(string: " \(laundromatData.nickName)"))
        nicknameLabel.attributedText = nicknameLabelAttributedString
        
        addressLabel = UILabel()
        addressLabel.frame.size = CGSize(width: self.frame.width * 0.9, height: 40)
        addressLabel.font = getCustomFont(name: .Ubuntu_Regular, size: 12, dynamicSize: true)
        addressLabel.backgroundColor = .clear
        addressLabel.textColor = .lightGray
        addressLabel.textAlignment = .left
        addressLabel.adjustsFontForContentSizeCategory = true
        addressLabel.adjustsFontSizeToFitWidth = true
        addressLabel.isUserInteractionEnabled = true
        
        /** Attributed string with a system image in the front*/
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = UIImage(systemName: "mappin.circle.fill")?.withTintColor(appThemeColor)
        
        let attributedString = NSMutableAttributedString()
        attributedString.append(NSAttributedString(attachment: imageAttachment))
        attributedString.append(NSMutableAttributedString(string: " \(laundromatData.address.streetAddress1), \(laundromatData.address.borough), \(laundromatData.address.state), \(laundromatData.address.zipCode)"))
        addressLabel.attributedText = attributedString
        
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(addressLabelTapped))
        tapGestureRecognizer.numberOfTouchesRequired = 1
        tapGestureRecognizer.delegate = self
        addressLabel.addGestureRecognizer(tapGestureRecognizer)
    
        phoneNumberButton = UIButton()
        phoneNumberButton.frame.size = CGSize(width: self.frame.width * 0.45, height: 40)
        phoneNumberButton.backgroundColor = appThemeColor
        phoneNumberButton.setTitle("\(readyPhoneKit.format(laundromatData.phoneNumber, toType: .national))", for: .normal)
        phoneNumberButton.setTitleColor(.white, for: .normal)
        phoneNumberButton.titleLabel?.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: true)
        phoneNumberButton.contentHorizontalAlignment = .center
        phoneNumberButton.titleLabel?.adjustsFontSizeToFitWidth = true
        phoneNumberButton.titleLabel?.adjustsFontForContentSizeCategory = true
        phoneNumberButton.layer.cornerRadius = phoneNumberButton.frame.height/2
        phoneNumberButton.isExclusiveTouch = true
        phoneNumberButton.isEnabled = true
        phoneNumberButton.castDefaultShadow()
        phoneNumberButton.layer.shadowColor = UIColor.darkGray.cgColor
        phoneNumberButton.tintColor = .white
        phoneNumberButton.setImage(UIImage(systemName: "phone.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        phoneNumberButton.addTarget(self, action: #selector(phoneNumberButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: phoneNumberButton)
        
        operatingHoursLabel = PaddedLabel(withInsets: 1, 1, 5, 5)
        operatingHoursLabel.frame.size = CGSize(width: self.frame.width * 0.3, height: 40)
        operatingHoursLabel.font = getCustomFont(name: .Ubuntu_Regular, size: 18, dynamicSize: true)
        operatingHoursLabel.backgroundColor = bgColor
        operatingHoursLabel.textColor = appThemeColor
        operatingHoursLabel.textAlignment = .left
        operatingHoursLabel.adjustsFontForContentSizeCategory = true
        operatingHoursLabel.adjustsFontSizeToFitWidth = true
        operatingHoursLabel.layer.cornerRadius = operatingHoursLabel.frame.height/5
        operatingHoursLabel.layer.masksToBounds = true
        operatingHoursLabel.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        
        openingClosingHoursLabel = PaddedLabel(withInsets: 1, 1, 5, 5)
        openingClosingHoursLabel.frame.size = CGSize(width: self.frame.width * 0.3, height: 40)
        openingClosingHoursLabel.font = getCustomFont(name: .Ubuntu_Light, size: 18, dynamicSize: true)
        openingClosingHoursLabel.backgroundColor = bgColor
        openingClosingHoursLabel.textColor = fontColor
        openingClosingHoursLabel.textAlignment = .left
        openingClosingHoursLabel.adjustsFontForContentSizeCategory = true
        openingClosingHoursLabel.adjustsFontSizeToFitWidth = true
        openingClosingHoursLabel.layer.cornerRadius = openingClosingHoursLabel.frame.height/5
        openingClosingHoursLabel.layer.masksToBounds = true
        openingClosingHoursLabel.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        
        distanceLabel = PaddedLabel(withInsets: 1, 1, 5, 5)
        distanceLabel.frame.size = CGSize(width: self.frame.width * 0.3, height: 40)
        distanceLabel.font = getCustomFont(name: .Ubuntu_Light, size: 16, dynamicSize: true)
        distanceLabel.backgroundColor = bgColor
        distanceLabel.textColor = fontColor
        distanceLabel.textAlignment = .left
        distanceLabel.adjustsFontForContentSizeCategory = true
        distanceLabel.adjustsFontSizeToFitWidth = true
        distanceLabel.layer.cornerRadius = distanceLabel.frame.height/5
        distanceLabel.layer.masksToBounds = true
        distanceLabel.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        /** Placeholder text to give the label a dimension*/
        distanceLabel.text = "X.xx mi"
        /** Reveal this label only when a distance has been computed between the user and the location of this laundromat*/
        distanceLabel.alpha = 0
        
        totalReviewsLabel = PaddedLabel(withInsets: 1, 1, 5, 5)
        totalReviewsLabel.frame.size = CGSize(width: self.frame.width * 0.2, height: 40)
        totalReviewsLabel.font = getCustomFont(name: .Ubuntu_Regular, size: 12, dynamicSize: true)
        totalReviewsLabel.backgroundColor = .clear
        totalReviewsLabel.textColor = fontColor
        totalReviewsLabel.textAlignment = .left
        totalReviewsLabel.adjustsFontForContentSizeCategory = true
        totalReviewsLabel.adjustsFontSizeToFitWidth = true
        totalReviewsLabel.layer.cornerRadius = totalReviewsLabel.frame.height/2
        totalReviewsLabel.layer.borderColor = appThemeColor.cgColor
        totalReviewsLabel.layer.borderWidth = 0.5
        totalReviewsLabel.layer.masksToBounds = true
        totalReviewsLabel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        /** Reveal this label after the data for it has been loaded*/
        totalReviewsLabel.alpha = 1
        
        /** Attributed string with a system image in the front*/
        let imageAttachment2 = NSTextAttachment()
        imageAttachment2.image = UIImage(systemName: "person.3.fill")?.withTintColor(appThemeColor)
        
        let numberOfReviews = 0
        
        let attributedString2 = NSMutableAttributedString()
        attributedString2.append(NSAttributedString(attachment: imageAttachment2))
        attributedString2.append(NSMutableAttributedString(string: " \(numberOfReviews)"))
        totalReviewsLabel.attributedText = attributedString2
        
        favoriteButton = LottieButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40), lottieFile: "heart-like")
        favoriteButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        favoriteButton.backgroundColor = bgColor
        favoriteButton.tintColor = fontColor
        favoriteButton.layer.cornerRadius = favoriteButton.frame.height/2
        favoriteButton.castDefaultShadow()
        favoriteButton.layer.shadowColor = UIColor.darkGray.cgColor
        favoriteButton.isEnabled = true
        favoriteButton.isExclusiveTouch = true
        favoriteButton.addTarget(self, action: #selector(favoriteButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: favoriteButton)
        
        /** Reflect whether or not this laundromat has been favorited*/
        if favorited == true{
            favoriteButton.setAnimationFrameTo(this: 70)
        }
        else{
            favoriteButton.setAnimationFrameTo(this: 0)
        }
        
        averageRatings = RatingsCircleProgressView(frame: CGRect(x: 0, y: 0, width: (self.frame.width * 0.135), height: (self.frame.width * 0.135)), layerBackgroundColor: bgColor, completionPercentage: 0, trackColor: UIColor.white.darker, fillColor: UIColor.green, useGradientColor: true, centerLabelText: "0", centerLabelSubtitleText: "", centerLabelSecondarySubtitleText: "", centerLabelFontColor: fontColor, centerLabelSubtitleFontColor: fontColor, centerLabelSecondarySubtitleFontColor: fontColor, centerLabelFontSize: 20, centerLabelSubtitleFontSize: 14, centerLabelSecondarySubtitleFontSize: 14, displayCenterLabel: true, displayCenterLabelSubtitle: true, displayCenterLabelSecondarySubtitle: false)
        
        /** Don't animate the progress bar, set it statically*/
        averageRatings.progressAnimation(duration: 0)
        
        /** Reveal this item after the data for it has been loaded, this data can be retrieved using a listener to get fresh up to date info*/
        averageRatings.alpha = 1
        
        let result = getOpeningAndClosingTimes(operatingHoursMap: laundromatData.operatingHours)
        
        switch isWithinOperatingHours(operatingHoursMap: laundromatData.operatingHours){
        case true:
            operatingHoursLabel.text = "Open"
            operatingHoursLabel.textColor = appThemeColor
            openingClosingHoursLabel.text = "Closes: \(result.closingTime)"
        case false:
            operatingHoursLabel.text = "Closed"
            operatingHoursLabel.textColor = .red
            openingClosingHoursLabel.text = "Opens: \(result.openingTime)"
        }
        
        /** Resize the following views to fit their subviews*/
        operatingHoursLabel.sizeToFit()
        operatingHoursLabel.widthAnchor.constraint(equalToConstant: operatingHoursLabel.frame.width).isActive = true
        
        openingClosingHoursLabel.sizeToFit()
        openingClosingHoursLabel.widthAnchor.constraint(equalToConstant: openingClosingHoursLabel.frame.width).isActive = true
        
        distanceLabel.sizeToFit()
        distanceLabel.widthAnchor.constraint(equalToConstant: distanceLabel.frame.width).isActive = true
        
        nicknameLabel.sizeToFit()
        nicknameLabel.frame.size.width = self.frame.width * 0.9
        nicknameLabel.widthAnchor.constraint(equalToConstant: nicknameLabel.frame.width).isActive = true
        
        addressLabel.sizeToFit()
        addressLabel.frame.size.width = self.frame.width * 0.9
        addressLabel.widthAnchor.constraint(equalToConstant: addressLabel.frame.width).isActive = true
        
        /** Layout these subviews*/
        imageCarousel.frame.origin = CGPoint(x: 0, y: 0)
        
        dividingLine.frame.origin.y = imageCarousel.frame.maxY
        
        operatingHoursLabel.frame.origin = CGPoint(x: self.frame.minX, y: self.frame.minY + operatingHoursLabel.frame.height/3.5)
        
        openingClosingHoursLabel.frame.origin = CGPoint(x: self.frame.minX, y: operatingHoursLabel.frame.maxY + 10)
        
        distanceLabel.frame.origin = CGPoint(x: self.frame.minX, y: openingClosingHoursLabel.frame.maxY + 10)
        
        nicknameLabel.frame.origin = CGPoint(x: self.frame.width * 0.05, y: imageCarousel.frame.maxY + 10)
        
        addressLabel.frame.origin = CGPoint(x: self.frame.width * 0.05, y: nicknameLabel.frame.maxY + 10)
        
        favoriteButton.frame.origin = CGPoint(x: self.frame.maxX - (favoriteButton.frame.width * 1.25), y: self.frame.minY + favoriteButton.frame.height/3.5)
        
        averageRatings.frame.origin = CGPoint(x: self.frame.maxX - (averageRatings.frame.width * 1.15), y: self.frame.maxY - (averageRatings.frame.height * 1.15))
        
        /** Have a little overlap with the average ratings view*/
        totalReviewsLabel.frame.origin = CGPoint(x: averageRatings.frame.minX - (totalReviewsLabel.frame.width * 0.9), y: 0)
        totalReviewsLabel.center.y = averageRatings.center.y
        
        phoneNumberButton.frame.origin = CGPoint(x: self.frame.width * 0.05, y: 0)
        phoneNumberButton.center.y = totalReviewsLabel.center.y
        
        self.addSubview(container)
        container.addSubview(imageCarousel)
        container.addSubview(operatingHoursLabel)
        container.addSubview(distanceLabel)
        container.addSubview(openingClosingHoursLabel)
        container.addSubview(nicknameLabel)
        container.addSubview(addressLabel)
        container.addSubview(phoneNumberButton)
        container.addSubview(favoriteButton)
        container.addSubview(totalReviewsLabel)
        container.addSubview(averageRatings)
        container.addSubview(dividingLine)
    }
    
    /** Check to see if this laundromat location is on the favorites list*/
    func isFavorited()->Bool{
        var bool = false
        
        for index in 0..<favoriteLaundromats.count(){
            if self.laundromatData.storeID == favoriteLaundromats.nodeAt(index: index)?.value.laundromatID{
                bool = true
            }
        }
        
        return bool
    }
    
    /** Add this laundromat to the favorites list*/
    private func favorite(){
        let favoritedLaundromat = FavoriteLaundromat(creationDate: .now, laundromatID: self.laundromatData.storeID)
        favoritedLaundromat.addToFavoriteLaundromats()
    }
    
    /** Remove this laundromat from the favorites list*/
    private func unFavorite(){
        for index in 0..<favoriteLaundromats.count(){
            if self.laundromatData.storeID == favoriteLaundromats.nodeAt(index: index)?.value.laundromatID{
                favoriteLaundromats.nodeAt(index: index)?.value.removeFromFavoriteLaundromats()
            }
        }
    }
    
    /** Favorite this laundromat location*/
    @objc func favoriteButtonPressed(sender: LottieButton){
        successfulActionShake()
        
        if favorited == false{
            /** Start the animation and go to the middle since the middle is the 'complete' state and the end is the 'initial state'*/
            sender.playAnimation(from: 0, to: 70, with: .playOnce, animationSpeed: 2.5)
            favorited = true
            /** Add to favorites list and save updated record*/
            favorite()
            
            globallyTransmit(this: "Added to favorites", with: UIImage(systemName: "heart.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: appThemeColor, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 2, selfDismiss: true)
        }
        else{
            /** Complete the animation since it reverses at the end anyways*/
            sender.playAnimation(from: 70, to: 125, with: .playOnce, animationSpeed: 2.5)
            favorited = false
            /** Remove from favorites list and save updated record*/
            unFavorite()
            
            globallyTransmit(this: "Removed from favorites", with: UIImage(systemName: "heart.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 2, selfDismiss: true)
        }
    }
    
    /** Call the phone number of the laundromat location associated with this data*/
    @objc func phoneNumberButtonPressed(sender: UIButton){
        lightHaptic()
        
        guard let number = URL(string: "tel://" + String(laundromatData.phoneNumber.nationalNumber)) else { return }
            UIApplication.shared.open(number)
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        false
    }
    
    /** Open the tapped address in the maps app*/
    @objc func addressLabelTapped(sender: UITapGestureRecognizer){
        lightHaptic()
        
        displayMapOptionAlert()
    }
    
    /** Display an alert that gives the user the option to open up the available coordinates for the laundromat location in either google maps or apple maps (default)*/
    func displayMapOptionAlert(){
        let alert = JCAlertController(title: "Choose a maps service", message: "Which app would you like to use to find this address?", preferredStyle: .actionSheet)
        
        /** Open the address in Apple maps (if available)*/
        let appleMaps = UIAction(title: "Apple Maps", handler: { [weak self] (action) in
            /**Capture self to avoid retain cycles*/
            guard let self = self else{
                return
            }
            
            if (UIApplication.shared.canOpenURL(URL(string:"http://maps.apple.com/")!)) {
                guard let location = URL(string: "http://maps.apple.com/?daddr=" + "\(self.laundromatData.coordinates.latitude),\(self.laundromatData.coordinates.longitude)") else { return }
                
                UIApplication.shared.open(location)
            }
            else{
                /** Can't open that URL, app not available*/
                globallyTransmit(this: "Apple Maps is unavailable", with: UIImage(systemName: "globe.americas.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
            }
        })
        
        /** Open the address in google maps (if available)*/
        let googleMaps = UIAction(title: "Google Maps", handler: { [weak self] (action) in
            /**Capture self to avoid retain cycles*/
            guard let self = self else{
                return
            }
            
            if (UIApplication.shared.canOpenURL(URL(string:"https://www.google.com/maps/")!)) {
                guard let location = URL(string: "https://www.google.com/maps/?center=\(self.laundromatData.coordinates.latitude),\(self.laundromatData.coordinates.longitude)&zoom=15&views=traffic&q=\(self.laundromatData.address.streetAddress1.replacingOccurrences(of: " ", with: "+"))") else { return }
                
                UIApplication.shared.open(location)
            }
            else{
                /** Can't open that URL, app not available*/
                globallyTransmit(this: "Google Maps is unavailable", with: UIImage(systemName: "globe.americas.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
            }
        })
        
        let cancelAction = UIAction(title: "Cancel", handler: {_ in })
        
        alert.addAction(action: appleMaps, with: .default)
        alert.addAction(action: googleMaps, with: .default)
        alert.addAction(action: cancelAction, with: .cancel)
        alert.modalPresentationStyle = .overFullScreen
        alert.bottomButtonBackgroundColor = appThemeColor
        alert.bottomButtonFontColor = .white
        presentingVC.present(alert, animated: true)
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
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/** Get the corresponding opening and closing times relevant to the current day of the week*/
func getOpeningAndClosingTimes(operatingHoursMap: [String : String])->(openingTime: String, closingTime: String){
    var closingTimeString = ""
    var openingTimeString = ""
    
    /** Make sure the given dictionary does contain the following keys*/
    guard operatingHoursMap["Fri-Sun"] != nil &&  operatingHoursMap["Mon-Thurs"] != nil else {
        return (openingTimeString,closingTimeString)
    }
    
    /** Friday - Sunday Hours*/
    let timeInterval1 = operatingHoursMap["Fri-Sun"]
    
    /** Monday - Thursday Hours*/
    let timeInterval2 = operatingHoursMap["Mon-Thurs"]
    
    /** The time interval corresponding to the current time*/
    var targetTimeInterval = ""

    /** Get the current day of the week*/
    let date = Date.now
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "EEEE"
    let dayOfTheWeekString = dateFormatter.string(from: date)
    
    /** A dictionary of days of the week and the corresponding interval that they're associated with*/
    let dayOfTheWeekDictionary = ["Friday":"Fri-Sun","Saturday":"Fri-Sun","Sunday":"Fri-Sun","Monday":"Mon-Thurs","Tuesday":"Mon-Thurs","Wednesday":"Mon-Thurs","Thursday":"Mon-Thurs"]
    
    /** Determine which time interval the current day of the week lies in*/
    if dayOfTheWeekDictionary[dayOfTheWeekString] == "Mon-Thurs"{
        targetTimeInterval = timeInterval2!
    }
    else if dayOfTheWeekDictionary[dayOfTheWeekString] == "Fri-Sun"{
        targetTimeInterval = timeInterval1!
    }
    else{
        /** Default to Mon-Thurs if all else fails*/
        targetTimeInterval = timeInterval2!
    }
    
    /** If the current day is Sunday or Thursday then change the opening time to follow the other interval since only the opening times differ*/
    if dayOfTheWeekString == "Sunday"{
        
        /** Loop over to the next day's opening time when the store is closed on a thursday or sunday as these are the days when the opening / closing times change the day after*/
        var closingTime = ""
        /** Detect when the dash in the middle has been reached*/
        var separatorReached = false
        
        /** Opening times come first and closing times come second*/
        for char in targetTimeInterval{
            if char == "-" && separatorReached == false{
                separatorReached = true
            }
            
            if char != " " && char != "-" && separatorReached == true{
                closingTime.append(char)
            }
            
        }
        
        /** Create a formatter to format the date in a 12 hour format*/
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
    
        let time = formatter.date(from: closingTime)
        
        var currentTime = Date.now
        let currentTimeString = formatter.string(from: date)
        currentTime = formatter.date(from: currentTimeString)!
        
        if currentTime > time!{
        targetTimeInterval = timeInterval2!
        }
    }
    else if dayOfTheWeekString == "Thursday"{
        
        /** Loop over to the next day's opening time when the store is closed on a thursday or sunday as these are the days when the opening / closing times change the day after*/
        var closingTime = ""
        /** Detect when the dash in the middle has been reached*/
        var separatorReached = false
        
        /** Opening times come first and closing times come second*/
        for char in targetTimeInterval{
            if char == "-" && separatorReached == false{
                separatorReached = true
            }
            
            if char != " " && char != "-" && separatorReached == true{
                closingTime.append(char)
            }
            
        }
        
        /** Create a formatter to format the date in a 12 hour format*/
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
    
        let time = formatter.date(from: closingTime)
        
        var currentTime = Date.now
        let currentTimeString = formatter.string(from: date)
        currentTime = formatter.date(from: currentTimeString)!
        
        if currentTime > time!{
        targetTimeInterval = timeInterval1!
        }
    }
    
    /** Two variables for storing the opening and closing times stored by the target time interval string*/
    var openingTime = ""
    var closingTime = ""
    /** Detect when the dash in the middle has been reached*/
    var separatorReached = false
    
    /** Opening times come first and closing times come second*/
    for char in targetTimeInterval{
        if char != " " && char != "-" && separatorReached == false{
            openingTime.append(char)
        }
        
        if char == "-" && separatorReached == false{
            separatorReached = true
        }
        
        if char != " " && char != "-" && separatorReached == true{
            closingTime.append(char)
        }
    }
    
    /** Create a formatter to format the date in a 12 hour format*/
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mma"
    
    let time1 = formatter.date(from: openingTime)
    let time2 = formatter.date(from: closingTime)
    
    /** Format the date in a more comfortable format*/
    let secondaryFormatter = DateFormatter()
    secondaryFormatter.dateFormat = "h:mm a"
    
    /** Make sure all of the dates are not nil*/
    guard time1 != nil && time2 != nil else {
        return (openingTimeString,closingTimeString)
    }
    
    openingTimeString = secondaryFormatter.string(from: time1!)
    closingTimeString = secondaryFormatter.string(from: time2!)
    
    return (openingTimeString,closingTimeString)
}

/** Parse the operating hours stored by the operating hours map and compare the times and days to the current date*/
func isWithinOperatingHours(operatingHoursMap: [String : String])->Bool{
    var withinOperatingHours = false
    
    /** Make sure the given dictionary does contain the following keys*/
    guard operatingHoursMap["Fri-Sun"] != nil &&  operatingHoursMap["Mon-Thurs"] != nil else {
        return withinOperatingHours
    }
    
    /** Friday - Sunday Hours*/
    let timeInterval1 = operatingHoursMap["Fri-Sun"]
    
    /** Monday - Thursday Hours*/
    let timeInterval2 = operatingHoursMap["Mon-Thurs"]
    
    /** The time interval corresponding to the current time*/
    var targetTimeInterval = ""

    /** Get the current day of the week*/
    let date = Date.now
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "EEEE"
    let dayOfTheWeekString = dateFormatter.string(from: date)
    
    /** A dictionary of days of the week and the corresponding interval that they're associated with*/
    let dayOfTheWeekDictionary = ["Friday":"Fri-Sun","Saturday":"Fri-Sun","Sunday":"Fri-Sun","Monday":"Mon-Thurs","Tuesday":"Mon-Thurs","Wednesday":"Mon-Thurs","Thursday":"Mon-Thurs"]
    
    /** Determine which time interval the current day of the week lies in*/
    if dayOfTheWeekDictionary[dayOfTheWeekString] == "Mon-Thurs"{
        targetTimeInterval = timeInterval2!
    }
    else if dayOfTheWeekDictionary[dayOfTheWeekString] == "Fri-Sun"{
        targetTimeInterval = timeInterval1!
    }
    else{
        /** Default to Mon-Thurs if all else fails*/
        targetTimeInterval = timeInterval2!
    }
    
    /** Two variables for storing the opening and closing times stored by the target time interval string*/
    var openingTime = ""
    var closingTime = ""
    /** Detect when the dash in the middle has been reached*/
    var separatorReached = false
    
    /** Opening times come first and closing times come second*/
    for char in targetTimeInterval{
        if char != " " && char != "-" && separatorReached == false{
            openingTime.append(char)
        }
        
        if char == "-" && separatorReached == false{
            separatorReached = true
        }
        
        if char != " " && char != "-" && separatorReached == true{
            closingTime.append(char)
        }
        
    }
    
    /** Create a formatter to format the date in a 12 hour format*/
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mma"
    
    let time1 = formatter.date(from: openingTime)
    let time2 = formatter.date(from: closingTime)
    
    var currentTime = date
    let currentTimeString = formatter.string(from: date)
    currentTime = formatter.date(from: currentTimeString)!
    
    /** Make sure all of the dates are not nil*/
    guard time1 != nil && time2 != nil else {
        return withinOperatingHours
    }
 
    if currentTime >= time1! && currentTime <= time2!{
        withinOperatingHours = true
    }
    
    return withinOperatingHours
}
