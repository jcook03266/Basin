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
    var titleLabelView: PaddedLabel!
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
        
        titleLabelView.frame.size = CGSize(width: self.frame.width * 0.95, height: self.frame.height/2)
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
