//
//  MapUI.swift
//  Stuy Wash N Dry
//
//  Created by Justin Cook on 3/24/22.
//

import UIKit
import CoreLocation
/** Contains the custom UI elements for the mapview*/

/** UIView subclass that acts as a custom UIView for the map markers*/
public class LaundromatIconView: UIView{
    /** The image to be displayed by the icon*/
    var image: UIImage
    /** The string to be displayed by the icon*/
    var title: String
    
    /** Image view displaying an image for this marker icon*/
    var imageView = UIImageView()
    /** Label describing the context of the marker*/
    var titleLabelView = PaddedLabel(withInsets: 1, 1, 5, 5)
    /** Shadow behind the title label*/
    var shadowView = UIView()
    
    init(image: UIImage, title: String) {
        self.image = image
        self.title = title
        
        /** Init the view with a generic square dimension*/
        super.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        
        construct()
    }
    
    /** Create the UI components and add them to the parent view*/
    func construct(){
        imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: self.frame.height/2, height: self.frame.height/2))
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        imageView.image = image
        imageView.layer.cornerRadius = imageView.frame.height/2
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 2
        imageView.clipsToBounds = true
        
        titleLabelView.frame.size = CGSize(width: self.frame.width * 0.95, height: self.frame.height/2)
        /** Replace the | divider with a new line character to make the title look seamless*/
        titleLabelView.text = title.replacingOccurrences(of: "|", with: "\n")
        titleLabelView.font = getCustomFont(name: .Ubuntu_Medium, size: 18, dynamicSize: false)
        switch darkMode {
        case true:
            titleLabelView.backgroundColor = .black
        case false:
            titleLabelView.backgroundColor = bgColor
        }
        titleLabelView.textColor = fontColor
        titleLabelView.textAlignment = .center
        titleLabelView.numberOfLines = 2
        titleLabelView.lineBreakMode = .byClipping
        titleLabelView.adjustsFontForContentSizeCategory = false
        titleLabelView.adjustsFontSizeToFitWidth = true
        titleLabelView.layer.cornerRadius = titleLabelView.frame.height/4
        titleLabelView.layer.masksToBounds = true
        titleLabelView.sizeToFit()
        titleLabelView.translatesAutoresizingMaskIntoConstraints = false
        
        shadowView = UIView(frame: titleLabelView.frame)
        shadowView.layer.cornerRadius = titleLabelView.layer.cornerRadius
        shadowView.layer.shadowColor = UIColor.darkGray.cgColor
        shadowView.layer.shadowOpacity = 0.25
        shadowView.layer.shadowRadius = 2
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 2)
        shadowView.layer.masksToBounds = true
        shadowView.clipsToBounds = false
        shadowView.addSubview(titleLabelView)
        
        titleLabelView.widthAnchor.constraint(equalToConstant: shadowView.frame.width).isActive = true
        
        /** The frame of the titleLabelView is out of bounds in terms of width so a bounding rectangle must be constructed manually*/
        shadowView.layer.shadowPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: shadowView.frame.width, height: titleLabelView.frame.height), cornerRadius: shadowView.layer.cornerRadius).cgPath
        
        /** Layout these subviews*/
        imageView.frame.origin = CGPoint(x: self.frame.width/2 - imageView.frame.width/2, y: 0)
        
        titleLabelView.frame.origin = CGPoint(x: shadowView.frame.width/2 - titleLabelView.frame.width/2, y: shadowView.frame.height/2 - titleLabelView.frame.height/2)
        
        shadowView.frame.origin = CGPoint(x: self.frame.width/2 - shadowView.frame.width/2, y: imageView.frame.maxY + 5)
        
        /** Add the subviews to the view hierarchy*/
        self.addSubview(imageView)
        self.addSubview(shadowView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/** UIView subclass that displays an icon depicting the user's address for a specified location on the map, this object will be used as the subview for a map marker, contains address information, and parsed coordinates, as well as an icon depicting what kind of address this is, home, business etc. When this view is pressed then a small separate view can be displayed with the full address information above it if necessary via delegation*/
public class AddressIconView: UIView{
    /** Where this user is located*/
    var address: Address
    /** What kind of address this is*/
    var addressType: AddressType!
    /** The coordinates of the given address*/
    var coordinates: CLLocation!
    /** Display an icon of the address type*/
    var imageView: UIImageView!
    /** Label describing the address*/
    var label: PaddedLabel!
    /** Button that allows the user to edit the address and or delete it*/
    var editButton: UIButton!
    
    init(address: Address){
        self.address = address
        
        /** Init the view with a generic square dimension*/
        super.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        
        construct()
    }
    
    /** Construct the corresponding UI associated with this UIView*/
    func construct(){
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/** For the user to specify what kind of address the given address is*/
public enum AddressType: Int{
    case home = 0
    case business = 1
    case other = 2
}
