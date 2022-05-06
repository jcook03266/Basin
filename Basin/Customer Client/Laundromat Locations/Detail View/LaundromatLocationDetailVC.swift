//
//  LaundromatLocationDetailVC.swift
//  Stuy Wash N Dry
//
//  Created by Justin Cook on 3/29/22.
//
import UIKit
import Network
import FirebaseAuth
import GoogleMaps
import Lottie

/** Detail view controller for the laundromat location cells that allows the user to create an order and proceed to check out*/
public class LaundromatLocationDetailVC: UIViewController, UISearchBarDelegate, UISearchResultsUpdating, UIBarPositioningDelegate, UINavigationBarDelegate, UITableViewDelegate, UITableViewDataSource, CartDelegate, CLLocationManagerDelegate{
    /** Status bar styling variables*/
    public override var preferredStatusBarStyle: UIStatusBarStyle{
        /** The pictures are dark so use a light color*/
        return .lightContent
    }
    public override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation{
        return .slide
    }
    /** Specify status bar display preference*/
    public override var prefersStatusBarHidden: Bool {
        return false
    }
    /** Status bar styling variables*/
    
    var navItem = UINavigationItem()
    /** Simple way for the user to dismiss this VC*/
    private var backButton: UIButton = UIButton()
    /** Bar button item that hosts the back button*/
    private var closeButton = UIBarButtonItem()
    /** Button that gives the user more options for this detail view*/
    private var optionsButton: UIButton = UIButton()
    private var optionsButtonItem = UIBarButtonItem()
    /** Lottie animation view with an animated heart that animates when the user taps on the lottie view to favorite this specific laundromat location*/
    var favoriteButton: LottieButton!
    /** Check to see if a record exists for this item in the list of favorited laundromats*/
    lazy var favorited: Bool = isFavorited()
    /** Bar button item that hosts the favorite button*/
    private var favoriteButtonItem = UIBarButtonItem()
    
    /** Create navigation bar to host navigation items*/
    private var navBar = UINavigationBar()
    private var searchController: UISearchController? = nil
    /** A filtered collection of order item sets and their coresponding categories that matches the current characters entered by the user into the search bar*/
    private var filteredItems: [String : [OrderItem]] = [:]
    /** Only filter the order items and categories from the washing menu when this option is enabled*/
    private var filterWashingMenu: Bool = true
    /** Only filter the order items and categories from the dry cleaning menu when this option is enabled*/
    private var filterDryCleaningMenu: Bool = false
    
    private var washingButton = UIButton()
    private var dryCleaningButton = UIButton()
    private var buttonBar: underlinedButtonBar!
    /** The various different views will be hosted inside of this scrollview stack view combination*/
    private var scrollView = UIScrollView()
    private var stackView = UIStackView()
    private var washingView = UIView()
    private var dryCleaningView = UIView()
    private var currentPage = 0
    private var sectionTitleLabel = UILabel()
    
    /** Search UI*/
    /** A container that drops down and retracts when the user uses the search bar*/
    var searchTableViewContainer: UIView!
    /** Control the expansion and contraction states of the search table view*/
    var searchTableViewExpanded = false
    /** A collection view containing previously searched queries matching this laundromat location's id*/
    var recentSearchesCollectionView: UICollectionView!
    /** Display search results from the search bar's current text and the data being searched*/
    var searchTableView: UITableView!
    /** Container that will hold all of the subsequent views specified below*/
    var noSearchResultsFoundContainer: UIView!
    /** Button to cancel the search operation and go back to the base view controller*/
    var noSearchResultsFoundBackButton: UIButton!
    /** A textual representation of the no search results found state for those who didn't get the memo the first time*/
    var noSearchResultsFoundLabel: UILabel!
    /** Secondary label prompting the user to either continue with a new query or go back*/
    var noSearchResultsFoundSecondaryLabel: UILabel!
    /** Nice little animation to inform the user that their query turned up no results*/
    var noSearchResultsFoundLottieView: AnimationView!
    /** Bool used to determine whether or not the no search results panel is currently being displayed, this prevents the lottie animation from being restarted prematurely when the user enters new text into the search bar*/
    var noSearchResultsFoundBeingDisplayed: Bool = false
    /** Search UI*/
    
    /** View that will contain all of the information pertaining to this laundromat*/
    var informationPanel: UIView!
    /** Button for expanding the content of the information panel*/
    var expansionButton: UIButton!
    /** Bool to control the state of the information panel*/
    var informationPanelExpanded: Bool = false
    /** Label containing the shortened name of the location*/
    var nicknameLabel: UILabel!
    /** Label containing the address of the location*/
    var addressLabel: UILabel!
    /** Clickable button containing the phone number of the location*/
    var phoneNumberButton: UIButton!
    /** Label containing the operating hours of the location*/
    var operatingHoursLabel: PaddedLabel!
    /** Labeling containing the opening or closing hours of the location depending on the current time*/
    var openingClosingHoursLabel: PaddedLabel!
    /** Label containing the distance of the location from the user's current location*/
    var distanceLabel: UILabel!
    /** View that shows the average ratings for the given laundromat, fetched from the database*/
    var averageRatings: RatingsCircleProgressView!
    /** Label expressing the total reviews for this laundromat*/
    var totalReviewsLabel: PaddedLabel!
    /** Segmented control that allows the user to select their preference for getting their order to the laundromat*/
    var pickUpDropOffSegmentedControl: UISegmentedControl!
    /** Default option is pick up service for the laundry*/
    var laundryWillBePickedUp = true
    /** Tap gesture recognizer used to open the address data in the default maps app*/
    var tapGestureRecognizer: UITapGestureRecognizer!
    
    /** Data to display in this view controller*/
    var laundromatData: Laundromat
    /** Cart associated with this laundromat and user*/
    var laundromatCart: Cart!
    /** Determine if the cart has been erased or not, if so then give the user a 2 second option to undo that erase*/
    var undoCartEraseInProgress: Bool = false
    /** Shape layer to add to the view cart button that will act as a moving progress indicator of the undo action's current progress*/
    var viewCartButtonLayer = CALayer()
    /** Washing menu tableview will be populated with data from this menu (if any)*/
    var washingMenu: LaundromatMenu? = nil
    /** Dry cleaning menu tableview will be populated with data from this menu (if any)*/
    var dryCleaningMenu: LaundromatMenu? = nil
    /** Partition all of the items associated with the given category into accessible arrays*/
    var dryCleaningMenuCategorySections: [String : [OrderItem]] = [:]
    /** A sorted array of the category titles for the dry cleaning menu so that the layout of the tableview is consistent every time the detail view is instantiated*/
    var sortedDryCleaningMenuCategories: [String] = []
    /** Partition all of the items associated with the given category into accessible arrays*/
    var washingMenuCategorySections: [String : [OrderItem]] = [:]
    /** A sorted array of the category titles for the washing menu*/
    var sortedWashingMenuCategories: [String] = []
    var washingMenuTableView: UITableView!
    var washingMenuTableViewRefreshControl = LottieRefreshControl()
    var dryCleaningMenuTableView: UITableView!
    var dryCleaningMenuTableViewRefreshControl = LottieRefreshControl()
    var tableViewHeaderHeight: CGFloat = 60
    var tableViewFooterHeight: CGFloat = 0
    
    /** Placeholder table views for when data is being downloaded*/
    var shimmeringTableView_1: UITableView!
    var shimmeringTableView_2: UITableView!
    
    /** Background views*/
    /** Button that takes the user to the cart view controller*/
    var viewCartButton: UIButton!
    /** Display the name of the laundromat*/
    var titleLabel = UILabel()
    /** Location Management*/
    var locationManager: CLLocationManager!
    var currentLocation: CLLocation?
    /** Camera for the mapview*/
    var camera: GMSCameraPosition!
    /** The mapview to display in the header when the user selects drop-off*/
    var mapView: GMSMapView!
    /** Various zoom levels from closest to farthest (0)*/
    var streetLevelZoomLevel: Float = 19.0
    var preciseLocationZoomLevel: Float = 15.0
    var approximateLocationZoomLevel: Float = 12.5
    /** An image carousel that will display images at the top of the view controller*/
    var imageCarousel: imageCarousel!
    /** Decorative line dividing the bottom of the image carousel from the rest of the content*/
    var dividingLine: UIView!
    
    /** Data fetching control variables*/
    /** Monitor network conditions for changes in order to load data after an internet connection has been established*/
    private var networkMonitor: NWPathMonitor = NWPathMonitor()
    /** Secondary network monitor that monitors the network in order to */
    private var networkMonitor_2: NWPathMonitor = NWPathMonitor()
    var washingMenuFetched = false
    var dryCleaningMenuFetched = false
    
    /**Notification from delegate that says whether the app has exited from the foreground and into the background or not*/
    @objc func appMovedToBackground(){}
    
    /**Notification from delegate that says whether the app has reentered from the background and into the foreground or not*/
    @objc func appMovedToForeground(){}
    
    /** Activates when the application regains focus*/
    @objc func appDidBecomeActive(){}
    
    @objc func appIsInBackground(){}
    
    /** Initialize this view controller with laundromat data*/
    init(laundromatData: Laundromat){
        self.laundromatData = laundromatData
        
        super.init(nibName: nil, bundle: nil)
    }
    
    public override func viewWillAppear(_ animated: Bool){
    }
    
    public override func viewDidLoad(){
        /** Specify a maximum font size*/
        self.view.maximumContentSizeCategory = .large
        
        setNotificationCenter()
        
        configure()
        setSearchController()
        setViews()
        setButtons()
        constructUI()
        setCustomNavUI()
        
        /** Inform the user that loading is occurring*/
        displayShimmeringPlaceholders()
        fetchLaundromatMenuData()
    }
    
    /**App Delegate Notifs*/
    func setNotificationCenter(){
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appIsInBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    /** Fetch the cart associated with this laundromat or create a new one if one isn't located*/
    func fetchCart(){
        let result = doesACartExistForThis(laundromat: laundromatData)
        if result.0 == true{
            if result.1!.items.isEmpty == false{
                /** The cart has items, reuse it*/
                laundromatCart = result.1!
            }
            else{
                /** The cart has no items delete it and make a new one*/
                if Auth.auth().currentUser != nil{
                    laundromatCart = createACartForThis(laundromat: laundromatData, user: Auth.auth().currentUser!)
                }
            }
        }
        else{
            /** Cart doesn't exist, make a new one and push it to the remote when the user connects to internet*/
            if Auth.auth().currentUser != nil{
                laundromatCart = createACartForThis(laundromat: laundromatData, user: Auth.auth().currentUser!)
                
                /** Push this cart to the remote when internet is available*/
                pushThisCart(cart: laundromatCart)
            }
        }
        /** Show or hide the cart button depending on the items in the current cart*/
        updateViewCartButtonLabel()
        
        laundromatCart.delegate = self
    }
    
    /** Fetch the laundromat's menu data to parse into items that will be displayed in this view controller*/
    func fetchLaundromatMenuData(){
        if internetAvailable == true{
            fetchCart()
            /** If the internet is available then continue*/
            fetchThisMenu(menuDocumentID: laundromatData.washingMenuDocumentID){ [self] laundromatMenu in
                if laundromatMenu != nil{
                    washingMenuFetched = true
                    washingMenu = laundromatMenu
                }
                
                fetchThisMenu(menuDocumentID: laundromatData.dryCleaningMenuDocumentID){ [self] laundromatMenu in
                    if laundromatMenu != nil{
                        dryCleaningMenuFetched = true
                        dryCleaningMenu = laundromatMenu
                        
                        if washingMenuFetched == true && dryCleaningMenuFetched == true{
                            RemoveShimmeringPlaceholders()
                            
                            washingMenuCategorySections = computeTotalSectionsForWashingMenuTableView() ?? [:]
                            dryCleaningMenuCategorySections = computeTotalSectionsForDryCleaningMenuTableView() ?? [:]
                            
                            sortCategoriesInDescendingOrder()
                            
                            createWashingMenuTableView()
                            createDryCleaningMenuTableView()
                        }
                        else{
                            /** Wait 5 seconds to see if all data is loaded finally*/
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5){[self] in
                                if washingMenuFetched == true && dryCleaningMenuFetched == true{
                                    RemoveShimmeringPlaceholders()
                                    
                                    washingMenuCategorySections = computeTotalSectionsForWashingMenuTableView() ?? [:]
                                    dryCleaningMenuCategorySections = computeTotalSectionsForDryCleaningMenuTableView() ?? [:]
                                    
                                    sortCategoriesInDescendingOrder()
                                    
                                    createWashingMenuTableView()
                                    createDryCleaningMenuTableView()
                                }
                                else{
                                    /** Server can't be reached most likely, tell the user to try again*/
                                    globallyTransmit(this: "This data could not be fetched at this time, please try again", with: UIImage(systemName: "server.rack", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: .clear, imageBorder: .none, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 3, selfDismiss: true)
                                }
                            }
                        }
                    }
                }
            }
        }
        else{
            /** Retry when the internet is available*/
            globallyTransmit(this: "Internet connection unavailable, retrying when a connection has been established", with: UIImage(systemName: "wifi.slash", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: .clear, imageBorder: .none, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 3, selfDismiss: true)
            
            networkMonitor.start(queue: DispatchQueue.global(qos: .background))
            
            networkMonitor.pathUpdateHandler = { path in
                switch path.status{
                case .satisfied:
                    /** Internet available, recursion starts, stop monitor*/
                    DispatchQueue.main.async{ [self] in
                        fetchLaundromatMenuData()
                        networkMonitor.cancel()
                    }
                case .unsatisfied:
                    /** Internet unavailable keep waiting*/
                    break
                case .requiresConnection:
                    /** Internet unavailable keep waiting*/
                    break
                @unknown default:
                    break
                }
            }
        }
    }
    
    /** Display Shimmering placeholder views*/
    func displayShimmeringPlaceholders(){
        shimmeringTableView_1 = UITableView(frame: self.view.frame, style: .grouped)
        shimmeringTableView_1.frame.size.height = self.view.frame.height - imageCarousel.frame.height
        shimmeringTableView_1.clipsToBounds = true
        switch darkMode {
        case true:
            shimmeringTableView_1.backgroundColor = bgColor
        case false:
            shimmeringTableView_1.backgroundColor = bgColor
        }
        shimmeringTableView_1.tintColor = fontColor
        shimmeringTableView_1.isOpaque = false
        shimmeringTableView_1.showsVerticalScrollIndicator = true
        shimmeringTableView_1.showsHorizontalScrollIndicator = false
        shimmeringTableView_1.isExclusiveTouch = true
        shimmeringTableView_1.contentInsetAdjustmentBehavior = .never
        shimmeringTableView_1.dataSource = self
        shimmeringTableView_1.delegate = self
        shimmeringTableView_1.separatorStyle = .none
        shimmeringTableView_1.layer.borderColor = UIColor.white.darker.cgColor
        shimmeringTableView_1.layer.borderWidth = 0
        shimmeringTableView_1.isUserInteractionEnabled = false
        
        /** Add a little space at the bottom of the scrollview*/
        shimmeringTableView_1.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: view.frame.width * 0.25, right: 0)
        
        shimmeringTableView_1.register(ShimmeringTableViewCell.self, forCellReuseIdentifier: ShimmeringTableViewCell.identifier)
        
        if(darkMode == true){
            shimmeringTableView_1.indicatorStyle = .white
        }
        else{
            shimmeringTableView_1.indicatorStyle = .black
        }
        
        shimmeringTableView_2 = UITableView(frame: self.view.frame, style: .grouped)
        shimmeringTableView_2.frame.size.height = self.view.frame.height - imageCarousel.frame.height
        shimmeringTableView_2.clipsToBounds = true
        switch darkMode {
        case true:
            shimmeringTableView_2.backgroundColor = bgColor
        case false:
            shimmeringTableView_2.backgroundColor = bgColor
        }
        shimmeringTableView_2.tintColor = fontColor
        shimmeringTableView_2.isOpaque = false
        shimmeringTableView_2.showsVerticalScrollIndicator = true
        shimmeringTableView_2.showsHorizontalScrollIndicator = false
        shimmeringTableView_2.isExclusiveTouch = true
        shimmeringTableView_2.contentInsetAdjustmentBehavior = .never
        shimmeringTableView_2.dataSource = self
        shimmeringTableView_2.delegate = self
        shimmeringTableView_2.separatorStyle = .none
        shimmeringTableView_2.layer.borderColor = UIColor.white.darker.cgColor
        shimmeringTableView_2.layer.borderWidth = 0
        shimmeringTableView_2.isUserInteractionEnabled = false
        
        /** Add a little space at the bottom of the scrollview*/
        shimmeringTableView_2.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: view.frame.width * 0.25, right: 0)
        
        shimmeringTableView_2.register(ShimmeringTableViewCell.self, forCellReuseIdentifier: ShimmeringTableViewCell.identifier)
        
        if(darkMode == true){
            shimmeringTableView_2.indicatorStyle = .white
        }
        else{
            shimmeringTableView_2.indicatorStyle = .black
        }
        
        washingView.addSubview(shimmeringTableView_1)
        dryCleaningView.addSubview(shimmeringTableView_2)
        stackView.addArrangedSubview(washingView)
        stackView.addArrangedSubview(dryCleaningView)
    }
    
