//
//  OrderItemTableViewCell.swift
//  Stuy Wash N Dry
//
//  Created by Justin Cook on 4/4/22.
//

import UIKit
import Nuke

/** Table view cell that will display an order item*/
class OrderItemTableViewCell: UITableViewCell{
    static let identifier = "OrderItemTableViewCell"
    /** Data passed to this cell*/
    var itemData: OrderItem!
    /** The name of this item*/
    var nameLabel: UILabel!
    /** The price of this item*/
    var priceLabel: PaddedLabel!
    /** Description of this item (optional)*/
    var descriptionLabel: UILabel!
    /** Display the optional image for this item by parsing the given URL (if any)*/
    var iconImageView: UIImageView!
    /** Animatable path around the iconImageView that's filled in when the user presses the plus button to add an item to their cart */
    var imageViewShapeLayer: CAShapeLayer!
    /** Label that can display a small piece of information like a single word such as 'popular' to convey trends or availability*/
    var informationTagLabel: PaddedLabel!
    /** A button that expands to allow the user to add increments of an item without having to go into the detail view*/
    var addButton: UIButton!
    /** Opposite of the add button, only revealed when the user adds an item*/
    var subtractButton: UIButton!
    /** itemCount Button that displays the amount of items currently added, this appears when one or more items have been added and disappears along with the subtract button when the item count = 0, max amount of duplicate items for one order is 100*/
    var itemCountButton: UIButton!
    /** Background view behind the item count button*/
    var itemCountButtonBackgroundView: UIView!
    /** Do not let the adder or menu go above this number*/
    let maxItems = 100
    /** Do not let the subtracter or menu go below this number*/
    let minItems = 0
    /** Used to determine when the user is currently editing the amount of items to add*/
    var editingItemCount: Bool = false
    /** UIView that contains all of the subviews placed in the contentView of this cell to make garbage collection easier*/
    var container: UIView!
    /** UIView that acts as a shadow behind the container*/
    var shadowView: UIView!
    /** The cart object that will be used to store this object if the user chooses to add it*/
    var cart: Cart! = nil
    /** The view controller this cell is being displayed in*/
    var presentingVC: UIViewController? = nil
    /** The tableview from which this detail view originated from, can be used as a reference for refreshing when the cart data has been updated*/
    var presentingTableView: UITableView? = nil
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: OrderItemTableViewCell.identifier)
    }
    
    /** Provide the data needed to construct this object*/
    func create(with data: OrderItem, cart: Cart){
        /** Specify a maximum font size*/
        self.maximumContentSizeCategory = .large
        
        self.backgroundColor = .clear
        self.selectionStyle = .none
        self.clipsToBounds = true
        self.itemData = data
        self.cart = cart
        
        /** If this item exists in the cart then replace the item data with the item from the cart, both items must have the same id, category and menu id*/
        for item in cart.items{
            if item.id == itemData.id && item.category == itemData.category && item.menu.id == itemData.menu.id{
                let menu = itemData.menu
                itemData = item
                
                /** The cart item's menu doesn't contain items in order to save memory so the passed item's menu is referenced*/
                itemData.menu = menu
                
                break
            }
        }
        
        /** Add a single tap gesture recognizer to highlight where the user touches the cell*/
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(viewSingleTapped))
        singleTap.numberOfTapsRequired = 1
        singleTap.numberOfTouchesRequired = 1
        singleTap.requiresExclusiveTouchType = true
        singleTap.cancelsTouchesInView = false
        self.addGestureRecognizer(singleTap)
        
        /** A container slightly smaller than the cell*/
        container = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width * 0.925, height: self.frame.height * 0.9))
        container.backgroundColor = bgColor
        container.layer.cornerRadius = container.frame.height/5
        container.clipsToBounds = true
        
        shadowView = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width * 0.95, height: self.frame.height * 0.95))
        shadowView.backgroundColor = .clear
        shadowView.clipsToBounds = false
        shadowView.layer.masksToBounds = true
        shadowView.layer.cornerRadius = container.layer.cornerRadius
        shadowView.layer.shadowColor = UIColor.lightGray.cgColor
        shadowView.layer.shadowOpacity = 0.25
        shadowView.layer.shadowRadius = 5
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 2)
        shadowView.layer.shadowPath = UIBezierPath(roundedRect: shadowView.bounds, cornerRadius: shadowView.layer.cornerRadius).cgPath
        
        nameLabel = UILabel()
        nameLabel.frame.size = CGSize(width: container.frame.width * 0.7, height: container.frame.height * 0.25)
        nameLabel.font = getCustomFont(name: .Ubuntu_Medium, size: 16, dynamicSize: true)
        nameLabel.backgroundColor = .clear
        nameLabel.textColor = fontColor
        nameLabel.textAlignment = .left
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.numberOfLines = 1
        nameLabel.lineBreakMode = .byClipping
        nameLabel.text = data.name
        
        priceLabel = PaddedLabel(withInsets: 0, 0, 5, 5)
        priceLabel.frame.size = CGSize(width: container.frame.width * 0.7, height: container.frame.height * 0.25)
        priceLabel.font = getCustomFont(name: .Ubuntu_Regular, size: 17, dynamicSize: true)
        priceLabel.text = "$\(String(format: "%.2f", data.price)) /Item"
        priceLabel.backgroundColor = .clear
        priceLabel.textColor = fontColor
        priceLabel.textAlignment = .left
        priceLabel.adjustsFontForContentSizeCategory = true
        priceLabel.adjustsFontSizeToFitWidth = true
        ///priceLabel.layer.cornerRadius = priceLabel.frame.height/2
        priceLabel.layer.masksToBounds = true
        priceLabel.attributedText = attribute(this: priceLabel.text!, font: getCustomFont(name: .Ubuntu_Regular, size: 17, dynamicSize: true), mainColor: fontColor, subColor: .lightGray, subString: "/Item")
        priceLabel.sizeToFit()
        
        descriptionLabel = UILabel()
        descriptionLabel.frame.size = CGSize(width: container.frame.width * 0.7, height: container.frame.height * 0.3)
        descriptionLabel.font = getCustomFont(name: .Ubuntu_Regular, size: 12, dynamicSize: true)
        descriptionLabel.backgroundColor = .clear
        descriptionLabel.textColor = .lightGray
        descriptionLabel.textAlignment = .left
        descriptionLabel.adjustsFontForContentSizeCategory = true
        descriptionLabel.adjustsFontSizeToFitWidth = false
        descriptionLabel.numberOfLines = 2
        descriptionLabel.lineBreakMode = .byClipping
        descriptionLabel.text = data.itemDescription
        descriptionLabel.sizeToFit()
        
        informationTagLabel = PaddedLabel(withInsets: 1, 1, 2, 2)
        informationTagLabel.frame.size = CGSize(width: container.frame.width * 0.35, height: container.frame.height * 0.2)
        informationTagLabel.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: true)
        informationTagLabel.text = ""
        informationTagLabel.backgroundColor = appThemeColor
        informationTagLabel.textColor = .white
        informationTagLabel.textAlignment = .left
        informationTagLabel.adjustsFontForContentSizeCategory = true
        informationTagLabel.adjustsFontSizeToFitWidth = true
        informationTagLabel.layer.cornerRadius = informationTagLabel.frame.height/2
        informationTagLabel.layer.masksToBounds = true
        informationTagLabel.sizeToFit()
        informationTagLabel.alpha = 0
        
        iconImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: container.frame.width * 0.24, height: container.frame.width * 0.24))
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.backgroundColor = .white
        iconImageView.layer.cornerRadius = iconImageView.frame.height/5
        iconImageView.layer.borderWidth = 2
        iconImageView.layer.borderColor = appThemeColor.withAlphaComponent(0.2).cgColor
        iconImageView.clipsToBounds = true
        iconImageView.tintColor = appThemeColor
        
        imageViewShapeLayer = CAShapeLayer()
        imageViewShapeLayer.path = UIBezierPath(roundedRect: iconImageView.bounds, cornerRadius: iconImageView.layer.cornerRadius).cgPath
        imageViewShapeLayer.bounds = iconImageView.bounds
        imageViewShapeLayer.frame = iconImageView.frame
        imageViewShapeLayer.fillRule = .nonZero
        imageViewShapeLayer.fillColor = UIColor.clear.cgColor
        imageViewShapeLayer.lineCap = .round
        imageViewShapeLayer.lineWidth = 2.0
        /** If the amount of items is >= 1 then fill in the path, if not then the path will be filled in when an item is added*/
        imageViewShapeLayer.strokeEnd = itemData.count >=  1 ? 1 : 0
        imageViewShapeLayer.strokeColor = appThemeColor.cgColor
        /** Rotate the shape layer 180 degrees to change the position of the stroke start*/
        imageViewShapeLayer.setAffineTransform(CGAffineTransform(rotationAngle: .pi/4 * 6))
        iconImageView.layer.addSublayer(imageViewShapeLayer)
        
        if let url = URL(string: data.photoURL ?? ""){
            let request = ImageRequest(url: url)
            let options = ImageLoadingOptions(
                transition: .fadeIn(duration: 0.5)
            )
            
            Nuke.loadImage(with: request, options: options, into: iconImageView){ _ in
            }
        }
        else{
            /** No image provided so use a default placeholder stored in the assets collection*/
            iconImageView.image = UIImage(named: "placeholderLaundryIcon")
        }
        
        addButton = UIButton()
        addButton.frame.size = CGSize(width: self.frame.width * 0.075, height: self.frame.width * 0.075)
        addButton.backgroundColor = appThemeColor
        addButton.contentHorizontalAlignment = .center
        addButton.layer.cornerRadius = addButton.frame.height/2
        addButton.isExclusiveTouch = true
        addButton.isEnabled = true
        addButton.isUserInteractionEnabled = true
        addButton.castDefaultShadow()
        addButton.layer.shadowColor = UIColor.lightGray.cgColor
        addButton.tintColor = .white
        if itemData.count < 1{
            addButton.setTitle(nil, for: .normal)
            addButton.setImage(UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        }else{
            /** Display the item count, on the add button when the cell has multiple items added*/
            addButton.setImage(nil, for: .normal)
            addButton.setTitleColor(.white, for: .normal)
            addButton.setTitle("\(cart.getTotalCountFor(this: itemData))", for: .normal)
            addButton.titleLabel?.adjustsFontSizeToFitWidth = true
            addButton.titleLabel?.adjustsFontForContentSizeCategory = true
        }
        addButton.addTarget(self, action: #selector(addButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: addButton)
        addButton.menu = getMenuForAddButton()
        
        subtractButton = UIButton()
        subtractButton.frame.size = CGSize(width: self.frame.width * 0.075, height: self.frame.width * 0.075)
        subtractButton.backgroundColor = appThemeColor
        subtractButton.contentHorizontalAlignment = .center
        subtractButton.layer.cornerRadius = subtractButton.frame.height/2
        subtractButton.isExclusiveTouch = true
        subtractButton.isEnabled = true
        subtractButton.isUserInteractionEnabled = true
        subtractButton.castDefaultShadow()
        subtractButton.layer.shadowColor = UIColor.lightGray.cgColor
        subtractButton.tintColor = .white
        subtractButton.setImage(UIImage(systemName: "minus", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        subtractButton.addTarget(self, action: #selector(subtractButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: subtractButton)
        subtractButton.menu = getMenuForSubtractButton()
        
        itemCountButtonBackgroundView = UIView(frame: CGRect(x: 0, y: 0, width: subtractButton.frame.width * 2.5, height: subtractButton.frame.height * 0.9))
        itemCountButtonBackgroundView.isUserInteractionEnabled = true
        itemCountButtonBackgroundView.backgroundColor = appThemeColor
        itemCountButtonBackgroundView.clipsToBounds = true
        
        itemCountButton = UIButton()
        itemCountButton.frame.size = CGSize(width: subtractButton.frame.width * 0.8, height: subtractButton.frame.height * 0.8)
        itemCountButton.backgroundColor = .white
        itemCountButton.contentHorizontalAlignment = .center
        itemCountButton.layer.cornerRadius = itemCountButton.frame.height/5
        itemCountButton.isExclusiveTouch = true
        itemCountButton.isEnabled = true
        itemCountButton.isUserInteractionEnabled = false
        itemCountButton.tintColor = .black
        itemCountButton.setTitleColor(.black, for: .normal)
        itemCountButton.setTitle("\(cart.getTotalCountFor(this: itemData))", for: .normal)
        itemCountButton.titleLabel?.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: true)
        itemCountButton.titleLabel?.adjustsFontSizeToFitWidth = true
        itemCountButton.titleLabel?.adjustsFontForContentSizeCategory = true
        ///itemCountButton.addTarget(self, action: #selector(itemCountButtonPressed), for: .touchUpInside)
        
        /** Layout these subviews*/
        shadowView.frame.origin = CGPoint(x: self.frame.width/2 - shadowView.frame.width/2, y: self.frame.height/2 - shadowView.frame.height/2)
        
        container.frame.origin = CGPoint(x: shadowView.frame.width/2 - container.frame.width/2, y: shadowView.frame.height/2 - container.frame.height/2)
        
        nameLabel.frame.origin = CGPoint(x: self.frame.width * 0.05, y: container.frame.height/4 - nameLabel.frame.height/2)
        
        priceLabel.frame.origin = CGPoint(x: self.frame.width * 0.05, y: nameLabel.frame.maxY + container.frame.height * 0.05)
        
        ///descriptionLabel.frame.origin = CGPoint(x: self.frame.width * 0.05, y: priceLabel.frame.maxY + container.frame.height * 0.05)
        
        ///informationTagLabel.frame.origin = CGPoint(x: 0, y: descriptionLabel.frame.maxY + container.frame.height * 0.05)
        ///informationTagLabel.center.x = descriptionLabel.center.x
        
        iconImageView.frame.origin = CGPoint(x: nameLabel.frame.maxX, y: container.frame.height/2 - iconImageView.frame.height/2)
        
        itemCountButton.frame.origin = CGPoint(x: itemCountButtonBackgroundView.frame.width/2 - itemCountButton.frame.width/2, y: itemCountButtonBackgroundView.frame.height/2 - itemCountButton.frame.height/2)
        
        if iconImageView.alpha != 0{
            addButton.frame.origin = CGPoint(x: iconImageView.frame.minX - iconImageView.frame.width/10, y: iconImageView.frame.maxY - (addButton.frame.height * 1.1))
        }
        else{
            /** Center this button since the imageview view is empty*/
            addButton.frame.origin = CGPoint(x: 0, y: container.frame.height/2 - addButton.frame.height/2)
            addButton.center.x = iconImageView.center.x
        }
        
        itemCountButton.isUserInteractionEnabled = false
        itemCountButton.alpha = 0
        
        itemCountButtonBackgroundView.alpha = 0
        itemCountButtonBackgroundView.frame.origin = addButton.frame.origin
        itemCountButtonBackgroundView.center.y = addButton.center.y
        
        subtractButton.alpha = 0
        subtractButton.isUserInteractionEnabled = false
        subtractButton.frame.origin = addButton.frame.origin
        
        /** Add subviews to content view*/
        shadowView.addSubview(container)
        self.container.addSubview(nameLabel)
        self.container.addSubview(priceLabel)
        ///self.container.addSubview(descriptionLabel)
        self.container.addSubview(iconImageView)
        self.container.addSubview(informationTagLabel)
        itemCountButtonBackgroundView.addSubview(itemCountButton)
        self.container.addSubview(itemCountButtonBackgroundView)
        self.container.addSubview(subtractButton)
        self.container.addSubview(addButton)
        self.contentView.addSubview(shadowView)
    }
    
    /** Display the subtracter button and the item count display button*/
    func displayItemCountEditingUI(animated: Bool){
        itemCountButtonBackgroundView.alpha = 1
        itemCountButton.alpha = 1
        itemCountButton.isUserInteractionEnabled = true
        subtractButton.alpha = 1
        subtractButton.isUserInteractionEnabled = true
        itemCountButtonBackgroundView.frame.size.width = 0
        
        editingItemCount = true
        
        switch animated{
        case true:
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
                itemCountButtonBackgroundView.frame.size.width = subtractButton.frame.width * 2.5
                
                itemCountButtonBackgroundView.frame.origin = CGPoint(x: addButton.frame.minX - (itemCountButtonBackgroundView.frame.width - addButton.frame.width/2), y: 0)
                itemCountButtonBackgroundView.center.y = addButton.center.y
                
                subtractButton.frame.origin.x = itemCountButtonBackgroundView.frame.minX - (subtractButton.frame.width * 0.5)
            }
        case false:
            itemCountButtonBackgroundView.frame.size.width = subtractButton.frame.width * 2.5
            
            itemCountButtonBackgroundView.frame.origin = CGPoint(x: addButton.frame.minX - (itemCountButtonBackgroundView.frame.width - addButton.frame.width/2), y: 0)
            itemCountButtonBackgroundView.center.y = addButton.center.y
            
            subtractButton.frame.origin = addButton.frame.origin
            subtractButton.frame.origin.x = itemCountButtonBackgroundView.frame.minX - (subtractButton.frame.width * 0.5)
        }
    }
    
    func hideItemCountEditingUI(animated: Bool){
        itemCountButton.isUserInteractionEnabled = false
        subtractButton.isUserInteractionEnabled = false
        
        editingItemCount = false
        
        switch animated{
        case true:
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn){[self] in
                subtractButton.frame.origin = addButton.frame.origin
            }
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn){[self] in
                itemCountButtonBackgroundView.frame.size.width = 0
                
                /** Move the view to the right as it disappears from the right*/
                itemCountButtonBackgroundView.frame.origin = addButton.frame.origin
                
                itemCountButtonBackgroundView.center.y = addButton.center.y
                
                /** Reset the button's label*/
                if itemData.count < 1{
                    addButton.setTitle(nil, for: .normal)
                    addButton.setImage(UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
                }else{
                    /** Display the item count, on the add button when the cell has multiple items added*/
                    addButton.setImage(nil, for: .normal)
                    addButton.setTitleColor(.white, for: .normal)
                    addButton.setTitle("\(cart.getTotalCountFor(this: itemData))", for: .normal)
                    addButton.titleLabel?.adjustsFontSizeToFitWidth = true
                    addButton.titleLabel?.adjustsFontForContentSizeCategory = true
                }
            }
        case false:
            itemCountButtonBackgroundView.frame.size.width = 0
            
            itemCountButtonBackgroundView.frame.origin = addButton.frame.origin
            
            itemCountButtonBackgroundView.center.y = addButton.center.y
            
            subtractButton.frame.origin = addButton.frame.origin
            
            /** Set the button's label*/
            if itemData.count < 1{
                addButton.setTitle(nil, for: .normal)
                addButton.setImage(UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
            }else{
                /** Display the item count, on the add button when the cell has multiple items added*/
                addButton.setImage(nil, for: .normal)
                addButton.setTitleColor(.white, for: .normal)
                addButton.setTitle("\(cart.getTotalCountFor(this: itemData))", for: .normal)
                addButton.titleLabel?.adjustsFontSizeToFitWidth = true
                addButton.titleLabel?.adjustsFontForContentSizeCategory = true
            }
        }
    }
    
    /** Decrement the item counter and present the decrement button and counter label*/
    @objc func subtractButtonPressed(sender: UIButton){
        guard itemData != nil else{
            return
        }
        
        if itemData.count > minItems{
            self.itemData.count -= 1
            lightHaptic()
            
            UIView.transition(with: itemCountButton, duration: 0.1, options: .transitionCrossDissolve, animations:{ [self] in
                itemCountButton.setTitle("\(cart.getTotalCountFor(this: itemData))", for: .normal)
            })
        }
        else{
            itemData.count = 0
            errorShake()
            
            /** Inform the user that they can't go below zero*/
            globallyTransmit(this: "You can't have negative clothes!", with: UIImage(systemName: "tshirt.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .rightStrip, animated: true, duration: 3, selfDismiss: true)
        }
        
        if itemData.count == 0{
            hideItemCountEditingUI(animated: true)
            
            /** Remove the item from the given cart*/
            cart.removeThis(item: self.itemData)
            cart.updateThis(item: self.itemData)
            
            updateBorder()
        }
        else{
            /** Send an update to the delegate listeners to tell them the item has been updated*/
            cart.updateThis(item: self.itemData)
        }
        
        animateShapeLayerPathRemoving()
    }
    
    
    /** Increment the item counter and present the decrement button and counter label*/
    @objc func addButtonPressed(sender: UIButton){
        guard itemData != nil else {
            return
        }
        
        /** If this item requires a selection to be made in order to add the item then push the detail view controller for this item where the user can then make their selection and also add any additional duplicates to the overall count for this item*/
        if itemData.itemChoices.isEmpty == false{
            var isSelectionRequired = false
            for choice in itemData.itemChoices{
                if choice.required == true{
                    isSelectionRequired = true
                    break
                }
            }
            if isSelectionRequired == true{
                lightHaptic()
                
                let vc = OrderItemDetailVC(itemData: self.itemData, laundromatCart: self.cart, laundromatMenu: self.itemData.menu)
                
                if presentingTableView != nil{
                    vc.presentingTableView = self.presentingTableView
                    vc.laundromatMenu = itemData.menu
                }
                
                if presentingVC != nil{
                    /** Prevent the user from using interactive dismissal*/
                    vc.isModalInPresentation = true
                    presentingVC!.show(vc, sender: presentingVC)
                }
                
                return
            }
        }
        
        /** Reset the image for this button when the user taps it*/
        addButton.setImage(UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        addButton.setTitle(nil, for: .normal)
        
        if editingItemCount == false{
            displayItemCountEditingUI(animated: true)
        }
        
        if itemData.count < maxItems{
            self.itemData.count += 1
            lightHaptic()
            
            /** Add the item to the given cart*/
            if itemData.count == 1{
                cart.addThis(item: self.itemData)
                cart.updateThis(item: self.itemData)
                
                updateBorder()
            }
            else{
                /** Send an update to the delegate listeners to tell them the item has been updated*/
                cart.updateThis(item: self.itemData)
            }
            
            if itemData.count == 1 && imageViewShapeLayer != nil{
                animateShapeLayerPathFilling()
            }
            
            UIView.transition(with: itemCountButton, duration: 0.1, options: .transitionCrossDissolve, animations:{ [self] in
                itemCountButton.setTitle("\(cart.getTotalCountFor(this: itemData))", for: .normal)
            })
        }
        else{
            itemData.count = maxItems
            errorShake()
            globallyTransmit(this: "Maximum number of items reached for this item", with: UIImage(systemName: "tshirt.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .rightStrip, animated: true, duration: 3, selfDismiss: true)
        }
    }
    
    /** Animate the shape layer path filling in*/
    func animateShapeLayerPathFilling(){
        if imageViewShapeLayer != nil{
            let fillInAnimation = CABasicAnimation(keyPath: "strokeEnd")
            fillInAnimation.duration = 1
            fillInAnimation.toValue = 1
            fillInAnimation.fillMode = .forwards
            fillInAnimation.isRemovedOnCompletion = false
            imageViewShapeLayer.add(fillInAnimation, forKey: "fillInAnimation")
        }
    }
    
    /** Animate the shape layer path being removed*/
    func animateShapeLayerPathRemoving(){
        if itemData.count == 0 && imageViewShapeLayer != nil{
            let fillInAnimation = CABasicAnimation(keyPath: "strokeEnd")
            fillInAnimation.duration = 1
            fillInAnimation.fromValue = 1
            fillInAnimation.toValue = 0
            fillInAnimation.fillMode = .forwards
            fillInAnimation.isRemovedOnCompletion = false
            imageViewShapeLayer.add(fillInAnimation, forKey: "fillInAnimation")
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
    
    /** Show where the user taps on the screen*/
    @objc func viewSingleTapped(sender: UITapGestureRecognizer){
        guard container != nil else {
            return
        }
        
        /** Don't trigger the animation if the user is pressing any of the following views*/
        guard addButton.frame.contains(sender.location(in: container)) == false && subtractButton.frame.contains(sender.location(in: container)) == false && itemCountButtonBackgroundView.frame.contains(sender.location(in: container)) == false else{
            return
        }
        
        let circleView = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width * 2, height: self.frame.width * 2))
        circleView.layer.cornerRadius = circleView.frame.height/2
        circleView.backgroundColor = appThemeColor.withAlphaComponent(0.2)
        circleView.clipsToBounds = true
        circleView.center.x = sender.location(in: container).x
        circleView.center.y = sender.location(in: container).y
        circleView.transform = CGAffineTransform(scaleX: 0, y: 0)
        
        if container != nil{
            container.addSubview(circleView)
        }
        
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
    
    /** Change the border to reflect whether or not this item is in the user's cart currently*/
    func updateBorder(){
        guard cart != nil && container != nil && itemData != nil else {
            return
        }
        
        /** If this item is already in the user's cart then highlight the cell*/
        if self.cart.getTotalCountFor(this: self.itemData) > 0{
            self.shadowView.layer.shadowColor = appThemeColor.cgColor
            self.shadowView.layer.shadowOpacity = 1
        }
        else{
            self.shadowView.layer.shadowColor = UIColor.lightGray.cgColor
            self.shadowView.layer.shadowOpacity = 0.25
        }
    }
    
    /** Provide a menu for this button*/
    func getMenuForAddButton()->UIMenu?{
        guard itemData != nil else {
            return nil
        }
        
        /** If this item requires a selection to be made in order to add the item then don't allow this menu to be displayed*/
        if itemData.itemChoices.isEmpty == false{
            var isSelectionRequired = false
            for choice in itemData.itemChoices{
                if choice.required == true{
                    isSelectionRequired = true
                    break
                }
            }
            if isSelectionRequired == true{
                return nil
            }
        }
        
        var children: [UIMenuElement] = []
        let menuTitle = "Increment by:"
        
        let clear = UIAction(title: "Clear", image: UIImage(systemName: "trash.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light))){ [self] action in
            lightHaptic()
            
            itemData.count = 0
            updateDisplayForCountButton()
            
            hideItemCountEditingUI(animated: true)
            cart.clearAllInstancesOf(this: itemData)
            cart.updateThis(item: self.itemData)
            animateShapeLayerPathRemoving()
            
            updateBorder()
        }
        let by20 = UIAction(title: "+20", image: nil){ [self] action in
            lightHaptic()
            
            /** If this item's quantity was 0 prior then add it to the cart now*/
            if itemData.count == minItems{
                displayItemCountEditingUI(animated: true)
                cart.addThis(item: itemData)
                cart.updateThis(item: self.itemData)
                animateShapeLayerPathFilling()
                
                updateBorder()
            }
            
            /** Don't go over the max quantity*/
            if (itemData.count + 20) <= maxItems{
                itemData.count += 20
                cart.updateThis(item: self.itemData)
                
                updateDisplayForCountButton()
            }
            /** Max num of items reached, inform the user*/
            if itemData.count == maxItems{
                itemData.count = maxItems
                errorShake()
                globallyTransmit(this: "Maximum number of items reached for this item", with: UIImage(systemName: "tshirt.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .rightStrip, animated: true, duration: 3, selfDismiss: true)
            }
            
            updateAddButtonWhenNotEditingDisplay()
        }
        let by10 = UIAction(title: "+10", image: nil){ [self] action in
            lightHaptic()
            
            if itemData.count == minItems{
                displayItemCountEditingUI(animated: true)
                cart.addThis(item: itemData)
                cart.updateThis(item: self.itemData)
                animateShapeLayerPathFilling()
                
                updateBorder()
            }
            
            if (itemData.count + 10) <= maxItems{
                itemData.count += 10
                cart.updateThis(item: self.itemData)
                
                updateDisplayForCountButton()
            }
            if itemData.count == maxItems{
                itemData.count = maxItems
                errorShake()
                globallyTransmit(this: "Maximum number of items reached for this item", with: UIImage(systemName: "tshirt.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .rightStrip, animated: true, duration: 3, selfDismiss: true)
            }
            
            updateAddButtonWhenNotEditingDisplay()
        }
        let by5 = UIAction(title: "+5", image: nil){ [self] action in
            lightHaptic()
            
            if itemData.count == minItems{
                displayItemCountEditingUI(animated: true)
                cart.addThis(item: itemData)
                cart.updateThis(item: self.itemData)
                animateShapeLayerPathFilling()
                
                updateBorder()
            }
            
            if (itemData.count + 5) <= maxItems{
                itemData.count += 5
                cart.updateThis(item: self.itemData)
                
                updateDisplayForCountButton()
            }
            if itemData.count == maxItems{
                itemData.count = maxItems
                errorShake()
                globallyTransmit(this: "Maximum number of items reached for this item", with: UIImage(systemName: "tshirt.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .rightStrip, animated: true, duration: 3, selfDismiss: true)
            }
            
            updateAddButtonWhenNotEditingDisplay()
        }
        let by2 = UIAction(title: "+2", image: nil){ [self] action in
            lightHaptic()
            
            if itemData.count == minItems{
                displayItemCountEditingUI(animated: true)
                cart.addThis(item: itemData)
                cart.updateThis(item: self.itemData)
                animateShapeLayerPathFilling()
                
                updateBorder()
            }
            
            if (itemData.count + 2) <= maxItems{
                itemData.count += 2
                cart.updateThis(item: self.itemData)
                
                updateDisplayForCountButton()
            }
            if itemData.count == maxItems{
                itemData.count = maxItems
                errorShake()
                globallyTransmit(this: "Maximum number of items reached for this item", with: UIImage(systemName: "tshirt.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .rightStrip, animated: true, duration: 3, selfDismiss: true)
            }
            
            updateAddButtonWhenNotEditingDisplay()
        }
        let by1 = UIAction(title: "+1", image: nil){ [self] action in
            lightHaptic()
            
            if itemData.count == minItems{
                displayItemCountEditingUI(animated: true)
                cart.addThis(item: itemData)
                cart.updateThis(item: self.itemData)
                animateShapeLayerPathFilling()
                
                updateBorder()
            }
            
            if (itemData.count + 1) <= maxItems{
                itemData.count += 1
                cart.updateThis(item: self.itemData)
                
                updateDisplayForCountButton()
            }
            if itemData.count == maxItems{
                itemData.count = maxItems
                errorShake()
                globallyTransmit(this: "Maximum number of items reached for this item", with: UIImage(systemName: "tshirt.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .rightStrip, animated: true, duration: 3, selfDismiss: true)
            }
            
            updateAddButtonWhenNotEditingDisplay()
        }
        
        children.append(clear)
        children.append(by20)
        children.append(by10)
        children.append(by5)
        children.append(by2)
        children.append(by1)
        children.reverse()
        
        return UIMenu(title: menuTitle, children: children)
    }
    
    /** Provide a menu for this button*/
    func getMenuForSubtractButton()->UIMenu?{
        guard itemData != nil else {
            return nil
        }
        
        /** If this item requires a selection to be made in order to add the item then don't allow this menu to be displayed*/
        if itemData.itemChoices.isEmpty == false{
            var isSelectionRequired = false
            for choice in itemData.itemChoices{
                if choice.required == true{
                    isSelectionRequired = true
                    break
                }
            }
            if isSelectionRequired == true{
                return nil
            }
        }
        
        var children: [UIMenuElement] = []
        let menuTitle = "Decrement by:"
        
        let clear = UIAction(title: "Clear", image: UIImage(systemName: "trash.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light))){ [self] action in
            lightHaptic()
            
            itemData.count = 0
            updateDisplayForCountButton()
            
            hideItemCountEditingUI(animated: true)
            cart.clearAllInstancesOf(this: itemData)
            cart.updateThis(item: self.itemData)
            animateShapeLayerPathRemoving()
            
            updateBorder()
        }
        let by20 = UIAction(title: "-20", image: nil){ [self] action in
            lightHaptic()
            
            /** Don't go below the min quantity*/
            if (itemData.count - 20) >= minItems{
                itemData.count -= 20
                cart.updateThis(item: self.itemData)
                
                updateDisplayForCountButton()
            }
            else{
                /** Inform the user that they can't go below zero*/
                globallyTransmit(this: "You can't have negative clothes!", with: UIImage(systemName: "tshirt.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .rightStrip, animated: true, duration: 3, selfDismiss: true)
            }
            
            /** If there's 0 items then remove this item*/
            if itemData.count == minItems{
                hideItemCountEditingUI(animated: true)
                cart.removeThis(item: self.itemData)
                cart.updateThis(item: self.itemData)
                animateShapeLayerPathRemoving()
                
                updateBorder()
            }
        }
        let by10 = UIAction(title: "-10", image: nil){ [self] action in
            lightHaptic()
            
            if (itemData.count - 10) >= minItems{
                itemData.count -= 10
                cart.updateThis(item: self.itemData)
                
                updateDisplayForCountButton()
            }
            else{
                globallyTransmit(this: "You can't have negative clothes!", with: UIImage(systemName: "tshirt.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .rightStrip, animated: true, duration: 3, selfDismiss: true)
            }
            
            if itemData.count == minItems{
                hideItemCountEditingUI(animated: true)
                cart.removeThis(item: self.itemData)
                cart.updateThis(item: self.itemData)
                animateShapeLayerPathRemoving()
                
                updateBorder()
            }
        }
        let by5 = UIAction(title: "-5", image: nil){ [self] action in
            lightHaptic()
            
            if (itemData.count - 5) >= minItems{
                itemData.count -= 5
                cart.updateThis(item: self.itemData)
                
                updateDisplayForCountButton()
            }
            else{
                globallyTransmit(this: "You can't have negative clothes!", with: UIImage(systemName: "tshirt.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .rightStrip, animated: true, duration: 3, selfDismiss: true)
            }
            
            if itemData.count == minItems{
                hideItemCountEditingUI(animated: true)
                cart.removeThis(item: self.itemData)
                cart.updateThis(item: self.itemData)
                animateShapeLayerPathRemoving()
                
                updateBorder()
            }
        }
        let by2 = UIAction(title: "-2", image: nil){ [self] action in
            lightHaptic()
            
            if (itemData.count - 2) >= minItems{
                itemData.count -= 2
                cart.updateThis(item: self.itemData)
                
                updateDisplayForCountButton()
            }
            else{
                globallyTransmit(this: "You can't have negative clothes!", with: UIImage(systemName: "tshirt.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .rightStrip, animated: true, duration: 3, selfDismiss: true)
            }
            
            if itemData.count == minItems{
                hideItemCountEditingUI(animated: true)
                cart.removeThis(item: self.itemData)
                cart.updateThis(item: self.itemData)
                animateShapeLayerPathRemoving()
                
                updateBorder()
            }
        }
        let by1 = UIAction(title: "-1", image: nil){ [self] action in
            lightHaptic()
            
            if (itemData.count - 1) >= minItems{
                itemData.count -= 1
                cart.updateThis(item: self.itemData)
                
                updateDisplayForCountButton()
            }
            else{
                globallyTransmit(this: "You can't have negative clothes!", with: UIImage(systemName: "tshirt.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .rightStrip, animated: true, duration: 3, selfDismiss: true)
            }
            
            if itemData.count == minItems{
                hideItemCountEditingUI(animated: true)
                cart.removeThis(item: self.itemData)
                cart.updateThis(item: self.itemData)
                animateShapeLayerPathRemoving()
                
                updateBorder()
            }
        }
        
        children.append(clear)
        children.append(by20)
        children.append(by10)
        children.append(by5)
        children.append(by2)
        children.append(by1)
        /** Im lazy*/
        children.reverse()
        
        return UIMenu(title: menuTitle, children: children)
    }
    
    /** Update the item count button's label*/
    func updateDisplayForCountButton(){
        if itemData.count > 0{
            UIView.transition(with: itemCountButton, duration: 0.1, options: .transitionCrossDissolve, animations:{ [self] in
                itemCountButton.setTitle("\(cart.getTotalCountFor(this: itemData))", for: .normal)
            })
        }
        else{
            itemCountButton.setTitle(nil, for: .normal)
        }
    }
    
    /** Update the label for the add button when the user isn't fully editing the item count*/
    func updateAddButtonWhenNotEditingDisplay(){
        if editingItemCount == false{
            addButton.setImage(nil, for: .normal)
            addButton.setTitleColor(.white, for: .normal)
            addButton.setTitle("\(cart.getTotalCountFor(this: itemData))", for: .normal)
            addButton.titleLabel?.adjustsFontSizeToFitWidth = true
            addButton.titleLabel?.adjustsFontForContentSizeCategory = true
        }
    }
    
    /** Various garbage collection procedures*/
    override func prepareForReuse(){
        super.prepareForReuse()
        
        itemData = nil
        nameLabel = nil
        priceLabel = nil
        descriptionLabel = nil
        iconImageView = nil
        informationTagLabel = nil
        addButton = nil
        subtractButton = nil
        itemCountButton = nil
        itemCountButtonBackgroundView = nil
        container = nil
        shadowView = nil
        imageViewShapeLayer = nil
        cart = nil
        presentingVC = nil
        presentingTableView = nil
        
        for subview in contentView.subviews{
            subview.removeFromSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
