//
//  ShoppingCartVC.swift
//  Stuy Wash N Dry
//
//  Created by Justin Cook on 3/28/22.
//

import UIKit

/** View controller in which the user will be able to view their order and proceed with checkout, the shopping cart is persistent and will be saved upon the user exiting the application, a push notification will remind the user that they have items in their shopping cart still after the app has been terminated whilst there are items in said cart*/
public class ShoppingCartVC: UIViewController, UICollectionViewDelegate, UITableViewDelegate, UITableViewDataSource, CartDelegate{
    /** The shopping cart data to reflect in this view controller*/
    var cart: Cart
    
    /** UI Elements*/
    /** A  view that can be tapped to dismiss the view controller (lies behind all other views)*/
    private var dismissableArea: UIVisualEffectView!
    
    /** Large label describing the content in the view*/
    var cartLabel: PaddedLabel!
    
    /** UIView that will contain all visible content, this container's size grows up until it reaches a certain point, then the scrollview of the embedded collectionview will kick in*/
    var container: UIView!
    
    /** Static header contains all header content [business name label, sharebutton, progress bar]*/
    var headerContainer: UIView!
    /** A label depicting the name of the laundromat / business this cart's items are from*/
    var businessNameHeaderLabel: PaddedLabel!
    
    /** Contains all subtotal UI*/
    var subtotalContainer: UIView!
    /** Label with the title 'subtotal' to direct the user to the subtotal price of the cart*/
    var subtotalHeadingLabel: UILabel!
    /** Label with the numeric value of the cart's subtotal value*/
    var subtotalPriceLabel: UILabel!
    
    /** Static footer contains the checkout and add items buttons*/
    var footerContainer: UIView!
    /** Simple line dividing the footer from the rest of the UI*/
    var footerDividingLine: UIView!
    
    /** Fancy progress bar to display for 'fake loading' purposes, it makes the user think more is going on which is always nice*/
    /** Container for the moving graphics*/
    var progressBarContainer: UIView!
    /** UIView to be animated in the progress bar container*/
    var progressBar: UIView!
    
    /** Dynamic Height Content*/
    /** Tableview*/
    /** A tableview depicting a minimalistic list of all the items inside of the cart currently (their individual itemized costs, the their total quantity and their name)*/
    var shoppingCartItemsTableView: UITableView!
    /** Tableview*/
    
    /** Where the dynamic content is held*/
    var scrollView: UIScrollView!
    
    /** Functional UI*/
    /** Basically a button that pops the user to the laundromat tied to the current cart (dismisses self if the presenting vc is the laundromatLocationDetailVC, or selfdismisses and instantiates a new laundromatLocationDetailVC for the laundromat in question if it's not being presented from one already), if an orderItemDetailVC is in the way then try to pop back to the locationDetailVC by dismissing that parent VC as well*/
    var addItemsButton: UIButton!
    /** Pushes the user to the checkout VC*/
    var goToCheckOutButton: UIButton!
    /** Allows the user to share an ordered list of text depicting the user's current order*/
    var shareButton: UIButton!
    /** Clear the cart's current items but don't dismiss*/
    var clearCartButton: UIButton!
    
    /** Tap to dismiss functionality*/
    var tapGestureRecognizer: UITapGestureRecognizer!
    
    /** Toggled on when the presenting VC is the laundromatLocationDetailVC because there's no need for an add more items button when you can dismiss this vc and go back to add more*/
    var displayAddMoreItemsButton: Bool
    
    /** Undo Functionality*/
    /** keep a soft copy of the original items from the cart and restore them if the user undoes the clear action*/
    var itemCache: Set<OrderItem> = []
    /** Used to provide dual functionality to the go to checkout button in order to make it double as an undo button*/
    var undoInProgress: Bool = false
    
    /** View Model*/
    /** Tap to Dismiss Area -> Container -> [Header ->[name label, share button, progress bar], ScrollView -> [collectionview, subtotal->[subtotal label, subtotal price label]]], Footer->[footerDividingLine, (bool)add items button, checkout button]]*/
    
    /** Dynamic Sizing properties*/
    /** The default computed height of the container without any order items*/
    lazy var defaultContainerHeight: CGFloat = getDefaultHeight()
    /** The height of each cell to be displayed in the table view*/
    var orderItemsHeight: CGFloat = 60
    
    /** The maximum size that the scrollview's content can grow to before the scrollview's scrolling is enabled to reflect overflowing content*/
    var maximumScrollViewContentHeightThreshold: CGFloat{
        return self.view.frame.height * 0.6
    }
    
    /** Passed the required data to this object upon instantiation*/
    init(cart: Cart, displayAddMoreItemsButton: Bool){
        self.cart = cart
        self.displayAddMoreItemsButton = displayAddMoreItemsButton
        
        super.init(nibName: nil, bundle: nil)
    }
    
