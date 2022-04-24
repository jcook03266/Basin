//
//  ordersTableViewCell.swift
//  Stuy Wash N Dry
//
//  Created by Justin Cook on 3/29/22.
//

import UIKit

/** Table view cell that hosts a custom UIView in which data about orders are hosted*/
class ordersTableViewCell: UITableViewCell{
    static let identifier = "ordersTableViewCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: ordersTableViewCell.identifier)
    }
    
    /** Create and populate the cell with the given data*/
    func create(){
        self.backgroundColor = [appThemeColor,.white,.darkGray,.lightGray].randomElement()!
        self.selectionStyle = .gray
    }
    
    func createPastOrder(){
        
    }
    
    func createCurrentOrder(){
        
    }
    
    /** Various garbage collection procedures*/
    override func prepareForReuse(){
        super.prepareForReuse()
        
        for subview in contentView.subviews{
            subview.removeFromSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
