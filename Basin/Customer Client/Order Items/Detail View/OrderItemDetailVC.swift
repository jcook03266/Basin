//
//  OrderItemDetailVC.swift
//  Stuy Wash N Dry
//
//  Created by Justin Cook on 4/8/22.
//

import UIKit
import Nuke
import SkeletonView
import GoogleMobileAds

/** View the order item in true detail and add it to a designated cart via a delegate protocol*/
public class OrderItemDetailVC: UIViewController, UINavigationBarDelegate, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, GADBannerViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate{
    /** External Data*/
    /** The item to reflect in this detail view controller*/
    var itemData: OrderItem
    /** Keep a reference to the original item data in order to update the count of the item when the user adds the item to the cart and returns back to the other view controller*/
    var originalItemData: OrderItem
    /** The cart in which this item will be added to, or updated in*/
    var laundromatCart: Cart
    /** The menu from which this item comes from*/
    var laundromatMenu: LaundromatMenu
    /** The tableview from which this detail view originated from, can be used as a reference for refreshing when the cart data has been updated*/
    var presentingTableView: UITableView? = nil
    /** External Data*/
    
    /** Internal Data*/
    /** Do not let the adder or menu go above this number*/
    let maxItems = 100
    /** Do not let the subtracter or menu go below this number*/
    let minItems = 0
    /** The count to increase the passed item's count by (not replace)*/
    var itemCount: Int = 0
    /** The subtotal value, this item's total count * the individual value of the item (after choice is specified) if no choice then the default price */
    var subtotal: Double = 0
    /** Internal Data*/
    
    /** Functional UI*/
    /** Scrollview in which the content below the image view will be hosted, this makes it simpler to view this content on smaller devices*/
    var scrollView: UIScrollView!
    /** Stack view that permits dynamic content in the scrollview*/
    var stackView: UIStackView!
    /** Add the item to the passed cart object*/
    var addToCartButton: UIButton!
    /** Allow user to add to the item's quantity*/
    var addButton: UIButton!
    /** Allow user to subtract from the item's quantity*/
    var subtractButton: UIButton!
    /** A textview that allows the user to write any special instructions for this item, (char limit is 100)*/
    var specialInstructionsTextView: UITextView!
    /** Button that allows the user to view the shopping cart, this is only visible in this view controller if the user already has this item inside of the shopping cart*/
    var shoppingCartButton: UIButton!
    /** Functional UI*/
    
    /** Control elements for the text view's char limit*/
    /** Limit describing the max characters the user can use for their special description, saves memory when stored in the remote*/
    var textViewCharLimit: Int = 100
    /** Display the current character count of the textview using the delegate method of the textview*/
    var textViewCharLimitDisplay: UILabel!
    /** The current count of the amount of characters in the textview*/
    var currentTextViewCharCount: Int = 0
    /** Control elements for the text view's char limit*/
    
    /** Properties*/
    /** Decide whether or not to display the recommendations collection view at the bottom of the screen*/
    var displayRecommendations: Bool = true
    /** Properties*/
    
    /** Navigation UI*/
    /** Navigation bar and navigation item*/
    var navBar = UINavigationBar()
    var navItem = UINavigationItem()
    /** Simple way for the user to dismiss this VC*/
    var backButton: UIButton = UIButton()
    /** Bar button item that hosts the back button*/
    var backButtonItem = UIBarButtonItem()
    /** Display a basic information view anchored at this button about what the user has to do*/
    var helpButton: UIButton = UIButton()
    /** Bar button item that hosts the help button*/
    var helpButtonItem = UIBarButtonItem()
    /** Navigation UI*/
    
    /** Display UI*/
    /** Display item's total quantity*/
    var itemCountDisplay: PaddedLabel!
    /** The image view in which a picture of the item will be displayed in*/
    var imageView: UIImageView!
    /** Label depicting the name of this item*/
    var nameLabel: UILabel!
    /** Label depicting the individual price of this item*/
    var priceLabel: PaddedLabel!
    /** Optional label that contains the description of this item*/
    var itemDescriptionLabel: UILabel!
    /** A label depicting the type of menu this item is from (washing, dry cleaning etc)*/
    var menuTypeLabel: UILabel!
    /** Container for both special instructions labels*/
    var specialInstructionsLabelContainer: UIView!
    /** Container that adds padding around the textview when the user scrolls to the bottom of the document*/
    var specialInstructionsTextViewContainer: UIView!
    /** Designate where the user can type special instructions for this item*/
    var specialInstructionsLabel: UILabel!
    /** Instructions to display below the main title*/
    var specialInstructionsLabelSubtitle: UILabel!
    /** Label describing the collection view below it*/
    var recommendedForYouCollectionViewLabel: UILabel!
    /** Display UI*/
    
    /** Decoration*/
    /** Simple masked / curved UIView that acts as the background for the image-view*/
    /** Masked clear view with a curved mask applied to the view's top layer*/
    var maskedHeaderView: UIView!
    /** Decoration*/
    
    /** Item Choices table view (display the choices for this item (if any))*/
    var itemChoicesTableView: UITableView!
    /** Preferred height of the tableview's rows*/
    var itemChoicesTableViewRowHeight: CGFloat = 60
    var itemChoicesTableViewSectionHeaderHeight: CGFloat = 60
    var itemChoicesTableViewSectionFooterHeight: CGFloat = 0
    /** A sorted array of the category titles for the item choices*/
    var sortedItemChoicesCategories: [String] = []
    /** Partition all of the item choices associated with the given category into accessible arrays*/
    var itemChoicesCategorySections: [String : [itemChoice]] = [:]
    /** Item Choices table view (display the choices for this item (if any))*/
    
    /** Recommendation Collection view (display a list of other items from the given laundromat menu)*/
    var recommendedForYouCollectionViewContainer: UIView!
    var recommendedForYouCollectionView: UICollectionView!
    var collectionViewHeight: CGFloat = 200
    /** Recommendation Collection view (display a list of other items from the given laundromat menu)*/
    
    /** Banner advertisement (display a banner advertisement directly below the optional description*/
    var bannerAdContainer: UIView!
    var bannerViewAd: GADBannerView!
    /** Banner advertisement (display a banner advertisement directly below the optional description*/
    
    /** Keep track of which item choice has been selected*/
    /** The total amount of item choices**/
    var numberOfItemChoices: Int = 0
    /** A unique set of item choices since an item choice is supposed to be unique, as well as the category where these item choices belong*/
    var selectedItemChoices: [String : Set<itemChoice>] = [:]
    /** The limit of the amount of item choices the user can choose, once this limit is reached, all the remaining item choices are greyed out until the user deselects the chosen items and goes under the maximum selection limit*/
    var maximumItemChoiceSelections: Int!
    /** Keep track of which item choice has been selected*/
    
    /** Pass over necessary data and containers for this view controller to interact with*/
    init(itemData: OrderItem, laundromatCart: Cart, laundromatMenu: LaundromatMenu) {
        
        /** Create a copy of the passed item in a new memory address in order to mutate the item without affecting the other object*/
        self.itemData = itemData.copy() as! OrderItem
        self.itemData.clearSelectedChoices()
        
        /** Clear any and all mutated data from this object*/
        self.itemData.count = 0
        self.itemData.specialInstructions = ""
        
        /** Keep an original reference to the given item*/
        self.originalItemData = itemData
        
        self.laundromatCart = laundromatCart
        self.laundromatMenu = laundromatMenu
        
        super.init(nibName: nil, bundle: nil)
        
        self.numberOfItemChoices = itemData.itemChoices.count
        
        /** Specify all of the item choice categories for the item selection dictionary*/
        for choice in itemData.itemChoices{
            selectedItemChoices[choice.category] = []
        }
        
        itemChoicesCategorySections = computeTotalSectionsForItemChoicesTableView() ?? [:]
        sortCategoriesInDescendingOrder()
    }
    
    public override func viewDidLoad() {
        /** Specify a maximum font size*/
        self.view.maximumContentSizeCategory = .large
        
        constructUI()
        configure()
        setCustomNavUI()
    }
    
    /** Determine if the item choice requirements for this item are satisfied*/
    func areRequirementsSatisfied()->Bool{
        let satisfied = true
        
        /** If no items then there's nothing to satisfy*/
        guard itemData.itemChoices.isEmpty == false else {
            return satisfied
        }
        
        /** The user has to specify a quantity higher than 0*/
        guard itemCount > 0 else {
            return false
        }
        
        /** If all required categories are not selected then return false*/
        for category in sortedItemChoicesCategories{
            if let choice = itemChoicesCategorySections[category]?.first{
                if choice.required == true && selectedItemChoices[category]?.isEmpty == true{
                    return false
                }
            }
        }
        
        /** All required categories are selected, now check to see if the limit is satisfied for the choices*/
        for (_, choices) in selectedItemChoices{
            for choice in choices{
                if choice.required == true && choices.count != choice.limit{
                    /** Required category doesn't have the required limit satisfied*/
                    return false
                }
                else if choice.required == false && choices.count > choice.limit{
                    /** Optional category has an overflow in selected choices*/
                    return false
                }
            }
        }
        
        return satisfied
    }
    
