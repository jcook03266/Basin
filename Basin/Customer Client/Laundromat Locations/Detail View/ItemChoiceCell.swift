//
//  ItemChoiceCell.swift
//  Stuy Wash N Dry
//
//  Created by Justin Cook on 4/15/22.
//

import UIKit

/** Table view cell subclass that encapsulates the data represented by an item choice data model, the user can select this cell in order to specify an item choice*/
class ItemChoiceCell: UITableViewCell{
    static let identifier = "ItemChoiceCell"
    var data: itemChoice!
    /** True if this item choice has been selected, false if it hasn't, used for persistence*/
    var selectionStatus: Bool! = false
    /** Mark as disabled to prevent the user from making another selection, used when the selection limit has been reached for the category this cell is within*/
    var disabled: Bool! = false
    /** Selectable button that indicates the user's current choice*/
    var selectionButton: LottieButton!
    /** The name of this item*/
    var nameLabel: UILabel!
    /** The price of this item*/
    var priceLabel: PaddedLabel!
    /** Description of this item (optional)*/
    var descriptionLabel: UILabel!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: ItemChoiceCell.identifier)
    }
    
    /** Create a laundromat location view and add it to the content view of this cell*/
    func create(with data: itemChoice, selectionStatus: Bool, disabled: Bool){
        self.backgroundColor = .clear
        self.selectionStyle = .none
        self.contentView.clipsToBounds = true
        self.data = data
        self.selectionStatus = selectionStatus
        self.disabled = disabled
        
        /** Add a single tap gesture recognizer to highlight where the user touches the cell*/
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(viewSingleTapped))
        singleTap.numberOfTapsRequired = 1
        singleTap.numberOfTouchesRequired = 1
        singleTap.requiresExclusiveTouchType = true
        singleTap.cancelsTouchesInView = false
        self.addGestureRecognizer(singleTap)
        
        nameLabel = UILabel()
        nameLabel.frame.size = CGSize(width: self.frame.width - (35 * 1.5), height: (self.frame.height * 0.35) - 5)
        nameLabel.font = getCustomFont(name: .Ubuntu_Medium, size: 14, dynamicSize: true)
        nameLabel.backgroundColor = .clear
        nameLabel.textColor = fontColor
        nameLabel.textAlignment = .left
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.numberOfLines = 1
        nameLabel.lineBreakMode = .byClipping
        nameLabel.text = data.name
        
        priceLabel = PaddedLabel(withInsets: 0, 0, 0, 0)
        priceLabel.frame.size = CGSize(width: self.frame.width * 0.7, height: self.frame.height * 0.35)
        priceLabel.font = getCustomFont(name: .Ubuntu_Regular, size: 13, dynamicSize: true)
        priceLabel.text = "$\(String(format: "%.2f", data.price)) /Item"
        priceLabel.backgroundColor = .clear
        priceLabel.textColor = fontColor
        priceLabel.textAlignment = .left
        priceLabel.adjustsFontForContentSizeCategory = true
        priceLabel.adjustsFontSizeToFitWidth = true
        ///priceLabel.layer.cornerRadius = priceLabel.frame.height/2
        priceLabel.layer.masksToBounds = true
        priceLabel.attributedText = attribute(this: priceLabel.text!, font: getCustomFont(name: .Ubuntu_Regular, size: 13, dynamicSize: true), mainColor: fontColor, subColor: .lightGray, subString: "/Item")
        priceLabel.sizeToFit()
        
        descriptionLabel = UILabel()
        descriptionLabel.frame.size = CGSize(width: self.frame.width * 0.7, height: self.frame.height * 0.3)
        descriptionLabel.font = getCustomFont(name: .Ubuntu_Regular, size: 12, dynamicSize: true)
        descriptionLabel.backgroundColor = .clear
        descriptionLabel.textColor = .lightGray
        descriptionLabel.textAlignment = .left
        descriptionLabel.adjustsFontForContentSizeCategory = true
        descriptionLabel.adjustsFontSizeToFitWidth = false
        descriptionLabel.numberOfLines = 2
        descriptionLabel.lineBreakMode = .byClipping
        descriptionLabel.text = data.choiceDescription
        descriptionLabel.sizeToFit()
        
        selectionButton = LottieButton(frame: CGRect(x: 0, y: 0, width: 35, height: 35), lottieFile: "liquidCheckMark")
        selectionButton.layer.borderWidth = 1
        selectionButton.layer.borderColor = appThemeColor.cgColor
        selectionButton.backgroundColor = .clear
        selectionButton.tintColor = fontColor
        selectionButton.layer.cornerRadius = selectionButton.frame.height/2
        selectionButton.isEnabled = true
        /** Let hits pass through this button in order to recognize a selection event in the tableview's delegate methods*/
        selectionButton.isUserInteractionEnabled = false
        selectionButton.isExclusiveTouch = true
        selectionButton.addTarget(self, action: #selector(selectionButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: selectionButton)
        
        if disabled == true{
        selectionButton.isEnabled = false
        selectionButton.layer.borderColor = UIColor.lightGray.cgColor
            nameLabel.textColor = .lightGray
            priceLabel.textColor = .lightGray
            descriptionLabel.textColor = .lightGray
            
        }
        
        /** Reflect whether or not this choice has been selected*/
        if selectionStatus == true{
            selectionButton.setAnimationFrameTo(this: 195)
        }
        else{
            selectionButton.setAnimationFrameTo(this: 0)
        }
        
        /** Layout subviews*/
        selectionButton.frame.origin = CGPoint(x: self.frame.width * 0.05, y: self.frame.height/2 - selectionButton.frame.height/2)
        
        nameLabel.frame.origin = CGPoint(x: selectionButton.frame.maxX + (0.25 * selectionButton.frame.width), y: selectionButton.frame.minY)
        
        priceLabel.frame.origin = CGPoint(x: nameLabel.frame.minX, y: nameLabel.frame.maxY + 5)
        
        self.contentView.addSubview(selectionButton)
        self.contentView.addSubview(nameLabel)
        self.contentView.addSubview(priceLabel)
    }
    
    /** Trigger the selection logic*/
    @objc func selectionButtonPressed(sender: LottieButton){
        
        if selectionStatus == true{
            lightHaptic()
            
            /** Deselect*/
            sender.playAnimation(from: 195, to: 0, with: .playOnce, animationSpeed: 2.5)
            
            selectionStatus = false
        }
        else{
            mediumHaptic()
            
            /** Select*/
            sender.playAnimation(from: 0, to: 195, with: .playOnce, animationSpeed: 2.5)
            selectionStatus = true
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
    /** Button press methods*/
    
    /** Show where the user taps on the screen*/
    @objc func viewSingleTapped(sender: UITapGestureRecognizer){
        let circleView = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width * 2, height: self.frame.width * 2))
        circleView.layer.cornerRadius = circleView.frame.height/2
        circleView.backgroundColor = appThemeColor.withAlphaComponent(0.2)
        circleView.clipsToBounds = true
        circleView.center.x = sender.location(in: self.contentView).x
        circleView.center.y = sender.location(in: self.contentView).y
        circleView.transform = CGAffineTransform(scaleX: 0, y: 0)
        
        self.contentView.addSubview(circleView)
        
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .allowUserInteraction]){
            circleView.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        UIView.animate(withDuration: 0.5, delay: 1, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .allowUserInteraction]){
            circleView.alpha = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5){
            circleView.removeFromSuperview()
        }
    }
    /** A little something extra to keep things flashy*/
    
    /** Various garbage collection procedures*/
    override func prepareForReuse(){
        super.prepareForReuse()
        
        self.data = nil
        self.selectionStatus = nil
        self.disabled = nil
        self.selectionButton = nil
        self.nameLabel = nil
        self.priceLabel = nil
        self.descriptionLabel = nil
        
        for subview in contentView.subviews{
            subview.removeFromSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

