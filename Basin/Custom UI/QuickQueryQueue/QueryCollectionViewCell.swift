//
//  QueryCollectionViewCell.swift
//  Basin
//
//  Created by Justin Cook on 5/14/22.
//

import UIKit

/** Cell to display the string data of a passed 'query'*/
class QueryCollectionViewCell: UICollectionViewCell{
    static let identifier = "QueryCollectionViewCell"
    var query: String?
    
    /** UI Elements*/
    var container: UIView!
    var label: PaddedLabel!
    
    override init(frame: CGRect){
        super.init(frame: frame)
    }
    
    /** Create a laundromat location view and add it to the content view of this cell*/
    func create(with query: String){
        self.backgroundColor = .clear
        self.query = query
        
        container = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width * 0.95, height: self.frame.height * 0.8))
        container.backgroundColor = darkMode ? .darkGray.darker: .lightGray
        container.clipsToBounds = true
        container.layer.cornerRadius = container.frame.height/2
        container.layer.borderColor = bgColor.lighter.cgColor
        container.layer.borderWidth = 2
        
        label = PaddedLabel(withInsets: 1, 1, 4, 4)
        label.frame = container.frame
        label.backgroundColor = .clear
        label.text = query
        label.clipsToBounds = true
        label.centeredTextDynamicFontSize()
        label.adjustsFontSizeToFitWidth = false
        label.font = getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true)
        label.textColor = fontColor
        label.numberOfLines = 1
        
        /** Layout subviews*/
        container.centerInsideOf(this: self)
        label.centerInsideOf(this: container)
        
        container.addSubview(label)
        self.contentView.addSubview(container)
    }
    
    /** Various garbage collection procedures*/
    override func prepareForReuse(){
        super.prepareForReuse()
        
        query = nil
        container = nil
        label = nil
        
        for subview in contentView.subviews{
            subview.removeFromSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