    /** Construct the UI for this VC*/
    func constructUI(){
        switch darkMode{
        case true:
            self.view.backgroundColor = .black
        case false:
            self.view.backgroundColor = bgColor
        }
        
        maskedHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height * 0.25))
        maskedHeaderView.backgroundColor = appThemeColor
        
        /** Rectangle with a curved path at the bottom of it*/
        let curvedPath = UIBezierPath()
        curvedPath.move(to: CGPoint(x: maskedHeaderView.frame.maxX, y: 0))
        curvedPath.addLine(to: CGPoint(x: maskedHeaderView.frame.minX, y: 0))
        curvedPath.addLine(to: CGPoint(x: maskedHeaderView.frame.minX, y: maskedHeaderView.frame.height * 0.7))
        curvedPath.addQuadCurve(to: CGPoint(x: maskedHeaderView.frame.maxX, y: maskedHeaderView.frame.height * 0.7), controlPoint: CGPoint(x: maskedHeaderView.frame.width/2, y: maskedHeaderView.frame.height))
        curvedPath.close()
        
        /** Curved mask displayed over the image for aesthetics*/
        let mask = CAShapeLayer()
        mask.path = curvedPath.cgPath
        mask.fillColor = appThemeColor.cgColor
        mask.strokeColor = appThemeColor.cgColor
        mask.strokeEnd = 1
        mask.masksToBounds = false
        mask.shadowColor = UIColor.darkGray.cgColor
        mask.shadowRadius = 4
        mask.shadowOpacity = 1
        mask.shadowOffset = CGSize(width: 0, height: 2)
        mask.shadowPath = curvedPath.cgPath
        
        maskedHeaderView.layer.mask = mask
        
        imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width/3, height: self.view.frame.width/3))
        imageView.isUserInteractionEnabled = false
        imageView.clipsToBounds = false
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        ///imageView.layer.cornerRadius = imageView.frame.height/2
        imageView.tintColor = appThemeColor
        
        /** Load up given image into the imageview*/
        if let url = URL(string: itemData.photoURL ?? ""){
            let request = ImageRequest(url: url)
            let options = ImageLoadingOptions(
                transition: .fadeIn(duration: 0.5)
            )
            Nuke.loadImage(with: request, options: options, into: imageView){ _ in
            }
        }
        else{
            /** No image provided so use a default placeholder stored in the assets collection*/
            imageView.image = UIImage(named: "placeholderLaundryIcon")
        }
        
        stackView = UIStackView(frame: CGRect(x: 0, y: 0, width: view.frame.width * 1, height: view.frame.height * 0.9 - maskedHeaderView.frame.height))
        stackView.axis = .vertical
        stackView.clipsToBounds = false
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = 10
        
        scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height * 1 - maskedHeaderView.frame.height))
        scrollView.backgroundColor = .clear
        scrollView.clipsToBounds = true
        scrollView.delegate = self
        
        switch darkMode {
        case true:
            scrollView.indicatorStyle = .white
        case false:
            scrollView.indicatorStyle = .black
        }
        
        nameLabel = UILabel()
        nameLabel.frame.size = CGSize(width: self.stackView.frame.width * 0.9, height: 40)
        nameLabel.font = getCustomFont(name: .Ubuntu_bold, size: 26, dynamicSize: true)
        nameLabel.backgroundColor = .clear
        nameLabel.textColor = fontColor
        nameLabel.textAlignment = .center
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.text = itemData.name
        nameLabel.attributedText = attribute(this: nameLabel.text!, font: getCustomFont(name: .Ubuntu_Regular, size: 20, dynamicSize: true), mainColor: fontColor, subColor: .lightGray, subString: "")
        nameLabel.sizeToFit()
        
        priceLabel = PaddedLabel(withInsets: 2, 2, 5, 5)
        priceLabel.frame.size = CGSize(width: self.stackView.frame.width * 0.7, height: 50)
        priceLabel.font = getCustomFont(name: .Ubuntu_Regular, size: 22, dynamicSize: true)
        priceLabel.text = "$\(String(format: "%.2f", itemData.price)) /Item"
        priceLabel.backgroundColor = darkMode ? .darkGray : .darkGray.lighter
        priceLabel.layer.borderColor = UIColor.darkGray.cgColor
        priceLabel.layer.borderWidth = 1
        priceLabel.textColor = .white
        priceLabel.textAlignment = .center
        priceLabel.adjustsFontForContentSizeCategory = true
        priceLabel.adjustsFontSizeToFitWidth = true
        priceLabel.layer.masksToBounds = true
        priceLabel.attributedText = attribute(this: priceLabel.text!, font: getCustomFont(name: .Ubuntu_Regular, size: 20, dynamicSize: true), mainColor: .white, subColor: .lightGray, subString: "/Item")
        priceLabel.sizeToFit()
        priceLabel.layer.cornerRadius = priceLabel.frame.height/2
        
        menuTypeLabel = UILabel()
        menuTypeLabel.frame.size = CGSize(width: self.stackView.frame.width * 0.9, height: 40)
        menuTypeLabel.font = getCustomFont(name: .Bungee_Regular, size: 20, dynamicSize: true)
        menuTypeLabel.backgroundColor = .clear
        menuTypeLabel.textColor = appThemeColor
        menuTypeLabel.textAlignment = .center
        menuTypeLabel.adjustsFontForContentSizeCategory = true
        menuTypeLabel.adjustsFontSizeToFitWidth = true
        menuTypeLabel.text = "\(laundromatMenu.category) Serivce"
        menuTypeLabel.sizeToFit()
        
        shoppingCartButton = UIButton()
        shoppingCartButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        shoppingCartButton.frame.size.height = 50
        shoppingCartButton.frame.size.width = shoppingCartButton.frame.size.height
        shoppingCartButton.backgroundColor = bgColor
        shoppingCartButton.tintColor = appThemeColor
        shoppingCartButton.setImage(UIImage(systemName: "cart.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        shoppingCartButton.imageView?.contentMode = .scaleAspectFit
        shoppingCartButton.layer.cornerRadius = shoppingCartButton.frame.height/2
        shoppingCartButton.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMinXMinYCorner]
        shoppingCartButton.isEnabled = true
        shoppingCartButton.isExclusiveTouch = true
        shoppingCartButton.layer.borderColor = UIColor.lightGray.cgColor
        shoppingCartButton.layer.borderWidth = 0.5
        shoppingCartButton.addTarget(self, action: #selector(shoppingCartButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: shoppingCartButton)
        
        if laundromatCart.getTotalCountFor(this: itemData) <= 0{
            shoppingCartButton.isEnabled = false
            shoppingCartButton.alpha = 0
            shoppingCartButton.isHidden = true
        }
        
        addButton = UIButton()
        addButton.frame.size = CGSize(width: 40, height: 40)
        addButton.backgroundColor = bgColor
        addButton.contentHorizontalAlignment = .center
        addButton.layer.cornerRadius = addButton.frame.height/2
        addButton.isExclusiveTouch = true
        addButton.isEnabled = true
        addButton.isUserInteractionEnabled = true
        addButton.castDefaultShadow()
        addButton.layer.shadowColor = UIColor.darkGray.cgColor
        addButton.tintColor = appThemeColor
        addButton.setImage(UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        addButton.addTarget(self, action: #selector(addButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: addButton)
        addButton.menu = getMenuForAddButton()
        
        subtractButton = UIButton()
        subtractButton.frame.size = CGSize(width: 40, height: 40)
        subtractButton.backgroundColor = bgColor
        subtractButton.contentHorizontalAlignment = .center
        subtractButton.layer.cornerRadius = subtractButton.frame.height/2
        subtractButton.isExclusiveTouch = true
        subtractButton.isEnabled = true
        subtractButton.isUserInteractionEnabled = true
        subtractButton.castDefaultShadow()
        subtractButton.layer.shadowColor = UIColor.darkGray.cgColor
        subtractButton.tintColor = appThemeColor
        /** Enabled when the item's count is > 0*/
        subtractButton.isEnabled = false
        subtractButton.alpha = 0.5
        subtractButton.setImage(UIImage(systemName: "minus", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        subtractButton.addTarget(self, action: #selector(subtractButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: subtractButton)
        subtractButton.menu = getMenuForSubtractButton()
        
        addToCartButton = UIButton()
        addToCartButton.frame.size = CGSize(width: self.view.frame.width * 0.9, height: 60)
        addToCartButton.backgroundColor = appThemeColor
        addToCartButton.setTitleColor(.white, for: .normal)
        addToCartButton.titleLabel?.font = getCustomFont(name: .Ubuntu_Regular, size: 16, dynamicSize: true)
        addToCartButton.contentHorizontalAlignment = .center
        addToCartButton.titleLabel?.adjustsFontSizeToFitWidth = true
        addToCartButton.titleLabel?.adjustsFontForContentSizeCategory = true
        addToCartButton.layer.cornerRadius = addToCartButton.frame.height/2
        addToCartButton.isExclusiveTouch = true
        /** Disabled until the user increments the item count*/
        addToCartButton.isEnabled = false
        addToCartButton.alpha = 0.5
        addToCartButton.castDefaultShadow()
        addToCartButton.layer.shadowColor = UIColor.darkGray.cgColor
        addToCartButton.tintColor = .white
        addToCartButton.setImage(UIImage(systemName: "cart.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        addToCartButton.setTitle(" Add to Cart", for: .normal)
        addToCartButton.addTarget(self, action: #selector(addToCartButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: addToCartButton)
        
        itemCountDisplay = PaddedLabel(withInsets: 5, 5, 5, 5)
        itemCountDisplay.frame.size = CGSize(width: 40, height: 40)
        itemCountDisplay.backgroundColor = bgColor
        itemCountDisplay.text = "\(itemCount)"
        itemCountDisplay.font = getCustomFont(name: .Bungee_Regular, size: 14, dynamicSize: true)
        itemCountDisplay.textColor = appThemeColor
        itemCountDisplay.adjustsFontSizeToFitWidth = true
        itemCountDisplay.adjustsFontForContentSizeCategory = true
        itemCountDisplay.layer.cornerRadius = itemCountDisplay.frame.height/2
        itemCountDisplay.layer.borderColor = UIColor.darkGray.cgColor
        itemCountDisplay.layer.borderWidth = 3
        itemCountDisplay.clipsToBounds = true
        itemCountDisplay.alpha = 0
        itemCountDisplay.textAlignment = .center
        
        specialInstructionsLabelContainer = UIView(frame: CGRect(x: 0, y: 0, width: stackView.frame.width, height: itemChoicesTableViewSectionHeaderHeight))
        specialInstructionsLabelContainer.backgroundColor = bgColor.darker
        specialInstructionsLabelContainer.clipsToBounds = true
        
        specialInstructionsLabel = UILabel(frame: CGRect(x: 0, y: 0, width: specialInstructionsLabelContainer.frame.width * 0.95, height: specialInstructionsLabelContainer.frame.height/2))
        specialInstructionsLabel.font = getCustomFont(name: .Ubuntu_Regular, size: 16, dynamicSize: true)
        specialInstructionsLabel.textColor = fontColor
        specialInstructionsLabel.adjustsFontForContentSizeCategory = true
        specialInstructionsLabel.adjustsFontSizeToFitWidth = true
        specialInstructionsLabel.textAlignment = .left
        specialInstructionsLabel.text = "Special Instructions"
        specialInstructionsLabel.sizeToFit()
        
        specialInstructionsLabelSubtitle = UILabel(frame: CGRect(x: 0, y: 0, width: specialInstructionsLabelContainer.frame.width * 0.95, height: specialInstructionsLabelContainer.frame.height/2))
        specialInstructionsLabelSubtitle.font = getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true)
        specialInstructionsLabelSubtitle.textColor = .lightGray
        specialInstructionsLabelSubtitle.adjustsFontForContentSizeCategory = true
        specialInstructionsLabelSubtitle.adjustsFontSizeToFitWidth = true
        specialInstructionsLabelSubtitle.textAlignment = .left
        specialInstructionsLabelSubtitle.text = "Tell us any unique requests for this item"
        specialInstructionsLabelSubtitle.sizeToFit()
        
        specialInstructionsTextViewContainer = UIView(frame: CGRect(x: 0, y: 0, width: stackView.frame.width, height: 160))
        specialInstructionsTextViewContainer.clipsToBounds = true
        
        if displayRecommendations == false{
            specialInstructionsTextViewContainer.frame.size.height = 250
        }
        
        specialInstructionsTextView = AccessibleTextView(frame: CGRect(x: 0, y: 0, width: stackView.frame.width * 0.95, height: 150), presentingViewController: self, useContextMenu: true)
        specialInstructionsTextView.contentInset = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        specialInstructionsTextView.backgroundColor = bgColor
        specialInstructionsTextView.tintColor = appThemeColor
        specialInstructionsTextView.clipsToBounds = true
        specialInstructionsTextView.layer.cornerRadius = specialInstructionsTextView.frame.height/10
        specialInstructionsTextView.layer.borderWidth = 1
        specialInstructionsTextView.layer.borderColor = bgColor.darker.cgColor
        specialInstructionsTextView.autocorrectionType = .yes
        specialInstructionsTextView.autocapitalizationType = .sentences
        specialInstructionsTextView.isEditable = true
        specialInstructionsTextView.textColor = fontColor
        specialInstructionsTextView.textAlignment = .left
        specialInstructionsTextView.keyboardType = .asciiCapable
        specialInstructionsTextView.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: true)
        specialInstructionsTextView.enablesReturnKeyAutomatically =  true
        specialInstructionsTextView.showsHorizontalScrollIndicator = false
        specialInstructionsTextView.showsVerticalScrollIndicator = true
        specialInstructionsTextView.delegate = self
        
        switch darkMode{
        case true:
            specialInstructionsTextView.keyboardAppearance = .dark
        case false:
            specialInstructionsTextView.keyboardAppearance = .light
        }
        
        textViewCharLimitDisplay = PaddedLabel(withInsets: 2, 2, 2, 2)
        textViewCharLimitDisplay.frame = CGRect(x: 0, y: 0, width: 60, height: 30)
        textViewCharLimitDisplay.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: true)
        switch darkMode{
        case true:
            textViewCharLimitDisplay.backgroundColor = .darkGray.darker
            textViewCharLimitDisplay.textColor = .white.darker
        case false:
            textViewCharLimitDisplay.backgroundColor = .white.darker
            textViewCharLimitDisplay.textColor = .lightGray
        }
        textViewCharLimitDisplay.adjustsFontForContentSizeCategory = true
        textViewCharLimitDisplay.adjustsFontSizeToFitWidth = true
        textViewCharLimitDisplay.textAlignment = .center
        textViewCharLimitDisplay.layer.cornerRadius = textViewCharLimitDisplay.frame.height/2
        textViewCharLimitDisplay.clipsToBounds = true
        textViewCharLimitDisplay.text = "\(currentTextViewCharCount)/\(textViewCharLimit)"
        
        /** Layout subviews*/
        specialInstructionsLabel.frame.origin = CGPoint(x: specialInstructionsLabelContainer.frame.width * 0.05, y: specialInstructionsLabelContainer.frame.height/2 - specialInstructionsLabel.frame.height)
        
        specialInstructionsLabelSubtitle.frame.origin = CGPoint(x: specialInstructionsLabel.frame.minX, y: specialInstructionsLabel.frame.maxY)
        
        specialInstructionsTextView.frame.origin = CGPoint(x: specialInstructionsTextViewContainer.frame.width/2 - specialInstructionsTextView.frame.width/2, y: 5)
        
        textViewCharLimitDisplay.frame.origin = CGPoint(x: specialInstructionsTextView.frame.maxX - (textViewCharLimitDisplay.frame.width * 1.15), y: (specialInstructionsTextView.frame.maxY - (textViewCharLimitDisplay.frame.height + 5)))
        
        specialInstructionsLabelContainer.addSubview(specialInstructionsLabel)
        specialInstructionsLabelContainer.addSubview(specialInstructionsLabelSubtitle)
        
        specialInstructionsTextViewContainer.addSubview(specialInstructionsTextView)
        specialInstructionsTextViewContainer.addSubview(textViewCharLimitDisplay)
        
        recommendedForYouCollectionViewLabel = UILabel(frame: CGRect(x: 0, y: 0, width: stackView.frame.width * 0.95, height: itemChoicesTableViewSectionHeaderHeight))
        recommendedForYouCollectionViewLabel.font = getCustomFont(name: .Ubuntu_Regular, size: 18, dynamicSize: true)
        recommendedForYouCollectionViewLabel.textColor = fontColor
        recommendedForYouCollectionViewLabel.adjustsFontForContentSizeCategory = true
        recommendedForYouCollectionViewLabel.adjustsFontSizeToFitWidth = true
        recommendedForYouCollectionViewLabel.textAlignment = .left
        recommendedForYouCollectionViewLabel.text = "Recommended For You"
        recommendedForYouCollectionViewLabel.sizeToFit()
        
        recommendedForYouCollectionViewContainer = UIView(frame: CGRect(x: 0, y: 0, width: stackView.frame.width, height: collectionViewHeight + 60))
        recommendedForYouCollectionViewContainer.clipsToBounds = true
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        /** Specify item size in order to allow the collectionview to encompass all of them*/
        layout.itemSize = CGSize(width: stackView.frame.width/3, height: collectionViewHeight)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        recommendedForYouCollectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: stackView.frame.width, height: collectionViewHeight), collectionViewLayout: layout)
        recommendedForYouCollectionView.register(OrderItemCollectionViewCell.self, forCellWithReuseIdentifier: OrderItemCollectionViewCell.identifier)
        recommendedForYouCollectionView.delegate = self
        recommendedForYouCollectionView.backgroundColor = UIColor.clear
        recommendedForYouCollectionView.isPagingEnabled = true
        recommendedForYouCollectionView.dataSource = self
        recommendedForYouCollectionView.showsVerticalScrollIndicator = false
        recommendedForYouCollectionView.showsHorizontalScrollIndicator = false
        recommendedForYouCollectionView.isExclusiveTouch = true
        recommendedForYouCollectionView.contentSize = CGSize(width: ((stackView.frame.width)/3 * CGFloat(laundromatMenu.items.count)), height: collectionViewHeight)
        
        /** Layout subviews*/
        recommendedForYouCollectionView.frame.origin = CGPoint(x: 0, y: 0)
        recommendedForYouCollectionViewContainer.addSubview(recommendedForYouCollectionView)
        
        itemChoicesTableView = UITableView(frame: .zero, style: .grouped)
        itemChoicesTableView.clipsToBounds = true
        itemChoicesTableView.backgroundColor = .clear
        itemChoicesTableView.tintColor = fontColor
        itemChoicesTableView.isOpaque = false
        itemChoicesTableView.showsVerticalScrollIndicator = true
        itemChoicesTableView.showsHorizontalScrollIndicator = false
        itemChoicesTableView.isExclusiveTouch = true
        itemChoicesTableView.contentInsetAdjustmentBehavior = .never
        itemChoicesTableView.dataSource = self
        itemChoicesTableView.delegate = self
        itemChoicesTableView.separatorStyle = .singleLine
        itemChoicesTableView.isScrollEnabled = false
        itemChoicesTableView.layer.borderColor = UIColor.white.darker.cgColor
        itemChoicesTableView.layer.borderWidth = 0
        
        /** Specify the frame of this tableview*/
        itemChoicesTableView.frame = CGRect(x: 0, y: 0, width: stackView.frame.width, height: getEstimatedHeightOfItemChoicesTableView() * 1.1)
        
        /** Add a little space at the bottom of the scrollview*/
        itemChoicesTableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: view.frame.width * 0.1, right: 0)
        
        itemChoicesTableView.register(ItemChoiceCell.self, forCellReuseIdentifier: ItemChoiceCell.identifier)
        
        bannerAdContainer = UIView(frame: CGRect(x: 0, y: 0, width: stackView.frame.width * 0.95, height: 60))
        bannerAdContainer.backgroundColor = .clear
        bannerAdContainer.layer.cornerRadius = bannerAdContainer.frame.height/5
        bannerAdContainer.layer.borderColor = UIColor.lightGray.cgColor
        bannerAdContainer.layer.borderWidth = 0
        bannerAdContainer.clipsToBounds = true
        bannerAdContainer.isSkeletonable = true
        /** Display skeleton view until the GAD is loaded*/
        let animation = SkeletonAnimationBuilder().makeSlidingAnimation(withDirection: .leftRight)
        let gradient = SkeletonGradient(baseColor: .lightGray)
        
        bannerViewAd = GADBannerView(adSize: GADAdSizeFromCGSize(CGSize(width: bannerAdContainer.frame.width, height: bannerAdContainer.frame.height)))
        bannerViewAd.backgroundColor = UIColor.clear
        bannerViewAd.delegate = self
        bannerViewAd.isSkeletonable = true
        bannerViewAd.showAnimatedGradientSkeleton(usingGradient: gradient, animation: animation)
        
        bannerAdContainer.addSubview(bannerViewAd)
        bannerViewAd.frame.origin = CGPoint(x: bannerAdContainer.frame.width/2 - bannerViewAd.frame.width/2, y: bannerAdContainer.frame.height/2 - bannerViewAd.frame.height/2)
        
        /** Specify the root vc for displaying the overlay when the advert is pressed and the adUnitID*/
        bannerViewAd.adUnitID = bannerViewAdUnitID
        bannerViewAd.rootViewController = self
        
        /** Note: If an internet connection isn't available, the request will still load the advertisement after a small delay following a successful connection to the internet*/
        if shouldDisplayAds(){
            let request = GADRequest()
            request.keywords = ["Laundry","Washing","Clothes","Dry Cleaning","Detergent","Cleaning"]
            bannerViewAd.load(request)
        }
        else{
            bannerAdContainer.frame = .zero
            bannerAdContainer.isHidden = true
            bannerAdContainer.alpha = 0
            bannerAdContainer.isUserInteractionEnabled = false
        }
        /** Banner Ad code*/
        
        /** Layout subviews and add them to the view hierarchy*/
        maskedHeaderView.frame.origin = .zero
        
        imageView.frame.origin = CGPoint(x: maskedHeaderView.frame.width/2 - imageView.frame.width/2, y: maskedHeaderView.frame.height/2 - imageView.frame.height/2)
        
        menuTypeLabel.frame.origin = CGPoint(x: self.view.frame.width/2 - menuTypeLabel.frame.width/2, y: 0)
        
        nameLabel.frame.origin = CGPoint(x: self.view.frame.width/2 - nameLabel.frame.width/2, y: menuTypeLabel.frame.maxY + 10)
        
        priceLabel.frame.origin = CGPoint(x: self.view.frame.width/2 - priceLabel.frame.width/2, y: nameLabel.frame.maxY + 5)
        
        subtractButton.frame.origin = CGPoint(x: imageView.frame.minX - (addButton.frame.width * 2), y: 0)
        subtractButton.center.y = imageView.center.y
        
        addButton.frame.origin = CGPoint(x: imageView.frame.maxX + (subtractButton.frame.width * 1), y: 0)
        addButton.center.y = imageView.center.y
        
        itemCountDisplay.frame.origin = CGPoint(x: 0, y: imageView.frame.maxY - itemCountDisplay.frame.height/3)
        itemCountDisplay.center.x = imageView.center.x
        
        bannerAdContainer.frame.origin = CGPoint(x: self.stackView.frame.width/2 - bannerAdContainer.frame.width/2, y: priceLabel.frame.maxY + (bannerAdContainer.frame.height * 0.5))
        
        itemChoicesTableView.frame.origin = CGPoint(x: 0, y: bannerAdContainer.frame.maxY + 10)
        
        addToCartButton.frame.origin = CGPoint(x: view.frame.width/2 - addToCartButton.frame.width/2, y: view.frame.maxY - (addToCartButton.frame.height * 2.5))
        
        specialInstructionsLabelContainer.frame.origin = CGPoint(x: 0, y: itemChoicesTableView.frame.maxY + 0)
        
        specialInstructionsTextViewContainer.frame.origin = CGPoint(x: 0, y: specialInstructionsLabelContainer.frame.maxY + 10)
        
        if displayRecommendations == true{
            recommendedForYouCollectionViewLabel.frame.origin = CGPoint(x: stackView.frame.width * 0.05, y: specialInstructionsTextViewContainer.frame.maxY + recommendedForYouCollectionViewLabel.frame.height * 2)
        
        recommendedForYouCollectionViewContainer.frame.origin = CGPoint(x: stackView.frame.width/2 - recommendedForYouCollectionViewContainer.frame.width/2, y: recommendedForYouCollectionViewLabel.frame.maxY + 10)
        }
        
        scrollView.frame.origin = CGPoint(x: self.view.frame.width/2 - scrollView.frame.width/2, y: maskedHeaderView.frame.height * 0.725)
        
        stackView.frame.origin = CGPoint(x: self.scrollView.frame.width/2 - stackView.frame.width/2, y: maskedHeaderView.frame.height * 0.3)
        
        shoppingCartButton.frame.origin = CGPoint(x: self.view.frame.maxX - (shoppingCartButton.frame.width * 0.95), y: self.view.frame.height/2 - shoppingCartButton.frame.height/2)
        
        self.view.addSubview(scrollView)
        self.view.addSubview(maskedHeaderView)
        self.view.addSubview(imageView)
        self.view.addSubview(addButton)
        self.view.addSubview(subtractButton)
        self.view.addSubview(addToCartButton)
        self.view.addSubview(itemCountDisplay)
        self.view.addSubview(shoppingCartButton)
        
        scrollView.addSubview(stackView)
        stackView.addArrangedSubview(menuTypeLabel)
        stackView.addArrangedSubview(nameLabel)
        stackView.addArrangedSubview(priceLabel)
        stackView.addArrangedSubview(bannerAdContainer)
        stackView.addArrangedSubview(itemChoicesTableView)
        stackView.addArrangedSubview(specialInstructionsLabelContainer)
        stackView.addArrangedSubview(specialInstructionsTextViewContainer)
        if displayRecommendations == true{
        stackView.addArrangedSubview(recommendedForYouCollectionViewLabel)
        stackView.addArrangedSubview(recommendedForYouCollectionViewContainer)
        }
        
        /** Don't resize these views*/
        menuTypeLabel.translatesAutoresizingMaskIntoConstraints = true
        nameLabel.translatesAutoresizingMaskIntoConstraints = true
        priceLabel.translatesAutoresizingMaskIntoConstraints = true
        bannerAdContainer.translatesAutoresizingMaskIntoConstraints = true
        itemChoicesTableView.translatesAutoresizingMaskIntoConstraints = true
        specialInstructionsLabelContainer.translatesAutoresizingMaskIntoConstraints = true
        specialInstructionsTextView.translatesAutoresizingMaskIntoConstraints = true
        specialInstructionsTextViewContainer.translatesAutoresizingMaskIntoConstraints = true
        textViewCharLimitDisplay.translatesAutoresizingMaskIntoConstraints = true
        recommendedForYouCollectionViewLabel.translatesAutoresizingMaskIntoConstraints = true
        recommendedForYouCollectionViewContainer.translatesAutoresizingMaskIntoConstraints = true
        recommendedForYouCollectionView.translatesAutoresizingMaskIntoConstraints = true
        
        scrollView.translatesAutoresizingMaskIntoConstraints = true
        scrollView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        scrollView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        scrollView.topAnchor.constraint(equalTo: maskedHeaderView.bottomAnchor, constant: -(maskedHeaderView.frame.height * 0.3)).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: (maskedHeaderView.frame.height * 0.3)).isActive = true
        stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
        
        /** Specify the content size of the scrollview in order to allow scrolling*/
        scrollView.contentSize = stackView.frame.size
    }
    
    /** Provide a menu for this button*/
    func getMenuForSubtractButton()->UIMenu?{
        var children: [UIMenuElement] = []
        let menuTitle = "Decrement by:"
        
        let clear = UIAction(title: "Clear", image: UIImage(systemName: "trash.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light))){ [self] action in
            lightHaptic()
            
            itemCount = 0
            
            updateAddToCartButton()
        }
        let by20 = UIAction(title: "-20", image: nil){ [self] action in
            lightHaptic()
            
            /** Don't go below the min quantity*/
            if (itemCount - 20) >= minItems{
                itemCount -= 20
                updateAddToCartButton()
            }
            else{
                /** Inform the user that they can't go below zero*/
                globallyTransmit(this: "You can't have negative clothes!", with: UIImage(systemName: "tshirt.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .rightStrip, animated: true, duration: 3, selfDismiss: true)
            }
        }
        let by10 = UIAction(title: "-10", image: nil){ [self] action in
            lightHaptic()
            
            if (itemCount - 10) >= minItems{
                itemCount -= 10
                updateAddToCartButton()
            }
            else{
                globallyTransmit(this: "You can't have negative clothes!", with: UIImage(systemName: "tshirt.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .rightStrip, animated: true, duration: 3, selfDismiss: true)
            }
        }
        let by5 = UIAction(title: "-5", image: nil){ [self] action in
            lightHaptic()
            
            if (itemCount - 5) >= minItems{
                itemCount -= 5
                
                updateAddToCartButton()
            }
            else{
                globallyTransmit(this: "You can't have negative clothes!", with: UIImage(systemName: "tshirt.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .rightStrip, animated: true, duration: 3, selfDismiss: true)
            }
        }
        let by2 = UIAction(title: "-2", image: nil){ [self] action in
            lightHaptic()
            
            if (itemCount - 2) >= minItems{
                itemCount -= 2
                
                updateAddToCartButton()
            }
            else{
                globallyTransmit(this: "You can't have negative clothes!", with: UIImage(systemName: "tshirt.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .rightStrip, animated: true, duration: 3, selfDismiss: true)
            }
        }
        let by1 = UIAction(title: "-1", image: nil){ [self] action in
            lightHaptic()
            
            if (itemCount - 1) >= minItems{
                itemCount -= 1
                
                updateAddToCartButton()
            }
            else{
                globallyTransmit(this: "You can't have negative clothes!", with: UIImage(systemName: "tshirt.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .rightStrip, animated: true, duration: 3, selfDismiss: true)
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
    
    /** Provide a menu for this button*/
    func getMenuForAddButton()->UIMenu?{
        var children: [UIMenuElement] = []
        let menuTitle = "Increment by:"
        
        let clear = UIAction(title: "Clear", image: UIImage(systemName: "trash.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light))){ [self] action in
            lightHaptic()
            
            itemCount = 0
            updateAddToCartButton()
        }
        let by20 = UIAction(title: "+20", image: nil){ [self] action in
            lightHaptic()
            
            /** Don't go over the max quantity*/
            if (itemCount + 20) <= maxItems{
                itemCount += 20
                
                updateAddToCartButton()
            }
            /** Max num of items reached, inform the user*/
            if itemCount == maxItems{
                itemCount = maxItems
                errorShake()
                globallyTransmit(this: "Maximum number of items reached for this item", with: UIImage(systemName: "tshirt.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .rightStrip, animated: true, duration: 3, selfDismiss: true)
            }
        }
        let by10 = UIAction(title: "+10", image: nil){ [self] action in
            lightHaptic()
            
            if (itemCount + 10) <= maxItems{
                itemCount += 10
                
                updateAddToCartButton()
            }
            if itemCount == maxItems{
                itemCount = maxItems
                errorShake()
                globallyTransmit(this: "Maximum number of items reached for this item", with: UIImage(systemName: "tshirt.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .rightStrip, animated: true, duration: 3, selfDismiss: true)
            }
        }
        let by5 = UIAction(title: "+5", image: nil){ [self] action in
            lightHaptic()
            
            if (itemCount + 5) <= maxItems{
                itemCount += 5
                
                updateAddToCartButton()
            }
            if itemCount == maxItems{
                itemCount = maxItems
                errorShake()
                globallyTransmit(this: "Maximum number of items reached for this item", with: UIImage(systemName: "tshirt.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .rightStrip, animated: true, duration: 3, selfDismiss: true)
            }
        }
        let by2 = UIAction(title: "+2", image: nil){ [self] action in
            lightHaptic()
            
            if (itemCount + 2) <= maxItems{
                itemCount += 2
                
                updateAddToCartButton()
            }
            if itemCount == maxItems{
                itemCount = maxItems
                errorShake()
                globallyTransmit(this: "Maximum number of items reached for this item", with: UIImage(systemName: "tshirt.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .rightStrip, animated: true, duration: 3, selfDismiss: true)
            }
        }
        let by1 = UIAction(title: "+1", image: nil){ [self] action in
            lightHaptic()
            
            if (itemCount + 1) <= maxItems{
                itemCount += 1
                
                updateAddToCartButton()
            }
            if itemCount == maxItems{
                itemCount = maxItems
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
    
    /** Configure this view controller*/
    func configure(){
        var imageConfiguration = UIImage.SymbolConfiguration(weight: .regular)
        var image = UIImage(systemName: "xmark", withConfiguration: imageConfiguration)
        backButton.frame.size.height = 35
        backButton.frame.size.width = backButton.frame.size.height
        backButton.backgroundColor = bgColor
        backButton.tintColor = appThemeColor
        backButton.setImage(image, for: .normal)
        backButton.layer.cornerRadius = backButton.frame.height/2
        backButton.isExclusiveTouch = true
        backButton.castDefaultShadow()
        backButton.layer.shadowColor = UIColor.darkGray.cgColor
        backButton.addTarget(self, action: #selector(backButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: backButton)
        backButton.alpha = 1
        backButton.isEnabled = true
        backButtonItem.customView = backButton
        
        imageConfiguration = UIImage.SymbolConfiguration(weight: .regular)
        image = UIImage(systemName: "questionmark", withConfiguration: imageConfiguration)
        helpButton.frame.size.height = 35
        helpButton.frame.size.width = helpButton.frame.size.height
        helpButton.backgroundColor = bgColor
        helpButton.tintColor = appThemeColor
        helpButton.setImage(image, for: .normal)
        helpButton.layer.cornerRadius = helpButton.frame.height/2
        helpButton.isExclusiveTouch = true
        helpButton.castDefaultShadow()
        helpButton.layer.shadowColor = UIColor.darkGray.cgColor
        helpButton.addTarget(self, action: #selector(helpButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: helpButton)
        backButton.alpha = 1
        helpButton.isEnabled = true
        helpButtonItem.customView = helpButton
        
        navBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 90))
        navBar.delegate = self
        navBar.prefersLargeTitles = false
        /** Specify the title of this view controller*/
        navItem.title = itemData.name
        navItem.leftBarButtonItem = backButtonItem
        navItem.rightBarButtonItems = [helpButtonItem]
        navItem.largeTitleDisplayMode = .never
        navBar.setItems([navItem], animated: false)
        
        self.view.addSubview(navBar)
        navBar.translatesAutoresizingMaskIntoConstraints = false
        navBar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        navBar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        navBar.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
        navBar.heightAnchor.constraint(equalToConstant: navBar.frame.height).isActive = true
    }
    
    /**Customize the nav and tab bars for this view*/
    func setCustomNavUI(){
        /**Prevent the scrollview from snapping into place when integrating with large title nav bar*/
        self.extendedLayoutIncludesOpaqueBars = true
        /**nav bar customization*/
        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.configureWithOpaqueBackground()
        /**Make the shadow clear*/
        standardAppearance.shadowColor = UIColor.clear
        
        /** Background and font is clear when the scrollview is at the top*/
        standardAppearance.backgroundColor = .clear
        standardAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.clear, NSAttributedString.Key.font: getCustomFont(name: .Ubuntu_Medium, size: 30, dynamicSize: true)]
        standardAppearance.titleTextAttributes = [.foregroundColor: UIColor.clear, NSAttributedString.Key.font: getCustomFont(name: .Ubuntu_Medium, size: 18, dynamicSize: true)]
        
        navItem.leftItemsSupplementBackButton = true
        switch darkMode{
        case true:
            navBar.barTintColor = bgColor
            navBar.titleTextAttributes = [.foregroundColor: fontColor]
            navBar.tintColor = fontColor
            
            /**Customize the navigation items if any are present*/
            if(navItem.rightBarButtonItems?.count != nil){
                for index in 0..<self.navItem.rightBarButtonItems!.count{
                    navItem.rightBarButtonItems?[index].tintColor = fontColor
                }
            }
            if(navItem.leftBarButtonItems?.count != nil){
                for index in 0..<self.navItem.leftBarButtonItems!.count{
                    navItem.leftBarButtonItems?[index].tintColor = fontColor
                }
            }
            
        case false:
            navBar.barTintColor = bgColor
            navBar.titleTextAttributes = [.foregroundColor: UIColor.white]
            navBar.tintColor = UIColor.white
            
            /**Customize the navigation items if any are present*/
            if(navItem.rightBarButtonItems?.count != nil){
                for index in 0..<self.navItem.rightBarButtonItems!.count{
                    navItem.rightBarButtonItems?[index].tintColor = UIColor.white
                }
            }
            if(navItem.leftBarButtonItems?.count != nil){
                for index in 0..<self.navItem.leftBarButtonItems!.count{
                    navItem.leftBarButtonItems?[index].tintColor = UIColor.white
                }
            }
        }
        navBar.standardAppearance = standardAppearance
        navBar.scrollEdgeAppearance = standardAppearance
    }
    
    /** Button press methods*/
    /** Present the cart associated with this session*/
    @objc func shoppingCartButtonPressed(sender: UIButton){
        let cartVC = ShoppingCartVC(cart: self.laundromatCart, displayAddMoreItemsButton: true)
        
        /** Popover full screen without canceling out the background content*/
        cartVC.modalPresentationStyle = .overFullScreen
        cartVC.modalTransitionStyle = .coverVertical
        
        self.present(cartVC, animated: true)
    }
    
    /** Add the item to the cart, if the item is already in the cart (with the same item choice) then simply increase that cart item's count by the given count of this item data*/
    @objc func addToCartButtonPressed(sender: UIButton){
        guard internetAvailable == true else {
            errorShake()
            
            globallyTransmit(this: "Please connect to the internet in order to continue", with: UIImage(systemName: "wifi.slash", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: .clear, imageBorder: .none, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 3, selfDismiss: true)
            
            return
        }
        
        forwardTraversalShake()
        
        /** Add this mutated item to the cart and push these new changes to the remote in the delegate receiver*/
        laundromatCart.addThis(item: itemData)
        
        /** Reload the presenting table view using the updated cart data*/
        if presentingTableView != nil{
        presentingTableView!.reloadData()
        }
        
        /** Dismiss the keyboard if any*/
        view.endEditing(true)
        
        /** Dismiss this view controller*/
        self.dismiss(animated: true)
    }
    
    /** Display help menu*/
    @objc func helpButtonPressed(sender: UIButton){
        mediumHaptic()
        
        sender.isEnabled = false
        
        globallyTransmit(this: "In this section you can customize this service to best fit your needs, and even tell us specifically what you want done to your laundry.", with: UIImage(systemName: "lightbulb.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: appThemeColor, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .rightStrip, animated: true, duration: 3, selfDismiss: false)
    }
    
    @objc func backButtonPressed(sender: UIButton){
        backwardTraversalShake()
        
        /** Dismiss the keyboard if any*/
        view.endEditing(true)
        
        self.dismiss(animated: true, completion: nil)
    }
    
    /** Increment the quantity of this item*/
    @objc func addButtonPressed(sender: UIButton){
        if itemCount < maxItems{
            self.itemCount += 1
            lightHaptic()
            
            updateAddToCartButton()
        }
        else{
            itemCount = maxItems
            errorShake()
            globallyTransmit(this: "Maximum number of items reached for this item", with: UIImage(systemName: "tshirt.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .rightStrip, animated: true, duration: 3, selfDismiss: true)
        }
    }
    
    /** Decrement the quantity of this item*/
    @objc func subtractButtonPressed(sender: UIButton){
        if itemCount > minItems{
            self.itemCount -= 1
            lightHaptic()
            
            updateAddToCartButton()
        }
        else{
            itemData.count = 0
            errorShake()
            
            /** Inform the user that they can't go below zero*/
            globallyTransmit(this: "You can't have negative clothes!", with: UIImage(systemName: "tshirt.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .rightStrip, animated: true, duration: 3, selfDismiss: true)
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
    
    /** Tableview delegate methods*/
    
    /** Detect when a user selects a row in the tableview*/
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        mediumHaptic()
        
        /** Present the detail views for the following cells*/
        if tableView == itemChoicesTableView{
            lightHaptic()
            
            /** Fetch the cell at the given index path without dequeuing it and destroying its stored data*/
            let tableViewCell = tableView.cellForRow(at: indexPath) as! ItemChoiceCell
            
            /** Ignore disabled choices*/
            guard tableViewCell.disabled == false else {
                return
            }
            
            /** Already selected so remove it from the item choices and mark it as unselected in the item's data*/
            if tableViewCell.selectionStatus == true{
                
                tableViewCell.selectionButtonPressed(sender: tableViewCell.selectionButton)
                
                for choice in itemData.itemChoices{
                    if choice.name == tableViewCell.data.name && choice.category == tableViewCell.data.category{
                        choice.selected = false
                    }
                }
                
                selectedItemChoices[tableViewCell.data.category]?.remove(tableViewCell.data)
                
                var rowIndexPaths:[IndexPath] = []
                
                for row in 0..<tableView.numberOfRows(inSection: indexPath.section){
                    let thisIndexPath = IndexPath(row: row, section: indexPath.section)
                    
                    /** Make sure to not include the currently selected cells in the index path array*/
                    if let cell = tableView.cellForRow(at: thisIndexPath) as? ItemChoiceCell{
                        if cell.selectionStatus == false && tableViewCell != cell{
                            rowIndexPaths.append(thisIndexPath)
                        }
                    }
                }
                
                /** Reload all the rows in this section except the one that was selected*/
                tableView.reloadRows(at: rowIndexPaths, with: .none)
                
                /**Update the price of the cart, and the subtotal and the add to cart button's display*/
                updateAddToCartButton()
            }
            else{
                /** Only add the item choice to the selected dictionary if the set doesn't exceed the limit of the amount of item choices for that category*/
                if selectedItemChoices[tableViewCell.data.category]?.isEmpty == false{
                    if selectedItemChoices[tableViewCell.data.category]!.contains(tableViewCell.data) == false && selectedItemChoices[tableViewCell.data.category]!.count < tableViewCell.data.limit{
                        selectedItemChoices[tableViewCell.data.category]?.update(with: tableViewCell.data)
                        
                        tableViewCell.selectionButtonPressed(sender: tableViewCell.selectionButton)
                        
                        for choice in itemData.itemChoices{
                            if choice.name == tableViewCell.data.name && choice.category == tableViewCell.data.category{
                                choice.selected = true
                            }
                        }
                    }
                }
                else{
                    /** Category isn't already included so initialize it*/
                    selectedItemChoices[tableViewCell.data.category] = Set<itemChoice>()
                    selectedItemChoices[tableViewCell.data.category]?.update(with: tableViewCell.data)
                    
                    tableViewCell.selectionButtonPressed(sender: tableViewCell.selectionButton)
                    
                    for choice in itemData.itemChoices{
                        if choice.name == tableViewCell.data.name && choice.category == tableViewCell.data.category{
                            choice.selected = true
                        }
                    }
                }
                
                var rowIndexPaths:[IndexPath] = []
                
                for row in 0..<tableView.numberOfRows(inSection: indexPath.section){
                    let thisIndexPath = IndexPath(row: row, section: indexPath.section)
                    
                    /** Make sure to not include the currently selected cells in the index path array*/
                    if let cell = tableView.cellForRow(at: thisIndexPath) as? ItemChoiceCell{
                        if cell.selectionStatus == false && tableViewCell != cell{
                            rowIndexPaths.append(thisIndexPath)
                        }
                    }
                }
                
                /** Reload all the rows in this section except the one that was selected*/
                tableView.reloadRows(at: rowIndexPaths, with: .none)
                
                /**Update the price of the cart, and the subtotal and the add to cart button's display*/
                updateAddToCartButton()
            }
            
        }
    }
    
    /** Update the add to cart button with the updated subtotal given a change to the quantity and or item choices*/
    func updateAddToCartButton(){
        itemData.count = itemCount
        subtotal = itemData.getSubtotal()
        
        /** Update the item count display*/
        itemCountDisplay.text = "\(itemCount)"
        
        if areRequirementsSatisfied() == true && isSpecialInstructionsUnderCharLimit() == true{
            UIView.animate(withDuration: 0.5, delay: 0){[self] in
                addToCartButton.alpha = 1
            }
            addToCartButton.isEnabled = true
        }
        else{
            UIView.animate(withDuration: 0.5, delay: 0){[self] in
                addToCartButton.alpha = 0.5
            }
            addToCartButton.isEnabled = false
        }
        
        /** Display price and quantity info if the item has a count greater than 0*/
        if itemCount > 0{
            addToCartButton.setTitle(" Add to Cart (\(itemCount)) $\(String(format: "%.2f", itemData.getSubtotal()))", for: .normal)
            
            /** Enable subtract button*/
            UIView.animate(withDuration: 0.5, delay: 0){[self] in
                itemCountDisplay.alpha = 1
                
                subtractButton.alpha = 1
                subtractButton.isEnabled = true
            }
        }
        else{
            addToCartButton.setTitle(" Add to Cart", for: .normal)
            
            /** Disable subtract button*/
            UIView.animate(withDuration: 0.5, delay: 0){[self] in
                itemCountDisplay.alpha = 0
                
                subtractButton.alpha = 0.5
                subtractButton.isEnabled = false
            }
        }
    }
    
    /** Return the estimated height of the item choices tableview based on the number of sections and rows in those sections, required if inserting the tableview into a stackview (auto-compresses the view to 0 if no content is present)*/
    func getEstimatedHeightOfItemChoicesTableView()->CGFloat{
        let sections = itemChoicesTableView.numberOfSections
        var rows = 0
        let totalSectionHeaderHeight = itemChoicesTableViewSectionHeaderHeight * CGFloat(sections)
        let totalSectionFooterHeight = itemChoicesTableViewSectionFooterHeight * CGFloat(sections)
        
        /** Get the total amount of rows for all sections in the tableview*/
        for section in 0..<sections{
            rows += itemChoicesTableView.numberOfRows(inSection: section)
        }
        
        /** Multiply the number of rows by the tableview's preferred row height and add the heights for the section headers and footers*/
        return ((CGFloat(rows) * itemChoicesTableViewRowHeight) + totalSectionFooterHeight + totalSectionHeaderHeight)
    }
    
    /** Provide a custom view for the header of the given section*/
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        var view: UIView? = nil
        
        if tableView == itemChoicesTableView{
            let container = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: itemChoicesTableViewSectionHeaderHeight))
            container.backgroundColor = bgColor.darker
            container.clipsToBounds = true
            
            /** Describe the name of this category*/
            let categoryLabel = UILabel(frame: CGRect(x: 0, y: 0, width: container.frame.width * 0.95, height: container.frame.height/2))
            categoryLabel.font = getCustomFont(name: .Ubuntu_Regular, size: 16, dynamicSize: true)
            categoryLabel.textColor = fontColor
            categoryLabel.adjustsFontForContentSizeCategory = true
            categoryLabel.adjustsFontSizeToFitWidth = true
            categoryLabel.textAlignment = .left
            categoryLabel.text = sortedItemChoicesCategories[section]
            categoryLabel.sizeToFit()
            
            /** Inform the user if this choice is required or optional*/
            let requirementLabel = UILabel(frame: CGRect(x: 0, y: 0, width: container.frame.width * 0.95, height: container.frame.height/2))
            requirementLabel.font = getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true)
            requirementLabel.textColor = .lightGray
            requirementLabel.adjustsFontForContentSizeCategory = true
            requirementLabel.adjustsFontSizeToFitWidth = true
            requirementLabel.textAlignment = .left
            
            /** Get the requirement parameter for this choice category*/
            var required = false
            var limit = 0
            if let itemChoices = itemChoicesCategorySections[sortedItemChoicesCategories[section]]{
                if let itemChoice = itemChoices.first{
                    required = itemChoice.required
                    limit = itemChoice.limit
                }
            }
            
            if required{
                requirementLabel.text = "Required • Choose up to \(limit) choices"
                if limit == 1{
                    requirementLabel.text = "Required • Choose up to \(limit) choice"
                }
            }
            else{
                requirementLabel.text = "Optional • Choose up to \(limit) choices"
                if limit == 1{
                    requirementLabel.text = "Optional • Choose up to \(limit) choice"
                }
            }
            requirementLabel.sizeToFit()
            
            /** Layout subviews*/
            categoryLabel.frame.origin = CGPoint(x: container.frame.width * 0.05, y: container.frame.height/2 - categoryLabel.frame.height)
            
            requirementLabel.frame.origin = CGPoint(x: categoryLabel.frame.minX, y: categoryLabel.frame.maxY)
            
            container.addSubview(categoryLabel)
            container.addSubview(requirementLabel)
            
            view = container
        }
        
        return view
    }
    
    /**Here we pass the table view all of the data for the cells*/
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        var cell = UITableViewCell()
        
        /** Identify the tableview in question*/
        if tableView == itemChoicesTableView{
            
            let tableViewCell = tableView.dequeueReusableCell(withIdentifier: ItemChoiceCell.identifier, for: indexPath) as! ItemChoiceCell
            
            /** Get the category for this section and use this to pin-point the set of item choices associated with this section*/
            var category = ""
            category = sortedItemChoicesCategories[indexPath.section]
            
            let itemChoices = itemChoicesCategorySections[category]
            if itemChoices != nil{
                /** Avoid going out of bounds*/
                if indexPath.row < itemChoices!.count{
                    
                    /** Choice is not selected and the selection set has reached the selection limit of the category*/
                    if selectedItemChoices[category]!.contains(itemChoices![indexPath.row]) == false && selectedItemChoices[category]!.count == itemChoices![indexPath.row].limit{
                        tableViewCell.create(with: itemChoices![indexPath.row], selectionStatus: false, disabled: true)
                    }
                    else if selectedItemChoices[category]!.contains(itemChoices![indexPath.row]) == false && selectedItemChoices[category]!.count <= itemChoices![indexPath.row].limit{
                        /** Choice is not selected and the selection set has not yet reached the selection limit of the category*/
                        tableViewCell.create(with: itemChoices![indexPath.row], selectionStatus: false, disabled: false)
                    }
                    else if (selectedItemChoices[category]?.contains(itemChoices![indexPath.row]))! == true{
                        /** Choice is selected*/
                        tableViewCell.create(with: itemChoices![indexPath.row], selectionStatus: true, disabled: false)
                    }
                    else{
                        /** Nothing has been selected yet*/
                        tableViewCell.create(with: itemChoices![indexPath.row], selectionStatus: false, disabled: false)
                    }
                }
            }
            
            cell = tableViewCell
        }
        
        return cell
    }
    
    /** Sort the category strings in descending order from A-Z*/
    func sortCategoriesInDescendingOrder(){
        /** Store all of the keys and sort them in descending order*/
        sortedItemChoicesCategories.removeAll()
        for (key, _) in itemChoicesCategorySections{
            sortedItemChoicesCategories.append(key)
        }
        sortedItemChoicesCategories = sortedItemChoicesCategories.sorted(by: <)
    }
    
    /** Sort the category strings in ascending order from Z-A*/
    func sortCategoriesInAscendingOrder(){
        /** Store all of the keys and sort them in descending order*/
        sortedItemChoicesCategories.removeAll()
        for (key, _) in itemChoicesCategorySections{
            sortedItemChoicesCategories.append(key)
        }
        sortedItemChoicesCategories = sortedItemChoicesCategories.sorted(by: >)
    }
    
    /** Search through all the item choices in the item choices dictionary and return a dictionary containing categories and the amount of item choices in those categories*/
    func computeTotalSectionsForItemChoicesTableView()->[String : [itemChoice]]?{
        var itemsChoicesPerCatergory: [String: [itemChoice]]? = nil
        
        itemsChoicesPerCatergory = [:]
        
        for choice in itemData.itemChoices{
            /** Initialize the array for the given category string and append each item to the array for that key*/
            if itemsChoicesPerCatergory![choice.category] == nil{
                itemsChoicesPerCatergory![choice.category] = []
                itemsChoicesPerCatergory![choice.category]?.append(choice)
            }
            else{
                itemsChoicesPerCatergory![choice.category]?.append(choice)
            }
        }
        
        /** Sort the items from highest to lowest price*/
        for (category, itemChoices) in itemsChoicesPerCatergory!{
            itemsChoicesPerCatergory![category] = itemChoices.sorted(by: >)
        }
        
        return itemsChoicesPerCatergory
    }
    
    
    /** Specify the number of sections for the given table view*/
    public func numberOfSections(in tableView: UITableView) -> Int {
        var numberOfSections = 1
        
        if tableView == itemChoicesTableView{
            if sortedItemChoicesCategories.isEmpty == false{
                numberOfSections = sortedItemChoicesCategories.count
            }
            else{
                numberOfSections = 0
            }
        }
        
        return numberOfSections
    }
    
    /**Set the number of rows in the table view*/
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = 0
        
        /** The number of rows in each section is the number of items under each category*/
        if tableView == itemChoicesTableView{
            if itemChoicesCategorySections.isEmpty == false{
                for (_, pair) in itemChoicesCategorySections.enumerated(){
                    if sortedItemChoicesCategories[section] == pair.key{
                        count = pair.value.count
                    }
                }
            }
            else{
                count = 0
            }
        }
        
        return count
    }
    
    /** Set the height for the following section headers*/
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        var height:CGFloat  = 0
        
        if tableView == itemChoicesTableView{
            height = itemChoicesTableViewSectionHeaderHeight
        }
        
        return height
    }
    
    /** Set the height for the following section footers*/
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        var height:CGFloat = 0
        
        if tableView == itemChoicesTableView{
            height = itemChoicesTableViewSectionFooterHeight
        }
        
        return height
    }
    
    /** Specify the height of the rows for the tableviews*/
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var height: CGFloat = 0
        
        if tableView == itemChoicesTableView{
            height = itemChoicesTableViewRowHeight
        }
        
        return height
    }
    /** Tableview delegate methods*/
    
    /** Collectionview delegate methods*/
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var count = 0
        
        if collectionView == recommendedForYouCollectionView{
            count = laundromatMenu.items.count
        }
        
        return count
    }
    
    /** Supplement data to the collection view*/
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell = UICollectionViewCell()
        
        /** Identify the collectionview in question*/
        if collectionView == recommendedForYouCollectionView{
            let orderItemCell = collectionView.dequeueReusableCell(withReuseIdentifier: OrderItemCollectionViewCell.identifier, for: indexPath) as! OrderItemCollectionViewCell
            
            guard laundromatMenu.items.isEmpty == false else {
                return cell
            }
            
            var itemsArray: [OrderItem] = []
            for item in laundromatMenu.items{
                itemsArray.append(item)
            }
            
            orderItemCell.create(with: itemsArray[indexPath.row], cart: laundromatCart)
            orderItemCell.presentingVC = self
            orderItemCell.presentingTableView = presentingTableView
            
            /** If this item is already in the user's cart then highlight the cell*/
            orderItemCell.updateBorder()
            
            cell = orderItemCell
        }
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.view.frame.width/3, height: collectionViewHeight)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        mediumHaptic()
        
        let cell = collectionView.cellForItem(at: indexPath) as! OrderItemCollectionViewCell
        
        /** Present the detail views for the following cells*/
        if collectionView == recommendedForYouCollectionView{
        let vc = OrderItemDetailVC(itemData: cell.itemData, laundromatCart: laundromatCart, laundromatMenu: laundromatMenu)
        vc.presentingTableView = presentingTableView
        /** Don't display another recommendations collectionview*/
        vc.displayRecommendations = false
            
        /** Prevent the user from using interactive dismissal*/
        vc.isModalInPresentation = true
        self.show(vc, sender: self)
        }
    }
    /** Collectionview delegate methods*/
    
    /** Textview delegate methods*/
    public func textViewDidChange(_ textView: UITextView){
        currentTextViewCharCount = textView.text.count
        textViewCharLimitDisplay.text = "\(currentTextViewCharCount)/\(textViewCharLimit)"
        
        if currentTextViewCharCount > textViewCharLimit{
            /** Out of bounds*/
            errorShake()
            textViewCharLimitDisplay.textColor = .red
            specialInstructionsTextView.layer.borderColor = UIColor.red.cgColor
        }
        else{
            /** Within bounds*/
            itemData.specialInstructions = specialInstructionsTextView.text.removeEmptyLastChar()
            
            switch darkMode{
            case true:
                textViewCharLimitDisplay.backgroundColor = .darkGray.darker
                textViewCharLimitDisplay.textColor = .white.darker
            case false:
                textViewCharLimitDisplay.backgroundColor = .white.darker
                textViewCharLimitDisplay.textColor = .lightGray
            }
            specialInstructionsTextView.layer.borderColor = bgColor.darker.cgColor
        }
    }
    
    /** Check to see if the special instructions provided by the user is within the char limit*/
    func isSpecialInstructionsUnderCharLimit()->Bool{
        var bool = false
        
        if currentTextViewCharCount <= textViewCharLimit{
            bool = true
        }
        /** Just in case something weird happens*/
        if currentTextViewCharCount < 0{
            currentTextViewCharCount = 0
            specialInstructionsTextView.text = ""
        }
        
        return bool
    }
    /** Textview delegate methods*/
    
    /** Listen for scroll events*/
    public func scrollViewDidScroll(_ UIScrollView: UIScrollView){
        if UIScrollView == scrollView{
            let offset = UIScrollView.contentOffset.y
            let targetOffset = maskedHeaderView.frame.height * 0.6
            
            /** display the title of this view controller when the user scrolls to and past the target height, and hide this when the user scrolls within*/
            if offset >= targetOffset{
                let standardAppearance = UINavigationBarAppearance()
                standardAppearance.configureWithOpaqueBackground()
                /**Make the shadow clear*/
                standardAppearance.shadowColor = UIColor.clear
                standardAppearance.backgroundColor = .clear
                
                UIView.animate(withDuration: 0.5, delay: 0){[self] in
                    standardAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white.withAlphaComponent(1), NSAttributedString.Key.font: getCustomFont(name: .Ubuntu_Medium, size: 30, dynamicSize: true)]
                    standardAppearance.titleTextAttributes = [.foregroundColor: UIColor.white.withAlphaComponent(1), NSAttributedString.Key.font: getCustomFont(name: .Ubuntu_Medium, size: 18, dynamicSize: true)]
                    
                    navBar.standardAppearance = standardAppearance
                    navBar.scrollEdgeAppearance = standardAppearance
                }
            }
            else{
                let standardAppearance = UINavigationBarAppearance()
                standardAppearance.configureWithOpaqueBackground()
                /**Make the shadow clear*/
                standardAppearance.shadowColor = UIColor.clear
                standardAppearance.backgroundColor = .clear
                
                UIView.animate(withDuration: 0.5, delay: 0){[self] in
                    standardAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white.withAlphaComponent(0), NSAttributedString.Key.font: getCustomFont(name: .Ubuntu_Medium, size: 30, dynamicSize: true)]
                    standardAppearance.titleTextAttributes = [.foregroundColor: UIColor.white.withAlphaComponent(0), NSAttributedString.Key.font: getCustomFont(name: .Ubuntu_Medium, size: 18, dynamicSize: true)]
                    
                    navBar.standardAppearance = standardAppearance
                    navBar.scrollEdgeAppearance = standardAppearance
                }
            }
            
        }
    }
    
    /** Banner ad delegates*/
    public func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        ///print("bannerViewDidReceiveAd")
        
        bannerView.stopSkeletonAnimation()
        bannerView.hideSkeleton()
    }
    
    public func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        ///print("bannerViewWillLeaveApplication")
    }
    
    public func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        ///print("bannerView:didFailToReceiveAdWithError: \(error.localizedDescription)")
    }
    
    public func adViewDidRecordImpression(_ bannerView: GADBannerView) {
        ///print("bannerViewDidRecordImpression")
    }
    
    public func adViewWillPresentScreen(_ bannerView: GADBannerView) {
        ///print("bannerViewWillPresentScreen")
    }
    
    public func adViewWillDismissScreen(_ bannerView: GADBannerView) {
        ///print("bannerViewWillDismissScreen")
    }
    
    public func adViewDidDismissScreen(_ bannerView: GADBannerView) {
        ///print("bannerViewDidDismissScreen")
    }
    /** Banner ad delegates*/
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
