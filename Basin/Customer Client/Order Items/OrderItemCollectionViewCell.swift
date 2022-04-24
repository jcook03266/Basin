//
//  OrderItemCollectionViewCell.swift
//  Stuy Wash N Dry
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
        
        /** If this item exists in the cart then replace the item data with the item from the cart, both items must have the same id, category and menu id*/
        for item in cart.items{
            if item.id == itemData.id && item.category == itemData.category && item.menu.id == itemData.menu.id{
                let menu = itemData.menu
                itemData = item
                
                /** The cart item's menu doesn't contain items in order to save memory so the passed item's menu is referenced*/
                itemData.menu = menu
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
        ///priceLabel.layer.cornerRadius = priceLabel.frame.height/2
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
        addButton.layer.shadowColor = UIColor.lightGray.cgColor
        addButton.tintColor = .white
        addButton.setImage(UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        addButton.setTitleColor(.white, for: .normal)
        addButton.titleLabel?.adjustsFontSizeToFitWidth = true
        addButton.titleLabel?.adjustsFontForContentSizeCategory = true
        
        /** Layout these subviews*/
        shadowView.frame.origin = CGPoint(x: self.frame.width/2 - shadowView.frame.width/2, y: self.frame.height/2 - shadowView.frame.height/2)
        
        container.frame.origin = CGPoint(x: shadowView.frame.width/2 - container.frame.width/2, y: shadowView.frame.height/2 - container.frame.height/2)
        
        iconImageView.frame.origin = CGPoint(x: container.frame.width/2 - iconImageView.frame.width/2, y: 0)
        
        nameLabel.frame.origin = CGPoint(x: container.frame.width * 0.05, y: iconImageView.frame.maxY + 5)
        
        priceLabel.frame.origin = CGPoint(x: nameLabel.frame.minX, y: nameLabel.frame.maxY + 5)
        
        informationTagLabel.frame.origin = CGPoint(x: 0, y: iconImageView.frame.maxY - (informationTagLabel.frame.height * 1.15))
        
        addButton.frame.origin = CGPoint(x: container.frame.width/2 - addButton.frame.width/2, y: container.frame.maxY - addButton.frame.height * 1.15)
        
        /** Add subviews to content view*/
        shadowView.addSubview(container)
        self.container.addSubview(nameLabel)
        self.container.addSubview(priceLabel)
        self.container.addSubview(iconImageView)
        self.container.addSubview(informationTagLabel)
        self.container.addSubview(addButton)
        self.contentView.addSubview(shadowView)
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
        guard addButton.frame.contains(sender.location(in: container)) == false else{
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