    public override func viewDidLoad() {
        configure()
        constructUI()
    }
    
    func getDefaultHeight()->CGFloat{
        return displayAddMoreItemsButton ? self.view.frame.height * 0.45 : self.view.frame.height * 0.4
    }
    
    /** Construct the UI for this VC*/
    func constructUI(){
        self.view.backgroundColor = .clear
        
        /** Tap to dismiss area*/
        dismissableArea = UIVisualEffectView(frame: self.view.frame)
        dismissableArea.effect = UIBlurEffect(style: darkMode ? .dark : .light)
        dismissableArea.backgroundColor = bgColor.withAlphaComponent(0.1)
        dismissableArea.clipsToBounds = true
        
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognizerTriggered))
        tapGestureRecognizer.requiresExclusiveTouchType = true
        tapGestureRecognizer.numberOfTouchesRequired = 1
        
        dismissableArea.addGestureRecognizer(tapGestureRecognizer)
        /** Tap to dismiss area*/
        
        /** Cart Label*/
        cartLabel = PaddedLabel(withInsets: 0, 0, 5, 5)
        cartLabel.frame = CGRect(x: 0, y: 0, width: self.view.frame.width * 0.35, height: self.view.frame.height * 0.2)
        cartLabel.font = getCustomFont(name: .Bungee_Regular, size: 28, dynamicSize: true)
        cartLabel.textColor = appThemeColor
        cartLabel.adjustsFontForContentSizeCategory = true
        cartLabel.adjustsFontSizeToFitWidth = true
        cartLabel.textAlignment = .left
        cartLabel.text = "My Cart"
        cartLabel.shadowColor = .lightGray
        cartLabel.sizeToFit()
        /** Cart Label*/
        
        container = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: defaultContainerHeight))
        container.backgroundColor = bgColor
        container.layer.cornerRadius = 10
        container.clipsToBounds = true
        container.layer.maskedCorners = [.layerMaxXMinYCorner,.layerMinXMinYCorner]
        
        /** Header*/
        headerContainer = UIView(frame: CGRect(x: 0, y: 0, width: container.frame.width, height: displayAddMoreItemsButton ? container.frame.height * 0.185 : container.frame.height * 0.2))
        headerContainer.clipsToBounds = true
        headerContainer.backgroundColor = bgColor
        
        /** Progress Bar*/
        progressBarContainer = UIView(frame: CGRect(x: 0, y: 0, width: container.frame.width, height: 1))
        progressBarContainer.backgroundColor = darkMode ? .black : .lightGray
        progressBarContainer.clipsToBounds = true
        
        progressBar = UIView(frame: progressBarContainer.frame)
        progressBar.backgroundColor = appThemeColor
        progressBar.clipsToBounds = true
        progressBar.layer.cornerRadius = progressBar.frame.height/2
        /** Progress Bar*/
        
        businessNameHeaderLabel = PaddedLabel(withInsets: 2, 2, 5, 5)
        businessNameHeaderLabel.frame = CGRect(x: 0, y: 0, width: headerContainer.frame.width * 0.6, height: (headerContainer.frame.height - progressBarContainer.frame.height) * 0.9)
        businessNameHeaderLabel.font = getCustomFont(name: .Ubuntu_Regular, size: 22, dynamicSize: false)
        businessNameHeaderLabel.backgroundColor = bgColor.darker
        businessNameHeaderLabel.clipsToBounds = true
        businessNameHeaderLabel.textColor = fontColor
        businessNameHeaderLabel.layer.borderWidth = 1
        businessNameHeaderLabel.layer.borderColor = appThemeColor.cgColor
        businessNameHeaderLabel.adjustsFontForContentSizeCategory = false
        businessNameHeaderLabel.adjustsFontSizeToFitWidth = true
        businessNameHeaderLabel.textAlignment = .center
        businessNameHeaderLabel.text = cart.laundromatName
        businessNameHeaderLabel.sizeToFit()
        businessNameHeaderLabel.layer.cornerRadius = businessNameHeaderLabel.frame.height/2
        
        shareButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        shareButton.imageEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        shareButton.backgroundColor = .clear
        shareButton.tintColor = appThemeColor
        shareButton.setImage(UIImage(systemName: "person.fill.badge.plus", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        shareButton.imageView?.contentMode = .scaleAspectFit
        shareButton.layer.cornerRadius = shareButton.frame.height/2
        shareButton.isEnabled = true
        shareButton.isExclusiveTouch = true
        shareButton.addTarget(self, action: #selector(shareButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: shareButton)
        
        clearCartButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        clearCartButton.imageEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        clearCartButton.backgroundColor = .clear
        clearCartButton.tintColor = fontColor
        clearCartButton.setImage(UIImage(systemName: "trash.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        clearCartButton.imageView?.contentMode = .scaleAspectFit
        clearCartButton.layer.cornerRadius = clearCartButton.frame.height/2
        clearCartButton.isEnabled = true
        clearCartButton.isExclusiveTouch = true
        clearCartButton.addTarget(self, action: #selector(clearCartButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: clearCartButton)
        /** Header*/
        
        /** Footer*/
        footerContainer = UIView(frame: CGRect(x: 0, y: 0, width: container.frame.width, height: displayAddMoreItemsButton ? container.frame.height * 0.4 : container.frame.height * 0.3))
        footerContainer.clipsToBounds = true
        footerContainer.backgroundColor = bgColor
        
        footerDividingLine = UIView(frame: CGRect(x: 0, y: 0, width: container.frame.width, height: 1))
        footerDividingLine.backgroundColor = darkMode ? .black : .lightGray
        footerDividingLine.clipsToBounds = true
        
        goToCheckOutButton = UIButton(frame: CGRect(x: 0, y: 0, width: footerContainer.frame.width * 0.85, height: displayAddMoreItemsButton ? ((footerContainer.frame.height * 0.4) - 10) : (footerContainer.frame.height * 0.5)))
        goToCheckOutButton.backgroundColor = appThemeColor
        goToCheckOutButton.setTitleColor(.white, for: .normal)
        goToCheckOutButton.setTitle(" Continue to Checkout", for: .normal)
        goToCheckOutButton.titleLabel?.font = getCustomFont(name: .Ubuntu_Regular, size: 16, dynamicSize: true)
        goToCheckOutButton.contentHorizontalAlignment = .center
        goToCheckOutButton.titleLabel?.adjustsFontSizeToFitWidth = true
        goToCheckOutButton.titleLabel?.adjustsFontForContentSizeCategory = true
        goToCheckOutButton.layer.cornerRadius = goToCheckOutButton.frame.height/2
        goToCheckOutButton.isExclusiveTouch = true
        goToCheckOutButton.isEnabled = true
        goToCheckOutButton.castDefaultShadow()
        goToCheckOutButton.layer.shadowColor = UIColor.darkGray.cgColor
        goToCheckOutButton.tintColor = .white
        goToCheckOutButton.setImage(UIImage(systemName: "creditcard.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        goToCheckOutButton.addTarget(self, action: #selector(goToCheckOutButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: goToCheckOutButton)
        
        addItemsButton = UIButton(frame: CGRect(x: 0, y: 0, width: footerContainer.frame.width * 0.85, height: displayAddMoreItemsButton ? ((footerContainer.frame.height * 0.4) - 10) : (0)))
        addItemsButton.backgroundColor = bgColor.darker
        addItemsButton.setTitleColor(appThemeColor, for: .normal)
        addItemsButton.setTitle(" Add More Items", for: .normal)
        addItemsButton.titleLabel?.font = getCustomFont(name: .Ubuntu_Regular, size: 16, dynamicSize: true)
        addItemsButton.contentHorizontalAlignment = .center
        addItemsButton.titleLabel?.adjustsFontSizeToFitWidth = true
        addItemsButton.titleLabel?.adjustsFontForContentSizeCategory = true
        addItemsButton.layer.cornerRadius = addItemsButton.frame.height/2
        addItemsButton.isExclusiveTouch = true
        addItemsButton.isEnabled = true
        addItemsButton.castDefaultShadow()
        addItemsButton.layer.shadowColor = UIColor.darkGray.cgColor
        addItemsButton.tintColor = .white
        addItemsButton.setImage(UIImage(systemName: "cart.fill.badge.plus", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        addItemsButton.addTarget(self, action: #selector(addItemsButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: addItemsButton)
        /** Footer*/
        
        /** Scrollview*/
        scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: container.frame.width, height: displayAddMoreItemsButton ? container.frame.height * 0.415 : container.frame.height * 0.5))
        scrollView.clipsToBounds = true
        scrollView.backgroundColor = .clear
        scrollView.indicatorStyle =  darkMode ? .white : .black
        
        subtotalContainer = UIView(frame: CGRect(x: 0, y: 0, width: container.frame.width, height: 50))
        subtotalContainer.clipsToBounds = true
        subtotalContainer.backgroundColor = bgColor
        subtotalContainer.layer.borderColor = darkMode ? UIColor.black.cgColor : UIColor.lightGray.cgColor
        subtotalContainer.layer.borderWidth = 0.5
        
        subtotalHeadingLabel = UILabel(frame: CGRect(x: 0, y: 0, width: container.frame.width * 0.6, height: subtotalContainer.frame.height * 0.9))
        subtotalHeadingLabel.font = getCustomFont(name: .Ubuntu_Medium, size: 20, dynamicSize: true)
        subtotalHeadingLabel.textColor = fontColor
        subtotalHeadingLabel.adjustsFontForContentSizeCategory = true
        subtotalHeadingLabel.adjustsFontSizeToFitWidth = true
        subtotalHeadingLabel.textAlignment = .center
        subtotalHeadingLabel.text = "Subtotal:"
        subtotalHeadingLabel.sizeToFit()
        
        subtotalPriceLabel = UILabel(frame: CGRect(x: 0, y: 0, width: container.frame.width * 0.4, height: subtotalContainer.frame.height * 0.9))
        subtotalPriceLabel.font = getCustomFont(name: .Ubuntu_Regular, size: 18, dynamicSize: true)
        subtotalPriceLabel.textColor = fontColor
        subtotalPriceLabel.adjustsFontForContentSizeCategory = true
        subtotalPriceLabel.adjustsFontSizeToFitWidth = true
        subtotalPriceLabel.textAlignment = .center
        subtotalPriceLabel.text = "$\(String(format: "%.2f", cart.subtotal))"
        subtotalPriceLabel.sizeToFit()
        
        shoppingCartItemsTableView = UITableView(frame: CGRect(x: 0, y: 0, width: scrollView.frame.width, height: scrollView.frame.height - (subtotalContainer.frame.height)), style: .plain)
        shoppingCartItemsTableView.clipsToBounds = true
        shoppingCartItemsTableView.backgroundColor = darkMode ? .black : .white
        shoppingCartItemsTableView.tintColor = fontColor
        shoppingCartItemsTableView.isOpaque = false
        shoppingCartItemsTableView.showsVerticalScrollIndicator = true
        shoppingCartItemsTableView.showsHorizontalScrollIndicator = false
        shoppingCartItemsTableView.isExclusiveTouch = true
        shoppingCartItemsTableView.contentInsetAdjustmentBehavior = .never
        shoppingCartItemsTableView.dataSource = self
        shoppingCartItemsTableView.delegate = self
        shoppingCartItemsTableView.separatorStyle = .singleLine
        
        shoppingCartItemsTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
        
        shoppingCartItemsTableView.register(ShoppingCartItemsTableViewCell.self, forCellReuseIdentifier: ShoppingCartItemsTableViewCell.identifier)
        
        shoppingCartItemsTableView.indicatorStyle =  darkMode ? .white : .black
        
        /** If the cart is empty then disable these buttons*/
        if cart.items.count == 0{
           disableHeaderButtons()
        }
        
        /** Layout these subviews*/
        dismissableArea.frame.origin = .zero
        
        container.frame.origin = CGPoint(x: 0, y: self.view.frame.height - container.frame.height)
        
        cartLabel.frame.origin = CGPoint(x: 0, y: container.frame.minY - (cartLabel.frame.height * 1.25))
        
        headerContainer.frame.origin = .zero
        
        progressBarContainer.frame.origin = CGPoint(x: 0, y: headerContainer.frame.height - progressBarContainer.frame.height)
        
        progressBar.frame.origin.x = -progressBar.frame.width
        
        businessNameHeaderLabel.frame.origin = CGPoint(x: headerContainer.frame.width/2 - businessNameHeaderLabel.frame.width/2, y: headerContainer.frame.height/2 - businessNameHeaderLabel.frame.height/2)
        
        shareButton.frame.origin = CGPoint(x: headerContainer.frame.maxX - (shareButton.frame.width * 1.25), y: headerContainer.frame.height/2 - shareButton.frame.height/2)
        
        clearCartButton.frame.origin = CGPoint(x: headerContainer.frame.minX + (clearCartButton.frame.width * 0.25), y: headerContainer.frame.height/2 - clearCartButton.frame.height/2)
        
        footerContainer.frame.origin = CGPoint(x: 0, y: container.frame.height - footerContainer.frame.height)
        
        footerDividingLine.frame.origin = .zero
        
        addItemsButton.frame.origin = CGPoint(x: footerContainer.frame.width/2 - addItemsButton.frame.width/2, y: (footerContainer.frame.height/2 - (addItemsButton.frame.height + 5)))
        
        let checkoutButtonHeight = displayAddMoreItemsButton ? (footerContainer.frame.height/2 + 5) : (footerContainer.frame.height/2 - goToCheckOutButton.frame.height/2)
        goToCheckOutButton.frame.origin = CGPoint(x: footerContainer.frame.width/2 - goToCheckOutButton.frame.width/2, y: checkoutButtonHeight)
        
        scrollView.frame.origin = CGPoint(x: 0, y: headerContainer.frame.maxY)
        
        subtotalContainer.frame.origin = CGPoint(x: 0, y: scrollView.frame.height - subtotalContainer.frame.height)
        
        subtotalHeadingLabel.frame.origin = CGPoint(x: goToCheckOutButton.frame.minX, y: subtotalContainer.frame.height/2 - subtotalHeadingLabel.frame.height/2)
        
        subtotalPriceLabel.frame.origin = CGPoint(x: goToCheckOutButton.frame.maxX - subtotalPriceLabel.frame.width, y: subtotalContainer.frame.height/2 - subtotalPriceLabel.frame.height/2)
        
        shoppingCartItemsTableView.frame.origin = .zero
        
        self.view.addSubview(dismissableArea)
        self.view.addSubview(cartLabel)
        self.view.addSubview(container)
        
        scrollView.addSubview(shoppingCartItemsTableView)
        scrollView.addSubview(subtotalContainer)
         
        subtotalContainer.addSubview(subtotalHeadingLabel)
        subtotalContainer.addSubview(subtotalPriceLabel)
        
        progressBarContainer.addSubview(progressBar)
        
        headerContainer.addSubview(progressBarContainer)
        headerContainer.addSubview(businessNameHeaderLabel)
        headerContainer.addSubview(shareButton)
        headerContainer.addSubview(clearCartButton)
        
        footerContainer.addSubview(goToCheckOutButton)
        if displayAddMoreItemsButton == true{
            footerContainer.addSubview(addItemsButton)
        }
        footerContainer.addSubview(footerDividingLine)
        
        container.addSubview(scrollView)
        container.addSubview(headerContainer)
        container.addSubview(footerContainer)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){[self] in
            animateProgressBar(duration: 3)
            resize()
            
            /** Scroll to the bottom to show the user their subtotal*/
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){[self] in
            //scrollToBottom()
            }
        }
    }
    
    /** Update UI*/
    func updateSubtotal(){
        UIView.transition(with: subtotalPriceLabel, duration: 0.1, options: [.curveEaseIn], animations: { [self] in
            subtotalPriceLabel.text = "$\(String(format: "%.2f", cart.subtotal))"
        })
    }
    /** Update UI*/
    
    /** Cart delegate methods*/
    func cart(_ cart: Cart, didAdd item: OrderItem) {
        ///print("Item Added")
        
        updateSubtotal()
    }
    
    func cart(_ cart: Cart, didRemove item: OrderItem) {
        ///print("Item Removed")
        
        updateSubtotal()
    }
    
    /** Push any updates to this cart */
    func cart(_ cart: Cart, didUpdate item: OrderItem) {
        updateSubtotal()
        
        updateThisCart(cart: cart)
    }
    /** Cart delegate methods*/
    
    /** Tableview delegate methods*/
    /** Swipe Actions*/
    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?{
        var actions: [UIContextualAction] = []
        
        let removeAction = UIContextualAction(style: .destructive, title: "Remove Item"){[weak self] (action, view, completionHandler) in
            
            /** If internet is available then allow the user to delete the item*/
            if internetAvailable == true{
                lightHaptic()
                
                let tableViewCell = tableView.cellForRow(at: indexPath) as! ShoppingCartItemsTableViewCell
                let item = tableViewCell.itemData!
                
                self!.cart.removeThis(item: item)
                updateThisCart(cart: self!.cart)
                
                self!.updateSubtotal()
                
                /** Reload the tableview to reflect the new updates*/
                let indexSet = IndexSet(integer: 0)
                tableView.reloadSections(indexSet, with: .fade)
                
                /** Resize the view to reflect the new changes*/
                self!.resize()
                
                /** If this is the last item in the cart then remove the entire cart and dismiss this view*/
                if self!.cart.items.count == 0{
                    forwardTraversalShake()
                    
                    globallyTransmit(this: "Cart cleared", with: UIImage(systemName: "cart.fill.badge.minus", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: .clear, imageBorder: .borderLessCircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 3, selfDismiss: true)
                    
                deleteThisCart(cart: self!.cart)
                    
                    /** Update the cart of the presenting VC if it's a laundromat detail VC presenting the shopping cart*/
                    if let vc = self?.presentingViewController as? LaundromatLocationDetailVC{
                        
                        let _ = vc.isCartValid()
                    }
                    
                self!.dismiss(animated: true)
                }
            }
            else{
                errorShake()
                
                globallyTransmit(this: "An internet connection is required in order to update your cart", with: UIImage(systemName: "wifi.slash", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: .clear, imageBorder: .none, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 3, selfDismiss: true)
            }
        }
        removeAction.backgroundColor = .red
        
        actions.append(removeAction)
        
        let config = UISwipeActionsConfiguration(actions: actions)
        config.performsFirstActionWithFullSwipe = false
        
        return config
    }
    
    /** Detect when a user selects a row in the tableview*/
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        if tableView == shoppingCartItemsTableView{
            lightHaptic()
            
            /** Fetch the cell at the given index path without dequeuing it and destroying its stored data*/
            let tableViewCell = tableView.cellForRow(at: indexPath) as! ShoppingCartItemsTableViewCell
            
            let vc = OrderItemDetailVC(itemData: tableViewCell.itemData, laundromatCart: cart, laundromatMenu: tableViewCell.itemData.menu)
            
            /** Prevent the user from using interactive dismissal*/
            vc.isModalInPresentation = true
            self.show(vc, sender: self)
        }
    }
    
    /**Here we pass the table view all of the data for the cells*/
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        var cell = UITableViewCell()
        
        if tableView == shoppingCartItemsTableView{
            let tableViewCell = tableView.dequeueReusableCell(withIdentifier: ShoppingCartItemsTableViewCell.identifier, for: indexPath) as! ShoppingCartItemsTableViewCell
            
            let items = cart.items.toArray() as! [OrderItem]
            
            tableViewCell.create(with: items[indexPath.row], cart: cart)
            tableViewCell.presentingVC = self
            tableViewCell.presentingTableView = shoppingCartItemsTableView
            
            cell = tableViewCell
        }
        
        return cell
    }
    
    /** Specify the number of sections for the given table view*/
    public func numberOfSections(in tableView: UITableView) -> Int {
        var numberOfSections = 1
        
        if tableView == shoppingCartItemsTableView{
            numberOfSections = 1
        }
        
        return numberOfSections
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = 0
        
        if tableView == shoppingCartItemsTableView{
            count = cart.items.count
        }
        
        return count
    }
    
    /** Specify the height of the rows for the tableviews*/
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var height: CGFloat = 0
        
        if tableView == shoppingCartItemsTableView{
            
            let items = cart.items.toArray() as! [OrderItem]
            let itemData = items[indexPath.row]
            
            /** Two possible heights exist for these cells depending on if they have selections or not*/
            var hasSelections: Bool = false
            
            if itemData.itemChoices.isEmpty == false{
            for choice in itemData.itemChoices{
                if choice.selected == true{
                    hasSelections = true
                    height = orderItemsHeight + 10
                    break
                }
            }
            }
            else{
            height = orderItemsHeight
            }
            
            /** The increased height is used to show the selections below the main text*/
            height = hasSelections ? (orderItemsHeight + 10) : orderItemsHeight
        }
        
        return height
    }
    /** Tableview delegate methods*/
    
    /** Compute the total cell height for the collection view*/
    func computeTotalItemSize()->CGFloat{
        let items = cart.items.toArray() as! [OrderItem]
        var totalSize: CGFloat = 0
        var hasSelections: Bool = false
        
        /** Return the size of the items based on whether or not they have item choices selected or not*/
        for item in items{
            hasSelections = false
            
            if item.itemChoices.isEmpty == false{
            for choice in item.itemChoices{
                if choice.selected == true{
                    totalSize += orderItemsHeight + 10
                    hasSelections = true
                    break
                }
            }
            }
            
            /** If an item doesn't have item choices or does have item choices but they aren't selected (optional) then use the default height*/
            if hasSelections == false{
            totalSize += orderItemsHeight
            }
        }
        
        return totalSize
    }
    
    /** Resize the content of this VC to reflect the amount of items in the shopping cart*/
    func resize(){
        let totalItemSize = computeTotalItemSize()
        let scrollViewPadding: CGFloat = 0
        let totalScrollViewHeight: CGFloat = scrollViewPadding + totalItemSize + subtotalContainer.frame.height
        
        /** Animate the container growing*/
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn){ [self] in
            /** Resize and layout all of these subviews*/
            scrollView.frame.size.height = totalScrollViewHeight <= maximumScrollViewContentHeightThreshold ? totalScrollViewHeight : maximumScrollViewContentHeightThreshold
            
            shoppingCartItemsTableView.frame.size.height = scrollView.frame.height - subtotalContainer.frame.height
            
            container.frame.size.height = scrollView.frame.size.height + headerContainer.frame.size.height + footerContainer.frame.size.height
            
            container.frame.origin = CGPoint(x: 0, y: self.view.frame.height - container.frame.height)
            
            headerContainer.frame.origin = .zero
            
            scrollView.frame.origin = CGPoint(x: 0, y: headerContainer.frame.maxY)
            
            footerContainer.frame.origin = CGPoint(x: 0, y: container.frame.height - footerContainer.frame.height)
            
            subtotalContainer.frame.origin = CGPoint(x: 0, y: scrollView.frame.height - subtotalContainer.frame.height)
            
            shoppingCartItemsTableView.frame.origin = .zero
            
            cartLabel.frame.origin = CGPoint(x: 0, y: container.frame.minY - (cartLabel.frame.height * 1.25))
        }
    }
    
    /** Scroll to the bottom of the scrollview*/
    func scrollToBottom(){
        scrollView.contentOffset = CGPoint(x: 0, y: scrollView.frame.height)
    }
    
    /** Scroll to the top of the scrollview*/
    func scrollToTop(){
        scrollView.contentOffset = .zero
    }
    
    /** Cart is empty so do these things*/
    func cartEmpty(){
        disableHeaderButtons()
    }
    
    /** Disable the buttons in the header, you can't share or clear empty space*/
    func disableHeaderButtons(){
        shareButton.isEnabled = false
        shareButton.isUserInteractionEnabled = false
        
        clearCartButton.isEnabled = false
        clearCartButton.isUserInteractionEnabled = false
    }
    
    /** Enable the buttons in the header*/
    func enableHeaderButtons(){
        shareButton.isEnabled = true
        shareButton.isUserInteractionEnabled = true
        
        clearCartButton.isEnabled = true
        clearCartButton.isUserInteractionEnabled = true
    }
    
    /** Recognizer for tap gesture recognizer that dismisses the VC*/
    @objc func tapGestureRecognizerTriggered(sender: UITapGestureRecognizer){
        self.dismiss(animated: true)
    }
    
    func configure(){
        
    }
    
    /** Animate the progress bar for the given duration*/
    func animateProgressBar(duration: CGFloat){
        /** Initial Conditions bar starts off at the top left off the screen*/
        progressBar.frame.origin.x = -progressBar.frame.width
        progressBarContainer.addSubview(progressBar)
        progressBar.backgroundColor = appThemeColor
        
        /** Oscillating animation where the view goes back and forth in and out of the view port*/
        UIView.animate(withDuration: duration/4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn){ [self] in
            progressBar.frame.origin.x = self.view.frame.width + progressBar.frame.width
        }
        
        /** Bar moves to the bottom divider*/
        DispatchQueue.main.asyncAfter(deadline: .now() + duration/4){[self] in
            footerDividingLine.addSubview(progressBar)
            progressBar.frame.origin.x = self.view.frame.width + progressBar.frame.width
            
            UIView.animate(withDuration: duration/4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn){ [self] in
                progressBar.frame.origin.x = -progressBar.frame.width
            }
        }
        
        /** Bar moves to the top divider*/
        DispatchQueue.main.asyncAfter(deadline: .now() + (duration/4 * 2)){[self] in
            progressBarContainer.addSubview(progressBar)
            progressBar.frame.origin.x = -progressBar.frame.width
            
            UIView.animate(withDuration: duration/4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn){ [self] in
                progressBar.frame.origin.x = self.view.frame.width + progressBar.frame.width
            }
        }
        
        /** Bar moves to the bottom divider again (final)*/
        DispatchQueue.main.asyncAfter(deadline: .now() + (duration/4 * 3)){[self] in
            footerDividingLine.addSubview(progressBar)
            progressBar.frame.origin.x = self.view.frame.width + progressBar.frame.width
            
            UIView.animate(withDuration: duration/4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn){ [self] in
                progressBar.frame.origin.x = -progressBar.frame.width
            }
        }
        
        /** Remove from the screen*/
        DispatchQueue.main.asyncAfter(deadline: .now() + (duration + duration/4 + 0.5)){[self] in
            progressBar.frame.origin.x = -progressBar.frame.width
            progressBar.backgroundColor = .clear
            progressBar.removeFromSuperview()
        }
    }
    
    /** Button press methods*/
    /** Clear cart functionality*/
    /** Clear the cart and give the user the option to undo their selection*/
    @objc func clearCartButtonPressed(sender: UIButton){
        guard internetAvailable == true else {
            errorShake()
            
            globallyTransmit(this: "An internet connection is required in order to update your cart", with: UIImage(systemName: "wifi.slash", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: .clear, imageBorder: .none, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 3, selfDismiss: true)
            
            return
        }
        
        let originalColor = sender.tintColor
        
        /** Briefly change the color to red to reflect the destructive nature of this action*/
        UIView.animate(withDuration: 0.5, delay: 0){
        sender.tintColor = .red
        }
        UIView.animate(withDuration: 0.5, delay: 0.5){
        sender.tintColor = originalColor
        }
        
        globallyTransmit(this: "Cart cleared successfully\nYou can still undo this action", with: UIImage(systemName: "cart.fill.badge.minus", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: .clear, imageBorder: .borderLessCircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 3, selfDismiss: true)
        
        itemCache.removeAll()
        for item in cart.items{
        itemCache.insert(item)
        }
        
        cart.items.removeAll()
        
        /** Reload the tableview to reflect the new updates*/
        let indexSet = IndexSet(integer: 0)
        shoppingCartItemsTableView.reloadSections(indexSet, with: .right)
        
        /** Resize the view to reflect the new changes*/
        resize()
        
        updateSubtotal()
        
        undoInProgress = true
        
        disableHeaderButtons()
    }
    
    /** Clear the cart and dismiss this vc*/
    func clearCart(){
        guard internetAvailable == true else {
            errorShake()
            
            globallyTransmit(this: "An internet connection is required in order to update your cart", with: UIImage(systemName: "wifi.slash", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: .clear, imageBorder: .none, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 3, selfDismiss: true)
            
            undoClear()
            
            return
        }
        
        forwardTraversalShake()
        
        globallyTransmit(this: "Cart cleared", with: UIImage(systemName: "cart.fill.badge.minus", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: .clear, imageBorder: .borderLessCircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 3, selfDismiss: true)
        
        deleteThisCart(cart: self.cart)
        
        /** Update the cart of the presenting VC if it's a laundromat detail VC presenting the shopping cart*/
        if let vc = self.presentingViewController as? LaundromatLocationDetailVC{
            let _ = vc.isCartValid()
        }
        
    self.dismiss(animated: true)
    }
    
    /** Undo the clear action*/
    func undoClear(){
        successfulActionShake()
        
        cart.items = itemCache
        
        itemCache.removeAll()
        
        undoInProgress = false
        
        /** Reload the tableview to reflect the new updates*/
        let indexSet = IndexSet(integer: 0)
        shoppingCartItemsTableView.reloadSections(indexSet, with: .left)
        
        /** Resize the view to reflect the new changes*/
        resize()
        
        updateSubtotal()
    }
    /** Clear cart functionality*/
    
    /** Open the share sheet and give the user the option to share their laundry list*/
    @objc func shareButtonPressed(sender: UIButton){
        
    }
    
    /** Push the user to the locationsDetailVC for the laundromat to which this cart belongs to*/
    @objc func addItemsButtonPressed(sender: UIButton){
        
        if let vc = self.presentingViewController as? OrderItemDetailVC{
            self.dismiss(animated: true)
            vc.dismiss(animated: true)
        }
        else if let _ = self.presentingViewController as? LaundromatLocationDetailVC{
            self.dismiss(animated: true)
        }
        else{
            /** No common ancestors that reference the laundromat location detail VC we need to go to so we have to instantiate it ourselves*/
            
            /** Check to see if the laundromat data already exists if not then try to download it from the remote*/
            var dataAlreadyLoaded: Bool = false
            
            for laundromat in laundromats{
                if laundromat.storeID == cart.laundromatStoreID{
                    let vc = LaundromatLocationDetailVC(laundromatData: laundromat)
                    
                    vc.modalPresentationStyle = .fullScreen
                    vc.modalTransitionStyle = .coverVertical
                    
                    dataAlreadyLoaded = true
                    
                    self.present(vc, animated: true)
                }
            }
            
            if dataAlreadyLoaded == false{
                /** Fetch this laundromat from the remote*/
                if internetAvailable == true{
                    fetchThisLaundromat(with: cart.laundromatStoreID, completion:{ [self] laundromat in
                        
                        guard laundromat != nil else{
                            globallyTransmit(this: "Interesting, we can't find that location right now, please try again", with: UIImage(systemName: "exclamationmark.arrow.triangle.2.circlepath", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: .clear, imageBorder: .none, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 3, selfDismiss: true)
                            
                            return
                        }
                        
                        let vc = LaundromatLocationDetailVC(laundromatData: laundromat!)
                        
                        vc.modalPresentationStyle = .fullScreen
                        vc.modalTransitionStyle = .coverVertical
                        
                        dataAlreadyLoaded = true
                        
                        self.present(vc, animated: true)
                    })
                }
                else{
                    /** Internet unavailable can't download the data to go to the laundromat detail vc in question*/
                    errorShake()
                    
                    globallyTransmit(this: "Please connect to the internet to continue", with: UIImage(systemName: "wifi.slash", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: .clear, imageBorder: .none, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 3, selfDismiss: true)
                }
            }
            
        }
    }
    
    /** Move the user to the check out screen to complete their order*/
    @objc func goToCheckOutButtonPressed(sender: UIButton){
        guard undoInProgress == false else{
            undoClear()
            
            return
        }
        
        /** Only go to the checkout screen if internet is available*/
        if internetAvailable == true{
            forwardTraversalShake()
            
            /*
             let checkoutVC =
             
             checkoutVC.modalPresentationStyle = .fullScreen
             checkoutVC.modalTransitionStyle = .coverVertical
             
             self.present(checkoutVC, animated: true)
             */
        }
        else{
            /** Internet unavailable, can't proceed, inform the user that they must have an internet connection to continue*/
            errorShake()
            
            globallyTransmit(this: "Please connect to the internet in order to continue to checkout", with: UIImage(systemName: "wifi.slash", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: .clear, imageBorder: .none, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 3, selfDismiss: true)
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
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
