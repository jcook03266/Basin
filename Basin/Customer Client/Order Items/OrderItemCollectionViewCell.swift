//
//  OrderItemCollectionViewCell.swift
//  Basin
//
//  Created by Justin Cook on 4/18/22.
//

import UIKit
import Nuke

/** Collection view cell that will display an order item*/
class OrderItemCollectionViewCell: UICollectionViewCell{
    static let identifier = "OrderItemCollectionViewCell"
    /** Data passed to this cell*/
    var itemData: OrderItem!
    /** The name of this item*/
    var nameLabel: UILabel!
    /** The price of this item*/
    var priceLabel: PaddedLabel!
    /** Display the optional image for this item by parsing the given URL (if any)*/
    var iconImageView: UIImageView!
    /** Label that can display a small piece of information like a single word such as 'popular' to convey trends or availability*/
    var informationTagLabel: PaddedLabel!
    /** Button with a plus on it to inform the user they can add the following item*/
    var addButton: UIButton!
    /** Opposite of the add button, only revealed when the user adds an item*/
    var subtractButton: UIButton!
    /** itemCount Button that displays the amount of items currently added, this appears when one or more items have been added and disappears along with the subtract button when the item count = 0, max amount of duplicate items for one order is 100*/
    var itemCountButton: UIButton!
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
    /** The tableview from which the view originated from, can be used as a reference for refreshing when the cart data has been updated*/
    var presentingTableView: UITableView? = nil
    /** The collectionview from which the view originated from, can be used as a reference for refreshing when the cart data has been updated*/
    var presentingCollectionView: UICollectionView? = nil
    
    override init(frame: CGRect){
        super.init(frame: frame)
    }
    
