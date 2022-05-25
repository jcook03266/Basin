//
//  ShoppingCartItemsTableViewCell.swift
//  Basin
//
//  Created by Justin Cook on 5/15/22.
//

import UIKit
import Nuke

class ShoppingCartItemsTableViewCell: UITableViewCell{
    static let identifier = "ShoppingCartItemsTableViewCell"
    /** The order item data to be displayed inside of this cell*/
    var itemData: OrderItem!
    /** Display the name of this item*/
    var nameLabel: UILabel!
    /** Display the price for this item*/
    var priceLabel: UILabel!
    /** Display the image for this item to make it easier for the user to navigate the search results*/
    var itemImageView: UIImageView!
    /** Animatable path around the iconImageView that's filled in when the user has the item in their cart*/
    var imageViewShapeLayer: CAShapeLayer!
    /** itemCount Button that displays the amount of items currently added, this appears when one or more items have been added and disappears along with the subtract button when the item count = 0, max amount of duplicate items for one order is 100*/
    var itemCountButton: UIButton!
    /** Label that reflects the total cost of this item when selections and quantity is taken into account*/
    var totalItemPriceLabel: PaddedLabel!
    /** Reflect the currently selected choices*/
    var currentlySelectedChoicesLabel: UILabel!
    /** Container to hold the content and potentially pad it*/
    var container: UIView!
    /** The cart object that will be used to store this object if the user chooses to add it*/
    var cart: Cart! = nil
    /** The view controller this cell is being displayed in*/
    var presentingVC: UIViewController? = nil
    /** The tableview from which this detail view originated from, can be used as a reference for refreshing when the cart data has been updated*/
    var presentingTableView: UITableView? = nil
    /** Pan gesture recognizer for scrolling the view to reveal the swipe actions beneath it*/
    var panGestureRecognizer: UIPanGestureRecognizer!
    /** The point up to which the user can swipe in order to reveal the button beneath it, the user can't swipe past this point*/
    var panGestureThreshold: CGFloat{
        return (0 - self.frame.width/4)
    }
    /** Long press gesture recognizer allows the pan gesture recognizer to not conflict with the pan gesture recognizer of the scrollview, this pan gesture recognizer kicks in after a delay triggered by the user keeping their finger on the view*/
    var longPressGestureRecognizer: UILongPressGestureRecognizer!
    /** Button behind the container that allows the user to remove this item from the cart and the subsequent table view*/
    var removeSwipeActionButton: UIButton!
    var removeSwipeActionButtonAction: UIAction!
    /** Use this to hide the swipe action when the user scrolls the tableview*/
    var swipeActionExposed: Bool = false
    /** Maintain a global copy of the current horizontal position of the button in order to remember the last resting position of the button*/
    var currentXPosition: CGFloat! = .zero
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: ShoppingCartItemsTableViewCell.identifier)
    }
    
    /** Create a view with an imageview, a name label and a price label to display when a user searches for a specific item in the menu*/
    func create(with data: OrderItem, cart: Cart){
        /** Specify a maximum font size*/
        self.maximumContentSizeCategory = .large
        
        self.backgroundColor = .clear
        self.selectionStyle = .none
        self.contentView.clipsToBounds = true
        self.itemData = data
        self.cart = cart
        
        /** Add a single tap gesture recognizer to highlight where the user touches the cell*/
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(viewSingleTapped))
        singleTap.numberOfTapsRequired = 1
        singleTap.numberOfTouchesRequired = 1
        singleTap.requiresExclusiveTouchType = true
        singleTap.cancelsTouchesInView = false
        self.addGestureRecognizer(singleTap)
        
        container = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width * 0.95, height: self.frame.height * 0.95))
        container.backgroundColor = .clear
        container.layer.cornerRadius = 0
        container.clipsToBounds = true
        
        nameLabel = UILabel()
        nameLabel.frame.size = CGSize(width: container.frame.width * 0.6, height: (self.itemData.hasSelections() ? ((container.frame.height * 0.325) - 5) : ((container.frame.height * 0.4) - 5)))
        nameLabel.font = getCustomFont(name: .Ubuntu_Medium, size: 14, dynamicSize: true)
        nameLabel.backgroundColor = .clear
        nameLabel.textColor = fontColor
        nameLabel.textAlignment = .left
        nameLabel.adjustsFontForContentSizeCategory = false
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.numberOfLines = 1
        nameLabel.lineBreakMode = .byClipping
        nameLabel.text = itemData.name
        nameLabel.sizeToFit()
        
        priceLabel = UILabel()
        priceLabel.frame.size = CGSize(width: container.frame.width * 0.6, height: (self.itemData.hasSelections() ? ((container.frame.height * 0.325) - 5) : ((container.frame.height * 0.4) - 5)))
        priceLabel.font = getCustomFont(name: .Ubuntu_Regular, size: 13, dynamicSize: false)
        priceLabel.text = "$\(String(format: "%.2f", itemData.price)) /Item"
        priceLabel.backgroundColor = .clear
        priceLabel.textColor = fontColor
        priceLabel.textAlignment = .left
        priceLabel.adjustsFontForContentSizeCategory = false
        priceLabel.adjustsFontSizeToFitWidth = true
        priceLabel.layer.masksToBounds = true
        priceLabel.attributedText = attribute(this: priceLabel.text!, font: getCustomFont(name: .Ubuntu_Regular, size: 13, dynamicSize: true), mainColor: fontColor, subColor: .lightGray, subString: "/Item")
        priceLabel.sizeToFit()
        
        itemImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: container.frame.width * 0.25, height: container.frame.height * 0.95))
        itemImageView.contentMode = .scaleAspectFit
        itemImageView.backgroundColor = .white
        itemImageView.layer.cornerRadius = itemImageView.frame.height/5
        itemImageView.layer.borderWidth = 2
        itemImageView.layer.borderColor = appThemeColor.withAlphaComponent(0.2).cgColor
        itemImageView.clipsToBounds = true
        itemImageView.tintColor = appThemeColor
        
        if let url = URL(string: itemData.photoURL ?? ""){
            let request = ImageRequest(url: url)
            let options = ImageLoadingOptions(
                transition: .fadeIn(duration: 0.5)
            )
            
            Nuke.loadImage(with: request, options: options, into: itemImageView){ _ in
            }
        }
        else{
            /** No image provided so use a default placeholder stored in the assets collection*/
            itemImageView.image = UIImage(named: "placeholderLaundryIcon")
        }
        
        itemCountButton = UIButton()
        itemCountButton.frame.size = CGSize(width: itemImageView.frame.width/3, height: itemImageView.frame.width/3)
        itemCountButton.backgroundColor = appThemeColor
        itemCountButton.contentHorizontalAlignment = .center
        itemCountButton.layer.cornerRadius = itemCountButton.frame.height/2
        itemCountButton.isExclusiveTouch = true
        itemCountButton.isEnabled = true
        itemCountButton.isUserInteractionEnabled = false
        itemCountButton.tintColor = .white
        itemCountButton.setTitleColor(.white, for: .normal)
        
        /** Hide the button if its not present in the cart*/
        if cart.getTotalCountFor(this: itemData) == 0{
            itemCountButton.alpha = 0
        }
        
        itemCountButton.setTitle("\(itemData.count)", for: .normal)
        itemCountButton.titleLabel?.font = getCustomFont(name: .Ubuntu_Regular, size: 15, dynamicSize: true)
        itemCountButton.titleLabel?.adjustsFontSizeToFitWidth = true
        itemCountButton.titleLabel?.adjustsFontForContentSizeCategory = true
        
        /** Button will have a width equal to the threshold value plus the padding (10 pts)*/
        removeSwipeActionButton = UIButton(frame: CGRect(x: 0, y: 0, width: (panGestureThreshold + 10), height: container.frame.height))
        removeSwipeActionButton.backgroundColor = .red
        removeSwipeActionButton.contentHorizontalAlignment = .center
        removeSwipeActionButton.layer.cornerRadius = removeSwipeActionButton.frame.height/5
        removeSwipeActionButton.isExclusiveTouch = true
        removeSwipeActionButton.isEnabled = true
        removeSwipeActionButton.tintColor = .white
        removeSwipeActionButton.setImage(UIImage(systemName: "cart.fill.badge.minus", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        removeSwipeActionButton.setTitleColor(.white, for: .normal)
        removeSwipeActionButton.setTitle(" Remove", for: .normal)
        removeSwipeActionButton.titleLabel?.font = getCustomFont(name: .Ubuntu_Regular, size: 15, dynamicSize: true)
        removeSwipeActionButton.titleLabel?.adjustsFontSizeToFitWidth = true
        removeSwipeActionButton.titleLabel?.adjustsFontForContentSizeCategory = true
        removeSwipeActionButton.clipsToBounds = true
        removeSwipeActionButton.addAction(removeSwipeActionButtonAction, for: .touchUpInside)
        addDynamicButtonGR(button: removeSwipeActionButton)
        
        totalItemPriceLabel = PaddedLabel(withInsets: 1, 1, 3, 3)
        totalItemPriceLabel.frame.size = CGSize(width: itemImageView.frame.width/2, height: itemImageView.frame.width/3)
        totalItemPriceLabel.font = getCustomFont(name: .Ubuntu_Regular, size: 16, dynamicSize: true)
        totalItemPriceLabel.text = "$\(String(format: "%.2f", itemData.getSubtotal()))"
        totalItemPriceLabel.backgroundColor = appThemeColor
        totalItemPriceLabel.textColor = fontColor
        totalItemPriceLabel.textAlignment = .center
        totalItemPriceLabel.adjustsFontForContentSizeCategory = true
        totalItemPriceLabel.adjustsFontSizeToFitWidth = true
        totalItemPriceLabel.clipsToBounds = true
        totalItemPriceLabel.sizeToFit()
        totalItemPriceLabel.layer.cornerRadius = totalItemPriceLabel.frame.height/2
        
        currentlySelectedChoicesLabel = UILabel()
        currentlySelectedChoicesLabel.frame.size = CGSize(width: container.frame.width * 0.7, height: (self.itemData.hasSelections() ? ((container.frame.height * 0.325) - 5) : ((container.frame.height * 0.4) - 5)))
        currentlySelectedChoicesLabel.font = getCustomFont(name: .Ubuntu_Regular, size: 12, dynamicSize: false)
        currentlySelectedChoicesLabel.text = self.itemData.getTextualRepresentationOfSelectedChoices(from: self.itemData.getCurrentlySelectedChoices(), using: "•")
        currentlySelectedChoicesLabel.backgroundColor = .clear
        currentlySelectedChoicesLabel.textColor = fontColor.darker
        currentlySelectedChoicesLabel.textAlignment = .left
        currentlySelectedChoicesLabel.adjustsFontForContentSizeCategory = false
        currentlySelectedChoicesLabel.adjustsFontSizeToFitWidth = true
        currentlySelectedChoicesLabel.sizeToFit()
        
        /** Layout subviews*/
        container.frame.origin = CGPoint(x: self.frame.width/2 - container.frame.width/2, y: self.frame.height/2 - container.frame.height/2)
        /** Setting the initial position of the container's x position*/
        currentXPosition = container.frame.minX
        
        itemCountButton.frame.origin = CGPoint(x: 0, y: 5)
        
        nameLabel.frame.origin = CGPoint(x: itemCountButton.frame.maxX + 5, y: 5)
        
        priceLabel.frame.origin = CGPoint(x: nameLabel.frame.minX, y: nameLabel.frame.maxY + 5)
        
        itemImageView.frame.origin = CGPoint(x: container.frame.maxX - (itemImageView.frame.width * 1.25), y: container.frame.height/2 - itemImageView.frame.height/2)
        
        totalItemPriceLabel.frame.origin = CGPoint(x: itemImageView.frame.maxX - (totalItemPriceLabel.frame.width * 0.95), y: itemImageView.frame.maxY - (totalItemPriceLabel.frame.height * 0.95))
        
        currentlySelectedChoicesLabel.frame.origin = CGPoint(x: nameLabel.frame.minX, y: priceLabel.frame.maxY + 5)
        
        removeSwipeActionButton.frame.origin = CGPoint(x: self.frame.maxX, y: 0)
        removeSwipeActionButton.center.y = container.center.y
        removeSwipeActionButton.frame.size.width = 0
        
        /** Configure pan gesture recognizer*/
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerTriggered))
        panGestureRecognizer.maximumNumberOfTouches = 1
        panGestureRecognizer.delegate = self
        panGestureRecognizer.isEnabled = false
        container.addGestureRecognizer(panGestureRecognizer)
        
        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressGestureRecognizerTriggered))
        longPressGestureRecognizer.delegate = self
        longPressGestureRecognizer.minimumPressDuration = 0.15
        self.addGestureRecognizer(longPressGestureRecognizer)
        
        container.addSubview(nameLabel)
        container.addSubview(priceLabel)
        container.addSubview(itemImageView)
        container.addSubview(itemCountButton)
        container.addSubview(totalItemPriceLabel)
        if itemData.hasSelections() == true{
            container.addSubview(currentlySelectedChoicesLabel)
        }
        self.contentView.addSubview(removeSwipeActionButton)
        self.contentView.addSubview(container)
    }
    
    @objc func longPressGestureRecognizerTriggered(sender: UILongPressGestureRecognizer){
        panGestureRecognizer.isEnabled = true
    }
    
    /** Move the cell's content up to a specified threshold value to reveal and hide a swipe action beneath the visible content*/
    @objc func panGestureRecognizerTriggered(sender: UIPanGestureRecognizer){
        guard container != nil else {
            return
        }
        
        /** Current movement of the user's finger in the following view*/
        let translation = sender.translation(in: container)
        let horizontalOffset = translation.x
        
        /** The far left edge of the container that's being translated*/
        let containerEdge = container.frame.minX
        /** The absolute starting position of the container*/
        let originalXPosition: CGFloat = self.frame.width/2 - container.frame.width/2
        
        /** Move*/
        if sender.state == .changed || sender.state == .began || sender.state == .possible{
            /** First term -> Lowerbound, it can't move lower than this value - 10pts*/
            /** && Second term -> Upperbound, it can't move higher than this value + 10pts*/
            if (currentXPosition + horizontalOffset) > (panGestureThreshold - 10) && (currentXPosition + horizontalOffset) < (originalXPosition + 10){
                
                /** Disable scrolling if the pan gesture is currently functioning*/
                if presentingTableView != nil{
                presentingTableView!.isScrollEnabled = false
                }
                
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .beginFromCurrentState]){[self] in
                    container.frame.origin.x = currentXPosition + horizontalOffset
                    
                    /** Resize and reposition the button*/
                    let containerDisplacement = (self.frame.maxX - container.frame.maxX)
                    let containerShiftFromOriginalPosition = (originalXPosition - container.frame.origin.x)
                    let buttonSize = (self.frame.maxX - container.frame.maxX) * 0.9
                    if containerShiftFromOriginalPosition >= 1{
                    removeSwipeActionButton.frame.size.width = buttonSize
                    }
                    else{
                    removeSwipeActionButton.frame.size.width = 0
                    }
                    removeSwipeActionButton.frame.origin = CGPoint(x: self.frame.maxX - (buttonSize + (containerDisplacement - buttonSize)/2), y: removeSwipeActionButton.frame.minY)
                }
            }
        }
        
        /** Rest*/
        if sender.state == .ended || sender.state == .cancelled || sender.state == .failed{
            /** Enable scrolling when the pan gesture ends*/
            if presentingTableView != nil{
            presentingTableView!.isScrollEnabled = true
            }
            
            panGestureRecognizer.isEnabled = false
            
            if containerEdge <= panGestureThreshold/2{
                /** View is now resting, save this new position*/
                currentXPosition = panGestureThreshold
                
                swipeActionExposed = true
                
                /** Go to the threshold value*/
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .beginFromCurrentState]){[self] in
                    container.frame.origin.x = panGestureThreshold
                    
                    /** Resize and reposition the button*/
                    let containerDisplacement = (self.frame.maxX - container.frame.maxX)
                    let buttonSize = (self.frame.maxX - container.frame.maxX) * 0.9
                    removeSwipeActionButton.frame.size.width = buttonSize
                    removeSwipeActionButton.frame.origin = CGPoint(x: self.frame.maxX - (buttonSize + (containerDisplacement - buttonSize)/2), y: removeSwipeActionButton.frame.minY)
                }
            }
            else{
                currentXPosition = originalXPosition
                
                swipeActionExposed = false
                
                /** Go back to the starting point*/
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .beginFromCurrentState]){[self] in
                    container.frame.origin.x = originalXPosition
                    
                    /** Resize and reposition the button*/
                    let containerDisplacement = (self.frame.maxX - container.frame.maxX)
                    let buttonSize: CGFloat = 0
                    removeSwipeActionButton.frame.size.width = 0
                    removeSwipeActionButton.frame.origin = CGPoint(x: self.frame.maxX - (buttonSize + (containerDisplacement - buttonSize)/2), y: removeSwipeActionButton.frame.minY)
                }
            }
        }
    }

    /** Allow for simultaneous gesture recognition for the scrollview*/
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    /** Show the swipe action if it's exposed in a static or animated fashion*/
    func showSwipeAction(animated: Bool){
        /** View is now resting, save this new position*/
        currentXPosition = panGestureThreshold
        
        swipeActionExposed = true
        
        switch animated{
        case true:
            /** Go to the threshold value*/
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .beginFromCurrentState]){[self] in
                container.frame.origin.x = panGestureThreshold
                
                /** Resize and reposition the button*/
                let containerDisplacement = (self.frame.maxX - container.frame.maxX)
                let buttonSize = (self.frame.maxX - container.frame.maxX) * 0.9
                removeSwipeActionButton.frame.size.width = buttonSize
                removeSwipeActionButton.frame.origin = CGPoint(x: self.frame.maxX - (buttonSize + (containerDisplacement - buttonSize)/2), y: removeSwipeActionButton.frame.minY)
            }
        case false:
            container.frame.origin.x = panGestureThreshold
            
            /** Resize and reposition the button*/
            let containerDisplacement = (self.frame.maxX - container.frame.maxX)
            let buttonSize = (self.frame.maxX - container.frame.maxX) * 0.9
            removeSwipeActionButton.frame.size.width = buttonSize
            removeSwipeActionButton.frame.origin = CGPoint(x: self.frame.maxX - (buttonSize + (containerDisplacement - buttonSize)/2), y: removeSwipeActionButton.frame.minY)
        }
    }
    
    /** Hide the swipe action if it's exposed in a static or animated fashion*/
    func hideSwipeAction(animated: Bool){
        /** The absolute starting position of the container*/
        let originalXPosition: CGFloat = self.frame.width/2 - container.frame.width/2
        currentXPosition = originalXPosition
        swipeActionExposed = false
        
        switch animated{
        case true:
            /** Go back to the starting point*/
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .beginFromCurrentState]){[self] in
                container.frame.origin.x = originalXPosition
                
                /** Resize and reposition the button*/
                let containerDisplacement = (self.frame.maxX - container.frame.maxX)
                let buttonSize: CGFloat = 0
                removeSwipeActionButton.frame.size.width = 0
                removeSwipeActionButton.frame.origin = CGPoint(x: self.frame.maxX - (buttonSize + (containerDisplacement - buttonSize)/2), y: removeSwipeActionButton.frame.minY)
            }
        case false:
            container.frame.origin.x = originalXPosition
            
            /** Resize and reposition the button*/
            let containerDisplacement = (self.frame.maxX - container.frame.maxX)
            let buttonSize: CGFloat = 0
            removeSwipeActionButton.frame.size.width = 0
            removeSwipeActionButton.frame.origin = CGPoint(x: self.frame.maxX - (buttonSize + (containerDisplacement - buttonSize)/2), y: removeSwipeActionButton.frame.minY)
        }
    }
    
    /** Change the border to reflect whether or not this item is in the user's cart currently*/
    func updateBorder(){
        guard cart != nil && container != nil && itemData != nil else {
            return
        }
        
        /** If this item is already in the user's cart then highlight the cell*/
        if self.cart.getTotalCountFor(this: self.itemData) > 0{
            itemImageView.layer.borderColor = appThemeColor.withAlphaComponent(1).cgColor
        }
        else{
            itemImageView.layer.borderColor = appThemeColor.withAlphaComponent(0.2).cgColor
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
        guard container != nil else {
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
    
    /** Clear up memory while the view is being recycled*/
    override func prepareForReuse() {
        super.prepareForReuse()
        
        itemData = nil
        container = nil
        nameLabel = nil
        priceLabel = nil
        itemImageView = nil
        imageViewShapeLayer = nil
        itemCountButton = nil
        currentlySelectedChoicesLabel = nil
        totalItemPriceLabel = nil
        removeSwipeActionButton = nil
        removeSwipeActionButtonAction = nil
        panGestureRecognizer = nil
        currentXPosition = nil
        presentingTableView = nil
        presentingVC = nil
        
        for subview in contentView.subviews{
            subview.removeFromSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
