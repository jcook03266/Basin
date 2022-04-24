//
//  LaundromatLocationTableViewCell.swift
//  Stuy Wash N Dry
//
//  Created by Justin Cook on 3/25/22.
//

import UIKit

/** Table view cell that hosts a custom UIView in which data about laundromat locations is hosted*/
class LaundromatLocationTableViewCell: UITableViewCell {
    static let identifier = "LaundromatLocationTableViewCell"
    var subview: LaundromatLocationView?
    var laundromatData: Laundromat?
    /** Required in order to use the detail view on tap functionality of the image carousel*/
    var presentingVC: UIViewController?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: LaundromatLocationTableViewCell.identifier)
    }
    
    /** Create a laundromat location view and add it to the content view of this cell*/
    func create(with data: Laundromat, presentingVC: UIViewController){
        self.backgroundColor = .clear
        self.selectionStyle = .none
        self.laundromatData = data
        self.presentingVC = presentingVC
        
        subview = LaundromatLocationView(frame: contentView.frame, laundromatData: data, presentingVC: presentingVC)
        /** Disable the page control because it triggers the selection delegate method for the host tableview or collectionview when tapped (weird behavior from apple, could probably fix this by embedding it in another UIView but whatever)*/
        subview!.imageCarousel.getPageControl().isEnabled = false
        
        /** Center this subview inside of this content view*/
        subview!.frame.origin = CGPoint(x: self.contentView.frame.width/2 - subview!.frame.width/2, y: self.contentView.frame.height/2 - subview!.frame.height/2)
        
        self.contentView.addSubview(subview!)
    }
    
    /** Various garbage collection procedures*/
    override func prepareForReuse(){
        super.prepareForReuse()
        subview?.removeFromSuperview()
        
        subview = nil
        laundromatData = nil
        presentingVC = nil
        
        for subview in contentView.subviews{
            subview.removeFromSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