    /** Provide the data needed to construct this object*/
    func create(with data: OrderItem, cart: Cart){
        /** Specify a maximum font size*/
        self.maximumContentSizeCategory = .large
        
        self.backgroundColor = .clear
        self.clipsToBounds = true
        self.itemData = data
        self.cart = cart
        
        /** For items that don't require further selections they can be edited from this cell directly, but they must use the item data directly from the cart in order to not mutate the reference item data passed to it*/
        for storedItem in cart.items{
            if areTheseItemsIdentical(item1: data, item2: storedItem){
                self.itemData = storedItem
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
        container = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width * 0.93, height: self.frame.height * 0.93))
        container.backgroundColor = bgColor
        container.layer.cornerRadius = container.frame.height/7
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
        nameLabel.frame.size = CGSize(width: container.frame.width * 0.9, height: container.frame.height * 0.25)
        nameLabel.font = getCustomFont(name: .Ubuntu_bold, size: 14, dynamicSize: true)
        nameLabel.backgroundColor = .clear
        nameLabel.textColor = fontColor
        nameLabel.textAlignment = .left
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.numberOfLines = 2
        nameLabel.lineBreakMode = .byWordWrapping
        nameLabel.text = data.name
        nameLabel.sizeToFit()
        
        priceLabel = PaddedLabel(withInsets: 0, 0, 0, 0)
        priceLabel.frame.size = CGSize(width: container.frame.width * 0.9, height: container.frame.height * 0.25)
        priceLabel.font = getCustomFont(name: .Ubuntu_Regular, size: 12, dynamicSize: true)
        priceLabel.text = "$\(String(format: "%.2f", data.price)) /Item"
        priceLabel.backgroundColor = .clear
        priceLabel.textColor = fontColor
        priceLabel.textAlignment = .left
        priceLabel.adjustsFontForContentSizeCategory = true
        priceLabel.adjustsFontSizeToFitWidth = true
        priceLabel.layer.masksToBounds = true
        priceLabel.attributedText = attribute(this: priceLabel.text!, font: getCustomFont(name: .Ubuntu_Regular, size: 12, dynamicSize: true), mainColor: fontColor, subColor: .lightGray, subString: "/Item")
        priceLabel.sizeToFit()
        
        informationTagLabel = PaddedLabel(withInsets: 1, 1, 2, 2)
        informationTagLabel.frame.size = CGSize(width: container.frame.width * 0.5, height: container.frame.height * 0.2)
        informationTagLabel.font = getCustomFont(name: .Ubuntu_Regular, size: 12, dynamicSize: true)
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
        
        iconImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: container.frame.width, height: container.frame.height/2))
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.backgroundColor = .white
        iconImageView.layer.cornerRadius = iconImageView.frame.height/5
        iconImageView.layer.borderWidth = 2
        iconImageView.layer.borderColor = appThemeColor.withAlphaComponent(0.2).cgColor
        iconImageView.clipsToBounds = true
        iconImageView.tintColor = appThemeColor
        
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
        addButton.frame.size = CGSize(width: container.frame.width, height: container.frame.height * 0.15)
        addButton.backgroundColor = appThemeColor
        addButton.contentHorizontalAlignment = .center
        addButton.layer.cornerRadius = 0
        addButton.isExclusiveTouch = true
        addButton.isEnabled = true
        addButton.isUserInteractionEnabled = true
        addButton.castDefaultShadow()
        addButton.layer.shadowColor = UIColor.darkGray.cgColor
        addButton.tintColor = .white
        addButton.setImage(UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        addButton.setTitleColor(.white, for: .normal)
        addButton.titleLabel?.adjustsFontSizeToFitWidth = true
        addButton.titleLabel?.adjustsFontForContentSizeCategory = true
        addButton.addTarget(self, action: #selector(addButtonPressed), for: .touchUpInside)
        addButton.menu = getMenuForAddButton()
        addDynamicButtonGR(button: addButton)
        
        subtractButton = UIButton()
        subtractButton.frame.size = CGSize(width: container.frame.width/2, height: container.frame.height * 0.15)
        subtractButton.backgroundColor = appThemeColor
        subtractButton.contentHorizontalAlignment = .center
        subtractButton.layer.cornerRadius = 0
        subtractButton.isExclusiveTouch = true
        subtractButton.isEnabled = true
        subtractButton.isUserInteractionEnabled = false
        subtractButton.castDefaultShadow()
        subtractButton.layer.shadowColor = UIColor.darkGray.cgColor
        subtractButton.tintColor = .white
        subtractButton.setImage(UIImage(systemName: "minus", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        subtractButton.setTitleColor(.white, for: .normal)
        subtractButton.titleLabel?.adjustsFontSizeToFitWidth = true
        subtractButton.titleLabel?.adjustsFontForContentSizeCategory = true
        subtractButton.addTarget(self, action: #selector(subtractButtonPressed), for: .touchUpInside)
        subtractButton.menu = getMenuForSubtractButton()
        addDynamicButtonGR(button: subtractButton)
        
        itemCountButton = UIButton()
        itemCountButton.frame.size = CGSize(width: iconImageView.frame.width/4, height: iconImageView.frame.width/4)
        itemCountButton.backgroundColor = appThemeColor
        itemCountButton.contentHorizontalAlignment = .center
        itemCountButton.layer.cornerRadius = itemCountButton.frame.height/2
        itemCountButton.isExclusiveTouch = true
        itemCountButton.castDefaultShadow()
        itemCountButton.layer.shadowColor = UIColor.darkGray.cgColor
        itemCountButton.isEnabled = true
        itemCountButton.isUserInteractionEnabled = false
        itemCountButton.tintColor = .white
        itemCountButton.setTitleColor(.white, for: .normal)
        
        /** Hide the button if its not present in the cart*/
        if cart.getTotalCountFor(this: itemData) == 0{
            itemCountButton.alpha = 0
        }
        
        itemCountButton.setTitle("\(cart.getTotalCountFor(this: itemData))", for: .normal)
        itemCountButton.titleLabel?.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: true)
        itemCountButton.titleLabel?.adjustsFontSizeToFitWidth = true
        itemCountButton.titleLabel?.adjustsFontForContentSizeCategory = true
        
        /** Layout these subviews*/
        shadowView.frame.origin = CGPoint(x: self.frame.width/2 - shadowView.frame.width/2, y: self.frame.height/2 - shadowView.frame.height/2)
        
        container.frame.origin = CGPoint(x: shadowView.frame.width/2 - container.frame.width/2, y: shadowView.frame.height/2 - container.frame.height/2)
        
        iconImageView.frame.origin = CGPoint(x: container.frame.width/2 - iconImageView.frame.width/2, y: 0)
        
        nameLabel.frame.origin = CGPoint(x: container.frame.width * 0.05, y: iconImageView.frame.maxY + 5)
        
        priceLabel.frame.origin = CGPoint(x: nameLabel.frame.minX, y: nameLabel.frame.maxY + 5)
        
        informationTagLabel.frame.origin = CGPoint(x: 0, y: iconImageView.frame.maxY - (informationTagLabel.frame.height * 1.15))
        
        addButton.frame.origin = CGPoint(x: container.frame.width/2 - addButton.frame.width/2, y: container.frame.maxY - addButton.frame.height * 1)
        
        subtractButton.frame.origin = CGPoint(x: 0 - subtractButton.frame.width, y: 0)
        subtractButton.center.y = addButton.center.y
        
        itemCountButton.frame.origin = CGPoint(x: container.frame.width - itemCountButton.frame.width, y: iconImageView.frame.maxY - itemCountButton.frame.height)
        
        /** Add subviews to content view*/
        shadowView.addSubview(container)
        self.container.addSubview(nameLabel)
        self.container.addSubview(priceLabel)
        self.container.addSubview(iconImageView)
        self.container.addSubview(informationTagLabel)
        self.container.addSubview(addButton)
        self.container.addSubview(subtractButton)
        self.container.addSubview(itemCountButton)
        self.contentView.addSubview(shadowView)
    }
    
    /** Update these data sensitive views that are within the view hierarchy*/
    func updatePresentingViews(){
        /** Reload the presenting table view using the updated cart data*/
        if presentingTableView != nil{
            presentingTableView!.reloadData()
        }
    }
    
    /** Increment the item counter and present the decrement button and counter label*/
    @objc func addButtonPressed(sender: UIButton){
        guard itemData != nil else {
            return
        }
        
        /** If this item requires a selection to be made in order to add the item then push the detail view controller for this item where the user can then make their selection and also add any additional duplicates to the overall count for this item*/
        if itemData.isSelectionRequired() == true{
            lightHaptic()
            
            let vc = OrderItemDetailVC(itemData: self.itemData, laundromatCart: self.cart, laundromatMenu: self.itemData.menu)
            vc.presentingTableView = self.presentingTableView
            vc.presentingCollectionView = self.presentingCollectionView
            
            if presentingVC != nil{
                /** Prevent the user from using interactive dismissal*/
                vc.isModalInPresentation = true
                presentingVC!.show(vc, sender: presentingVC)
            }
            
            return
        }
        
        if editingItemCount == false && itemData.count != 0{
            /** User must press the button again to add an item if they've already added items*/
            updateEditingUI(animated: true)
            return
        }
        else if editingItemCount == false && itemData.count == 0{
            updateEditingUI(animated: true)
            showEditingUI(animated: true)
        }
        
        if itemData.count < maxItems{
            self.itemData.count += 1
            lightHaptic()
            
            /** Add the item to the given cart*/
            if itemData.count == 1{
                cart.addThis(item: self.itemData)
                
                updateBorder()
            }
            else{
                /** Send an update to the delegate listeners to tell them the item has been updated*/
                cart.updateThis(item: self.itemData)
            }
            
            if itemData.count == 1{
                animatedBorderUpdate()
            }
            
            updateDisplayForCountButton()
        }
        else{
            itemData.count = maxItems
            errorShake()
            globallyTransmit(this: "Maximum number of items reached for this item", with: UIImage(systemName: "tshirt.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .rightStrip, animated: true, duration: 3, selfDismiss: true)
        }
        
        updatePresentingViews()
    }
    
    /** Decrement the item counter and present the decrement button and counter label*/
    @objc func subtractButtonPressed(sender: UIButton){
        guard itemData != nil else{
            return
        }
        
        if itemData.count > minItems{
            self.itemData.count -= 1
            lightHaptic()
            
            updateDisplayForCountButton()
        }
        else{
            itemData.count = 0
            errorShake()
            
            /** Inform the user that they can't go below zero*/
            globallyTransmit(this: "You can't have negative clothes!", with: UIImage(systemName: "tshirt.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .rightStrip, animated: true, duration: 3, selfDismiss: true)
        }
        
        if itemData.count == 0{
            updateEditingUI(animated: true)
            
            /** Remove the item from the given cart*/
            cart.removeThis(item: self.itemData)
            
            updateBorder()
        }
        else{
            /** Send an update to the delegate listeners to tell them the item has been updated*/
            cart.updateThis(item: self.itemData)
        }
        
        animatedBorderUpdate()
        updatePresentingViews()
    }
    
    /** Update the border in an animated fashion to reflect if the current cart has this item or not*/
    func animatedBorderUpdate(){
        guard cart != nil && container != nil && itemData != nil else {
            return
        }
        
        /** If this item is already in the user's cart then highlight the cell*/
        if self.cart.getTotalCountFor(this: self.itemData) > 0{
            UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseIn]){
                self.container.layer.borderWidth = 2
                self.container.layer.borderColor = appThemeColor.cgColor
            }
        }
        else{
            UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseIn]){
                self.container.layer.borderWidth = 0
                self.container.layer.borderColor = UIColor.clear.cgColor
            }
        }
    }
    
    /** Update the item count button's label*/
    func updateDisplayForCountButton(){
        UIView.transition(with: itemCountButton, duration: 0.1, options: .transitionCrossDissolve, animations:{ [self] in
            itemCountButton.setTitle("\(cart.getTotalCountFor(this: itemData))", for: .normal)
        })
        
        if self.cart.getTotalCountFor(this: self.itemData) > 0{
            /** Don't execute unneccessary animations*/
            guard itemCountButton.alpha == 0 else{
                return
            }
            UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseIn]){[self] in
                itemCountButton.alpha = 1
            }
        }
        else{
            guard itemCountButton.alpha == 1 else {
                return
            }
            
            UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseIn]){[self] in
                itemCountButton.alpha = 0
            }
        }
    }
    
    /** Hide and or show the editing UI in an animated or static fashion*/
    func showEditingUI(animated: Bool){
        subtractButton.isUserInteractionEnabled = true
        editingItemCount = true
        
        switch animated{
        case true:
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
                addButton.frame.size.width = container.frame.width/2
                subtractButton.frame.origin.x = 0
                addButton.frame.origin.x = subtractButton.frame.maxX
            }
        case false:
            addButton.frame.size.width = container.frame.width/2
            subtractButton.frame.origin.x = 0
            addButton.frame.origin.x = subtractButton.frame.maxX
        }
    }
    func hideEditingUI(animated: Bool){
        subtractButton.isUserInteractionEnabled = false
        editingItemCount = false
        
        switch animated{
        case true:
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
                addButton.frame.size.width = container.frame.width
                subtractButton.frame.origin.x = -subtractButton.frame.width
                addButton.frame.origin.x = 0
            }
        case false:
            addButton.frame.size.width = container.frame.width
            subtractButton.frame.origin.x = -subtractButton.frame.width
            addButton.frame.origin.x = 0
        }
    }
    
    /** Resize the add button and hide or show the subtract button in an animated or static fashion*/
    func updateEditingUI(animated: Bool){
        updateDisplayForCountButton()
        
        /** This item is in the cart so display the add and subtract button*/
        if self.cart.getTotalCountFor(this: self.itemData) > 0{
            showEditingUI(animated: true)
        }
        else{
            /** This item is not in the cart so hide the subtract button and resize the add button*/
            hideEditingUI(animated: true)
        }
    }
    
    /** Provide a menu for this button*/
    func getMenuForAddButton()->UIMenu?{
        guard itemData != nil else {
            return nil
        }
        
        /** If this item requires a selection to be made in order to add the item then don't allow this menu to be displayed*/
        if itemData.isSelectionRequired() == true{
            return nil
        }
        
        var children: [UIMenuElement] = []
        let menuTitle = "Increment by:"
        
        let clear = UIAction(title: "Clear", image: UIImage(systemName: "trash.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light))){ [self] action in
            lightHaptic()
            
            itemData.count = 0
            
            hideEditingUI(animated: true)
            cart.clearAllInstancesOf(this: itemData)
            
            updateBorder()
            updateDisplayForCountButton()
        }
        let by20 = UIAction(title: "+20", image: nil){ [self] action in
            lightHaptic()
            
            /** If this item's quantity was 0 prior then add it to the cart now*/
            if itemData.count == minItems{
                itemData.count += 20
                
                showEditingUI(animated: true)
                cart.addThis(item: itemData)
                
                updateBorder()
                updateDisplayForCountButton()
            }
            else if (itemData.count + 20) < maxItems{
                /** Don't go over the max quantity*/
                itemData.count += 20
                cart.updateThis(item: self.itemData)
                
                updateDisplayForCountButton()
            }
            else if itemData.count == maxItems{
                /** Max num of items reached, inform the user*/
                itemData.count = maxItems
                errorShake()
                globallyTransmit(this: "Maximum number of items reached for this item", with: UIImage(systemName: "tshirt.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .rightStrip, animated: true, duration: 3, selfDismiss: true)
            }
        }
        let by10 = UIAction(title: "+10", image: nil){ [self] action in
            lightHaptic()
            
            if itemData.count == minItems{
                itemData.count += 10
                
                showEditingUI(animated: true)
                cart.addThis(item: itemData)
                
                updateBorder()
                updateDisplayForCountButton()
            }
            else if (itemData.count + 10) < maxItems{
                itemData.count += 10
                cart.updateThis(item: self.itemData)
                
                updateDisplayForCountButton()
            }
            else if itemData.count == maxItems{
                itemData.count = maxItems
                errorShake()
                globallyTransmit(this: "Maximum number of items reached for this item", with: UIImage(systemName: "tshirt.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .rightStrip, animated: true, duration: 3, selfDismiss: true)
            }
        }
        let by5 = UIAction(title: "+5", image: nil){ [self] action in
            lightHaptic()
            
            if itemData.count == minItems{
                itemData.count += 5
                
                showEditingUI(animated: true)
                cart.addThis(item: itemData)
                
                updateBorder()
                updateDisplayForCountButton()
            }
            else if (itemData.count + 5) < maxItems{
                itemData.count += 5
                cart.updateThis(item: self.itemData)
                
                updateDisplayForCountButton()
            }
            else if itemData.count == maxItems{
                itemData.count = maxItems
                errorShake()
                globallyTransmit(this: "Maximum number of items reached for this item", with: UIImage(systemName: "tshirt.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .rightStrip, animated: true, duration: 3, selfDismiss: true)
            }
        }
        let by2 = UIAction(title: "+2", image: nil){ [self] action in
            lightHaptic()
            
            if itemData.count == minItems{
                itemData.count += 2
                
                showEditingUI(animated: true)
                cart.addThis(item: itemData)
                
                updateBorder()
                updateDisplayForCountButton()
            }
            else if (itemData.count + 2) < maxItems{
                itemData.count += 2
                cart.updateThis(item: self.itemData)
                
                updateDisplayForCountButton()
            }
            else if itemData.count == maxItems{
                itemData.count = maxItems
                errorShake()
                globallyTransmit(this: "Maximum number of items reached for this item", with: UIImage(systemName: "tshirt.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .rightStrip, animated: true, duration: 3, selfDismiss: true)
            }
        }
        let by1 = UIAction(title: "+1", image: nil){ [self] action in
            lightHaptic()
            
            if itemData.count == minItems{
                itemData.count += 1
                
                showEditingUI(animated: true)
                cart.addThis(item: itemData)
                
                updateBorder()
                updateDisplayForCountButton()
            }
            else if (itemData.count + 1) < maxItems{
                itemData.count += 1
                cart.updateThis(item: self.itemData)
                
                updateDisplayForCountButton()
            }
            else if itemData.count == maxItems{
                itemData.count = maxItems
                errorShake()
                globallyTransmit(this: "Maximum number of items reached for this item", with: UIImage(systemName: "tshirt.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .rightStrip, animated: true, duration: 3, selfDismiss: true)
            }
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
        if itemData.isSelectionRequired() == true{
            return nil
        }
        
        var children: [UIMenuElement] = []
        let menuTitle = "Decrement by:"
        
        let clear = UIAction(title: "Clear", image: UIImage(systemName: "trash.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light))){ [self] action in
            lightHaptic()
            
            itemData.count = 0
            updateDisplayForCountButton()
            
            hideEditingUI(animated: true)
            cart.clearAllInstancesOf(this: itemData)
            
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
                hideEditingUI(animated: true)
                cart.removeThis(item: self.itemData)
                
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
                hideEditingUI(animated: true)
                cart.removeThis(item: self.itemData)
                
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
                hideEditingUI(animated: true)
                cart.removeThis(item: self.itemData)
                
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
                hideEditingUI(animated: true)
                cart.removeThis(item: self.itemData)
                
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
                hideEditingUI(animated: true)
                cart.removeThis(item: self.itemData)
                
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
    
    /** Change the border to reflect whether or not this item is in the user's cart currently*/
    func updateBorder(){
        guard cart != nil && container != nil && itemData != nil else {
            return
        }
        
        /** If this item is already in the user's cart then highlight the cell*/
        if self.cart.getTotalCountFor(this: self.itemData) > 0{
            self.container.layer.borderWidth = 2
            self.container.layer.borderColor = appThemeColor.cgColor
        }
        else{
            self.container.layer.borderWidth = 0
            self.container.layer.borderColor = UIColor.clear.cgColor
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
    }
    
    /** Generic recognizer that scales the button up when the user drags their finger into it*/
    @objc func buttonDEN(sender: UIButton){
    }
    
    /** Generic recognizer that scales the button up when the user drags their finger out inside of it*/
    @objc func buttonDE(sender: UIButton){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
            lightHaptic()
        }
    }
    
    /** Show where the user taps on the screen*/
    @objc func viewSingleTapped(sender: UITapGestureRecognizer){
        guard container != nil else {
            return
        }
        
        /** Don't trigger the animation if the user is pressing any of the following views*/
        guard addButton.frame.contains(sender.location(in: container)) == false && subtractButton.frame.contains(sender.location(in: container)) == false else{
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
    
    /** Various garbage collection procedures*/
    override func prepareForReuse(){
        super.prepareForReuse()
        
        itemData = nil
        nameLabel = nil
        priceLabel = nil
        addButton = nil
        subtractButton = nil
        itemCountButton = nil
        iconImageView = nil
        informationTagLabel = nil
        container = nil
        shadowView = nil
        cart = nil
        
        for subview in contentView.subviews{
            subview.removeFromSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