    /** Remove the shimmering placeholder views from the tableviews when all of the data is fully loaded*/
    func RemoveShimmeringPlaceholders(){
        guard shimmeringTableView_1 != nil && shimmeringTableView_2 != nil else {
            return
        }
        
        UIView.animate(withDuration: 0.1, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){ [self] in
            shimmeringTableView_1.alpha = 0
            shimmeringTableView_2.alpha = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){[self] in
            shimmeringTableView_1.removeFromSuperview()
            shimmeringTableView_2.removeFromSuperview()
        }
    }
    
    /** Show the view cart button when there are items in the cart / when the items in the current cart have been updated ( and not = 0)*/
    func displayViewCartButton(animated: Bool){
        guard viewCartButton != nil else {
            return
        }
        
        switch animated {
        case true:
            UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){ [self] in
                viewCartButton.frame.origin = CGPoint(x: view.frame.width/2 - viewCartButton.frame.width/2, y: view.frame.maxY - (viewCartButton.frame.height * 1.5))
            }
        case false:
            viewCartButton.frame.origin = CGPoint(x: view.frame.width/2 - viewCartButton.frame.width/2, y: view.frame.maxY - (viewCartButton.frame.height * 1.5))
        }
    }
    
    /** Hide the view cart button when no items are current in the cart*/
    func hideViewCartButton(animated: Bool){
        guard viewCartButton != nil else {
            return
        }
        
        switch animated {
        case true:
            UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){ [self] in
                viewCartButton.frame.origin = CGPoint(x: view.frame.width/2 - viewCartButton.frame.width/2, y: view.frame.maxY + (viewCartButton.frame.height * 1.5))
            }
        case false:
            viewCartButton.frame.origin = CGPoint(x: view.frame.width/2 - viewCartButton.frame.width/2, y: view.frame.maxY + (viewCartButton.frame.height * 1.5))
        }
    }
    
    /** Update the current text being displayed by the view cart button*/
    func updateViewCartButtonLabel(){
        guard viewCartButton != nil && laundromatCart != nil else {
            return
        }
        
        /** Don't show zero in the label, it's redundant*/
        if laundromatCart.getTotalItemQuantity() != 0{
            displayViewCartButton(animated: true)
            viewCartButton.setImage(UIImage(systemName: "cart.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
            viewCartButton.setTitle(" View Cart (\(laundromatCart.getTotalItemQuantity())) $\(String(format: "%.2f", laundromatCart.subtotal))", for: .normal)
        }
        else{
            hideViewCartButton(animated: true)
            viewCartButton.setImage(UIImage(systemName: "cart.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
            viewCartButton.setTitle(" View Cart", for: .normal)
        }
    }
    
    func createWashingMenuTableView(){
        washingMenuTableView = UITableView(frame: self.view.frame, style: .grouped)
        washingMenuTableView.frame.size.height = self.view.frame.height - imageCarousel.frame.height
        washingMenuTableView.clipsToBounds = true
        switch darkMode {
        case true:
            washingMenuTableView.backgroundColor = bgColor
        case false:
            washingMenuTableView.backgroundColor = bgColor
        }
        washingMenuTableView.tintColor = fontColor
        washingMenuTableView.isOpaque = false
        washingMenuTableView.showsVerticalScrollIndicator = true
        washingMenuTableView.showsHorizontalScrollIndicator = false
        washingMenuTableView.isExclusiveTouch = true
        washingMenuTableView.contentInsetAdjustmentBehavior = .never
        washingMenuTableView.dataSource = self
        washingMenuTableView.delegate = self
        washingMenuTableView.separatorStyle = .none
        washingMenuTableView.layer.borderColor = UIColor.white.darker.cgColor
        washingMenuTableView.layer.borderWidth = 0
        
        /** Add a little space at the bottom of the scrollview*/
        washingMenuTableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: view.frame.width * 0.25, right: 0)
        
        washingMenuTableView.register(OrderItemTableViewCell.self, forCellReuseIdentifier: OrderItemTableViewCell.identifier)
        
        if(darkMode == true){
            washingMenuTableView.indicatorStyle = .white
        }
        else{
            washingMenuTableView.indicatorStyle = .black
        }
        
        /** Set refresh control*/
        washingMenuTableViewRefreshControl.addTarget(self, action: #selector(self.washingMenuTableViewRefreshStart(_:)), for: .valueChanged)
        washingMenuTableViewRefreshControl.tintColor = .clear
        washingMenuTableViewRefreshControl.layer.zPosition = -1
        washingMenuTableView.refreshControl = washingMenuTableViewRefreshControl
        
        /** Animate the tableview appearing*/
        washingMenuTableView.alpha = 0
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){ [self] in
            washingMenuTableView.alpha = 1
        }
        
        washingView.addSubview(washingMenuTableView)
        stackView.addArrangedSubview(washingView)
    }
    
    func createDryCleaningMenuTableView(){
        dryCleaningMenuTableView = UITableView(frame: self.view.frame, style: .grouped)
        dryCleaningMenuTableView.frame.size.height = self.view.frame.height - imageCarousel.frame.height
        dryCleaningMenuTableView.clipsToBounds = true
        switch darkMode {
        case true:
            dryCleaningMenuTableView.backgroundColor = bgColor
        case false:
            dryCleaningMenuTableView.backgroundColor = bgColor
        }
        dryCleaningMenuTableView.tintColor = fontColor
        dryCleaningMenuTableView.isOpaque = false
        dryCleaningMenuTableView.showsVerticalScrollIndicator = true
        dryCleaningMenuTableView.showsHorizontalScrollIndicator = false
        dryCleaningMenuTableView.isExclusiveTouch = true
        dryCleaningMenuTableView.contentInsetAdjustmentBehavior = .never
        dryCleaningMenuTableView.dataSource = self
        dryCleaningMenuTableView.delegate = self
        dryCleaningMenuTableView.separatorStyle = .none
        dryCleaningMenuTableView.layer.borderColor = UIColor.white.darker.cgColor
        dryCleaningMenuTableView.layer.borderWidth = 0
        
        /** Add a little space at the bottom of the scrollview*/
        dryCleaningMenuTableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: view.frame.width * 0.25, right: 0)
        
        dryCleaningMenuTableView.register(OrderItemTableViewCell.self, forCellReuseIdentifier: OrderItemTableViewCell.identifier)
        
        if(darkMode == true){
            dryCleaningMenuTableView.indicatorStyle = .white
        }
        else{
            dryCleaningMenuTableView.indicatorStyle = .black
        }
        
        /** Set refresh control*/
        dryCleaningMenuTableViewRefreshControl.addTarget(self, action: #selector(self.dryCleaningMenuTableViewRefreshStart(_:)), for: .valueChanged)
        dryCleaningMenuTableViewRefreshControl.tintColor = .clear
        dryCleaningMenuTableViewRefreshControl.layer.zPosition = -1
        dryCleaningMenuTableView.refreshControl = dryCleaningMenuTableViewRefreshControl
        
        /** Animate the tableview appearing*/
        dryCleaningMenuTableView.alpha = 0
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){ [self] in
            dryCleaningMenuTableView.alpha = 1
        }
        
        dryCleaningView.addSubview(dryCleaningMenuTableView)
        stackView.addArrangedSubview(dryCleaningView)
    }
    
    /** Refresh control methods for the table views*/
    @objc func washingMenuTableViewRefreshStart(_ sender: AnyObject){
        mediumHaptic()
        
        guard washingMenuTableView != nil else{
            return
        }
        
        /** Refresh the cart using the remote copy, the remote copy is kept up to date with the local copy when the user is connected to the internet, and write operations are queued up when the user is offline to be committed when the user reconnects to the internet*/
        if internetAvailable == true && laundromatCart != nil{
            fetchThisCart(cart: laundromatCart){ [self] cart in
                fetchCart()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5){ [self] in
            /** Reload the table view*/
            washingMenuTableView.reloadData()
            
            washingMenuTableViewRefreshControl.endRefreshing()
        }
    }
    @objc func dryCleaningMenuTableViewRefreshStart(_ sender: AnyObject){
        mediumHaptic()
        
        guard dryCleaningMenuTableView != nil else{
            return
        }
        
        /** Refresh the cart using the remote copy, the remote copy is kept up to date with the local copy when the user is connected to the internet, and write operations are queued up when the user is offline to be committed when the user reconnects to the internet*/
        if internetAvailable == true && laundromatCart != nil{
            fetchThisCart(cart: laundromatCart){ [self] cart in
                fetchCart()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5){ [self] in
            /** Reload the table view*/
            dryCleaningMenuTableView.reloadData()
            
            dryCleaningMenuTableViewRefreshControl.endRefreshing()
        }
    }
    /** Refresh control methods for the table views*/
    
    /** Sets the height and width parameters for all views inside of the horizontal stackview*/
    func setViews(){
        washingView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        ///Please set these anchors if you actually want to see these inside of the stackview
        washingView.heightAnchor .constraint(equalToConstant: washingView.frame.height) .isActive = true
        washingView.widthAnchor .constraint(equalToConstant: washingView.frame.width) .isActive = true
        washingView.backgroundColor = UIColor.clear
        
        dryCleaningView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.width)
        dryCleaningView.heightAnchor .constraint(equalToConstant: dryCleaningView.frame.height) .isActive = true
        dryCleaningView.widthAnchor .constraint(equalToConstant: dryCleaningView.frame.width) .isActive = true
        dryCleaningView.backgroundColor = UIColor.clear
    }
    
    /** Customize the specified buttons that control navigation*/
    func setButtons(){
        washingButton.frame.size.height = 40
        washingButton.frame.size.width = 100
        washingButton.contentHorizontalAlignment = .center
        washingButton.setTitle("Washing", for: .normal)
        washingButton.setTitleColor(darkModeFontColor, for: .normal)
        washingButton.layer.backgroundColor = UIColor.clear.cgColor
        washingButton.isExclusiveTouch = true
        washingButton.clipsToBounds = true
        washingButton.titleLabel?.font = getCustomFont(name: .Ubuntu_Medium, size: 16, dynamicSize: true)
        washingButton.titleLabel?.adjustsFontSizeToFitWidth = true
        washingButton.titleLabel?.adjustsFontForContentSizeCategory = true
        washingButton.addTarget(self, action: #selector(washingButtonPressed), for: .touchDown)
        
        dryCleaningButton.frame.size.height = 40
        dryCleaningButton.frame.size.width = 100
        dryCleaningButton.contentHorizontalAlignment = .center
        dryCleaningButton.setTitle("Dry Cleaning", for: .normal)
        dryCleaningButton.setTitleColor(darkModeFontColor, for: .normal)
        dryCleaningButton.layer.backgroundColor = UIColor.clear.cgColor
        dryCleaningButton.isExclusiveTouch = true
        dryCleaningButton.clipsToBounds = true
        dryCleaningButton.titleLabel?.font = getCustomFont(name: .Ubuntu_Medium, size: 16, dynamicSize: true)
        dryCleaningButton.titleLabel?.adjustsFontSizeToFitWidth = true
        dryCleaningButton.titleLabel?.adjustsFontForContentSizeCategory = true
        dryCleaningButton.addTarget(self, action: #selector(dryCleaningButtonPressed), for: .touchDown)
    }
    
    /** ScrollView Button Bar Methods*/
    /** Hide the information panel when the user scrolls upwards, and reveal it when they scroll down (move up)*/
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView){
        let actualPosition = scrollView.panGestureRecognizer.translation(in: scrollView)
        
        if scrollView == washingMenuTableView || scrollView == dryCleaningMenuTableView{
            if actualPosition.y > 0{
                /** Scrolled down, scrollview moves up*/
                /** Show information panel and move the scrollview back down*/
                DispatchQueue.main.asyncAfter(deadline: .now()){
                    UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn){ [self] in
                        self.informationPanel.frame.origin = CGPoint(x: 0, y: buttonBar.frame.maxY)
                    }
                    UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn){ [self] in
                        self.scrollView.frame.origin = CGPoint(x: 0, y: informationPanel.frame.maxY)
                    }
                }
            }
            else{
                /** Scrolled up, scrollview moves down*/
                /** Hide information panel and move the scrollview upwards*/
                DispatchQueue.main.asyncAfter(deadline: .now()){
                    UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn){ [self] in
                        self.informationPanel.frame.origin = CGPoint(x: 0, y: -informationPanel.frame.height)
                    }
                    UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn){ [self] in
                        self.scrollView.frame.origin = CGPoint(x: 0, y: buttonBar.frame.maxY)
                    }
                }
            }
        }
    }
    
    /**Override default listener for UIScrollview*/
    public func scrollViewDidScroll(_ UIScrollView: UIScrollView){
        if(UIScrollView == scrollView){
            let pageIndex = round(scrollView.contentOffset.x/scrollView.frame.width)
            
            /** Start from the offset of the first button then move until the total distance between the first and last button is covered*/
            let scrollingDistanceComputation = buttonBar!.getOffsetOfFirstButton() + ((buttonBar!.getTotalDistance()) * CGFloat(scrollView.contentOffset.x/(scrollView.frame.width * CGFloat(buttonBar!.buttons.count-1))))
            
            /** Shift the underline along the total distance between the first and last offset in the track according to the percentage of the scrollview scrolled*/
            buttonBar!.underline.frame.origin = CGPoint(x: scrollingDistanceComputation, y: 0)
            
            switch pageIndex{
            case 0:
                currentPage = 0
                buttonBar!.resizeTheUnderlineFor(this: buttonBar!.buttons[currentPage])
            case 1:
                currentPage = 1
                buttonBar!.resizeTheUnderlineFor(this: buttonBar!.buttons[currentPage])
            case 2:
                currentPage = 2
                buttonBar!.resizeTheUnderlineFor(this: buttonBar!.buttons[currentPage])
            case 3:
                currentPage = 3
                buttonBar!.resizeTheUnderlineFor(this: buttonBar!.buttons[currentPage])
            default:
                break
            }
        }
        
        /** If the user scrolls more than the height of the navbar * 3 then completely reveal the navbar's small title and hide the image carousel*/
        if UIScrollView == washingMenuTableView || UIScrollView == dryCleaningMenuTableView{
            
            /** Close the editing UI for the visible cells when the user scrolls*/
            if UIScrollView == washingMenuTableView{
                
                /** Trigger refresh animation*/
                washingMenuTableViewRefreshControl.updateProgress(with: UIScrollView.contentOffset.y)
                
                for cell in washingMenuTableView.visibleCells{
                    if let tableViewCell = cell as? OrderItemTableViewCell{
                        if tableViewCell.editingItemCount == true{
                            tableViewCell.hideItemCountEditingUI(animated: true)
                        }
                    }
                }
            }
            else{
                /** Trigger refresh animation*/
                dryCleaningMenuTableViewRefreshControl.updateProgress(with: UIScrollView.contentOffset.y)
                
                for cell in dryCleaningMenuTableView.visibleCells{
                    if let tableViewCell = cell as? OrderItemTableViewCell{
                        if tableViewCell.editingItemCount == true{
                            tableViewCell.hideItemCountEditingUI(animated: true)
                        }
                    }
                }
            }
            
            let offset = UIScrollView.contentOffset.y
            let targetOffset = navBar.frame.height * 3
            
            /** Alpha can't be greater than 1 nor less than 0*/
            var alpha = offset/targetOffset
            if alpha > 1{alpha = 1}
            else if alpha < 0{alpha = 0}
            
            let standardAppearance = UINavigationBarAppearance()
            standardAppearance.configureWithOpaqueBackground()
            /**Make the shadow clear*/
            standardAppearance.shadowColor = UIColor.clear
            
            /** Add the button bar when the navbar is completely faded in*/
            if alpha >= 1{
                buttonBar.isUserInteractionEnabled = true
            }
            else{
                buttonBar.isUserInteractionEnabled = false
            }
            
            /**
             /** Move the image carousel slightly upwards so that its hidden by the navbar when the user scrolls*/
             UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
             if offset > 0{
             if imageCarousel.frame.maxY >= navBar.frame.maxY && (imageCarousel.frame.height - offset) >= navBar.frame.maxY{
             imageCarousel.frame.origin.y = 0 - offset
             }
             
             /** If the offset is very great then force the carousel to its raised position*/
             if (imageCarousel.frame.height - offset) < navBar.frame.maxY{
             imageCarousel.frame.origin.y = (navBar.frame.maxY - imageCarousel.frame.height)
             }
             }
             }
             */
            
            /** Slowly fade the navbar in and out*/
            UIView.animate(withDuration: 0.5, delay: 0){[self] in
                buttonBar.alpha = alpha
                
                standardAppearance.backgroundColor = appThemeColor.withAlphaComponent(alpha)
                standardAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white.withAlphaComponent(alpha), NSAttributedString.Key.font: getCustomFont(name: .Ubuntu_Medium, size: 30, dynamicSize: true)]
                standardAppearance.titleTextAttributes = [.foregroundColor: UIColor.white.withAlphaComponent(alpha), NSAttributedString.Key.font: getCustomFont(name: .Ubuntu_Medium, size: 18, dynamicSize: true)]
                
                navBar.standardAppearance = standardAppearance
                navBar.scrollEdgeAppearance = standardAppearance
            }
            
        }
    }
    
    /** Switches to the current page indicated by the scrollview offset and moves the underline beneath the corresponding button*/
    func turnPage(){
        DispatchQueue.main.asyncAfter(deadline: .now()){[self] in
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
                scrollView.contentOffset = CGPoint(x: scrollView.frame.width * CGFloat(currentPage), y: 0)
            }
        }
        
        /** Delay this because animations need to finish*/
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01){[self] in
            switch currentPage{
            case 0:
                filterWashingMenu = true
                filterDryCleaningMenu = false
                
                buttonBar!.moveUnderLineTo(this: buttonBar!.buttons[currentPage])
                searchController!.searchBar.placeholder = "Search for washing options"
                ///sectionTitleLabel.text = "Wash Dry Fold"
            case 1:
                filterDryCleaningMenu = true
                filterWashingMenu = false
                
                buttonBar!.moveUnderLineTo(this: buttonBar!.buttons[currentPage])
                searchController!.searchBar.placeholder = "Search for dry cleaning options"
                ///sectionTitleLabel.text = "Dry Cleaning"
            default:
                break
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ UIScrollView: UIScrollView) {
        /** Reenable the parent scrollview when any scrollview is done scrolling*/
        scrollView.isScrollEnabled = true
        
        /**Force the underline to stay under the nearest element*/
        if(UIScrollView == scrollView){
            turnPage()
        }
    }
    /** ScrollView Button Bar Methods*/
    
    /** Objc methods for navigating between the different views in the paged horizontal scrollview*/
    @objc func washingButtonPressed(sender: UIButton){
        currentPage = buttonBar!.getIndexOf(this: sender)!
        turnPage()
    }
    
    @objc func dryCleaningButtonPressed(sender: UIButton){
        currentPage = buttonBar!.getIndexOf(this: sender)!
        turnPage()
    }
    /** Objc methods for navigating between the different views in the paged horizontal scrollview*/
    
    /** Attach the navigation bar to the top of the view and extend its edges past the status bar*/
    public func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
    
    /** Construct the UI for this VC*/
    func constructUI(){
        informationPanel = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 220))
        informationPanel.clipsToBounds = true
        informationPanel.layer.masksToBounds = false
        switch darkMode {
        case true:
            informationPanel.backgroundColor = bgColor.darker
        case false:
            informationPanel.backgroundColor = bgColor
        }
        
        /**
         informationPanel.layer.shadowColor = UIColor.lightGray.cgColor
         informationPanel.layer.shadowOpacity = 0.25
         informationPanel.layer.shadowRadius = 5
         informationPanel.layer.shadowOffset = CGSize(width: 0, height: 2)
         informationPanel.layer.shadowPath = UIBezierPath(roundedRect: informationPanel.bounds, cornerRadius: informationPanel.layer.cornerRadius).cgPath
         */
        
        expansionButton = UIButton(frame: CGRect(x: 0, y: 0, width: informationPanel.frame.width, height: 30))
        expansionButton.backgroundColor = appThemeColor
        switch darkMode {
        case true:
            expansionButton.backgroundColor = .darkGray
        case false:
            expansionButton.backgroundColor = appThemeColor
        }
        expansionButton.setImage(UIImage(systemName: "chevron.compact.down")?.withTintColor(.white), for: .normal)
        expansionButton.castDefaultShadow()
        expansionButton.layer.cornerRadius =  expansionButton.frame.height/4
        expansionButton.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        expansionButton.contentMode = .center
        expansionButton.contentHorizontalAlignment = .center
        expansionButton.contentVerticalAlignment = .center
        expansionButton.isExclusiveTouch = true
        expansionButton.tintColor = .white
        expansionButton.clipsToBounds = true
        expansionButton.addTarget(self, action: #selector(expansionButtonPressed), for: .touchDown)
        
        nicknameLabel = UILabel()
        nicknameLabel.frame.size = CGSize(width: informationPanel.frame.width * 0.9, height: 40)
        nicknameLabel.font = getCustomFont(name: .Ubuntu_Medium, size: 20, dynamicSize: true)
        nicknameLabel.backgroundColor = .clear
        nicknameLabel.textColor = fontColor
        nicknameLabel.textAlignment = .left
        nicknameLabel.adjustsFontForContentSizeCategory = true
        nicknameLabel.adjustsFontSizeToFitWidth = false
        
        /** Attributed string with a system image in the front*/
        let nicknameLabelImageAttachment = NSTextAttachment()
        switch darkMode {
        case true:
            nicknameLabelImageAttachment.image = UIImage(systemName: "building.2.fill")?.withTintColor(.white)
        case false:
            nicknameLabelImageAttachment.image = UIImage(systemName: "building.2.fill")?.withTintColor(.darkGray)
        }
        
        let nicknameLabelAttributedString = NSMutableAttributedString()
        nicknameLabelAttributedString.append(NSAttributedString(attachment: nicknameLabelImageAttachment))
        nicknameLabelAttributedString.append(NSMutableAttributedString(string: " \(laundromatData.nickName)"))
        nicknameLabel.attributedText = nicknameLabelAttributedString
        
        addressLabel = UILabel()
        addressLabel.frame.size = CGSize(width: informationPanel.frame.width * 0.9, height: 40)
        addressLabel.font = getCustomFont(name: .Ubuntu_Regular, size: 16, dynamicSize: true)
        addressLabel.backgroundColor = .clear
        addressLabel.textColor = .lightGray
        addressLabel.textAlignment = .left
        addressLabel.adjustsFontForContentSizeCategory = true
        addressLabel.adjustsFontSizeToFitWidth = true
        addressLabel.isUserInteractionEnabled = true
        
        /** Attributed string with a system image in the front*/
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = UIImage(systemName: "mappin.circle.fill")?.withTintColor(appThemeColor)
        
        let attributedString = NSMutableAttributedString()
        attributedString.append(NSAttributedString(attachment: imageAttachment))
        attributedString.append(NSMutableAttributedString(string: " \(laundromatData.address.streetAddress1), \(laundromatData.address.borough), \(laundromatData.address.state), \(laundromatData.address.zipCode)"))
        addressLabel.attributedText = attributedString
        
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(addressLabelTapped))
        tapGestureRecognizer.numberOfTouchesRequired = 1
        tapGestureRecognizer.delegate = self
        addressLabel.addGestureRecognizer(tapGestureRecognizer)
        
        phoneNumberButton = UIButton()
        phoneNumberButton.frame.size = CGSize(width: informationPanel.frame.width * 0.45, height: 40)
        phoneNumberButton.backgroundColor = appThemeColor
        phoneNumberButton.setTitle("\(readyPhoneKit.format(laundromatData.phoneNumber, toType: .national))", for: .normal)
        phoneNumberButton.setTitleColor(.white, for: .normal)
        phoneNumberButton.titleLabel?.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: true)
        phoneNumberButton.contentHorizontalAlignment = .center
        phoneNumberButton.titleLabel?.adjustsFontSizeToFitWidth = true
        phoneNumberButton.titleLabel?.adjustsFontForContentSizeCategory = true
        phoneNumberButton.layer.cornerRadius = phoneNumberButton.frame.height/2
        phoneNumberButton.isExclusiveTouch = true
        phoneNumberButton.isEnabled = true
        phoneNumberButton.castDefaultShadow()
        phoneNumberButton.layer.shadowColor = UIColor.darkGray.cgColor
        phoneNumberButton.tintColor = .white
        phoneNumberButton.setImage(UIImage(systemName: "phone.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        phoneNumberButton.addTarget(self, action: #selector(phoneNumberButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: phoneNumberButton)
        
        operatingHoursLabel = PaddedLabel(withInsets: 0, 0, 0, 0)
        operatingHoursLabel.frame.size = CGSize(width: informationPanel.frame.width * 0.3, height: 40)
        operatingHoursLabel.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: true)
        operatingHoursLabel.backgroundColor = .clear
        operatingHoursLabel.textColor = appThemeColor
        operatingHoursLabel.textAlignment = .left
        operatingHoursLabel.adjustsFontForContentSizeCategory = false
        operatingHoursLabel.adjustsFontSizeToFitWidth = true
        
        openingClosingHoursLabel = PaddedLabel(withInsets: 0, 0, 0, 0)
        openingClosingHoursLabel.frame.size = CGSize(width: informationPanel.frame.width * 0.3, height: 40)
        openingClosingHoursLabel.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: true)
        openingClosingHoursLabel.textAlignment = .left
        openingClosingHoursLabel.adjustsFontForContentSizeCategory = false
        openingClosingHoursLabel.adjustsFontSizeToFitWidth = true
        switch darkMode {
        case true:
            openingClosingHoursLabel.textColor = .lightGray.lighter
        case false:
            openingClosingHoursLabel.textColor = .darkGray
        }
        
        distanceLabel = PaddedLabel(withInsets: 0, 0, 0, 0)
        distanceLabel.frame.size = CGSize(width: informationPanel.frame.width * 0.3, height: 40)
        distanceLabel.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: true)
        distanceLabel.textAlignment = .left
        distanceLabel.adjustsFontForContentSizeCategory = false
        distanceLabel.adjustsFontSizeToFitWidth = true
        /** Placeholder text to give the label a dimension*/
        distanceLabel.text = ""
        switch darkMode {
        case true:
            distanceLabel.textColor = .lightGray.lighter
        case false:
            distanceLabel.textColor = .darkGray
        }
        
        pickUpDropOffSegmentedControl = UISegmentedControl(items: ["Pick-Up \n Use Delivery","Drop-off \n Go In-person"])
        pickUpDropOffSegmentedControl.frame = CGRect(x: 0, y: 0, width: informationPanel.frame.width * 0.95, height: 40)
        pickUpDropOffSegmentedControl.backgroundColor = .lightGray.lighter
        pickUpDropOffSegmentedControl.setTitleTextAttributes([.font: getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: true), .foregroundColor: UIColor.white], for: .normal)
        switch darkMode {
        case true:
            pickUpDropOffSegmentedControl.backgroundColor = .darkGray.lighter
            pickUpDropOffSegmentedControl.setTitleTextAttributes([.font: getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: true), .foregroundColor: UIColor.white], for: .selected)
            pickUpDropOffSegmentedControl.selectedSegmentTintColor = appThemeColor
        case false:
            pickUpDropOffSegmentedControl.backgroundColor = .lightGray.lighter
            pickUpDropOffSegmentedControl.setTitleTextAttributes([.font: getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: true), .foregroundColor: appThemeColor], for: .selected)
            pickUpDropOffSegmentedControl.selectedSegmentTintColor = bgColor
        }
        pickUpDropOffSegmentedControl.tintColor = .white
        pickUpDropOffSegmentedControl.selectedSegmentIndex = 0
        pickUpDropOffSegmentedControl.isExclusiveTouch = true
        pickUpDropOffSegmentedControl.addTarget(self, action: #selector(segmentControlSelected), for: .valueChanged)
        
        totalReviewsLabel = PaddedLabel(withInsets: 1, 1, 5, 5)
        totalReviewsLabel.frame.size = CGSize(width: informationPanel.frame.width * 0.2, height: 40)
        totalReviewsLabel.font = getCustomFont(name: .Ubuntu_Regular, size: 12, dynamicSize: true)
        totalReviewsLabel.backgroundColor = .clear
        totalReviewsLabel.textColor = fontColor
        totalReviewsLabel.textAlignment = .left
        totalReviewsLabel.adjustsFontForContentSizeCategory = true
        totalReviewsLabel.adjustsFontSizeToFitWidth = true
        totalReviewsLabel.layer.cornerRadius = totalReviewsLabel.frame.height/2
        totalReviewsLabel.layer.borderColor = appThemeColor.cgColor
        totalReviewsLabel.layer.borderWidth = 0.5
        totalReviewsLabel.layer.masksToBounds = true
        totalReviewsLabel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        /** Reveal this label after the data for it has been loaded*/
        totalReviewsLabel.alpha = 1
        
        /** Attributed string with a system image in the front*/
        let imageAttachment2 = NSTextAttachment()
        imageAttachment2.image = UIImage(systemName: "person.3.fill")?.withTintColor(appThemeColor)
        
        let numberOfReviews = 0
        
        let attributedString2 = NSMutableAttributedString()
        attributedString2.append(NSAttributedString(attachment: imageAttachment2))
        attributedString2.append(NSMutableAttributedString(string: " \(numberOfReviews)"))
        totalReviewsLabel.attributedText = attributedString2
        
        averageRatings = RatingsCircleProgressView(frame: CGRect(x: 0, y: 0, width: (informationPanel.frame.width * 0.135), height: (informationPanel.frame.width * 0.135)), layerBackgroundColor: bgColor, completionPercentage: 1, trackColor: UIColor.white.darker, fillColor: UIColor.green, useGradientColor: true, centerLabelText: "5.0", centerLabelSubtitleText: "", centerLabelSecondarySubtitleText: "", centerLabelFontColor: fontColor, centerLabelSubtitleFontColor: fontColor, centerLabelSecondarySubtitleFontColor: fontColor, centerLabelFontSize: 20, centerLabelSubtitleFontSize: 14, centerLabelSecondarySubtitleFontSize: 14, displayCenterLabel: true, displayCenterLabelSubtitle: true, displayCenterLabelSecondarySubtitle: false)
        
        /** Don't animate the progress bar, set it statically*/
        averageRatings.progressAnimation(duration: 1)
        
        /** Reveal this item after the data for it has been loaded, this data can be retrieved using a listener to get fresh up to date info*/
        averageRatings.alpha = 1
        
        let result = getOpeningAndClosingTimes(operatingHoursMap: laundromatData.operatingHours)
        
        switch isWithinOperatingHours(operatingHoursMap: laundromatData.operatingHours){
        case true:
            operatingHoursLabel.text = "Open"
            operatingHoursLabel.textColor = appThemeColor
            openingClosingHoursLabel.text = "•  Closes: \(result.closingTime)"
        case false:
            operatingHoursLabel.text = "Closed"
            operatingHoursLabel.textColor = .red
            openingClosingHoursLabel.text = "•  Opens: \(result.openingTime)"
        }
        
        /** Default minimized height of the information panel*/
        informationPanel.frame.size.height = 140
        
        /** Resize the following views to fit their subviews*/
        operatingHoursLabel.sizeToFit()
        operatingHoursLabel.widthAnchor.constraint(equalToConstant: operatingHoursLabel.frame.width).isActive = true
        
        openingClosingHoursLabel.sizeToFit()
        openingClosingHoursLabel.widthAnchor.constraint(equalToConstant: openingClosingHoursLabel.frame.width).isActive = true
        
        distanceLabel.sizeToFit()
        distanceLabel.widthAnchor.constraint(equalToConstant: distanceLabel.frame.width).isActive = true
        
        nicknameLabel.sizeToFit()
        nicknameLabel.frame.size.width = informationPanel.frame.width * 0.9
        nicknameLabel.widthAnchor.constraint(equalToConstant: nicknameLabel.frame.width).isActive = true
        
        addressLabel.sizeToFit()
        addressLabel.frame.size.width = informationPanel.frame.width * 0.9
        addressLabel.widthAnchor.constraint(equalToConstant: addressLabel.frame.width).isActive = true
        
        /** Layout these subviews*/
        informationPanel.frame.origin = CGPoint(x: 0, y: 10)
        
        expansionButton.frame.origin = CGPoint(x: 0, y: informationPanel.frame.height - expansionButton.frame.height)
        
        nicknameLabel.frame.origin = CGPoint(x: informationPanel.frame.width * 0.05, y: 5)
        
        addressLabel.frame.origin = CGPoint(x: informationPanel.frame.width * 0.05, y: nicknameLabel.frame.maxY + 5)
        
        operatingHoursLabel.frame.origin = CGPoint(x: informationPanel.frame.width * 0.05, y: addressLabel.frame.maxY + 5)
        
        openingClosingHoursLabel.frame.origin = CGPoint(x: operatingHoursLabel.frame.maxX + 5, y: 0)
        openingClosingHoursLabel.center.y = operatingHoursLabel.center.y
        
        distanceLabel.frame.origin = CGPoint(x: openingClosingHoursLabel.frame.maxX + 5, y: 0)
        distanceLabel.center.y = openingClosingHoursLabel.center.y
        
        averageRatings.frame.origin = CGPoint(x: informationPanel.frame.maxX - (averageRatings.frame.width * 1.15), y: openingClosingHoursLabel.frame.maxY + 5)
        
        /** Have a little overlap with the average ratings view*/
        totalReviewsLabel.frame.origin = CGPoint(x: averageRatings.frame.minX - (totalReviewsLabel.frame.width * 0.9), y: 0)
        totalReviewsLabel.center.y = averageRatings.center.y
        
        phoneNumberButton.frame.origin = CGPoint(x: informationPanel.frame.width * 0.05, y: 0)
        phoneNumberButton.center.y = totalReviewsLabel.center.y
        
        pickUpDropOffSegmentedControl.frame.origin = CGPoint(x: informationPanel.frame.width/2 - pickUpDropOffSegmentedControl.frame.width/2, y: expansionButton.frame.minY - (pickUpDropOffSegmentedControl.frame.height + 5))
        
        /** Add all subviews to the information panel*/
        informationPanel.addSubview(distanceLabel)
        informationPanel.addSubview(operatingHoursLabel)
        informationPanel.addSubview(openingClosingHoursLabel)
        informationPanel.addSubview(nicknameLabel)
        informationPanel.addSubview(addressLabel)
        informationPanel.addSubview(phoneNumberButton)
        informationPanel.addSubview(totalReviewsLabel)
        informationPanel.addSubview(averageRatings)
        informationPanel.addSubview(pickUpDropOffSegmentedControl)
        informationPanel.addSubview(expansionButton)
        
        /** These views start out invisible*/
        operatingHoursLabel.alpha = 0
        openingClosingHoursLabel.alpha = 0
        distanceLabel.alpha = 0
        averageRatings.alpha = 0
        totalReviewsLabel.alpha = 0
        phoneNumberButton.alpha = 0
        
        let imageConfiguration = UIImage.SymbolConfiguration(weight: .regular)
        let image = UIImage(systemName: "arrow.backward", withConfiguration: imageConfiguration)
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
        closeButton.customView = backButton
        
        optionsButton.frame.size.height = 35
        optionsButton.frame.size.width = optionsButton.frame.size.height
        optionsButton.backgroundColor = bgColor
        optionsButton.tintColor = appThemeColor
        optionsButton.setImage(UIImage(systemName: "ellipsis", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        optionsButton.layer.cornerRadius = optionsButton.frame.height/2
        optionsButton.isExclusiveTouch = true
        optionsButton.castDefaultShadow()
        optionsButton.layer.shadowColor = UIColor.darkGray.cgColor
        optionsButton.addTarget(self, action: #selector(optionsButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: optionsButton)
        optionsButton.alpha = 1
        optionsButton.isEnabled = true
        optionsButton.showsMenuAsPrimaryAction = true
        optionsButtonItem.customView = optionsButton
        
        favoriteButton = LottieButton(frame: CGRect(x: 0, y: 0, width: 35, height: 35), lottieFile: "heart-like")
        favoriteButton.backgroundColor = bgColor
        favoriteButton.tintColor = fontColor
        favoriteButton.layer.cornerRadius = favoriteButton.frame.height/2
        favoriteButton.castDefaultShadow()
        favoriteButton.layer.shadowColor = UIColor.darkGray.cgColor
        favoriteButton.isEnabled = true
        favoriteButton.isExclusiveTouch = true
        favoriteButtonItem.customView = favoriteButton
        favoriteButton.addTarget(self, action: #selector(favoriteButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: favoriteButton)
        
        /** Reflect whether or not this laundromat has been favorited*/
        if favorited == true{
            favoriteButton.setAnimationFrameTo(this: 70)
        }
        else{
            favoriteButton.setAnimationFrameTo(this: 0)
        }
        
        /**Initialize the location manager*/
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        /** Update the user's location every 1 meter (3+ ft)*/
        locationManager.distanceFilter = 1
        locationManager.startUpdatingLocation()
        locationManager.showsBackgroundLocationIndicator = true
        ///locationManager.allowsBackgroundLocationUpdates = false
        locationManager.activityType = .fitness
        locationManager.delegate = self
        
        /**
         /** Generic coordinate point in Brooklyn*/
         let coordinate = CLLocationCoordinate2D(latitude: 40.67985516878483, longitude: -73.93747149720345)
         
         camera = GMSCameraPosition.camera(withLatitude: coordinate.latitude, longitude: coordinate.longitude, zoom: preciseLocationZoomLevel)
         
         /** Cloud based map styling*/
         var mapIDString = "f95c619415f25d75"
         switch darkMode {
         case true:
         mapIDString = "a4c677bcbe54c097"
         case false:
         mapIDString = "f95c619415f25d75"
         }
         
         mapView = GMSMapView(frame: CGRect(origin: .zero, size: CGSize(width: self.view.frame.width, height: self.view.frame.height * 0.2)), mapID: GMSMapID(identifier: mapIDString), camera: camera)
         mapView.backgroundColor = .clear
         mapView.settings.myLocationButton = false
         mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
         mapView.isMyLocationEnabled = true
         /** Specify a maximum zoom out level to prevent the user from seeing the edges of the map*/
         mapView.setMinZoom(12, maxZoom: 30)
         mapView.settings.myLocationButton = false
         mapView.settings.consumesGesturesInView = false
         mapView.isUserInteractionEnabled = false
         mapView.layer.isOpaque = false
         mapView.frame.origin = .zero
         
         /**Add the map to the view, hide it until we've got a location update.*/
         mapView.isHidden = true
         
         /** Set the initial position of the map to be the user's current location*/
         let currentZoomLevel = locationManager.accuracyAuthorization == .fullAccuracy ? streetLevelZoomLevel : preciseLocationZoomLevel
         
         let camera = GMSCameraPosition.camera(withLatitude: locationManager.location?.coordinate.latitude ?? coordinate.latitude, longitude: locationManager.location?.coordinate.longitude ?? coordinate.longitude, zoom: currentZoomLevel)
         
         if mapView.isHidden{
         mapView.isHidden = false
         mapView.camera = camera
         } else {
         /** Set the initial position of the map to be the user's current location*/
         mapView.animate(to: camera)
         }*/
        
        imageCarousel = Basin.imageCarousel(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height * 0.2), images: nil, urls: stringToURL(stringArray: laundromatData.photos), useURLs: true, contentBackgroundColor: UIColor.clear, animatedTransition: true, transitionDuration: 0.25, infiniteScroll: true, showDetailViewOnTap: false, showContextMenu: false, presentingVC: self, showPageControl: false, pageControlActiveDotColor: appThemeColor, pageControlInactiveDotColor: UIColor.lightGray.lighter, pageControlPosition: .bottom, loadOnce: true, showImageTrackerLabel: false, imageTrackerLabelPosition: .lowerRight, imageViewContentMode: .scaleAspectFill)
        imageCarousel.autoMove(timeInterval: 5, animationDuration: 1, animated: true, repeating: true)
        /** Prevent the user from scrolling and interacting with the view*/
        imageCarousel.isUserInteractionEnabled = false
        imageCarousel.frame.origin = .zero
        
        dividingLine = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 4))
        dividingLine.backgroundColor = appThemeColor
        dividingLine.clipsToBounds = true
        dividingLine.frame.origin.y = imageCarousel.frame.maxY
        
        navBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 90))
        navBar.delegate = self
        navBar.prefersLargeTitles = false
        /** Specify the title of this view controller*/
        navItem.title = laundromatData.nickName
        navItem.leftBarButtonItem = closeButton
        navItem.rightBarButtonItems = [optionsButtonItem,favoriteButtonItem]
        navItem.largeTitleDisplayMode = .never
        navBar.setItems([navItem], animated: false)
        
        var barBgColor = appThemeColor
        var underlineColor = appThemeColor
        switch darkMode{
        case true:
            barBgColor = bgColor.darker
            underlineColor = appThemeColor
        case false:
            barBgColor =  appThemeColor
            underlineColor =  UIColor.white
        }
        
        buttonBar = underlinedButtonBar(buttons: [washingButton, dryCleaningButton], width: self.view.frame.width, height: 45, underlineColor: underlineColor, underlineTrackColor: .lightGray.lighter, underlineHeight: 3, backgroundColor: barBgColor, animated: true)
        buttonBar.alpha = 0
        buttonBar.isUserInteractionEnabled = false
        
        /** Will be redisplayed if a persistent storage cart is loaded up and the cart's parent data matches the data of this laundromat*/
        viewCartButton = UIButton()
        viewCartButton.frame.size = CGSize(width: informationPanel.frame.width * 0.9, height: 60)
        viewCartButton.backgroundColor = appThemeColor
        viewCartButton.setTitleColor(.white, for: .normal)
        viewCartButton.titleLabel?.font = getCustomFont(name: .Ubuntu_Regular, size: 16, dynamicSize: true)
        viewCartButton.contentHorizontalAlignment = .center
        viewCartButton.titleLabel?.adjustsFontSizeToFitWidth = true
        viewCartButton.titleLabel?.adjustsFontForContentSizeCategory = true
        viewCartButton.layer.cornerRadius = viewCartButton.frame.height/2
        viewCartButton.isExclusiveTouch = true
        viewCartButton.isEnabled = true
        viewCartButton.castDefaultShadow()
        viewCartButton.layer.shadowColor = UIColor.darkGray.cgColor
        viewCartButton.tintColor = .white
        viewCartButton.setImage(UIImage(systemName: "cart.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        viewCartButton.menu = getViewCartButtonMenu()
        viewCartButton.frame.origin = CGPoint(x: view.frame.width/2 - viewCartButton.frame.width/2, y: view.frame.maxY + (viewCartButton.frame.height * 1.5))
        viewCartButton.addTarget(self, action: #selector(viewCartButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: viewCartButton)
        
        searchTableViewContainer = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height - imageCarousel.frame.height))
        switch darkMode {
        case true:
            searchTableViewContainer.backgroundColor = bgColor
        case false:
            searchTableViewContainer.backgroundColor = bgColor
        }
        searchTableViewContainer.isUserInteractionEnabled = true
        searchTableViewContainer.clipsToBounds = true
        searchTableViewContainer.frame.size.height = 0
        
        searchTableView = UITableView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height), style: .grouped)
        searchTableView.clipsToBounds = true
        searchTableView.backgroundColor = .clear
        searchTableView.tintColor = fontColor
        searchTableView.isOpaque = false
        searchTableView.showsVerticalScrollIndicator = true
        searchTableView.showsHorizontalScrollIndicator = false
        searchTableView.isExclusiveTouch = true
        searchTableView.contentInsetAdjustmentBehavior = .never
        searchTableView.dataSource = self
        searchTableView.delegate = self
        searchTableView.separatorStyle = .none
        searchTableView.layer.borderColor = UIColor.white.darker.cgColor
        searchTableView.layer.borderWidth = 0
        
        /** Add a little space at the bottom of the scrollview*/
        searchTableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: imageCarousel.frame.height * 1.25, right: 0)
        
        searchTableView.register(OrderItemSearchTableViewCell.self, forCellReuseIdentifier: OrderItemSearchTableViewCell.identifier)
        
        if(darkMode == true){
            searchTableView.indicatorStyle = .white
        }
        else{
            searchTableView.indicatorStyle = .black
        }
        
        searchTableViewContainer.addSubview(searchTableView)
        
        /** Delay this slightly to give the buttonbar time to be repositioned*/
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){[self] in
            /**Add the button bar below the navigation bar*/
            buttonBar.frame.origin = CGPoint(x: 0, y: navBar.frame.maxY)
            
            searchTableViewContainer.frame.origin = CGPoint(x: 0, y: dividingLine.frame.maxY)
            
            /**
             sectionTitleLabel.frame = CGRect(x: 0, y: buttonBar!.frame.maxY + 20, width:  view.frame.width, height: 40)
             sectionTitleLabel.text = "Wash Dry Fold"
             sectionTitleLabel.font = getCustomFont(name: .Bungee_Regular, size: 25, dynamicSize: true)
             sectionTitleLabel.textColor = appThemeColor
             sectionTitleLabel.adjustsFontSizeToFitWidth = true
             sectionTitleLabel.textAlignment = .left
             sectionTitleLabel.layer.zPosition = -1
             */
            
            informationPanel.frame.origin = CGPoint(x: 0, y: buttonBar.frame.maxY)
            
            scrollView.frame = CGRect(x: 0, y: informationPanel.frame.maxY, width: view.frame.width, height: view.frame.height)
            stackView.frame = CGRect(x: 0, y: 10, width: view.frame.width, height: view.frame.height)
            
            scrollView.contentSize = CGSize(width: view.frame.width, height: scrollView.frame.height)
            
            let leading = NSLayoutConstraint(item: stackView, attribute: .leading, relatedBy: .equal, toItem: scrollView, attribute: .leading, multiplier: 1.0, constant: 0)
            scrollView.addConstraint(leading)
            let trailing = NSLayoutConstraint(item: stackView, attribute: .trailing, relatedBy: .equal, toItem: scrollView, attribute: .trailing, multiplier: 1.0, constant: 0)
            scrollView.addConstraint(trailing)
            let top = NSLayoutConstraint(item: stackView, attribute: .top, relatedBy: .equal, toItem: scrollView, attribute: .top, multiplier: 1.0, constant: 0)
            scrollView.addConstraint(top)
            let bottom = NSLayoutConstraint(item: stackView, attribute: .bottom, relatedBy: .equal, toItem: scrollView, attribute: .bottom, multiplier: 1.0, constant: 0)
            scrollView.addConstraint(bottom)
            let equalHeight = NSLayoutConstraint(item: stackView, attribute: .height, relatedBy: .equal, toItem: scrollView, attribute: .height, multiplier: 1.0, constant: 0)
            scrollView.addConstraint(equalHeight)
            leading.isActive = true
            trailing.isActive = true
            top.isActive = true
            bottom.isActive = true
            equalHeight.isActive = true
            
            /**Set priority of this constraint to 1 to enable stack view and stack view subview user interactions, if this isn't set then taps aren't sent to the views as a result of constraint hiccups*/
            equalHeight.priority = UILayoutPriority(1000)
        }
        
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        /**Scrollview can override touches to the content within an use those touches as parameters for movement*/
        scrollView.canCancelContentTouches = true
        scrollView.isPagingEnabled = true
        scrollView.clipsToBounds = false
        scrollView.delaysContentTouches = true
        scrollView.isExclusiveTouch = true
        
        stackView.backgroundColor = UIColor.clear
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 0
        stackView.axis = .horizontal
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isUserInteractionEnabled = true
        stackView.semanticContentAttribute = .forceLeftToRight
        
        scrollView.addSubview(stackView)
        self.view.addSubview(scrollView)
        self.view.addSubview(informationPanel)
        ///self.view.addSubview(mapView)
        self.view.addSubview(imageCarousel)
        self.view.addSubview(dividingLine)
        self.view.addSubview(navBar)
        self.view.addSubview(favoriteButton)
        self.view.addSubview(buttonBar)
        self.view.addSubview(viewCartButton)
        self.view.addSubview(searchTableViewContainer)
        
        navBar.translatesAutoresizingMaskIntoConstraints = false
        navBar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        navBar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        navBar.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
        navBar.heightAnchor.constraint(equalToConstant: navBar.frame.height).isActive = true
    }
    
    /** Return a custom menu for the view cart button*/
    func getViewCartButtonMenu()->UIMenu{
        var children: [UIMenuElement] = []
        let menuTitle = "Options:"
        
        /** Erase the cart from the carts collection, but give the user the option to undo the action in 2 seconds*/
        let clear = UIAction(title: "Clear", image: UIImage(systemName: "trash.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light))){ [self] action in
            if internetAvailable == true{
                guard laundromatCart != nil || undoCartEraseInProgress == false else {
                    return
                }
                lightHaptic()
                
                cartUndoButtonActivated()
            }
            else{
                globallyTransmit(this: "An internet connection is required in order to update your cart", with: UIImage(systemName: "wifi.slash", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: .clear, imageBorder: .none, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 3, selfDismiss: true)
            }
        }
        
        children.append(clear)
        return UIMenu(title: menuTitle, children: children)
    }
    
    /** Change the button's label to reflect its new Undo functionality, and also add the moving sublayer that will act as a progress bar for the user to know how much time they have left in order to undo their action before the cart is fully erased*/
    func cartUndoButtonActivated(){
        undoCartEraseInProgress = true
        
        viewCartButtonLayer.bounds = CGRect(x: 0, y: 0, width: 0, height: viewCartButton.bounds.height)
        viewCartButtonLayer.anchorPoint = .zero
        viewCartButtonLayer.position = .zero
        viewCartButtonLayer.backgroundColor = bgColor.cgColor
        viewCartButtonLayer.masksToBounds = true
        viewCartButtonLayer.cornerRadius = viewCartButton.layer.cornerRadius
        
        /** Insert this layer behind all other layers*/
        viewCartButton.layer.insertSublayer(viewCartButtonLayer, at: 0)
        
        viewCartButton.setTitleColor(appThemeColor, for: .normal)
        viewCartButton.setImage(nil, for: .normal)
        viewCartButton.setTitle("Undo", for: .normal)
        
        let progressAnimation = CABasicAnimation(keyPath: "bounds.size.width")
        progressAnimation.duration = 2
        progressAnimation.fromValue = 0
        progressAnimation.toValue = viewCartButton.bounds.width
        progressAnimation.fillMode = .forwards
        progressAnimation.isRemovedOnCompletion = false
        viewCartButtonLayer.add(progressAnimation, forKey: "progressAnimation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2){[self] in
            if undoCartEraseInProgress == true{
                finalizeCartErase()
            }
        }
        
        /** Slight delay so that the animation looks smooth*/
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5){[self] in
            if undoCartEraseInProgress == true{
                viewCartButtonLayer.removeFromSuperlayer()
            }
        }
    }
    
    /** Finalize the cart erase by refetching the cart, this will create a new cart object*/
    func finalizeCartErase(){
        if undoCartEraseInProgress == true{
            undoCartEraseInProgress = false
            
            deleteThisCart(cart: laundromatCart)
            hideViewCartButton(animated: true)
            
            /** Don't change the color of the title immediately*/
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){[self] in
                viewCartButtonLayer.removeFromSuperlayer()
                viewCartButton.setTitleColor(.white, for: .normal)
            }
            
            laundromatCart = nil
            fetchCart()
            
            clearMenuItems()
            
            /** Reload the table views to reflect the change in the cart*/
            if washingMenuTableView != nil{
                washingMenuTableView.reloadData()
            }
            
            if dryCleaningMenuTableView != nil{
                dryCleaningMenuTableView.reloadData()
            }
        }
    }
    
    /** Set the item count for all items in the menus to 0*/
    func clearMenuItems(){
        guard washingMenu != nil && dryCleaningMenu != nil else {
            return
        }
        
        washingMenu!.clear()
        dryCleaningMenu!.clear()
        
        washingMenuCategorySections = computeTotalSectionsForWashingMenuTableView() ?? [:]
        dryCleaningMenuCategorySections = computeTotalSectionsForDryCleaningMenuTableView() ?? [:]
        
        sortCategoriesInDescendingOrder()
    }
    
    /** Reverse the cart erase action*/
    func undoCartErase(){
        undoCartEraseInProgress = false
        
        /** Remove the progress layer from the button*/
        let progressAnimation = CABasicAnimation(keyPath: "bounds.size.width")
        progressAnimation.speed = 2
        progressAnimation.duration = 1
        progressAnimation.toValue = 0
        progressAnimation.fillMode = .both
        progressAnimation.isRemovedOnCompletion = false
        viewCartButtonLayer.add(progressAnimation, forKey: "reverseProgressAnimation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){[self] in
            viewCartButtonLayer.removeFromSuperlayer()
            viewCartButton.setTitleColor(.white, for: .normal)
            updateViewCartButtonLabel()
        }
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
    
    /** Search bar delegate methods*/
    /** Listen for the changes to the text in the search bar*/
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String){
        
        /** Hide the search table if no text has been entered, and display the search table once text has been entered*/
        if searchText != ""{
            showSearchTable()
        }
        else if searchText == ""{
            hideSearchTable()
        }
        
        /** Update the no search results label with the current search text*/
        if noSearchResultsFoundBeingDisplayed == true{
            /** Hide the no search results prompt*/
            if searchText == ""{
            hideNoSearchResultsFound()
            }
            else if noSearchResultsFoundLabel != nil{
            noSearchResultsFoundLabel.text = "No search result matches found for '\(searchText)'"
            }
        }
        
        if filterWashingMenu == true{
            
            for dictionary in washingMenuCategorySections{
                for item in dictionary.value{
                    /** Detect if the name of the item contains the given search text*/
                    var matchFound = false
                    
                    if item.name.lowercased().contains(searchText.lowercased()){
                        matchFound = true
                    }
                    else{
                        matchFound = false
                    }
                    
                    if matchFound == true{
                        /** Append this item to the filtered results if it's not already present*/
                        if filteredItems[dictionary.key] != nil{
                            
                            /** Make sure the elements in the array are unique*/
                            if !filteredItems[dictionary.key]!.contains(item){
                                filteredItems[dictionary.key]!.append(item)
                            }
                        }
                        else{
                            /** Instantiate the array for the given key*/
                            filteredItems[dictionary.key] = []
                            filteredItems[dictionary.key]!.append(item)
                        }
                    }
                    else{
                        /** Remove this item from the filtered results if it's not already removed*/
                        if filteredItems[dictionary.key] != nil{
                            for (index,filteredItem) in filteredItems[dictionary.key]!.enumerated(){
                                if filteredItem == item{
                                    filteredItems[dictionary.key]!.remove(at: index)
                                    break
                                }
                            }
                        }
                    }
                }
            }
            
            /** Remove any unused sections*/
            for pair in filteredItems{
                if pair.value.isEmpty == true{
                filteredItems.removeValue(forKey: pair.key)
                }
            }
            searchTableView.reloadData()
        }
        else if filterDryCleaningMenu == true{
            
            for dictionary in dryCleaningMenuCategorySections{
                for item in dictionary.value{
                    /** Detect if the name of the item contains the given search text*/
                    var matchFound = false
                    
                    if item.name.lowercased().contains(searchText.lowercased()){
                        matchFound = true
                    }
                    else{
                        matchFound = false
                    }
                    
                    if matchFound == true{
                        /** Append this item to the filtered results if it's not already present*/
                        if filteredItems[dictionary.key] != nil{
                            
                            if !filteredItems[dictionary.key]!.contains(item){
                                filteredItems[dictionary.key]!.append(item)
                            }
                        }
                        else{
                            /** Instantiate the array for the given key*/
                            filteredItems[dictionary.key] = []
                            filteredItems[dictionary.key]!.append(item)
                        }
                    }
                    else{
                        /** Remove this item from the filtered results if it's not already removed*/
                        if filteredItems[dictionary.key] != nil{
                            for (index,filteredItem) in filteredItems[dictionary.key]!.enumerated(){
                                if filteredItem == item{
                                    filteredItems[dictionary.key]!.remove(at: index)
                                    break
                                }
                            }
                        }
                    }
                }
            }
            
            /** Remove any unused sections*/
            for pair in filteredItems{
                if pair.value.isEmpty == true{
                filteredItems.removeValue(forKey: pair.key)
                }
            }
            searchTableView.reloadData()
            
        }
        
        /** If no search results are available then display the no search results available prompt*/
        if filteredItems.isEmpty == true{
            if noSearchResultsFoundBeingDisplayed == false{
                displayNoSearchResultsFound()
            }
        }
        else{
            /** There are search results available so hide the no search results panel*/
            hideNoSearchResultsFound()
        }
    }
    /** Clear the search table when the user cancels the search operation */
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        filteredItems.removeAll()
        searchTableView.reloadData()
        
        /** Reload the table views when the user exits the search table view*/
        if washingMenuTableView != nil && filterWashingMenu == true{
        washingMenuTableView.reloadData()
        }
        if dryCleaningMenuTableView != nil && filterDryCleaningMenu == true{
        dryCleaningMenuTableView.reloadData()
        }
        
        noSearchResultsFoundBeingDisplayed =  false
        
        hideNoSearchResultsFound()
        
        hideSearchTable()
    }
    
    /** Show the search results table view when the user starts editing*/
    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
    }
    
    /** Display the no search results found prompt*/
    func displayNoSearchResultsFound(){
        guard searchTableView != nil else {
            return
        }
        
        /** Get rid of the past no search results panel when a new one is to be displayed*/
        if noSearchResultsFoundContainer != nil{
        noSearchResultsFoundContainer.removeFromSuperview()
        noSearchResultsFoundContainer = nil
        }
        
        noSearchResultsFoundBeingDisplayed =  true
        
        noSearchResultsFoundContainer = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height - imageCarousel.frame.height))
        noSearchResultsFoundContainer.clipsToBounds = true
        noSearchResultsFoundContainer.alpha = 0
        noSearchResultsFoundContainer.backgroundColor = bgColor
        noSearchResultsFoundContainer.isUserInteractionEnabled = true
        
        noSearchResultsFoundBackButton = UIButton()
        noSearchResultsFoundBackButton.frame.size = CGSize(width: noSearchResultsFoundContainer.frame.width * 0.9, height: 50)
        noSearchResultsFoundBackButton.backgroundColor = bgColor
        noSearchResultsFoundBackButton.setTitleColor(appThemeColor, for: .normal)
        noSearchResultsFoundBackButton.setTitle("Go Back", for: .normal)
        noSearchResultsFoundBackButton.titleLabel?.font = getCustomFont(name: .Ubuntu_Regular, size: 18, dynamicSize: true)
        noSearchResultsFoundBackButton.contentHorizontalAlignment = .center
        noSearchResultsFoundBackButton.titleLabel?.adjustsFontSizeToFitWidth = true
        noSearchResultsFoundBackButton.titleLabel?.adjustsFontForContentSizeCategory = true
        noSearchResultsFoundBackButton.layer.cornerRadius = noSearchResultsFoundBackButton.frame.height/2
        noSearchResultsFoundBackButton.isExclusiveTouch = true
        noSearchResultsFoundBackButton.isEnabled = true
        noSearchResultsFoundBackButton.castDefaultShadow()
        noSearchResultsFoundBackButton.layer.shadowColor = UIColor.darkGray.cgColor
        noSearchResultsFoundBackButton.layer.borderColor = appThemeColor.cgColor
        noSearchResultsFoundBackButton.layer.borderWidth = 2
        noSearchResultsFoundBackButton.tintColor = appThemeColor
        noSearchResultsFoundBackButton.addTarget(self, action: #selector(noSearchResultsFoundBackButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: noSearchResultsFoundBackButton)
        
        noSearchResultsFoundLabel = UILabel()
        noSearchResultsFoundLabel.frame = CGRect(x: 0, y: 0, width: noSearchResultsFoundContainer.frame.width * 0.85, height: 40)
        noSearchResultsFoundLabel.font = getCustomFont(name: .Ubuntu_Medium, size: 22, dynamicSize: true)
        noSearchResultsFoundLabel.lineBreakMode = .byClipping
        noSearchResultsFoundLabel.numberOfLines = 2
        noSearchResultsFoundLabel.textColor = fontColor
        noSearchResultsFoundLabel.adjustsFontForContentSizeCategory = true
        noSearchResultsFoundLabel.adjustsFontSizeToFitWidth = true
        noSearchResultsFoundLabel.textAlignment = .center
        noSearchResultsFoundLabel.text = "No search result matches found for '\(searchController!.searchBar.searchTextField.text!)'"
        noSearchResultsFoundLabel.sizeToFit()
        
        noSearchResultsFoundSecondaryLabel = UILabel()
        noSearchResultsFoundSecondaryLabel.frame = CGRect(x: 0, y: 0, width: noSearchResultsFoundContainer.frame.width * 0.85, height: 40)
        noSearchResultsFoundSecondaryLabel.font = getCustomFont(name: .Ubuntu_Light, size: 16, dynamicSize: true)
        noSearchResultsFoundSecondaryLabel.lineBreakMode = .byClipping
        noSearchResultsFoundSecondaryLabel.numberOfLines = 2
        noSearchResultsFoundSecondaryLabel.textColor = .lightGray
        noSearchResultsFoundSecondaryLabel.adjustsFontForContentSizeCategory = true
        noSearchResultsFoundSecondaryLabel.adjustsFontSizeToFitWidth = true
        noSearchResultsFoundSecondaryLabel.textAlignment = .center
        noSearchResultsFoundSecondaryLabel.text = "You can try another query or go back to the main menu"
        noSearchResultsFoundSecondaryLabel.sizeToFit()
        
        noSearchResultsFoundLottieView = AnimationView(name: "noSearchResults")
        noSearchResultsFoundLottieView.frame = CGRect(x: 0, y: 0, width: noSearchResultsFoundContainer.frame.width/2, height: noSearchResultsFoundContainer.frame.width/2)
        noSearchResultsFoundLottieView.clipsToBounds = true
        noSearchResultsFoundLottieView.backgroundColor = .clear
        noSearchResultsFoundLottieView.backgroundBehavior = .pauseAndRestore
        noSearchResultsFoundLottieView.shouldRasterizeWhenIdle = true
        noSearchResultsFoundLottieView.play()
        noSearchResultsFoundLottieView.loopMode = .playOnce
        
        /** Layout these subviews*/
        noSearchResultsFoundLottieView.frame.origin = CGPoint(x: noSearchResultsFoundContainer.frame.width/2 - noSearchResultsFoundLottieView.frame.width/2, y: noSearchResultsFoundContainer.frame.height/2 - noSearchResultsFoundLottieView.frame.height)
        
        noSearchResultsFoundLabel.frame.origin = CGPoint(x: noSearchResultsFoundContainer.frame.width/2 - noSearchResultsFoundLabel.frame.width/2, y: noSearchResultsFoundLottieView.frame.minY - (noSearchResultsFoundLabel.frame.height * 1.15))
        
        noSearchResultsFoundSecondaryLabel.frame.origin = CGPoint(x: noSearchResultsFoundContainer.frame.width/2 - noSearchResultsFoundSecondaryLabel.frame.width/2, y: noSearchResultsFoundLottieView.frame.maxY + (noSearchResultsFoundLabel.frame.height * 0.15))
        
        noSearchResultsFoundBackButton.frame.origin = CGPoint(x: noSearchResultsFoundContainer.frame.width/2 - noSearchResultsFoundBackButton.frame.width/2, y: noSearchResultsFoundContainer.frame.maxY - (noSearchResultsFoundBackButton.frame.height * 1.75))
        
        noSearchResultsFoundContainer.addSubview(noSearchResultsFoundLabel)
        noSearchResultsFoundContainer.addSubview(noSearchResultsFoundLottieView)
        noSearchResultsFoundContainer.addSubview(noSearchResultsFoundSecondaryLabel)
        noSearchResultsFoundContainer.addSubview(noSearchResultsFoundBackButton)
        
        searchTableView.addSubview(noSearchResultsFoundContainer)
        
        UIView.animate(withDuration: 0.5, delay: 0){[self] in
        noSearchResultsFoundContainer.alpha = 1
        }
    }
    
    /** Hide the no search results found panel*/
    func hideNoSearchResultsFound(){
        guard noSearchResultsFoundContainer != nil else {
            return
        }
        
        noSearchResultsFoundBeingDisplayed = false
        
        noSearchResultsFoundContainer.isUserInteractionEnabled = false
        
        UIView.animate(withDuration: 0.5, delay: 0){[self] in
        noSearchResultsFoundContainer.alpha = 0
        }
    }
    
    /** Methods for showing and hiding the search table in an animated fashion*/
    func showSearchTable(){
        /** Expand*/
        searchTableViewExpanded = true
        
        /** If the information panel is not hidden then set the container's minY to the bottom of the image carousel's dividing line*/
        if scrollView.frame.origin.y != buttonBar.frame.maxY{
            searchTableViewContainer.frame.origin = CGPoint(x: 0, y: dividingLine.frame.maxY)
        }
        else{
            searchTableViewContainer.frame.origin = CGPoint(x: 0, y: buttonBar.frame.maxY)
        }
        
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn){ [self] in
            searchTableViewContainer.frame.size.height = self.view.frame.height - imageCarousel.frame.height
        }
    }
    
    func hideSearchTable(){
        /** Contract*/
        searchTableViewExpanded = false
        
        /** If the information panel is not hidden then set the container's minY to the bottom of the image carousel's dividing line*/
        if scrollView.frame.origin.y != buttonBar.frame.maxY{
            searchTableViewContainer.frame.origin = CGPoint(x: 0, y: dividingLine.frame.maxY)
        }
        else{
            searchTableViewContainer.frame.origin = CGPoint(x: 0, y: buttonBar.frame.maxY)
        }
        
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn){ [self] in
            searchTableViewContainer.frame.size.height = 0
        }
    }
    /** Methods for showing and hiding the search table in an animated fashion*/
    
    public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        
    }
    
    public func updateSearchResults(for searchController: UISearchController){
        //
    }
    /** Search bar delegate methods*/
    
    /**Customize and set up the search controller for this view*/
    func setSearchController(){
        searchController = UISearchController(searchResultsController: nil)
        searchController!.hidesNavigationBarDuringPresentation = false
        searchController!.searchResultsUpdater = self
        searchController!.obscuresBackgroundDuringPresentation = false
        searchController!.searchBar.placeholder = "Search for washing options"
        
        /**Cancel button and editing carot*/
        switch darkMode {
        case true:
            searchController!.searchBar.tintColor = .white
        case false:
            searchController!.searchBar.tintColor = .white
        }
        searchController?.searchBar.barTintColor = fontColor
        self.navItem.searchController = searchController
        self.definesPresentationContext = true
        navItem.hidesSearchBarWhenScrolling = false
        navBar.backgroundColor = bgColor
        
        searchController?.searchBar.delegate = self
        searchController?.searchBar.searchTextField.textColor = fontColor
        searchController?.searchBar.searchTextField.backgroundColor = bgColor.lighter
        searchController?.searchBar.searchTextField.leftView?.tintColor = appThemeColor/**change color of searchbar icon*/
        searchController?.searchBar.searchTextField.font = getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true)
        searchController?.searchBar.searchTextField.layer.cornerRadius = (searchController?.searchBar.frame.height)!/3.2
        searchController?.searchBar.searchTextField.layer.masksToBounds = true
    }
    
    func configure(){
        switch darkMode {
        case true:
            scrollView.indicatorStyle = .white
            view.backgroundColor = bgColor
        case false:
            scrollView.indicatorStyle = .black
            view.backgroundColor = bgColor
        }
        scrollView.clipsToBounds = false
        scrollView.isOpaque = false
        scrollView.delegate = self
        scrollView.scrollsToTop = false
        scrollView.isExclusiveTouch = true
        scrollView.backgroundColor = UIColor.clear
    }
    
    /** Button press methods*/
    /** Segmented control changed, act accordingly*/
    @objc func segmentControlSelected(sender: UISegmentedControl){
        switch sender.selectedSegmentIndex{
        case 0:
            laundryWillBePickedUp = true
            
            backwardTraversalShake()
            
            /**
             switch darkMode {
             case true:
             searchController!.searchBar.tintColor = appThemeColor
             case false:
             searchController!.searchBar.tintColor = .white
             }
             
             /** Pick-up selected, the user's laundry will be picked up by a driver*/
             UIView.animate(withDuration: 0.5, delay: 0){[self] in
             imageCarousel.alpha = 1
             mapView.alpha = 0
             }
             */
        case 1:
            laundryWillBePickedUp = false
            
            forwardTraversalShake()
            
            /**
             switch darkMode {
             case true:
             searchController!.searchBar.tintColor = appThemeColor
             case false:
             searchController!.searchBar.tintColor = .darkGray
             }
             
             /** Drop-off selected, user will drop off their laundry at the given location*/
             /** Hide the image carousel, display the map*/
             UIView.animate(withDuration: 0.5, delay: 0){[self] in
             imageCarousel.alpha = 0
             mapView.alpha = 1
             }
             */
        default:
            break
        }
    }
    
    /** Cancel the current search operation*/
    @objc func noSearchResultsFoundBackButtonPressed(sender: UIButton){
        guard searchController != nil else {
            return
        }
        
        self.searchBarCancelButtonClicked(searchController!.searchBar)
        self.searchController!.isActive = false
    }
    
    /** Present the cart associated with this session*/
    @objc func viewCartButtonPressed(sender: UIButton){
        /** This button will now act as an undo button*/
        if undoCartEraseInProgress == true{
            backwardTraversalShake()
            
            undoCartErase()
            return
        }
        
        /** Update the cart in the remote collection if the user is connected to internet*/
        if internetAvailable == true{
            forwardTraversalShake()
            
            if laundromatCart != nil{
                updateThisCart(cart: laundromatCart)
            }
            
            let cartVC = ShoppingCartVC()
            self.show(cartVC, sender: self)
        }
        else{
            /** Internet unavailable, can't proceed, inform the user that they must have an internet connection to continue*/
            errorShake()
            
            globallyTransmit(this: "Please connect to the internet in order to continue", with: UIImage(systemName: "wifi.slash", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: .clear, imageBorder: .none, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 3, selfDismiss: true)
        }
    }
    
    @objc func optionsButtonPressed(sender: UIButton){
        lightHaptic()
        
    }
    
    @objc func backButtonPressed(sender: UIButton){
        backwardTraversalShake()
        
        /** Dismiss the keyboard if any*/
        view.endEditing(true)
        
        /** The cart is empty, delete it from memory and the remote collection (only if internet is available, if internet is not available then this cart will be maintained in its last local form until it updates the remote, if the user comes back to the app after quiting the remote copy will overwrite the local data*/
        if laundromatCart != nil{
            if laundromatCart.items.isEmpty == true && internetAvailable == true{
                deleteThisCart(cart: laundromatCart)
            }
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    /** Expand and contract the size of the information panel and its content*/
    @objc func expansionButtonPressed(sender: UIButton){
        lightHaptic()
        
        if informationPanelExpanded == false{
            /** Expand*/
            informationPanelExpanded = true
            
            /** Fade these views in*/
            UIView.animate(withDuration: 0.25, delay: 0){[self] in
                operatingHoursLabel.alpha = 1
                openingClosingHoursLabel.alpha = 1
                distanceLabel.alpha = 1
                averageRatings.alpha = 1
                totalReviewsLabel.alpha = 1
                phoneNumberButton.alpha = 1
            }
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){ [self] in
                
                expansionButton.setImage(UIImage(systemName: "chevron.compact.up")?.withTintColor(.white), for: .normal)
                
                informationPanel.frame.size.height = 220
                
                /** If the information panel isn't currently hidden then move the scrollview up to the bottom of it*/
                if scrollView.frame.origin.y != buttonBar.frame.maxY{
                    self.scrollView.frame.origin = CGPoint(x: 0, y: informationPanel.frame.maxY)
                }
                
                nicknameLabel.frame.origin = CGPoint(x: informationPanel.frame.width * 0.05, y: 5)
                
                addressLabel.frame.origin = CGPoint(x: informationPanel.frame.width * 0.05, y: nicknameLabel.frame.maxY + 5)
                
                operatingHoursLabel.frame.origin = CGPoint(x: informationPanel.frame.width * 0.05, y: addressLabel.frame.maxY + 5)
                
                openingClosingHoursLabel.frame.origin = CGPoint(x: operatingHoursLabel.frame.maxX + 5, y: 0)
                openingClosingHoursLabel.center.y = operatingHoursLabel.center.y
                
                distanceLabel.frame.origin = CGPoint(x: openingClosingHoursLabel.frame.maxX + 5, y: 0)
                distanceLabel.center.y = openingClosingHoursLabel.center.y
                
                averageRatings.frame.origin = CGPoint(x: informationPanel.frame.maxX - (averageRatings.frame.width * 1.15), y: openingClosingHoursLabel.frame.maxY + 5)
                
                /** Have a little overlap with the average ratings view*/
                totalReviewsLabel.frame.origin = CGPoint(x: averageRatings.frame.minX - (totalReviewsLabel.frame.width * 0.9), y: 0)
                totalReviewsLabel.center.y = averageRatings.center.y
                
                phoneNumberButton.frame.origin = CGPoint(x: informationPanel.frame.width * 0.05, y: 0)
                phoneNumberButton.center.y = totalReviewsLabel.center.y
                
                expansionButton.frame.origin = CGPoint(x: 0, y: informationPanel.frame.height - expansionButton.frame.height)
                
                pickUpDropOffSegmentedControl.frame.origin = CGPoint(x: informationPanel.frame.width/2 - pickUpDropOffSegmentedControl.frame.width/2, y: expansionButton.frame.minY - (pickUpDropOffSegmentedControl.frame.height + 5))
            }
        }
        else{
            /** Contract*/
            informationPanelExpanded = false
            
            /** Fade these views out*/
            UIView.animate(withDuration: 0.25, delay: 0){[self] in
                operatingHoursLabel.alpha = 0
                openingClosingHoursLabel.alpha = 0
                distanceLabel.alpha = 0
                averageRatings.alpha = 0
                totalReviewsLabel.alpha = 0
                phoneNumberButton.alpha = 0
            }
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){ [self] in
                expansionButton.setImage(UIImage(systemName: "chevron.compact.down")?.withTintColor(.white), for: .normal)
                
                informationPanel.frame.size.height = 140
                
                /** If the information panel isn't currently hidden then move the scrollview up to the bottom of it*/
                if scrollView.frame.origin.y != buttonBar.frame.maxY{
                    self.scrollView.frame.origin = CGPoint(x: 0, y: informationPanel.frame.maxY)
                }
                
                nicknameLabel.frame.origin = CGPoint(x: informationPanel.frame.width * 0.05, y: 5)
                
                addressLabel.frame.origin = CGPoint(x: informationPanel.frame.width * 0.05, y: nicknameLabel.frame.maxY + 5)
                
                expansionButton.frame.origin = CGPoint(x: 0, y: informationPanel.frame.height - expansionButton.frame.height)
                
                pickUpDropOffSegmentedControl.frame.origin = CGPoint(x: informationPanel.frame.width/2 - pickUpDropOffSegmentedControl.frame.width/2, y: expansionButton.frame.minY - (pickUpDropOffSegmentedControl.frame.height + 5))
            }
        }
        
        /** Layout these subviews*/
        
        
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
    
    /** Cart delegate methods*/
    func cart(_ cart: Cart, didAdd item: OrderItem) {
        ///print("Item Added")
        
        updateViewCartButtonLabel()
    }
    
    func cart(_ cart: Cart, didRemove item: OrderItem) {
        ///print("Item Removed")
        
        updateViewCartButtonLabel()
    }
    
    /** Push any updates to this cart */
    func cart(_ cart: Cart, didUpdate item: OrderItem) {
        updateViewCartButtonLabel()
        
        updateThisCart(cart: cart)
    }
    /** Cart delegate methods*/
    
    /** Tableview delegate methods*/
    /** Provide a custom view for the header of the given section*/
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        var view: UIView? = nil
        
        if tableView == washingMenuTableView{
            let container = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: tableViewHeaderHeight))
            container.backgroundColor = .clear
            container.clipsToBounds = true
            
            /** Describe the name of this category*/
            let categoryLabel = UILabel()
            categoryLabel.frame = CGRect(x: 0, y: 0, width: container.frame.width * 0.95, height: container.frame.height/2)
            categoryLabel.font = getCustomFont(name: .Bungee_Regular, size: 22, dynamicSize: true)
            categoryLabel.textColor = appThemeColor
            categoryLabel.adjustsFontForContentSizeCategory = true
            categoryLabel.adjustsFontSizeToFitWidth = true
            categoryLabel.textAlignment = .left
            categoryLabel.text = sortedWashingMenuCategories[section]
            categoryLabel.sizeToFit()
            
            /** Layout subviews*/
            categoryLabel.frame.origin = CGPoint(x: container.frame.width * 0.05, y: container.frame.height/2 - categoryLabel.frame.height/2)
            
            container.addSubview(categoryLabel)
            
            view = container
        }
        else if tableView == dryCleaningMenuTableView{
            let container = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: tableViewHeaderHeight))
            container.backgroundColor = .clear
            container.clipsToBounds = true
            
            /** Describe the name of this category*/
            let categoryLabel = UILabel()
            categoryLabel.frame = CGRect(x: 0, y: 0, width: container.frame.width * 0.95, height: container.frame.height/2)
            categoryLabel.font = getCustomFont(name: .Bungee_Regular, size: 22, dynamicSize: true)
            categoryLabel.textColor = appThemeColor
            categoryLabel.adjustsFontForContentSizeCategory = true
            categoryLabel.adjustsFontSizeToFitWidth = true
            categoryLabel.textAlignment = .left
            categoryLabel.text = sortedDryCleaningMenuCategories[section]
            categoryLabel.sizeToFit()
            
            /** Layout subviews*/
            categoryLabel.frame.origin = CGPoint(x: container.frame.width * 0.05, y: container.frame.height/2 - categoryLabel.frame.height/2)
            
            container.addSubview(categoryLabel)
            
            view = container
        }
        else if tableView == searchTableView{
            if filterWashingMenu == true{
                let container = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: tableViewHeaderHeight))
                container.backgroundColor = .clear
                container.clipsToBounds = true
                
                /** Describe the name of this category*/
                let categoryLabel = UILabel()
                categoryLabel.frame = CGRect(x: 0, y: 0, width: container.frame.width * 0.95, height: container.frame.height/2)
                categoryLabel.font = getCustomFont(name: .Bungee_Regular, size: 22, dynamicSize: true)
                categoryLabel.textColor = appThemeColor
                categoryLabel.adjustsFontForContentSizeCategory = true
                categoryLabel.adjustsFontSizeToFitWidth = true
                categoryLabel.textAlignment = .left
                
                for (index, pair) in filteredItems.enumerated(){
                    if section == index{
                        categoryLabel.text = pair.key
                    }
                }
                
                categoryLabel.sizeToFit()
                
                /** Layout subviews*/
                categoryLabel.frame.origin = CGPoint(x: container.frame.width * 0.025, y: container.frame.height/2 - categoryLabel.frame.height/2)
                
                container.addSubview(categoryLabel)
                
                view = container
            }
            else if filterDryCleaningMenu == true{
                let container = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: tableViewHeaderHeight))
                container.backgroundColor = .clear
                container.clipsToBounds = true
                
                /** Describe the name of this category*/
                let categoryLabel = UILabel()
                categoryLabel.frame = CGRect(x: 0, y: 0, width: container.frame.width * 0.95, height: container.frame.height/2)
                categoryLabel.font = getCustomFont(name: .Bungee_Regular, size: 22, dynamicSize: true)
                categoryLabel.textColor = appThemeColor
                categoryLabel.adjustsFontForContentSizeCategory = true
                categoryLabel.adjustsFontSizeToFitWidth = true
                categoryLabel.textAlignment = .left
                
                for (index, pair) in filteredItems.enumerated(){
                    if section == index{
                        categoryLabel.text = pair.key
                    }
                }
                
                categoryLabel.sizeToFit()
                
                /** Layout subviews*/
                categoryLabel.frame.origin = CGPoint(x: container.frame.width * 0.025, y: container.frame.height/2 - categoryLabel.frame.height/2)
                
                container.addSubview(categoryLabel)
                
                view = container
            }
        }
        
        return view
    }
    
    /** Detect when a user selects a row in the tableview*/
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        /** Present the detail views for the following cells*/
        if tableView == washingMenuTableView{
            lightHaptic()
            
            guard laundromatCart != nil && washingMenu != nil else {
                return
            }
            
            /** Fetch the cell at the given index path without dequeuing it and destroying its stored data*/
            let tableViewCell = tableView.cellForRow(at: indexPath) as! OrderItemTableViewCell
            
            let vc = OrderItemDetailVC(itemData: tableViewCell.itemData, laundromatCart: self.laundromatCart, laundromatMenu: washingMenu!)
            vc.presentingTableView = washingMenuTableView
            
            /** Prevent the user from using interactive dismissal*/
            vc.isModalInPresentation = true
            self.show(vc, sender: self)
        }
        
        if tableView == dryCleaningMenuTableView{
            lightHaptic()
            
            guard laundromatCart != nil && dryCleaningMenu != nil else {
                return
            }
            
            let tableViewCell = tableView.cellForRow(at: indexPath) as! OrderItemTableViewCell
            
            let vc = OrderItemDetailVC(itemData: tableViewCell.itemData, laundromatCart: self.laundromatCart, laundromatMenu: dryCleaningMenu!)
            vc.presentingTableView = dryCleaningMenuTableView
            
            /** Prevent the user from using interactive dismissal*/
            vc.isModalInPresentation = true
            self.show(vc, sender: self)
        }
        
        if tableView == searchTableView{
            lightHaptic()
            
            guard laundromatCart != nil && washingMenu != nil else {
                return
            }
            
            /** Fetch the cell at the given index path without dequeuing it and destroying its stored data*/
            let tableViewCell = tableView.cellForRow(at: indexPath) as! OrderItemSearchTableViewCell
            
            var laundromatMenu = washingMenu!
            if filterWashingMenu == true{
                laundromatMenu = washingMenu!
            }
            else if filterDryCleaningMenu == true{
                laundromatMenu = dryCleaningMenu!
            }
            
            let vc = OrderItemDetailVC(itemData: tableViewCell.itemData, laundromatCart: self.laundromatCart, laundromatMenu: laundromatMenu)
            
            if filterWashingMenu == true || filterDryCleaningMenu == true{
                vc.presentingTableView = searchTableView
            }
            
            /** Prevent the user from using interactive dismissal*/
            vc.isModalInPresentation = true
            self.show(vc, sender: self)
        }
    }
    
    /**Here we pass the table view all of the data for the cells*/
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        var cell = UITableViewCell()
        
        /** Identify the tableview in question*/
        if tableView == washingMenuTableView{
            
            let tableViewCell = tableView.dequeueReusableCell(withIdentifier: OrderItemTableViewCell.identifier, for: indexPath) as! OrderItemTableViewCell
            
            if washingMenu != nil{
                /** Get the category for this section and use this to pin-point the array of items associated with this section*/
                var category = ""
                category = sortedWashingMenuCategories[indexPath.section]
                
                let items = washingMenuCategorySections[category]
                if items != nil{
                    /** Avoid going out of bounds*/
                    if indexPath.row < items!.count{
                        tableViewCell.create(with: items![indexPath.row], cart: laundromatCart)
                        tableViewCell.presentingVC = self
                        tableViewCell.presentingTableView = washingMenuTableView
                        
                        tableViewCell.updateBorder()
                    }
                }
            }
            else{
                /** Inform the user that no menu of this type exists for this laundromat*/
            }
            
            cell = tableViewCell
        }
        else if tableView == dryCleaningMenuTableView{
            let tableViewCell = tableView.dequeueReusableCell(withIdentifier: OrderItemTableViewCell.identifier, for: indexPath) as! OrderItemTableViewCell
            
            if dryCleaningMenu != nil{
                /** Get the category for this section and use this to pin-point the array of items associated with this section*/
                var category = ""
                category = sortedDryCleaningMenuCategories[indexPath.section]
                
                let items = dryCleaningMenuCategorySections[category]
                if items != nil{
                    /** Avoid going out of bounds*/
                    if indexPath.row < items!.count{
                        tableViewCell.create(with: items![indexPath.row], cart: laundromatCart)
                        tableViewCell.presentingVC = self
                        tableViewCell.presentingTableView = dryCleaningMenuTableView
                        
                        tableViewCell.updateBorder()
                    }
                }
            }
            else{
                /** Inform the user that no menu of this type exists for this laundromat*/
            }
            
            cell = tableViewCell
        }
        else if tableView == searchTableView{
            if filterWashingMenu == true{
                let tableViewCell = tableView.dequeueReusableCell(withIdentifier: OrderItemSearchTableViewCell.identifier, for: indexPath) as! OrderItemSearchTableViewCell
                
                if washingMenu != nil{
                    /** Get the category for this section and use this to pin-point the array of items associated with this section*/
                    var category = ""
                    
                    /** Match the indexPath's section up with the index of a pair in the filtered dictionary*/
                    for (index, pair) in filteredItems.enumerated(){
                        if indexPath.section == index{
                            category = pair.key
                        }
                    }
                    
                    let items = filteredItems[category]
                    if items != nil{
                        /** Avoid going out of bounds*/
                        if indexPath.row < items!.count{
                            tableViewCell.create(with: items![indexPath.row], cart: laundromatCart)
                            tableViewCell.presentingVC = self
                            tableViewCell.presentingTableView = searchTableView
                            
                            tableViewCell.updateBorder()
                        }
                    }
                }
                else{
                    /** Inform the user that no menu of this type exists for this laundromat*/
                }
                
                cell = tableViewCell
            }
            else if filterDryCleaningMenu == true{
                let tableViewCell = tableView.dequeueReusableCell(withIdentifier: OrderItemSearchTableViewCell.identifier, for: indexPath) as! OrderItemSearchTableViewCell
                
                if dryCleaningMenu != nil{
                    /** Get the category for this section and use this to pin-point the array of items associated with this section*/
                    var category = ""
          
                    /** Match the indexPath's section up with the index of a pair in the filtered dictionary*/
                    for (index, pair) in filteredItems.enumerated(){
                        if indexPath.section == index{
                            category = pair.key
                        }
                    }
                    
                    let items = filteredItems[category]
                    if items != nil{
                        /** Avoid going out of bounds*/
                        if indexPath.row < items!.count{
                            tableViewCell.create(with: items![indexPath.row], cart: laundromatCart)
                            tableViewCell.presentingVC = self
                            tableViewCell.presentingTableView = searchTableView
                            
                            tableViewCell.updateBorder()
                        }
                    }
                }
                else{
                    /** Inform the user that no menu of this type exists for this laundromat*/
                }
                
                cell = tableViewCell
            }
        }
        else if tableView == shimmeringTableView_1 || tableView == shimmeringTableView_2{
            let tableViewCell = tableView.dequeueReusableCell(withIdentifier: ShimmeringTableViewCell.identifier, for: indexPath) as! ShimmeringTableViewCell
            
            var color = UIColor.lightGray
            if darkMode == true{
                color = UIColor.darkGray
            }
            
            tableViewCell.create(with: color, duration: 2)
            
            cell = tableViewCell
        }
        
        return cell
    }
    
    /** Sort the category strings in descending order from A-Z*/
    func sortCategoriesInDescendingOrder(){
        /** Store all of the keys and sort them in descending order*/
        sortedWashingMenuCategories.removeAll()
        sortedDryCleaningMenuCategories.removeAll()
        for (key, _) in washingMenuCategorySections{
            sortedWashingMenuCategories.append(key)
        }
        sortedWashingMenuCategories = sortedWashingMenuCategories.sorted(by: <)
        
        for (key, _) in dryCleaningMenuCategorySections{
            sortedDryCleaningMenuCategories.append(key)
        }
        sortedDryCleaningMenuCategories = sortedDryCleaningMenuCategories.sorted(by: <)
    }
    
    /** Sort the category strings in ascending order from Z-A*/
    func sortCategoriesInAscendingOrder(){
        /** Store all of the keys and sort them in descending order*/
        sortedWashingMenuCategories.removeAll()
        sortedDryCleaningMenuCategories.removeAll()
        for (key, _) in washingMenuCategorySections{
            sortedWashingMenuCategories.append(key)
        }
        sortedWashingMenuCategories = sortedWashingMenuCategories.sorted(by: >)
        
        for (key, _) in dryCleaningMenuCategorySections{
            sortedDryCleaningMenuCategories.append(key)
        }
        sortedDryCleaningMenuCategories = sortedDryCleaningMenuCategories.sorted(by: >)
    }
    
    /** Search through all the items in the washing menu and return a dictionary containing categories and the amount of items in those categories*/
    func computeTotalSectionsForWashingMenuTableView()->[String : [OrderItem]]?{
        var itemsPerCatergory: [String: [OrderItem]]? = nil
        if washingMenu != nil{
            itemsPerCatergory = [:]
            for item in washingMenu!.items{
                /** Initialize the array for the given category string and append each item to the array for that key*/
                if itemsPerCatergory![item.category] == nil{
                    itemsPerCatergory![item.category] = []
                    itemsPerCatergory![item.category]?.append(item)
                }
                else{
                    itemsPerCatergory![item.category]?.append(item)
                }
            }
        }
        
        /** Sort the items from highest to lowest name alphabetically*/
        for (category, items) in itemsPerCatergory!{
            itemsPerCatergory![category] = items.sorted(by: <)
        }
        
        return itemsPerCatergory
    }
    
    /** Search through all the items in the dry cleaning menu and return a dictionary containing categories and the amount of items in those categories*/
    func computeTotalSectionsForDryCleaningMenuTableView()->[String : [OrderItem]]?{
        var itemsPerCatergory: [String: [OrderItem]]? = nil
        if dryCleaningMenu != nil{
            itemsPerCatergory = [:]
            for item in dryCleaningMenu!.items{
                /** Initialize the array for the given category string and append each item to the array for that key*/
                if itemsPerCatergory![item.category] == nil{
                    itemsPerCatergory![item.category] = []
                    itemsPerCatergory![item.category]?.append(item)
                }
                else{
                    itemsPerCatergory![item.category]?.append(item)
                }
            }
        }
        
        /** Sort the items from highest to lowest name alphabetically*/
        for (category, items) in itemsPerCatergory!{
            itemsPerCatergory![category] = items.sorted(by: <)
        }
        
        return itemsPerCatergory
    }
    
    /** Specify the number of sections for the given table view*/
    public func numberOfSections(in tableView: UITableView) -> Int {
        var numberOfSections = 1
        
        if tableView == washingMenuTableView{
            if washingMenuCategorySections.isEmpty == false{
                numberOfSections = washingMenuCategorySections.count
            }
            else{
                numberOfSections = 0
            }
        }
        
        if tableView == dryCleaningMenuTableView{
            if dryCleaningMenuCategorySections.isEmpty == false{
                numberOfSections = dryCleaningMenuCategorySections.count
            }
            else{
                numberOfSections = 0
            }
        }
        
        if tableView == searchTableView{
            if filteredItems.isEmpty == false{
                numberOfSections = filteredItems.count
            }
            else{
                numberOfSections = 0
            }
        }
        
        if tableView == shimmeringTableView_1 || tableView == shimmeringTableView_2{
            /** Specify a random number of sections for these table views*/
            numberOfSections = [3,4,5,6].randomElement()!
        }
        
        return numberOfSections
    }
    
    /**Set the number of rows in the table view*/
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = 0
        
        /** The number of rows in each section is the number of items under each category*/
        if tableView == washingMenuTableView{
            if washingMenuCategorySections.isEmpty == false{
                for (_, pair) in washingMenuCategorySections.enumerated(){
                    if sortedWashingMenuCategories[section] == pair.key{
                        count = pair.value.count
                    }
                }
            }
            else{
                count = 0
            }
        }
        
        if tableView == dryCleaningMenuTableView{
            if dryCleaningMenuCategorySections.isEmpty == false{
                for (_, pair) in dryCleaningMenuCategorySections.enumerated(){
                    if sortedDryCleaningMenuCategories[section] == pair.key{
                        count = pair.value.count
                    }
                }
            }
            else{
                count = 0
            }
        }
        
        /** Display the amount of rows based on the number of matching cases in the filtered items dictionary*/
        if tableView == searchTableView{
            if filteredItems.isEmpty == false{
                if filterWashingMenu == true{
                    /** Organize the sections used the presorted menu categories used for the other tableview*/
                    for (index, pair) in filteredItems.enumerated(){
                        if section == index{
                            count =  pair.value.count
                        }
                    }
                }
                else if filterDryCleaningMenu == true{
                    for (index, pair) in filteredItems.enumerated(){
                        if section == index{
                            count =  pair.value.count
                        }
                    }
                }
            }
            else{
                count = 0
            }
        }
        
        if tableView == shimmeringTableView_1 || tableView == shimmeringTableView_2{
            /** Specify a random number of cells for each section*/
            count = [1,3,4,6].randomElement()!
        }
        
        return count
    }
    
    /** Set the height for the following section headers*/
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        var height:CGFloat  = 0
        
        if tableView == washingMenuTableView || tableView == dryCleaningMenuTableView || tableView == shimmeringTableView_1 || tableView == shimmeringTableView_2 || tableView == searchTableView{
            height = tableViewHeaderHeight
        }
        
        return height
    }
    
    /** Set the height for the following section footers*/
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        var height:CGFloat = 0
        
        if tableView == washingMenuTableView || tableView ==  dryCleaningMenuTableView || tableView == searchTableView{
            height = tableViewFooterHeight
        }
        
        return height
    }
    
    /** Specify the height of the rows for the tableviews*/
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var height: CGFloat = 0
        
        if tableView == washingMenuTableView || tableView == dryCleaningMenuTableView || tableView == shimmeringTableView_1 || tableView == shimmeringTableView_2{
            height = 100
        }
        
        if tableView == searchTableView{
            height = 60
        }
        
        return height
    }
    /** Tableview delegate methods*/
    
    /** Check to see if this laundromat location is on the favorites list*/
    func isFavorited()->Bool{
        var bool = false
        
        for index in 0..<favoriteLaundromats.count(){
            if self.laundromatData.storeID == favoriteLaundromats.nodeAt(index: index)?.value.laundromatID{
                bool = true
            }
        }
        
        return bool
    }
    
    /** Add this laundromat to the favorites list*/
    private func favorite(){
        let favoritedLaundromat = FavoriteLaundromat(creationDate: .now, laundromatID: self.laundromatData.storeID)
        favoritedLaundromat.addToFavoriteLaundromats()
    }
    
    /** Remove this laundromat from the favorites list*/
    private func unFavorite(){
        for index in 0..<favoriteLaundromats.count(){
            if self.laundromatData.storeID == favoriteLaundromats.nodeAt(index: index)?.value.laundromatID{
                favoriteLaundromats.nodeAt(index: index)?.value.removeFromFavoriteLaundromats()
            }
        }
    }
    
    /** Favorite this laundromat location*/
    @objc func favoriteButtonPressed(sender: LottieButton){
        successfulActionShake()
        
        if favorited == false{
            /** Start the animation and go to the middle since the middle is the 'complete' state and the end is the 'initial state'*/
            sender.playAnimation(from: 0, to: 70, with: .playOnce, animationSpeed: 2.5)
            favorited = true
            /** Add to favorites list and save updated record*/
            favorite()
            
            globallyTransmit(this: "Added to favorites", with: UIImage(systemName: "heart.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: appThemeColor, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 2, selfDismiss: true)
        }
        else{
            /** Complete the animation since it reverses at the end anyways*/
            sender.playAnimation(from: 70, to: 125, with: .playOnce, animationSpeed: 2.5)
            favorited = false
            /** Remove from favorites list and save updated record*/
            unFavorite()
            
            globallyTransmit(this: "Removed from favorites", with: UIImage(systemName: "heart.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 2, selfDismiss: true)
        }
    }
    
    /** Call the phone number of the Stuy Wash N Dry location associated with this data*/
    @objc func phoneNumberButtonPressed(sender: UIButton){
        lightHaptic()
        
        guard let number = URL(string: "tel://" + String(laundromatData.phoneNumber.nationalNumber)) else { return }
        UIApplication.shared.open(number)
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        false
    }
    
    /** Open the tapped address in the maps app*/
    @objc func addressLabelTapped(sender: UITapGestureRecognizer){
        lightHaptic()
        
        displayMapOptionAlert()
    }
    
    /** Display an alert that gives the user the option to open up the available coordinates for the laundromat location in either google maps or apple maps (default)*/
    func displayMapOptionAlert(){
        let alert = UIAlertController(title: "Choose a map", message: "Which app would you like to use to find this address?", preferredStyle: .actionSheet)
        
        /** Open the address in Apple maps (if available)*/
        let appleMaps = UIAlertAction(title: "Apple Maps", style: .default, handler: { [weak self] (action) in
            /**Capture self to avoid retain cycles*/
            guard let self = self else{
                return
            }
            
            if (UIApplication.shared.canOpenURL(URL(string:"http://maps.apple.com/")!)) {
                guard let location = URL(string: "http://maps.apple.com/?daddr=" + "\(self.laundromatData.coordinates.latitude),\(self.laundromatData.coordinates.longitude)") else { return }
                
                UIApplication.shared.open(location)
            }
            else{
                /** Can't open that URL, app not available*/
                globallyTransmit(this: "Apple Maps is unavailable", with: UIImage(systemName: "globe.americas.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
            }
        })
        
        /** Open the address in google maps (if available)*/
        let googleMaps = UIAlertAction(title: "Google Maps", style: .default, handler: { [weak self] (action) in
            /**Capture self to avoid retain cycles*/
            guard let self = self else{
                return
            }
            
            if (UIApplication.shared.canOpenURL(URL(string:"https://www.google.com/maps/")!)) {
                guard let location = URL(string: "https://www.google.com/maps/?center=\(self.laundromatData.coordinates.latitude),\(self.laundromatData.coordinates.longitude)&zoom=15&views=traffic&q=\(self.laundromatData.address.streetAddress1.replacingOccurrences(of: " ", with: "+"))") else { return }
                
                UIApplication.shared.open(location)
            }
            else{
                /** Can't open that URL, app not available*/
                globallyTransmit(this: "Google Maps is unavailable", with: UIImage(systemName: "globe.americas.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
            }
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(appleMaps)
        alert.addAction(googleMaps)
        
        alert.addAction(cancelAction)
        alert.preferredAction = appleMaps
        
        self.present(alert, animated: true)
    }
    
    /** Location Manager Delegate methods*/
    /**Handle incoming location events*/
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations.last!
        
        /** Store the location of the laundromat as a coordinate point by unwrapping its Geopoint coordinate*/
        let storeLocation = CLLocation(latitude: (self.laundromatData.coordinates.latitude), longitude: (self.laundromatData.coordinates.longitude))
        
        /** Compute the distance between the two coordinates (in meters)*/
        let distance = location.distance(from: storeLocation)
        
        /** Convert to miles (b/c America)*/
        let distanceInMiles = getMiles(from: CGFloat(distance))
        
        /** Append a little emoji on to the end of the string depending on how far the user is from the location*/
        var distanceEmoji = ""
        if distanceInMiles <= 1.5{
            distanceEmoji = "🚶"
        }
        else if distanceInMiles > 1.5 && distanceInMiles <= 3{
            distanceEmoji = "🚴"
        }
        else if distanceInMiles > 3 && distanceInMiles <= 4{
            distanceEmoji = "🚇"
        }
        else if distanceInMiles > 4 && distanceInMiles <= 200{
            distanceEmoji = "🚘"
        }
        else{
            distanceEmoji = "✈️"
        }
        
        distanceLabel.text = "•  " + abbreviateMiles(miles: distanceInMiles, feetAbbreviation: "ft", milesAbbreviation: "mi") + " \(distanceEmoji)"
        distanceLabel.sizeToFit()
        
        distanceLabel.frame.origin = CGPoint(x: openingClosingHoursLabel.frame.maxX + 5, y: 0)
        distanceLabel.center.y = openingClosingHoursLabel.center.y
    }
    
    /**Handle location manager errors*/
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        locationManager.stopUpdatingLocation()
        
        print("Error: \(error)")
        
    }
    
    /**Handle authorization for the location manager.*/
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        /**Check accuracy authorization*/
        let accuracy = manager.accuracyAuthorization
        switch accuracy {
        case .fullAccuracy:
            print("Location accuracy is precise.")
        case .reducedAccuracy:
            print("Location accuracy is not precise.")
        @unknown default:
            fatalError()
        }
        
        /**Handle authorization status*/
        switch status {
        case .restricted:
            print("Location access was restricted.")
        case .denied:
            print("User denied access to location.")
            /**Display the map using the default location*/
            mapView.isHidden = false
        case .notDetermined:
            print("Location status not determined.")
        case .authorizedAlways: fallthrough
        case .authorizedWhenInUse:
            print("Location status is OK.")
        @unknown default:
            fatalError()
        }
    }
    /** Location Manager Delegate methods*/
    
    /** Story board implementation*/
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
