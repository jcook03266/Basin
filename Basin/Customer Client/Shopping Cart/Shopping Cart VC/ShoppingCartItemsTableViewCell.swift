//
//  shoppingCartItemsTableViewCell.swift
//  Basin
//
//  Created by Justin Cook on 5/15/22.
//

import UIKit

class ShoppingCartItemsTableViewCell: UITableView{
    /** Data passed to this cell*/
    var itemData: OrderItem!
    /** The name of this item*/
    var nameLabel: UILabel!
    /** The cart object that will be used to store this object if the user chooses to add it*/
    var cart: Cart! = nil
    
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
        
        nameLabel = UILabel()
        nameLabel.frame.size = CGSize(width: self.frame.width * 0.9, height: 50)
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
        
        self.contentView.addSubview(nameLabel)
    }
    
}
