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
        
        titleLabelView.frame.size = CGSize(width: self.frame.width * 0.95, height: self.frame.height * 0.4)
        /** Replace the | divider with a new line character to make the title look seamless*/
        titleLabelView.text = title.replacingOccurrences(of: "|", with: "\n")
        titleLabelView.font = getCustomFont(name: .Ubuntu_Medium, size: 16, dynamicSize: false)
        titleLabelView.backgroundColor = darkMode ? bgColor.lighter : bgColor
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
        titleLabelView.layer.borderWidth = 1
        titleLabelView.layer.borderColor = darkMode ? UIColor.darkGray.cgColor : UIColor.lightGray.cgColor
        
        shadowView = UIView(frame: titleLabelView.frame)
        shadowView.addSubview(titleLabelView)
        
        titleLabelView.widthAnchor.constraint(equalToConstant: shadowView.frame.width).isActive = true
        
        /** Layout these subviews*/
        titleLabelView.frame.origin = CGPoint(x: shadowView.frame.width/2 - titleLabelView.frame.width/2, y: shadowView.frame.height/2 - titleLabelView.frame.height/2)
        
        shadowView.frame.origin = CGPoint(x: self.frame.width/2 - shadowView.frame.width/2, y: self.frame.maxY - (shadowView.frame.height + self.frame.height * 0.05))
        
        imageView.frame.origin = CGPoint(x: self.frame.width/2 - imageView.frame.width/2, y: shadowView.frame.minY - (imageView.frame.height + self.frame.height * 0.05))
        
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
    /** The image to be displayed by the icon*/
    var image: UIImage
    /** The string to be displayed by the icon*/
    var title: String
    
    /** Where this user is located*/
    var address: Address
    /** What kind of address this is*/
    var addressType: AddressType!
    /** The coordinates of the given address*/
    var coordinates: CLLocation!
    /** Display an icon of the address type*/
    var imageView: UIImageView!
    /** Label describing the address*/
    var titleLabelView = PaddedLabel(withInsets: 1, 1, 5, 5)
    /** Button that allows the user to edit the address and or delete it*/
    var editButton: UIButton!
    /** Shadow behind the title label*/
    var shadowView = UIView()
    
    init(address: Address){
        self.address = address
        self.title = address.streetAddress1
        self.image = getImageFor(this: address.addressType)
        
        /** Init the view with a generic square dimension*/
        super.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        
        construct()
    }
    
    /** Construct the corresponding UI associated with this UIView*/
    func construct(){
        imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: self.frame.height/2, height: self.frame.height/2))
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        imageView.image = image
        imageView.layer.cornerRadius = imageView.frame.height/2
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 2
        imageView.clipsToBounds = true
        
        titleLabelView.frame.size = CGSize(width: self.frame.width * 0.95, height: self.frame.height * 0.4)
        titleLabelView.text = address.streetAddress1
        titleLabelView.font = getCustomFont(name: .Ubuntu_Medium, size: 16, dynamicSize: false)
        titleLabelView.backgroundColor = darkMode ? bgColor.lighter : bgColor
        titleLabelView.textColor = fontColor
        titleLabelView.textAlignment = .center
        /** More characters more lines*/
        titleLabelView.numberOfLines = titleLabelView.text!.count <= 20 ? 1 : 2
        titleLabelView.lineBreakMode = .byClipping
        titleLabelView.adjustsFontForContentSizeCategory = false
        titleLabelView.adjustsFontSizeToFitWidth = true
        ///titleLabelView.sizeToFit()
        titleLabelView.layer.masksToBounds = true
        titleLabelView.clipsToBounds = true
        titleLabelView.layer.cornerRadius = titleLabelView.frame.height/4
        titleLabelView.translatesAutoresizingMaskIntoConstraints = false
        titleLabelView.layer.borderWidth = 1
        titleLabelView.layer.borderColor = darkMode ? UIColor.darkGray.cgColor : UIColor.lightGray.cgColor
        
        shadowView = UIView(frame: titleLabelView.frame)
        shadowView.addSubview(titleLabelView)
        
        titleLabelView.widthAnchor.constraint(equalToConstant: shadowView.frame.width).isActive = true
        
        /** Layout these subviews*/
        titleLabelView.frame.origin = CGPoint(x: shadowView.frame.width/2 - titleLabelView.frame.width/2, y: shadowView.frame.height/2 - titleLabelView.frame.height/2)
        
        shadowView.frame.origin = CGPoint(x: self.frame.width/2 - shadowView.frame.width/2, y: self.frame.maxY - (shadowView.frame.height + self.frame.height * 0.05))
        
        imageView.frame.origin = CGPoint(x: self.frame.width/2 - imageView.frame.width/2, y: shadowView.frame.minY - (imageView.frame.height + self.frame.height * 0.05))
        
        /** Add the subviews to the view hierarchy*/
        self.addSubview(imageView)
        self.addSubview(shadowView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/** UIView displaying basic properties about the given address object
 - Parameter address: The address nformation to reflect in this panel*/
public class AddressInformationPanel: UIView{
    /** The information to reflect in this panel*/
    var address: Address!
    
    /** UI Elements*/
    private var container: UIView!
    private var imageView: UIImageView!
    private var addressTypeLabel: PaddedLabel!
    private var aliasLabel: PaddedLabel!
    private var streetAddress1Label: PaddedLabel!
    private var streetAddress2Label: PaddedLabel!
    private var boroughLabel: PaddedLabel!
    private var zipCodeLabel: PaddedLabel!
    private var coordinatesLabel: UILabel!
    
    override init(frame: CGRect) {
    super.init(frame: frame)
    }
    
    /** Specify the address to be reflected by this panel*/
    func build(with address: Address){
        self.address = address
        construct()
    }
    
    private func construct(){
        /** The parent view acts as a shadow for the container*/
        self.backgroundColor = .clear
        self.layer.masksToBounds = true
        self.clipsToBounds = false
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.cornerRadius = self.frame.height/4
        self.layer.shadowOpacity = 0.5
        self.layer.shadowRadius = self.frame.height/4
        self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: self.layer.cornerRadius).cgPath
        self.layer.shadowOffset = CGSize(width: 0, height: 2)
        
        container = UIView(frame: self.frame)
        container.backgroundColor = bgColor
        container.layer.cornerRadius = container.frame.height/5
        container.layer.borderColor = UIColor.darkGray.cgColor
        container.layer.borderWidth =  1
        container.clipsToBounds = true
        
        imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: container.frame.width, height: container.frame.width * 0.25))
        imageView.contentMode = .scaleAspectFit
        imageView.image = getImageFor(this: address.addressType)
        imageView.backgroundColor = .white
        imageView.clipsToBounds = true
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor =  appThemeColor.cgColor
        imageView.tintColor = appThemeColor
        
        addressTypeLabel = PaddedLabel(withInsets: 1, 1, 5, 5)
        addressTypeLabel.frame = CGRect(x: 0, y: 0, width: container.frame.width * 0.225, height: (container.frame.height * 0.2))
        addressTypeLabel.backgroundColor = appThemeColor
        addressTypeLabel.textColor = .white
        addressTypeLabel.font = getCustomFont(name: .Ubuntu_Regular, size: 16, dynamicSize: true)
        addressTypeLabel.adjustsFontSizeToFitWidth = true
        addressTypeLabel.adjustsFontForContentSizeCategory = true
        addressTypeLabel.text = address.addressType.toString()
        addressTypeLabel.tintColor = .white
        addressTypeLabel.textAlignment = .center
        addressTypeLabel.clipsToBounds = true
        addressTypeLabel.sizeToFit()
        addressTypeLabel.layer.cornerRadius = addressTypeLabel.frame.height/2
        
        aliasLabel = PaddedLabel(withInsets: 1, 1, 5, 5)
        aliasLabel.frame = CGRect(x: 0, y: 0, width: container.frame.width * 0.225, height: (container.frame.height * 0.2))
        aliasLabel.backgroundColor = appThemeColor
        aliasLabel.textColor = .white
        aliasLabel.text = address.alias
        aliasLabel.font = getCustomFont(name: .Ubuntu_Regular, size: 16, dynamicSize: true)
        aliasLabel.adjustsFontSizeToFitWidth = true
        aliasLabel.adjustsFontForContentSizeCategory = true
        aliasLabel.tintColor = .white
        aliasLabel.textAlignment = .center
        aliasLabel.clipsToBounds = true
        aliasLabel.sizeToFit()
        /** Hide the label if the alias label has no text*/
        aliasLabel.alpha = address.alias != "" ? 1 : 0
        aliasLabel.layer.cornerRadius = aliasLabel.frame.height/2
        
        boroughLabel = PaddedLabel(withInsets: 1, 1, 5, 5)
        boroughLabel.frame = CGRect(x: 0, y: 0, width: container.frame.width * 0.225, height: (container.frame.height * 0.2))
        boroughLabel.backgroundColor = appThemeColor
        boroughLabel.textColor = .white
        boroughLabel.font = getCustomFont(name: .Ubuntu_Regular, size: 16, dynamicSize: true)
        boroughLabel.adjustsFontSizeToFitWidth = true
        boroughLabel.adjustsFontForContentSizeCategory = true
        boroughLabel.text = address.borough.rawValue
        boroughLabel.tintColor = .white
        boroughLabel.textAlignment = .center
        boroughLabel.clipsToBounds = true
        boroughLabel.sizeToFit()
        boroughLabel.layer.cornerRadius = boroughLabel.frame.height/2
        
        zipCodeLabel = PaddedLabel(withInsets: 1, 1, 5, 5)
        zipCodeLabel.frame = CGRect(x: 0, y: 0, width: container.frame.width * 0.225, height: (container.frame.height * 0.2))
        zipCodeLabel.backgroundColor = appThemeColor
        zipCodeLabel.textColor = .white
        zipCodeLabel.text = address.zipCode.description
        zipCodeLabel.font = getCustomFont(name: .Ubuntu_Regular, size: 16, dynamicSize: true)
        zipCodeLabel.adjustsFontSizeToFitWidth = true
        zipCodeLabel.adjustsFontForContentSizeCategory = true
        zipCodeLabel.tintColor = .white
        zipCodeLabel.textAlignment = .center
        zipCodeLabel.clipsToBounds = true
        zipCodeLabel.sizeToFit()
        zipCodeLabel.layer.cornerRadius = zipCodeLabel.frame.height/2
        
        streetAddress1Label = PaddedLabel(withInsets: 1, 1, 5, 5)
        streetAddress1Label.frame = CGRect(x: 0, y: 0, width: container.frame.width * 0.25, height: (container.frame.height * 0.2))
        streetAddress1Label.backgroundColor = .lightGray
        streetAddress1Label.textColor = .white
        streetAddress1Label.text = address.streetAddress1
        streetAddress1Label.font = getCustomFont(name: .Ubuntu_Regular, size: 18, dynamicSize: true)
        streetAddress1Label.adjustsFontSizeToFitWidth = true
        streetAddress1Label.adjustsFontForContentSizeCategory = true
        streetAddress1Label.tintColor = .white
        streetAddress1Label.textAlignment = .center
        streetAddress1Label.clipsToBounds = true
        streetAddress1Label.sizeToFit()
        streetAddress1Label.layer.cornerRadius = streetAddress1Label.frame.height/2
        
        streetAddress2Label = PaddedLabel(withInsets: 1, 1, 5, 5)
        streetAddress2Label.frame = CGRect(x: 0, y: 0, width: container.frame.width * 0.25, height: (container.frame.height * 0.2))
        streetAddress2Label.backgroundColor = .lightGray
        streetAddress2Label.textColor = .white
        streetAddress2Label.text = address.streetAddress2
        streetAddress2Label.font = getCustomFont(name: .Ubuntu_Regular, size: 18, dynamicSize: true)
        streetAddress2Label.adjustsFontSizeToFitWidth = true
        streetAddress2Label.adjustsFontForContentSizeCategory = true
        streetAddress2Label.tintColor = .white
        streetAddress2Label.textAlignment = .center
        streetAddress2Label.clipsToBounds = true
        streetAddress2Label.sizeToFit()
        /** Hide the label if the label has no text*/
        streetAddress2Label.alpha = address.streetAddress2 != "" ? 1 : 0
        streetAddress2Label.layer.cornerRadius = streetAddress2Label.frame.height/2
        
        coordinatesLabel = UILabel()
        coordinatesLabel.frame = CGRect(x: 0, y: 0, width: container.frame.width * 0.25, height: (container.frame.height * 0.2))
        coordinatesLabel.backgroundColor = .clear
        coordinatesLabel.textColor = fontColor
        
        /** Ensure that the coordinates aren't nil*/
        if address.coordinates?.latitude != nil && address.coordinates?.longitude != nil{
        coordinatesLabel.text = "Longitude: \(address.coordinates!.longitude) Latitude: \(address.coordinates!.latitude)"
        }
        else{
        coordinatesLabel.text = ""
        coordinatesLabel.alpha = 0
        }
        
        coordinatesLabel.attributedText = coordinatesLabel.attribute(this: coordinatesLabel.text!, font: getCustomFont(name: .Ubuntu_Regular, size: 15, dynamicSize: true), mainColor: fontColor, subColor: .lightGray, subStrings: ["Longitude","Latitude"])
        coordinatesLabel.adjustsFontSizeToFitWidth = true
        coordinatesLabel.adjustsFontForContentSizeCategory = true
        coordinatesLabel.tintColor = .white
        coordinatesLabel.textAlignment = .center
        coordinatesLabel.clipsToBounds = true
        coordinatesLabel.sizeToFit()
        coordinatesLabel.layer.cornerRadius = coordinatesLabel.frame.height/2
        
        /** Layout these subviews*/
        container.frame.origin = CGPoint(x: self.frame.width/2 - container.frame.width/2, y: self.frame.height/2 - container.frame.height/2)
        
        /** Working with 1 - 0.35 - 0.65, so 0.6for everything else*/
        imageView.frame.origin = CGPoint(x: 0, y: 0)
        
        //0.25 + 0.2 + 0.025 + 0.025 -> 0.5 -> 0.475 left
        addressTypeLabel.frame.origin = CGPoint(x: container.frame.width * 0.025, y: imageView.frame.maxY - container.frame.height * 0.05)
        
        aliasLabel.frame.origin = CGPoint(x: addressTypeLabel.frame.maxX + container.frame.width * 0.025, y: 0)
        aliasLabel.center.y = addressTypeLabel.center.y
        
        boroughLabel.frame.origin = CGPoint(x: aliasLabel.frame.maxX + container.frame.width * 0.025, y: 0)
        boroughLabel.center.y = aliasLabel.center.y
        
        zipCodeLabel.frame.origin = CGPoint(x: boroughLabel.frame.maxX + container.frame.width * 0.025, y: 0)
        zipCodeLabel.center.y = aliasLabel.center.y
        
        streetAddress1Label.frame.origin = CGPoint(x: addressTypeLabel.frame.minX, y: addressTypeLabel.frame.maxY + container.frame.height * 0.025)
        
        streetAddress2Label.frame.origin = CGPoint(x: addressTypeLabel.frame.minX, y: streetAddress1Label.frame.maxY + container.frame.height * 0.025)
        
        coordinatesLabel.frame.origin = address.streetAddress2 != "" ? CGPoint(x: addressTypeLabel.frame.minX, y: streetAddress2Label.frame.maxY + container.frame.height * 0.025) : CGPoint(x: addressTypeLabel.frame.minX, y: streetAddress1Label.frame.maxY + container.frame.height * 0.025)
        
        self.addSubview(container)
        container.addSubview(imageView)
        container.addSubview(addressTypeLabel)
        container.addSubview(aliasLabel)
        container.addSubview(streetAddress1Label)
        container.addSubview(streetAddress2Label)
        container.addSubview(boroughLabel)
        container.addSubview(zipCodeLabel)
        container.addSubview(coordinatesLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/** Return a layer with a grid of lines forming a tile grid array for the mapview to display when the tiles aren't loaded yet
 - Parameter backgroundColor: The desired color of the tile grid array
 - Parameter lineWidth: The width of each line in the grid
 - Parameter lineColor: The color of the grid's lines
 - Parameter lineSpacing: Spacing between each line, X and Y
 - Parameter gridDimesions: The desired dimensions of the grid, the lines will only be rendered within this space
 - Parameter animated: Determine whether or not the lines should be drawn onto the screen when first displayed*/
func drawTileGrid(backgroundColor: UIColor, lineWidth: CGFloat, lineColor: UIColor, lineSpacing: CGSize, gridDimesions: CGFloat, animated: Bool)->CALayer{
    let parentLayer = CALayer()
    
    return parentLayer
}

/** Grid of intersecting vertical and horizontal lines displayed in a CALayer*/
public class MapViewTileGrid: CALayer{
    /** The desired color of the tile grid array*/
    var lineWidth: CGFloat!
    /** The color of the grid's lines*/
    var lineColor: UIColor!
    /** Spacing between each line, X and Y*/
    var lineSpacing: CGSize!
    /** The desired dimensions of the grid, the lines will only be rendered within this space*/
    var gridDimesions: CGSize!
    /** Keep track of all the horizontal lines from top to bottom in order*/
    var horizontalLines: [CAShapeLayer] = []
    /** Keep track of all the vertical lines left to right in order*/
    var verticalLines: [CAShapeLayer] = []
    
    /** Create a CALayer with a grid of lines forming a tile grid array for the mapview to display when the tiles aren't loaded yet
     - Parameter backgroundColor: The desired color of the tile grid array
     - Parameter lineWidth: The width of each line in the grid
     - Parameter lineColor: The color of the grid's lines
     - Parameter lineSpacing: Spacing between each line, X and Y
     - Parameter gridDimesions: The desired dimensions of the grid, the lines will only be rendered within this space*/
    init(backgroundColor: UIColor, lineWidth: CGFloat, lineColor: UIColor, lineSpacing: CGSize, gridDimesions: CGSize){
        self.lineWidth = lineWidth
        self.lineColor = lineColor
        self.lineSpacing = lineSpacing
        self.gridDimesions = gridDimesions
        
        super.init()
        self.backgroundColor = backgroundColor.cgColor
        
        construct()
    }
    
    private func construct(){
        /** Calculate the amount of lines to display given the dimensions, line width and line spacing*/
        let verticalLineCount = Int(gridDimesions.width/(lineWidth + lineSpacing.width))
        let horizontalLineCount = Int(gridDimesions.height/(lineWidth + lineSpacing.height))
        
        /** Start at 1 because the line must be offset from the edge of the container by the given spacing*/
        for int in 1..<(verticalLineCount + 1){
            let line = CAShapeLayer()
            line.path = CGPath(rect: CGRect(x: lineSpacing.width * CGFloat(int), y: 0, width: lineWidth, height: gridDimesions.height), transform: nil)
            line.frame.size = CGSize(width: lineWidth, height: gridDimesions.height)
            /** Don't enable the fill color if you want to draw the line from scratch, the line will have ghosting as we only want to animate the stroke being drawn*/
            line.fillColor = lineColor.withAlphaComponent(0.1).cgColor
            line.lineCap = .round
            line.strokeColor = lineColor.withAlphaComponent(0.5).cgColor
            line.lineWidth = lineWidth
            
            self.addSublayer(line)
            
            verticalLines.append(line)
        }
        
        for int in 1..<(horizontalLineCount + 1){
            let line = CAShapeLayer()
            line.path = CGPath(rect: CGRect(x: 0, y: lineSpacing.height * CGFloat(int), width: gridDimesions.width, height: lineWidth), transform: nil)
            line.frame.size = CGSize(width: lineWidth, height: gridDimesions.height)
            line.fillColor = lineColor.withAlphaComponent(0.1).cgColor
            line.lineCap = .round
            line.strokeColor = lineColor.withAlphaComponent(0.5).cgColor
            line.lineWidth = lineWidth
            
            self.addSublayer(line)
            
            horizontalLines.append(line)
        }
        
        /** Orient the arrays in a FIFO order*/
        verticalLines.reverse()
        horizontalLines.reverse()
    }
    
    /** Animate the grid being deconstructed from its current state in the animation tree*/
    func animateErasing(with duration: CGFloat){
        for (index, line) in horizontalLines.enumerated(){
            /** Set the line's end point to it's end point*/
            line.strokeEnd = 1
            
            /** Animate each line with a slight delay calculated by dividing the total duration by the number of lines*/
            DispatchQueue.main.asyncAfter(deadline: .now() + duration/CGFloat(index + 1)){
            let strokeEndAnim = CABasicAnimation(keyPath: #keyPath(CAShapeLayer.strokeEnd))
            strokeEndAnim.fromValue = 1
            strokeEndAnim.toValue = 0
            strokeEndAnim.duration = duration
            strokeEndAnim.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            strokeEndAnim.isRemovedOnCompletion = false
            strokeEndAnim.fillMode = .forwards
            
            line.add(strokeEndAnim, forKey: "strokeEnd")
            }
        }
        
        for (index, line) in verticalLines.enumerated(){
            line.strokeEnd = 1
            
            DispatchQueue.main.asyncAfter(deadline: .now() + duration/CGFloat(index + 1)){
            let strokeEndAnim = CABasicAnimation(keyPath: #keyPath(CAShapeLayer.strokeEnd))
            strokeEndAnim.fromValue = 1
            strokeEndAnim.toValue = 0
            strokeEndAnim.duration = duration + 1
            strokeEndAnim.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            strokeEndAnim.isRemovedOnCompletion = false
            strokeEndAnim.fillMode = .forwards
            
            line.add(strokeEndAnim, forKey: "strokeEnd")
            }
        }
    }
    
    /** Animate the grid being drawn, horizontal lines first then vertical, from left to right and top to bottom*/
    func animateDrawing(with duration: CGFloat){
        
        for (index, line) in horizontalLines.enumerated(){
            /** Set the line's end point to it's starting point*/
            line.strokeEnd = 0
            
            /** Animate each line with a slight delay calculated by dividing the total duration by the number of lines*/
            DispatchQueue.main.asyncAfter(deadline: .now() + duration/CGFloat(index + 1)){
            let strokeEndAnim = CABasicAnimation(keyPath: #keyPath(CAShapeLayer.strokeEnd))
            strokeEndAnim.fromValue = 0
            strokeEndAnim.toValue = 1
            strokeEndAnim.duration = duration
            strokeEndAnim.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            strokeEndAnim.isRemovedOnCompletion = false
            strokeEndAnim.fillMode = .forwards
            
            line.add(strokeEndAnim, forKey: "strokeEnd")
            }
        }
        
        for (index, line) in verticalLines.enumerated(){
            line.strokeEnd = 0
            
            DispatchQueue.main.asyncAfter(deadline: .now() + duration/CGFloat(index + 1)){
            let strokeEndAnim = CABasicAnimation(keyPath: #keyPath(CAShapeLayer.strokeEnd))
            strokeEndAnim.fromValue = 0
            strokeEndAnim.toValue = 1
            strokeEndAnim.duration = duration + 1
            strokeEndAnim.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            strokeEndAnim.isRemovedOnCompletion = false
            strokeEndAnim.fillMode = .forwards
            
            line.add(strokeEndAnim, forKey: "strokeEnd")
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
