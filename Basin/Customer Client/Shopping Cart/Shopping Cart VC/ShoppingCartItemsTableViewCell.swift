//
//  shoppingCartItemsTableViewCell.swift
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
        
        itemCountButton.frame.origin = CGPoint(x: 0, y: 5)
        
        nameLabel.frame.origin = CGPoint(x: itemCountButton.frame.maxX + 5, y: 5)
        
        priceLabel.frame.origin = CGPoint(x: nameLabel.frame.minX, y: nameLabel.frame.maxY + 5)
        
        itemImageView.frame.origin = CGPoint(x: container.frame.maxX - (itemImageView.frame.width * 1.25), y: container.frame.height/2 - itemImageView.frame.height/2)
        
        totalItemPriceLabel.frame.origin = CGPoint(x: itemImageView.frame.maxX - (totalItemPriceLabel.frame.width * 0.95), y: itemImageView.frame.maxY - (totalItemPriceLabel.frame.height * 0.95))
        
        currentlySelectedChoicesLabel.frame.origin = CGPoint(x: nameLabel.frame.minX, y: priceLabel.frame.maxY + 5)
        
        container.addSubview(nameLabel)
        container.addSubview(priceLabel)
        container.addSubview(itemImageView)
        container.addSubview(itemCountButton)
        container.addSubview(totalItemPriceLabel)
        if itemData.hasSelections() == true{
        container.addSubview(currentlySelectedChoicesLabel)
        }
        self.contentView.addSubview(container)
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
        
        for subview in contentView.subviews{
            subview.removeFromSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
