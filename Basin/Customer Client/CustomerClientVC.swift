//
//  CustomerClientVC.swift
//  Stuy Wash N Dry
//
//  Created by Justin Cook on 3/3/22.
//

import UIKit
import Firebase
import FirebaseAnalytics
import Lottie
import GoogleMaps
import GooglePlaces
import SwiftUI
import Nuke
import Network
import AppTrackingTransparency
import AdSupport

/** View controller that hosts all customer client side operations*/
class CustomerClientVC: UIViewController, CLLocationManagerDelegate, UITextFieldDelegate, GMSMapViewDelegate, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, JCTabbarDelegate{
    
    /** User UI*/
    /** Store a reference to the user's profile picture image stored in the button view in the search bar textfield*/
    var userProfilePicture: UIImage? = nil
    
    /** Google map UI*/
    /** A UIView that acts a snapshot of the map at a specific point in time, this is used as a placeholder view when the map view is deinitialized for memory management after the user goes to the background*/
    var mapViewSnapShot: UIView? = nil
    /** UIView to contain the mapview, this isn't necessary but might be used later for a placeholder view of some sort to display while the map loads initially*/
    var mapContainer: UIView = UIView()
    /** Little label that welcomes the user, tells them good morning and or goodnight depending on the time of day etc*/
    var welcomeLabelShadowView: UIView = UIView()
    var welcomeLabel: PaddedLabel = PaddedLabel(withInsets: 1, 1, 10, 10)
    /** Weather timer that fires every 20 minutes to update the current weather*/
    var weatherTimer: Timer? = nil
    /** View that displays information about the current weather to the user*/
    var weatherView: minimalWeatherView = minimalWeatherView()
    /** Custom UIButton used to zoom into the user's current location*/
    var currentLocationButton = UIButton()
    /** Button used to navigate to the support chat VC where the user can chat with a customer service representative*/
    var customerSupportButton = UIButton()
    /** Button used to navigate to the shopping cart screen where the user can then make their order*/
    var shoppingCartButton = UIButton()
    var mapView: GMSMapView!
    var camera: GMSCameraPosition = GMSCameraPosition()
    var mapMarker: GMSMarker = GMSMarker()
    /** Array of map markers that represent the locations of Stuy Wash N Dry laundromats*/
    var mapMarkers: [GMSMarker : Laundromat] = [:]
    /** Map containing a marker icon view and an marker that acts a key for that view*/
    var mapMarkerIconViews: [GMSMarker : LaundromatIconView] = [:]
    var laundromatLocations: [CLLocationCoordinate2D] = []
    /** Store the current map marker that the user has selected*/
    var currentlySelectedMapMarker: GMSMarker? = nil
    /** Google map UI*/
    
    /** Location Management*/
    var locationManager: CLLocationManager!
    var currentLocation: CLLocation?
    var placesClient: GMSPlacesClient!
    /** Various zoom levels from closest to farthest (0)*/
    var streetLevelZoomLevel: Float = 19.0
    var preciseLocationZoomLevel: Float = 15.0
    var approximateLocationZoomLevel: Float = 12.5
    /**An array to hold the list of likely places*/
    var likelyPlaces: [GMSPlace] = []
    /**The currently selected place*/
    var selectedPlace: GMSPlace?
    /** Location Management*/
    
    /** Custom search bar UI*/
    var searchBar: UITextField = UITextField()
    var searchBarContainer: UIView = UIView()
    var searchBarLeftViewButton = UIButton()
    var searchBarRightViewButton = UIButton()
    /** Custom search bar UI*/
    
    /** Bottom Sheet UI*/
    var bottomSheet: DetentedBottomSheetView!
    var laundromatLocationsTableView: UITableView!
    var laundromatLocationsCollectionView: UICollectionView!
    var locationSortingButton: UIButton!
    /** The default option*/
    var sortingByDistance = true
    var sortingByRatings = false
    var sortingByReviews = false
    /** The default sorting direction, allows user to sort from highest to lowest with only one button*/
    var highestToLowestSortingByDistance = false
    var highestToLowestSortingByRatings = true
    var highestToLowestSortingByReviews = true
    /** Refresh control object for the bottom sheet table view*/
    var bottomSheetRefreshControl = LottieRefreshControl()
    
    /** Orders tab UI*/
    var ordersTableView: UITableView!
    var ordersBottomSheet: DetentedBottomSheetView!
    /** UI Label displaying styled text above the orders bottom sheet*/
    var ordersTitleLabel: UILabel!
    /** Refresh control object for the bottom sheet table view*/
    var ordersBottomSheetRefreshControl = LottieRefreshControl()
    /** Array that controls the amount of rows displayed for each section with 1 section with a row value of 0 being a closed section at instantiation*/
    var rowsForSection = [5,20]
    /** Image views with a chevron image denoting the current state of the section, whether it's expanded or collapsed*/
    var imageViewsForSection = [UIImageView(),UIImageView()]
    
    /** Account tab UI*/
    var accountBottomSheet: DetentedBottomSheetView!
    
    /** Fetched laundromat locations from the database*/
    var laundromats: [Laundromat] = []
    
    /** Custom tabbar UI*/
    var customTabbar: JCTabbar!
    /** Buttons to be added to the custom tabbar*/
    var homeButton: JCTabbarItem!
    var ordersButton: JCTabbarItem!
    var accountButton: JCTabbarItem!
    var notificationsButton: JCTabbarItem!
    /** Differentiate between the different tabs*/
    var homeTabSelected: Bool = true
    var ordersTabSelected: Bool = false
    var accountTabSelected: Bool = false
    
    /** Monitor network conditions for changes in order to load data after an internet connection has been established*/
    private var networkMonitor: NWPathMonitor = NWPathMonitor()
    
    /** Request app tracking transparency*/
    func requestIDFA(){
      ATTrackingManager.requestTrackingAuthorization(completionHandler: { status in
          /// Tracking authorization completed. Start loading ads here.
          /// loadAd()
      })
    }
    
    override func viewWillAppear(_ animated: Bool){
    }
    
    /** Set up notifications from app delegate to know when the app goes to or from the background state*/
    func setNotificationCenter(){
        let notifCenter = NotificationCenter.default
        notifCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        notifCenter.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        notifCenter.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        notifCenter.addObserver(self, selector: #selector(appIsInBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    @objc func appMovedToBackground(){
        /** Clear the previous snapshot from the view hierarchy to prevent layering stale snapshots*/
        clearMapViewSnapshotRT()
        addMapViewSnapshot()
    }
    
    @objc func appMovedToForeground(){
    }
    
    /** Activates when the application regains focus*/
    @objc func appDidBecomeActive(){
        /** Remove the snapshot when the app becomes focused again*/
        ///clearMapViewSnapshotAsync()
    }
    
    /** Activates when app is fully in the background state*/
    @objc func appIsInBackground(){
    }
    
    /** Add a snapshot of the mapview to its view hierarchy when the application changes states as the mapview can't be rendered in the background due to memory management requirements*/
    func addMapViewSnapshot(){
        guard mapView != nil else {
            return
        }
        
        mapViewSnapShot = mapView.snapshotView(afterScreenUpdates: false)
        
        guard mapViewSnapShot != nil else {
            return
        }
        
        mapView.addSubview(mapViewSnapShot!)
    }
    
    /** Remove the snapshot UIView on top of the map view on the main thread*/
    func clearMapViewSnapshotRT(){
        guard mapView != nil else {
            return
        }
        
        if let _ = mapViewSnapShot{
            self.mapViewSnapShot!.removeFromSuperview()
            self.mapViewSnapShot = nil
        }
    }
    
    /** Remove the snapshot UIView on top of the map view asynchronously to provide a slight update delay*/
    func clearMapViewSnapshotAsync(){
        guard mapView != nil else {
            return
        }
        
        if let _ = mapViewSnapShot{
            DispatchQueue.main.async{
                self.mapViewSnapShot!.removeFromSuperview()
                self.mapViewSnapShot = nil
            }
        }
    }
    
    /** When the map's current tiles finish rendering then remove any snapshots from the view hierarchy**/
    func mapViewDidFinishTileRendering(_ mapView: GMSMapView){
        clearMapViewSnapshotAsync()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        /** Specify a maximum font size*/
        self.view.maximumContentSizeCategory = .large
        
        addCustomTabbar()
        addVisualSingleTapGestureRecognizer()
        configure()
        createUI()
        getLaundromatData()
        setNotificationCenter()
        requestIDFA()
    }
    
    /** Detect which button has been pressed and respond accordingly*/
    func JCtabbar(_ tabbar: JCTabbar, didSelect item: JCTabbarItem){
        switch item{
        case homeButton:
            homeButtonSelected()
        case ordersButton:
            ordersButtonSelected()
        case accountButton:
            accountButtonSelected()
        default:
            break
        }
    }
    
    /** Switch between these different states depending on which button was pressed*/
    func homeButtonSelected(){
        homeTabSelected = true
        ordersTabSelected = false
        accountTabSelected = false
        
        guard bottomSheet != nil && laundromatLocationsCollectionView != nil && mapView != nil else {
            return
        }
        
        /** Need these buttons on this screen*/
        showCurrentLocationButton(animated: true)
        showCustomerSupportButton(animated: true)
        showShoppingCartButton(animated: true)
        showWeatherView(animated: true)
        /** Shift the button back to its original position*/
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
            shoppingCartButton.frame.origin = CGPoint(x: self.view.frame.maxX - (shoppingCartButton.frame.width * 1.25), y: customerSupportButton.frame.maxY + 10)
        }
        
        
        /** Don't need these buttons on this screen*/
        hideOrdersTitleLabel(animated: true)
        
        /** The map is interactive in this tab*/
        mapView.isUserInteractionEnabled = true
        /** Zoom into the user's current location at a normal distance*/
        if mapView.myLocation != nil{
            currentLocationButtonPressed(sender: currentLocationButton)
        }
        
        /** Change the context of the search bar*/
        searchBar.attributedPlaceholder = NSAttributedString(string:"Search for a laundromat", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        bottomSheet.show(animated: true)
        ordersBottomSheet.hide(animated: true)
        accountBottomSheet.hide(animated: true)
        hideCollectionView()
    }
    
    /** Switch to the orders tab*/
    func ordersButtonSelected(){
        homeTabSelected = false
        ordersTabSelected = true
        accountTabSelected = false
        
        guard bottomSheet != nil && laundromatLocationsCollectionView != nil && mapView != nil else {
            return
        }
        
        /** Don't need these buttons on this screen*/
        hideCurrentLocationButton(animated: true)
        hideWelcomeLabel(animated: true)
        hideCustomerSupportButton(animated: true)
        hideWeatherView(animated: true)
        
        /** Need these views on this screen*/
        showOrdersTitleLabel(animated: true)
        showShoppingCartButton(animated: true)
        /** Shift the button back to a new position in line with the title label*/
        if ordersTitleLabel != nil{
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
                shoppingCartButton.frame.origin = CGPoint(x: self.view.frame.maxX - (shoppingCartButton.frame.width * 1.25), y: 0)
                shoppingCartButton.center.y = ordersTitleLabel.center.y
            }
        }
        
        /** Change the context of the search bar*/
        searchBar.attributedPlaceholder = NSAttributedString(string:"Search for orders", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        /** The map is just for visual effects in this tab*/
        mapView.isUserInteractionEnabled = false
        /** Zoom into the user's current location to create a cool effect*/
        if mapView.myLocation != nil{
            let location = mapView.myLocation!
            
            /** Zoom in to the user's current location (if available) (Animated), very very close*/
            let position = GMSCameraPosition(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: streetLevelZoomLevel, bearing: mapView.camera.bearing, viewingAngle: 70)
            
            /** Specify the animation duration of the camera position update animation*/
            CATransaction.begin()
            CATransaction.setValue(0.5, forKey: kCATransactionAnimationDuration)
            mapView.animate(to: position)
            CATransaction.commit()
            
            /** Very cool rotating animation*/
            CATransaction.begin()
            CATransaction.setValue(3, forKey: kCATransactionAnimationDuration)
            mapView.animate(toBearing: 300)
            CATransaction.commit()
            
        }
        
        bottomSheet.hide(animated: true)
        ordersBottomSheet.show(animated: true)
        accountBottomSheet.hide(animated: true)
        hideCollectionView()
    }
    
    /** Switch to the account tab*/
    func accountButtonSelected(){
        homeTabSelected = false
        ordersTabSelected = false
        accountTabSelected = true
        
        guard bottomSheet != nil && laundromatLocationsCollectionView != nil && mapView != nil else {
            return
        }
        
        /** Don't need these buttons on this screen*/
        hideCurrentLocationButton(animated: true)
        hideWelcomeLabel(animated: true)
        hideCustomerSupportButton(animated: true)
        hideShoppingCartButton(animated: true)
        hideWeatherView(animated: true)
        hideOrdersTitleLabel(animated: true)
        /*
         /** Shift the button back to its original position*/
         UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
         shoppingCartButton.frame.origin = CGPoint(x: self.view.frame.maxX - (shoppingCartButton.frame.width * 1.25), y: customerSupportButton.frame.maxY + 10)
         }*/
        
        /** The map is not even seen in this tab*/
        mapView.isUserInteractionEnabled = false
        /** Change the context of the search bar*/
        searchBar.attributedPlaceholder = NSAttributedString(string:"Search for options", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        bottomSheet.hide(animated: true)
        ordersBottomSheet.hide(animated: true)
        accountBottomSheet.show(animated: true)
        hideCollectionView()
    }
    /** Switch between these different states depending on which button was pressed*/
    
    /** Create and add the custom tabbar to the view controller's view hierarchy*/
    func addCustomTabbar(){
        self.tabBarController?.tabBar.isHidden = true
        
        /** Force the custom tabbar to have a height the same size as the real tabbar*/
        customTabbar = JCTabbar(height: self.tabBarController?.tabBar.frame.height)
        customTabbar.cornerRadius = 0
        customTabbar.layer.borderWidth = 0
        customTabbar.layer.borderColor = UIColor.lightGray.cgColor
        customTabbar.frame.origin = CGPoint(x: 0, y: self.view.frame.maxY - customTabbar.frame.height)
        customTabbar.overLineEnabled = true
        customTabbar.overlineHeight = 3
        customTabbar.overlineColor = appThemeColor
        customTabbar.overlineTrackColor = .clear
        customTabbar.overlineAnimated = true
        customTabbar.useVisualTaps = true
        customTabbar.visualTapsAccentColor = appThemeColor
        customTabbar.delegate = self
        
        homeButton = JCTabbarItem()
        homeButton.title = "Home"
        homeButton.image = UIImage(named: "washing-machine")
        homeButton.tintColor = appThemeColor
        homeButton.selectedTintColor = appThemeColor
        homeButton.notSelectedTintColor = .lightGray
        homeButton.badgeBackgroundColor =  appThemeColor
        homeButton.badgeFontColor = .white
        
        ordersButton = JCTabbarItem()
        ordersButton.title = "Orders"
        ordersButton.image = UIImage(named: "laundry-basket")
        ordersButton.tintColor = appThemeColor
        ordersButton.selectedTintColor = appThemeColor
        ordersButton.notSelectedTintColor = .lightGray
        ordersButton.badgeBackgroundColor =  appThemeColor
        ordersButton.badgeFontColor = .white
        
        accountButton = JCTabbarItem()
        accountButton.title = "Account"
        accountButton.image = UIImage(named: "laundry")
        accountButton.tintColor = appThemeColor
        accountButton.selectedTintColor = appThemeColor
        accountButton.notSelectedTintColor = .lightGray
        accountButton.badgeBackgroundColor =  appThemeColor
        accountButton.badgeFontColor = .white
        
        notificationsButton = JCTabbarItem()
        notificationsButton.title = "Notifications"
        notificationsButton.image = UIImage(named: "drying")
        notificationsButton.tintColor = appThemeColor
        notificationsButton.selectedTintColor = appThemeColor
        notificationsButton.notSelectedTintColor = .lightGray
        notificationsButton.badgeBackgroundColor =  appThemeColor
        notificationsButton.badgeFontColor = .white
        
        customTabbar.shadowEnabled = true
        customTabbar.setShadow(shadowColor: UIColor.lightGray.cgColor, ShadowOpacity: 0.25, ShadowRadius: 4)
        
        customTabbar.tabbarButtons = [homeButton,ordersButton,accountButton,notificationsButton]
        customTabbar.setCurrentlySelectedItem(item: homeButton)
        
        accountButton.frame.origin = CGPoint(x: 200, y: 200)
        
        /** Move the tabbar to the absolute front of all the views in the hierarchy*/
        UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.addSubview(customTabbar)
    }
    
    /** Create the discrete user interface for this view controller*/
    func createUI(){
        welcomeLabel.frame.size = CGSize(width: self.view.frame.width * 0.4, height: 40)
        welcomeLabel.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: true)
        welcomeLabel.backgroundColor = bgColor
        welcomeLabel.textColor = fontColor
        welcomeLabel.textAlignment = .center
        welcomeLabel.adjustsFontForContentSizeCategory = true
        welcomeLabel.adjustsFontSizeToFitWidth = true
        welcomeLabel.layer.cornerRadius = welcomeLabel.frame.height/2
        welcomeLabel.layer.masksToBounds = true
        welcomeLabel.text = "Good \(whatTimeOfDayIsIt().rawValue) \(getCurrentUser()?.displayName ?? "")"
        
        /** Shadow behind the welcome label*/
        welcomeLabelShadowView.frame = welcomeLabel.frame
        welcomeLabelShadowView.backgroundColor = .clear
        welcomeLabelShadowView.clipsToBounds = false
        welcomeLabelShadowView.layer.cornerRadius = welcomeLabel.layer.cornerRadius
        welcomeLabelShadowView.layer.shadowColor = UIColor.darkGray.cgColor
        welcomeLabelShadowView.layer.shadowOpacity = 0.25
        welcomeLabelShadowView.layer.shadowRadius = 2
        welcomeLabelShadowView.layer.shadowOffset = CGSize(width: 0, height: 2)
        welcomeLabelShadowView.layer.shadowPath = UIBezierPath(roundedRect: welcomeLabelShadowView.bounds, cornerRadius: welcomeLabelShadowView.layer.cornerRadius).cgPath
        
        welcomeLabelShadowView.addSubview(welcomeLabel)
        
        weatherView.frame.size = CGSize(width: self.view.frame.width * 0.3, height: 40)
        switch darkMode{
        case true:
            weatherView.backgroundColor = .black
        case false:
            weatherView.backgroundColor = bgColor
        }
        weatherView.layer.cornerRadius = weatherView.frame.height/2
        weatherView.layer.masksToBounds = true
        weatherView.temperatureUnit = .fahrenheit
        weatherView.alpha = 0
        
        /**Initialize the location manager*/
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        /** Update the user's location every 100 meters (300+ ft)*/
        locationManager.distanceFilter = 100
        locationManager.startUpdatingLocation()
        locationManager.showsBackgroundLocationIndicator = true
        ///locationManager.allowsBackgroundLocationUpdates = false
        locationManager.activityType = .fitness
        locationManager.delegate = self
        
        placesClient = GMSPlacesClient.shared()
        
        /**A default location to use when location permission is not granted.*/
        ///let defaultLocation = CLLocation(latitude: -33.869405, longitude: 151.199)
        
        /** Generic coordinate point in Brooklyn*/
        let coordinate = CLLocationCoordinate2D(latitude: 40.67985516878483, longitude: -73.93747149720345)
        
        let zoomLevel = locationManager.accuracyAuthorization == .fullAccuracy ? preciseLocationZoomLevel : approximateLocationZoomLevel
        camera = GMSCameraPosition.camera(withLatitude: coordinate.latitude, longitude: coordinate.longitude, zoom: zoomLevel)
        
        /** Cloud based map styling*/
        var mapIDString = "f95c619415f25d75"
        switch darkMode {
        case true:
            mapIDString = "a4c677bcbe54c097"
        case false:
            mapIDString = "f95c619415f25d75"
        }
        
        mapContainer.frame = CGRect(origin: .zero, size: CGSize(width: view.frame.width, height: view.frame.height * 1))
        
        mapView = GMSMapView(frame: CGRect(origin: .zero, size: CGSize(width: view.frame.width, height: view.frame.height * 1)), mapID: GMSMapID(identifier: mapIDString), camera: camera)
        mapView.backgroundColor = bgColor
        mapView.settings.myLocationButton = true
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.isMyLocationEnabled = true
        /** Specify a maximum zoom out level to prevent the user from seeing the edges of the map*/
        mapView.setMinZoom(12, maxZoom: 30)
        mapView.settings.myLocationButton = false
        mapView.settings.consumesGesturesInView = false
        mapView.delegate = self
        mapView.layer.isOpaque = false
        
        currentLocationButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        currentLocationButton.frame.size.height = 50
        currentLocationButton.frame.size.width = currentLocationButton.frame.size.height
        currentLocationButton.backgroundColor = appThemeColor
        currentLocationButton.tintColor = .white
        currentLocationButton.setImage(UIImage(systemName: "paperplane.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        currentLocationButton.imageView?.contentMode = .scaleAspectFit
        currentLocationButton.layer.cornerRadius = currentLocationButton.frame.height/2
        currentLocationButton.castDefaultShadow()
        currentLocationButton.layer.shadowColor = UIColor.darkGray.cgColor
        currentLocationButton.isEnabled = true
        currentLocationButton.isExclusiveTouch = true
        currentLocationButton.addTarget(self, action: #selector(currentLocationButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: currentLocationButton)
        
        customerSupportButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        customerSupportButton.frame.size.height = 50
        customerSupportButton.frame.size.width = customerSupportButton.frame.size.height
        customerSupportButton.backgroundColor = bgColor
        customerSupportButton.tintColor = appThemeColor
        customerSupportButton.setImage(UIImage(systemName: "bubble.right.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        customerSupportButton.imageView?.contentMode = .scaleAspectFit
        customerSupportButton.layer.cornerRadius = customerSupportButton.frame.height/2
        customerSupportButton.castDefaultShadow()
        customerSupportButton.layer.shadowColor = UIColor.darkGray.cgColor
        customerSupportButton.isEnabled = true
        customerSupportButton.isExclusiveTouch = true
        customerSupportButton.addTarget(self, action: #selector(customerSupportButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: customerSupportButton)
        
        shoppingCartButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        shoppingCartButton.frame.size.height = 50
        shoppingCartButton.frame.size.width = shoppingCartButton.frame.size.height
        shoppingCartButton.backgroundColor = bgColor
        shoppingCartButton.tintColor = appThemeColor
        shoppingCartButton.setImage(UIImage(systemName: "cart.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        shoppingCartButton.imageView?.contentMode = .scaleAspectFit
        shoppingCartButton.layer.cornerRadius = shoppingCartButton.frame.height/2
        shoppingCartButton.castDefaultShadow()
        shoppingCartButton.layer.shadowColor = UIColor.darkGray.cgColor
        shoppingCartButton.isEnabled = true
        shoppingCartButton.isExclusiveTouch = true
        shoppingCartButton.addTarget(self, action: #selector(shoppingCartButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: shoppingCartButton)
        
        view.addSubview(mapView)
        view.addSubview(currentLocationButton)
        view.addSubview(customerSupportButton)
        view.addSubview(shoppingCartButton)
        view.addSubview(weatherView)
        view.addSubview(welcomeLabelShadowView)
        
        /**Add the map to the view, hide it until we've got a location update.*/
        mapView.isHidden = true
        
        /** Set the initial position of the map to be the user's current location*/
        let currentZoomLevel = locationManager.accuracyAuthorization == .fullAccuracy ? preciseLocationZoomLevel : approximateLocationZoomLevel
        
        let camera = GMSCameraPosition.camera(withLatitude: locationManager.location?.coordinate.latitude ?? coordinate.latitude, longitude: locationManager.location?.coordinate.longitude ?? coordinate.longitude, zoom: currentZoomLevel)
        
        if mapView.isHidden{
            mapView.isHidden = false
            mapView.camera = camera
        } else {
            /** Set the initial position of the map to be the user's current location*/
            mapView.animate(to: camera)
        }
        
        /** Layout these subviews*/
        currentLocationButton.frame.origin = CGPoint(x: self.view.frame.maxX - (currentLocationButton.frame.width * 1.25), y: searchBar.frame.maxY + (currentLocationButton.frame.height * 0.9))
        
        customerSupportButton.frame.origin = CGPoint(x: self.view.frame.maxX - (currentLocationButton.frame.width * 1.25), y: currentLocationButton.frame.maxY + 10)
        
        shoppingCartButton.frame.origin = CGPoint(x: self.view.frame.maxX - (shoppingCartButton.frame.width * 1.25), y: customerSupportButton.frame.maxY + 10)
        
        weatherView.frame.origin.x = welcomeLabelShadowView.frame.width * 0.15
        weatherView.center.y = currentLocationButton.center.y
        
        welcomeLabelShadowView.frame.origin = CGPoint(x: welcomeLabelShadowView.frame.width * 0.15, y: weatherView.frame.maxY + 5)
        
        /** Animate these views appearing*/
        hideCurrentLocationButton(animated: false)
        hideWelcomeLabel(animated: false)
        hideCustomerSupportButton(animated: false)
        hideShoppingCartButton(animated: false)
        hideWeatherView(animated: false)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.25){
            self.showCurrentLocationButton(animated: true)
            self.showWelcomeLabel(animated: true)
            self.showCustomerSupportButton(animated: true)
            self.showShoppingCartButton(animated: true)
            self.showWeatherView(animated: true)
        }
        
        /** Move the welcome label out of the way and move the weather view up to its new origin point where the welcome label was previously*/
        DispatchQueue.main.asyncAfter(deadline: .now() + 3){[self] in
            hideWelcomeLabel(animated: true)
        }
    }
    
    /** Hide the weather view in a static or animated fashion*/
    func hideWeatherView(animated: Bool){
        if animated{
            UIView.animate(withDuration: 0.5, delay: 0.175, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
                self.weatherView.transform = CGAffineTransform(translationX: -self.view.frame.width/2, y: 0)
            }
        }
        else{
            weatherView.transform = CGAffineTransform(translationX: -self.view.frame.width/2, y: 0)
        }
    }
    
    /** Display the weather view in a static or animated fashion*/
    func showWeatherView(animated: Bool){
        if animated{
            UIView.animate(withDuration: 0.5, delay: 0.175, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
                self.weatherView.transform = CGAffineTransform(translationX: 0, y: 0)
            }
        }
        else{
            weatherView.transform = CGAffineTransform(translationX: 0, y: 0)
        }
    }
    
    /** Hide the shopping cart button in a static or animated fashion*/
    func hideShoppingCartButton(animated: Bool){
        if animated{
            UIView.animate(withDuration: 0.5, delay: 0.2, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
                self.shoppingCartButton.transform = CGAffineTransform(translationX: self.shoppingCartButton.frame.width * 2, y: 0)
            }
        }
        else{
            shoppingCartButton.transform = CGAffineTransform(translationX: self.shoppingCartButton.frame.width * 2, y: 0)
        }
    }
    
    /** Display the shopping cart button in a static or animated fashion*/
    func showShoppingCartButton(animated: Bool){
        if animated{
            UIView.animate(withDuration: 0.5, delay: 0.2, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
                self.shoppingCartButton.transform = CGAffineTransform(translationX: 0, y: 0)
            }
        }
        else{
            shoppingCartButton.transform = CGAffineTransform(translationX: 0, y: 0)
        }
    }
    
    /** Hide the customer support button in a static or animated fashion*/
    func hideCustomerSupportButton(animated: Bool){
        if animated{
            UIView.animate(withDuration: 0.5, delay: 0.1, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
                self.customerSupportButton.transform = CGAffineTransform(translationX: self.customerSupportButton.frame.width * 2, y: 0)
            }
        }
        else{
            customerSupportButton.transform = CGAffineTransform(translationX: self.customerSupportButton.frame.width * 2, y: 0)
        }
    }
    
    /** Display the customer support button in a static or animated fashion*/
    func showCustomerSupportButton(animated: Bool){
        if animated{
            UIView.animate(withDuration: 0.5, delay: 0.1, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
                self.customerSupportButton.transform = CGAffineTransform(translationX: 0, y: 0)
            }
        }
        else{
            customerSupportButton.transform = CGAffineTransform(translationX: 0, y: 0)
        }
    }
    
    /** Hide the welcome label in a static or animated fashion*/
    func hideWelcomeLabel(animated: Bool){
        if animated{
            UIView.animate(withDuration: 0.5, delay: 0.15, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
                self.welcomeLabelShadowView.transform = CGAffineTransform(translationX: -self.view.frame.width/2, y: 0)
            }
        }
        else{
            welcomeLabelShadowView.transform = CGAffineTransform(translationX: -self.view.frame.width/2, y: 0)
        }
    }
    
    /** Display the welcome label in a static or animated fashion*/
    func showWelcomeLabel(animated: Bool){
        if animated{
            UIView.animate(withDuration: 0.5, delay: 0.15, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
                self.welcomeLabelShadowView.transform = CGAffineTransform(translationX: 0, y: 0)
            }
        }
        else{
            welcomeLabelShadowView.transform = CGAffineTransform(translationX: 0, y: 0)
        }
    }
    
    /** Hide the current location button in a static or animated fashion*/
    func hideCurrentLocationButton(animated: Bool){
        currentLocationButton.isEnabled = false
        if animated{
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
                self.currentLocationButton.transform = CGAffineTransform(translationX: self.currentLocationButton.frame.width * 2, y: 0)
            }
        }
        else{
            currentLocationButton.transform = CGAffineTransform(translationX: currentLocationButton.frame.width * 2, y: 0)
        }
    }
    
    /** Display the current location button in a static or animated fashion*/
    func showCurrentLocationButton(animated: Bool){
        currentLocationButton.isEnabled = true
        if animated{
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
                self.currentLocationButton.transform = CGAffineTransform(translationX: 0, y: 0)
            }
        }
        else{
            currentLocationButton.transform = CGAffineTransform(translationX: 0, y: 0)
        }
    }
    
    /** Add the markers to the map*/
    func addMarkers(){
        /** Make sure there are in fact laundromats to be added to the map as markers*/
        guard laundromats.isEmpty == false else {
            return
        }
        
        /** Specify the locations of the laundromats*/
        for laundromat in laundromats{
            let coordinatePoint = CLLocationCoordinate2D(latitude: laundromat.coordinates.latitude, longitude: laundromat.coordinates.longitude)
            
            laundromatLocations.append(coordinatePoint)
        }
        
        for (index, location) in laundromatLocations.enumerated(){
            let mapMarker = GMSMarker(position: location)
            mapMarker.title = ""
            mapMarker.map = mapView
            mapMarker.appearAnimation = .pop
            
            /** Custom marker icon views*/
            mapMarkerIconViews[mapMarker] = LaundromatIconView(image: UIImage(named: "StuyWashNDryCutSVGLogo")!, title: laundromats[index].nickName)
            
            mapMarkerIconViews[mapMarker]!.imageView.backgroundColor = appThemeColor
            /** Fill the map marker dictionary up, the indexes are the same bounds so no worry*/
            mapMarkers[mapMarker] = laundromats[index]
            
            mapMarker.iconView = mapMarkerIconViews[mapMarker]
            mapMarker.isTappable = true
        }
        
        /** Animate the marker icon views appearing after a slight delay*/
        for pair in mapMarkerIconViews{
            let view = pair.value.shadowView
            
            view.transform = CGAffineTransform(scaleX: 0.0001, y: 0.0001)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2){[self] in
            for pair in mapMarkerIconViews{
                let view = pair.value.shadowView
                
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
                    view.transform = CGAffineTransform(scaleX: 1, y: 1)
                }
            }
        }
    }
    
    /** Fetch the data for the laundromats and display them on the screen for the user to see, if internet isn't available then this function will use the listener to trigger itself again in a recursive manner when internet is available*/
    func getLaundromatData(){
        /** Fetch all the laundromats*/
        fetchAllLaundromats{ [self] laundromats in
            /** Cast the fetched set of laundromats to an array to make accessing their indexes easier*/
            self.laundromats = Array(laundromats)
            
            /** The laundromats are cached by the local firestore listener so the only way to refresh the data is to detect if the internet is available or not*/
            if internetAvailable == false{
                globallyTransmit(this: "Please connect to the internet in order to use our services. Thank you!", with: UIImage(systemName: "wifi.slash", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: .clear, imageBorder: .none, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 3, selfDismiss: true)
                
                networkMonitor.start(queue: DispatchQueue.global(qos: .background))
                networkMonitor.pathUpdateHandler = { path in
                    switch path.status{
                    case .satisfied:
                        /** Internet available, recursion starts, stop monitor*/
                        DispatchQueue.main.async{ [self] in
                            getLaundromatData()
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
            else if internetAvailable == true{
                /** All of the changes must be activated in the completion handler, anything outside isn't triggered*/
                
                /** Fetch all of the carts made by this user*/
                fetchCarts()
                
                /** Update the weather view when the internet is available*/
                if mapView != nil{
                    
                    /** Move the user to their current location*/
                    if let location = mapView!.myLocation{
                        UIView.animate(withDuration: 0.5, delay: 0){[self] in
                            weatherView.alpha = 1
                        }
                        
                        updateTheCurrentWeather(using: location.coordinate.latitude, longitude: location.coordinate.longitude)
                    }
                    else{
                        /** Location not available, go with a default location for now*/
                        /** Generic coordinate point in Brooklyn*/
                        let coordinate = CLLocationCoordinate2D(latitude: 40.67985516878483, longitude: -73.93747149720345)
                        
                        UIView.animate(withDuration: 0.5, delay: 0){[self] in
                            weatherView.alpha = 1
                        }
                        
                        updateTheCurrentWeather(using: coordinate.latitude, longitude: coordinate.longitude)
                    }
                }
                
                /** Use the user's profile picture as the image for this button*/
                if let user = Auth.auth().currentUser{
                    if user.photoURL != nil{
                        
                        let request = ImageRequest(url: user.photoURL!)
                        let options = ImageLoadingOptions(
                            transition: .fadeIn(duration: 0.15)
                        )
                        
                        searchBarRightViewButton.layer.borderColor = appThemeColor.cgColor
                        Nuke.loadImage(with: request, options: options, into: searchBarRightViewButton){ [self] _ in
                            userProfilePicture = searchBarRightViewButton.imageView?.image
                        }
                    }
                    else{
                        searchBarRightViewButton.layer.borderColor = appThemeColor.cgColor
                        searchBarRightViewButton.setImage(UIImage(named: "user"), for: .normal)
                    }
                }
                
                /** Extra precaution to avoid fatal errors*/
                guard laundromats.isEmpty == false else{
                    /** The data isn't present in the database (?) very bad*/
                    return
                }
                
                /** Everything is normal, data is there*/
                createBottomSheet()
                createOrdersBottomSheet()
                createAccountBottomSheet()
                createCollectionView()
                addMarkers()
            }
        }
    }
    
    /** Create a collectionview to display the locations of the laundromats dynamically depending on which location the user presses on*/
    func createCollectionView(){
        /** Make sure there are in fact laundromats to be represented in the tableview*/
        guard laundromats.isEmpty == false else {
            return
        }
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        /** Specify item size in order to allow the collectionview to encompass all of them*/
        layout.itemSize = CGSize(width: self.view.frame.width, height: self.view.frame.height * 0.4)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        laundromatLocationsCollectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height * 0.4), collectionViewLayout: layout)
        laundromatLocationsCollectionView.register(LaundromatLocationCollectionViewCell.self, forCellWithReuseIdentifier: LaundromatLocationCollectionViewCell.identifier)
        laundromatLocationsCollectionView.delegate = self
        laundromatLocationsCollectionView.backgroundColor = UIColor.clear
        laundromatLocationsCollectionView.isPagingEnabled = true
        laundromatLocationsCollectionView.dataSource = self
        laundromatLocationsCollectionView.showsVerticalScrollIndicator = false
        laundromatLocationsCollectionView.showsHorizontalScrollIndicator = false
        laundromatLocationsCollectionView.isExclusiveTouch = true
        laundromatLocationsCollectionView.contentSize = CGSize(width: ((self.view.frame.width) * CGFloat(laundromats.count)), height: self.view.frame.height * 0.4)
        
        /** Layout these subviews*/
        laundromatLocationsCollectionView.frame.origin = CGPoint(x: 0, y: self.view.frame.maxY - laundromatLocationsCollectionView.frame.height * 1.1)
        
        /** Transform this collectionview below the screen and show it when needed*/
        laundromatLocationsCollectionView.transform = CGAffineTransform(translationX: 0, y: laundromatLocationsCollectionView.frame.height)
        
        self.view.addSubview(laundromatLocationsCollectionView)
    }
    
    /** Create a bottom sheet to display the user's past and current orders (internet required to update them and load them up the first time)*/
    func createOrdersBottomSheet(){
        ordersTitleLabel = UILabel()
        ordersTitleLabel.frame.size = CGSize(width: self.view.frame.width * 0.9, height: ((self.view.frame.height/3) * 0.9))
        ordersTitleLabel.adjustsFontSizeToFitWidth = true
        ordersTitleLabel.adjustsFontForContentSizeCategory = false
        ordersTitleLabel.textAlignment = .left
        ordersTitleLabel.numberOfLines = 1
        ordersTitleLabel.lineBreakMode = .byClipping
        ordersTitleLabel.backgroundColor = .clear
        ordersTitleLabel.attributedText = attribute(this: "My Orders", font: getCustomFont(name: .Bungee_Regular, size: 35, dynamicSize: false), subFont: getCustomFont(name: .Bungee_Regular, size: 35, dynamicSize: false), mainColor: appThemeColor, subColor: .lightGray, subString: "")
        ordersTitleLabel.sizeToFit()
        
        ordersTableView = UITableView(frame: self.view.frame, style: .insetGrouped)
        ordersTableView.clipsToBounds = true
        switch darkMode{
        case true:
            laundromatLocationsTableView.backgroundColor = .black
        case false:
            laundromatLocationsTableView.backgroundColor = bgColor
        }
        ordersTableView.tintColor = fontColor
        ordersTableView.isOpaque = false
        ordersTableView.showsVerticalScrollIndicator = true
        ordersTableView.showsHorizontalScrollIndicator = false
        ordersTableView.isExclusiveTouch = true
        ordersTableView.contentInsetAdjustmentBehavior = .never
        ordersTableView.dataSource = self
        ordersTableView.delegate = self
        ordersTableView.separatorStyle = .none
        
        /** Add a little space at the bottom of the scrollview*/
        ordersTableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: view.frame.width, right: 0)
        
        ordersTableView.register(ordersTableViewCell.self, forCellReuseIdentifier: ordersTableViewCell.identifier)
        
        ordersBottomSheetRefreshControl.addTarget(self, action: #selector(self.ordersBottomSheetRefreshStart(_:)), for: .valueChanged)
        ordersBottomSheetRefreshControl.tintColor = .clear
        ordersBottomSheetRefreshControl.layer.zPosition = -1
        ordersTableView.refreshControl = ordersBottomSheetRefreshControl
        
        if(darkMode == true){
            ordersTableView.indicatorStyle = .white
        }
        else{
            ordersTableView.indicatorStyle = .black
        }
        
        ordersBottomSheet = DetentedBottomSheetView(detents: [view.frame.height/3], subview: ordersTableView)
        ordersBottomSheet.startingDetent = view.frame.height/3
        /** Use the table view's scrollview*/
        ordersBottomSheet.scrollView.isScrollEnabled = false
        
        /** Add a little space at the top between the tableview and the top of the bottom sheet*/
        ordersTableView.frame.origin.y = 50
        let topLayoutConstraint = NSLayoutConstraint(item: ordersTableView!, attribute: .top, relatedBy: .equal, toItem: ordersBottomSheet, attribute: .top, multiplier: 1.0, constant: 50)
        topLayoutConstraint.isActive = true
        
        let topBorder = CALayer()
        topBorder.frame = CGRect(x: 0, y: ordersTableView.frame.minY, width: ordersTableView.frame.width, height: 1)
        topBorder.backgroundColor = bgColor.darker.cgColor
        ordersBottomSheet.layer.addSublayer(topBorder)
        
        /** Layout these subviews*/
        ordersTitleLabel.frame.origin = CGPoint(x: 10, y: ordersBottomSheet.frame.minY - (ordersTitleLabel.frame.height * 2))
        
        /** Add these views to the view hierarchy*/
        view.addSubview(ordersTitleLabel)
        view.addSubview(ordersBottomSheet)
        
        /** Hide these views initially*/
        hideOrdersTitleLabel(animated: false)
        
        /** Hidden by default as this isn't the inital bottom sheet that's being displayed*/
        ordersBottomSheet.hide(animated: false)
    }
    
    /** Hide this view in a static or animated fashion*/
    func hideOrdersTitleLabel(animated: Bool){
        if animated{
            UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
                self.ordersTitleLabel.transform = CGAffineTransform(translationX: 0, y: self.view.frame.height * 1.1)
            }
        }
        else{
            ordersTitleLabel.transform = CGAffineTransform(translationX: 0, y: self.view.frame.height * 1.5)
        }
    }
    
    /** Display this view in a static or animated fashion*/
    func showOrdersTitleLabel(animated: Bool){
        if animated{
            UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
                self.ordersTitleLabel.transform = CGAffineTransform(translationX: 0, y: 0)
            }
        }
        else{
            ordersTitleLabel.transform = CGAffineTransform(translationX: 0, y: 0)
        }
    }
    
    /** Create a bottom sheet to display the properties of the user's current account (internet required to update them and load them up the first time)*/
    func createAccountBottomSheet(){
        let testView = UIView()
        testView.backgroundColor = bgColor
        
        accountBottomSheet = DetentedBottomSheetView(detents: [0], subview: testView)
        accountBottomSheet.startingDetent = 0
        accountBottomSheet.disablePullDown = true
        
        accountBottomSheet.scrollView.isScrollEnabled = true
        
        view.addSubview(accountBottomSheet)
        
        /** Hidden by default as this isn't the inital bottom sheet that's being displayed*/
        accountBottomSheet.hide(animated: false)
    }
    
    /** Create the bottom sheet to be added to the view hierachy*/
    func createBottomSheet(){
        /** Make sure there are in fact laundromats to be represented in the tableview*/
        guard laundromats.isEmpty == false else {
            return
        }
        
        laundromatLocationsTableView = UITableView(frame: self.view.frame, style: .plain)
        laundromatLocationsTableView.clipsToBounds = true
        switch darkMode{
        case true:
            laundromatLocationsTableView.backgroundColor = .black
        case false:
            laundromatLocationsTableView.backgroundColor = bgColor
        }
        laundromatLocationsTableView.tintColor = fontColor
        laundromatLocationsTableView.isOpaque = false
        laundromatLocationsTableView.showsVerticalScrollIndicator = true
        laundromatLocationsTableView.showsHorizontalScrollIndicator = false
        laundromatLocationsTableView.isExclusiveTouch = true
        laundromatLocationsTableView.contentInsetAdjustmentBehavior = .never
        laundromatLocationsTableView.dataSource = self
        laundromatLocationsTableView.delegate = self
        laundromatLocationsTableView.separatorStyle = .none
        
        /** Add a little space at the bottom of the scrollview*/
        laundromatLocationsTableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: view.frame.width, right: 0)
        
        laundromatLocationsTableView.register(LaundromatLocationTableViewCell.self, forCellReuseIdentifier: LaundromatLocationTableViewCell.identifier)
        
        if(darkMode == true){
            laundromatLocationsTableView.indicatorStyle = .white
        }
        else{
            laundromatLocationsTableView.indicatorStyle = .black
        }
        
        /** Create the bottom sheet, specify its detents and add the tableview to it as a subview*/
        bottomSheet = DetentedBottomSheetView(detents: [view.frame.height * 0.8,view.frame.height/5,view.frame.height/2], subview: laundromatLocationsTableView)
        bottomSheet.startingDetent = view.frame.height * 0.8
        /** Use the table view's scrollview instead*/
        bottomSheet.scrollView.isScrollEnabled = false
        view.addSubview(bottomSheet)
        
        /** Add a little space at the top between the tableview and the top of the bottom sheet*/
        laundromatLocationsTableView.frame.origin.y = 50
        let topLayoutConstraint = NSLayoutConstraint(item: laundromatLocationsTableView!, attribute: .top, relatedBy: .equal, toItem: bottomSheet, attribute: .top, multiplier: 1.0, constant: 50)
        topLayoutConstraint.isActive = true
        
        let topBorder = CALayer()
        topBorder.frame = CGRect(x: 0, y: laundromatLocationsTableView.frame.minY, width: laundromatLocationsTableView.frame.width, height: 1)
        topBorder.backgroundColor = bgColor.darker.cgColor
        bottomSheet.layer.addSublayer(topBorder)
        
        /** Sort button in order for the user to sort through the various laundromat locations*/
        locationSortingButton = UIButton()
        locationSortingButton.frame.size.height = 50
        locationSortingButton.frame.size.width = locationSortingButton.frame.size.height
        locationSortingButton.backgroundColor = .clear
        locationSortingButton.tintColor = fontColor
        locationSortingButton.setImage(UIImage(systemName: "slider.horizontal.3", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        locationSortingButton.imageView?.contentMode = .scaleToFill
        locationSortingButton.layer.cornerRadius = 0
        locationSortingButton.isEnabled = true
        locationSortingButton.isExclusiveTouch = true
        /** When the user taps the button, show the menu immediately*/
        locationSortingButton.showsMenuAsPrimaryAction = true
        locationSortingButton.menu = getMenuForLocationSortingButton()
        addDynamicButtonGR(button: locationSortingButton)
        bottomSheet.addSubview(locationSortingButton)
        
        /** Center this button at the top right of the view*/
        locationSortingButton.frame.origin = CGPoint(x: bottomSheet.frame.maxX - (locationSortingButton.frame.width * 1.25), y: 50/2 - locationSortingButton.frame.height/2)
        
        bottomSheet.hide(animated: false)
        
        bottomSheetRefreshControl.addTarget(self, action: #selector(self.bottomSheetRefreshStart(_:)), for: .valueChanged)
        bottomSheetRefreshControl.tintColor = .clear
        bottomSheetRefreshControl.layer.zPosition = -1
        laundromatLocationsTableView.refreshControl = bottomSheetRefreshControl
        
        /** Sort the locations of the laundromats by closest to farthest*/
        sortingByDistance = true
        highestToLowestSortingByDistance = false
        sortLocationsByDistance(highestToLowest: false)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1){
            self.bottomSheet.show(animated: true)
        }
    }
    
    /** Refresh all data sensitive UI Objects with new data (if any)*/
    @objc func ordersBottomSheetRefreshStart(_ sender: AnyObject){
        mediumHaptic()
        
        guard ordersTableView != nil else{
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5){ [self] in
            /** Reload the table view*/
            ordersTableView.reloadSections([0], with: .fade)
            
            ordersBottomSheetRefreshControl.endRefreshing()
        }
    }
    
    /** Refresh all data sensitive UI Objects with new data (if any)*/
    @objc func bottomSheetRefreshStart(_ sender: AnyObject){
        mediumHaptic()
        
        guard laundromatLocationsTableView != nil else{
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5){ [self] in
            /** Reload both the table view and collection view*/
            laundromatLocationsTableView.reloadSections([0], with: .top)
            laundromatLocationsCollectionView.reloadData()
            
            bottomSheetRefreshControl.endRefreshing()
        }
    }
    
    /** Menu interaction methods*/
    /** Provide the non-context menu for this button*/
    func getMenuForLocationSortingButton()->UIMenu{
        var children: [UIMenuElement] = []
        let menuTitle = "Sort by:"
        
        if locationSortingButton != nil{
            /** Specify the sorting direction of the current menu option based on the state of its boolean for sorting direction*/
            var imageForSorting: UIImage? = nil
            if highestToLowestSortingByDistance == true{
                imageForSorting = UIImage(systemName: "chevron.up")
            }
            else{
                imageForSorting = UIImage(systemName: "chevron.down")
            }
            
            /** If any of the other sort options are triggered don't provide an image for this*/
            if sortingByRatings == true || sortingByReviews == true{
                imageForSorting = nil
            }
            
            let distance = UIAction(title: "Distance", image: imageForSorting){ [self] action in
                lightHaptic()
                
                sortingByDistance = true
                sortingByRatings = false
                sortingByReviews = false
                
                if highestToLowestSortingByDistance == true{
                    sortLocationsByDistance(highestToLowest: false)
                    
                    /** Flip the state for the next time that the user presses the button*/
                    highestToLowestSortingByDistance = false
                }
                else{
                    sortLocationsByDistance(highestToLowest: true)
                    
                    highestToLowestSortingByDistance = true
                }
                
                /** Refresh the menu of this button to reflect these changes*/
                locationSortingButton.menu = getMenuForLocationSortingButton()
            }
            
            if highestToLowestSortingByRatings == true{
                imageForSorting = UIImage(systemName: "chevron.up")
            }
            else{
                imageForSorting = UIImage(systemName: "chevron.down")
            }
            
            /** If any of the other sort options are triggered don't provide an image for this*/
            if sortingByDistance == true || sortingByReviews == true{
                imageForSorting = nil
            }
            
            let ratings = UIAction(title: "Ratings", image: imageForSorting){ [self] action in
                lightHaptic()
                
                sortingByDistance = false
                sortingByRatings = true
                sortingByReviews = false
                
                if highestToLowestSortingByRatings == true{
                    sortLocationsByReviews(highestToLowest: false)
                    
                    /** Flip the state for the next time that the user presses the button*/
                    highestToLowestSortingByRatings = false
                }
                else{
                    sortLocationsByReviews(highestToLowest: true)
                    
                    highestToLowestSortingByRatings = true
                }
                
                /** Refresh the menu of this button to reflect these changes*/
                locationSortingButton.menu = getMenuForLocationSortingButton()
            }
            
            if highestToLowestSortingByReviews == true{
                imageForSorting = UIImage(systemName: "chevron.up")
            }
            else{
                imageForSorting = UIImage(systemName: "chevron.down")
            }
            
            /** If any of the other sort options are triggered don't provide an image for this*/
            if sortingByDistance == true || sortingByRatings == true{
                imageForSorting = nil
            }
            
            let reviews = UIAction(title: "Popularity", image: imageForSorting){ [self] action in
                lightHaptic()
                
                sortingByDistance = false
                sortingByRatings = false
                sortingByReviews = true
                
                if highestToLowestSortingByReviews == true{
                    sortLocationsByReviews(highestToLowest: false)
                    
                    /** Flip the state for the next time that the user presses the button*/
                    highestToLowestSortingByReviews = false
                }
                else{
                    sortLocationsByReviews(highestToLowest: true)
                    
                    highestToLowestSortingByReviews = true
                }
                
                /** Refresh the menu of this button to reflect these changes*/
                locationSortingButton.menu = getMenuForLocationSortingButton()
            }
            
            children.append(distance)
            children.append(ratings)
            children.append(reviews)
        }
        
        return UIMenu(title: menuTitle, children: children)
    }
    
    /** Sorts the current data set of laundromats by distance from the current user*/
    func sortLocationsByDistance(highestToLowest: Bool){
        /** You can't sort nothing*/
        guard laundromats.isEmpty == false else {
            return
        }
        
        if highestToLowest == true{
            /** Simple highest to lowest sorting algorithm*/
            for (i, _) in laundromats.enumerated(){
                
                /** Swapping is happening so to reference the new element you must reference it at its index*/
                var farthestDistance = getDistanceFromThis(laundromat: laundromats[i], inMiles: true)
                
                /** Choose one laundromat compare it with everything else, swap and then move*/
                for (j, otherLaundromat) in laundromats.enumerated(){
                    
                    /** Make sure it's only comparing the elements it hasn't sorted yet*/
                    guard j > i else{
                        continue
                    }
                    
                    guard farthestDistance != nil else {
                        break
                    }
                    
                    if let otherDistance = getDistanceFromThis(laundromat: otherLaundromat, inMiles: true){
                        
                        /** Keep swapping until the entire array is sorted from high to low*/
                        if otherDistance > farthestDistance!{
                            farthestDistance = otherDistance
                            laundromats.swapAt(i, j)
                        }
                    }
                }
            }
            
            /** Ensure the tableview is in memory*/
            guard laundromatLocationsTableView != nil else {
                return
            }
            
            /** Reload the tableview with the newly sorted data*/
            laundromatLocationsTableView.reloadSections([0], with: .left)
            
            guard laundromatLocationsCollectionView != nil else{
                return
            }
            
            laundromatLocationsCollectionView.reloadData()
        }
        else{
            /** Simple lowest to highest sorting algorithm*/
            for (i, _) in laundromats.enumerated(){
                
                /** Swapping is happening so to reference the new element you must reference it at its index*/
                var closestDistance = getDistanceFromThis(laundromat: laundromats[i], inMiles: true)
                
                /** Choose one laundromat compare it with everything else, swap and then move*/
                for (j, otherLaundromat) in laundromats.enumerated(){
                    
                    /** Make sure it's only comparing the elements it hasn't sorted yet*/
                    guard j > i else{
                        continue
                    }
                    
                    guard closestDistance != nil else {
                        break
                    }
                    
                    if let otherDistance = getDistanceFromThis(laundromat: otherLaundromat, inMiles: true){
                        
                        /** Keep swapping until the entire array is sorted from low to high*/
                        if otherDistance < closestDistance!{
                            closestDistance = otherDistance
                            laundromats.swapAt(i, j)
                        }
                    }
                }
            }
            
            /** Ensure the tableview is in memory*/
            guard laundromatLocationsTableView != nil else {
                return
            }
            
            /** Reload the tableview with the newly sorted data*/
            laundromatLocationsTableView.reloadSections([0], with: .right)
            
            guard laundromatLocationsCollectionView != nil else{
                return
            }
            
            laundromatLocationsCollectionView.reloadData()
        }
    }
    
    /** Compute the current distance from the given laundromat and the user's location (in miles or KM)*/
    func getDistanceFromThis(laundromat: Laundromat, inMiles: Bool)->CGFloat?{
        guard mapView != nil else{
            return nil
        }
        
        var distance: CGFloat = 0
        
        /** Store the location of the laundromat as a coordinate point by unwrapping its Geopoint coordinate*/
        let storeLocation = CLLocation(latitude: laundromat.coordinates.latitude, longitude: laundromat.coordinates.longitude)
        
        /** Compute the distance between the two coordinates (in meters)*/
        /** If the mapview's location isn't available then use the location manager's last location*/
        if let location = mapView.myLocation{
        distance = location.distance(from: storeLocation)
        }
        else if let location = locationManager.location{
        distance = location.distance(from: storeLocation)
        }
        
        /** Convert to miles (b/c America)*/
        if inMiles == true{
            distance = getMiles(from: CGFloat(distance))
        }
        
        return distance
    }
    
    /** Fetch the ratings for the laundromat locations and store them if they're not already fetched and then compare the ratings for each location, sorting by highest ratings to lowest*/
    func sortLocationsByRatings(highestToLowest: Bool){
        
    }
    
    /** Fetch the reviews for the laundromat locations and store them if they're not already fetched and then compare the number of reviews for each location, sorting by most reviews to least*/
    func sortLocationsByReviews(highestToLowest: Bool){
        
    }
    /** Menu interaction methods*/
    
    /** Map Delegate methods*/
    func mapView(_ mapView: GMSMapView, markerInfoContents marker: GMSMarker) -> UIView? {
        //Do Something
        return nil
    }
    
    /** Detect when the user taps a specific coordinate point*/
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        /** Present the bottom sheet whenever the user taps on the screen to dismiss any other views occupying the screen if there is a currently selected map marker and if the user isn't tapping directly on it*/
        if currentlySelectedMapMarker != nil{
            if currentlySelectedMapMarker!.position.longitude != coordinate.longitude && currentlySelectedMapMarker!.position.latitude != coordinate.latitude{
                bottomSheet.show(animated: true)
                hideCollectionView()
                
                currentlySelectedMapMarker = nil
            }
        }
    }
    
    /** Detect when a marker is tapped*/
    public func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        /** Marker tapped*/
        mediumHaptic()
        
        /** Get the custom iconview for this map marker*/
        if let iconView = mapMarkerIconViews[marker]{
            /** A little shrink and pop out animation*/
            UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
                iconView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            }
            UIView.animate(withDuration: 0.25, delay: 0.15, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
                iconView.transform = CGAffineTransform(scaleX: 1, y: 1)
            }
        }
        
        /** Zoom in on the location designated by the marker (Animated)*/
        let position = GMSCameraPosition(latitude: marker.position.latitude, longitude: marker.position.longitude, zoom: streetLevelZoomLevel)
        
        /** Specify the animation duration of the camera position update animation*/
        CATransaction.begin()
        CATransaction.setValue(0.5, forKey: kCATransactionAnimationDuration)
        mapView.animate(to: position)
        CATransaction.commit()
        
        /** Move the bottom sheet out of the way (if it is in the way) to reveal the details of the laundromat associated with the marker tapped*/
        bottomSheet.moveToStartingDetent(animated: true)
        bottomSheet.hide(animated: true)
        
        currentlySelectedMapMarker = marker
        
        /** Offset the collection view's scrollview so that it is centered on the item at the given index, the collectionview's data is the laundromats array, therefore this collection's indexes are indicative of the position of the views inside of the collectionview*/
        let selectedLaundromat = mapMarkers[marker]
        for (index, laundromat) in laundromats.enumerated(){
            guard selectedLaundromat != nil else {
                break
            }
            
            if selectedLaundromat == laundromat{
                laundromatLocationsCollectionView.setContentOffset(CGPoint(x: (self.view.frame.width * CGFloat(index)), y: 0), animated: true)
            }
        }
        
        popUpCollectionView()
        
        return true
    }
    
    /** Popup the collectionview and center it on the laundromat in question that was clicked with the marker*/
    func popUpCollectionView(){
        /** Only pop up the collection view when the home tab is selected*/
        guard homeTabSelected == true else {
            return
        }
        
        /** hide the tabbar since it will partially cover the collectionview a bit*/
        hideTabbar()
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            self.laundromatLocationsCollectionView.transform = CGAffineTransform(translationX: 0, y: 0)
        }
    }
    
    /** Hide the collection view since its not needed anymore*/
    func hideCollectionView(){
        showTabbar()
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            self.laundromatLocationsCollectionView.transform = CGAffineTransform(translationX: 0, y: self.laundromatLocationsCollectionView.frame.height * 1.5)
        }
    }
    
    public func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        /** When the user has zoomed out too far minimize the title labels of the markers*/
        if position.zoom < 11{
            for pair in mapMarkerIconViews{
                let view = pair.value.shadowView
                
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
                    view.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
                }
            }
        }
        else{
            for pair in mapMarkerIconViews{
                let view = pair.value.shadowView
                
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
                    view.transform = CGAffineTransform(scaleX: 1, y: 1)
                }
            }
        }
    }
    
    /** Fetch new data for the current weather every 30 minutes*/
    func updateTheCurrentWeather(using latitude: CLLocationDegrees, longitude: CLLocationDegrees){
        /** Don't send a request if the user doesn't have internet*/
        guard internetAvailable == true else{
            return
        }
        
        /** Initialize this timer if it hasn't been initialized already, this prevents the timer from being overwritten*/
        if weatherTimer == nil{
            /** Get the current weather initially and then wait 20 minutes in the timer*/
            getCurrentWeather(latitude: latitude, longitude: longitude){ [self]
                (result: Result<CurrentWeather,APIService.APIError>) in
                switch result {
                case .success(let currentWeather):
                    
                    /** The given temp is in Kelvin, so convert to Farenheit*/
                    weatherView.temperature = convertFromKelvinToFahrenheit(k: currentWeather.main.temp)
                    
                    weatherView.weatherIcon = currentWeather.weather.first?.weatherIconURL
                    
                    /** Depending on what time of day it is specify the 'sky' color of the weather icon*/
                    switch whatTimeOfDayIsIt(){
                    case .morning:
                        weatherView.weatherIconBackgroundColor = UIColor(red: 144/255, green: 227/255, blue: 255/255, alpha: 1)
                    case .afternoon:
                        weatherView.weatherIconBackgroundColor = UIColor(red: 0/255, green: 191/255, blue: 255/255, alpha: 1)
                    case .evening:
                        weatherView.weatherIconBackgroundColor = UIColor(red: 254/255, green: 192/255, blue: 81/255, alpha: 1)
                    case .night:
                        weatherView.weatherIconBackgroundColor = UIColor(red: 20/255, green: 24/255, blue: 82/255, alpha: 1)
                    }
                    
                    ///print("Current weather fetched and decoded successfully")
                    ///print("\(currentWeather.main) \(currentWeather.dt)")
                case .failure(let apiError):
                    switch apiError{
                    case .error(let errorString):
                        print("Error: current weather could not be fetched and decoded")
                        print(errorString)
                    }
                }
            }
            
            /** Fire every 20 seconds*/
            weatherTimer = Timer.scheduledTimer(withTimeInterval: 1200, repeats: true, block:{ _ in
                getCurrentWeather(latitude: latitude, longitude: longitude){ [self]
                    (result: Result<CurrentWeather,APIService.APIError>) in
                    switch result {
                    case .success(let currentWeather):
                        
                        weatherView.temperature = convertFromKelvinToFahrenheit(k: currentWeather.main.temp)
                        
                        weatherView.weatherIcon = currentWeather.weather.first?.weatherIconURL
                        
                        switch whatTimeOfDayIsIt(){
                        case .morning:
                            weatherView.weatherIconBackgroundColor = UIColor(red: 144/255, green: 227/255, blue: 255/255, alpha: 1)
                        case .afternoon:
                            weatherView.weatherIconBackgroundColor = UIColor(red: 0/255, green: 191/255, blue: 255/255, alpha: 1)
                        case .evening:
                            weatherView.weatherIconBackgroundColor = UIColor(red: 254/255, green: 192/255, blue: 81/255, alpha: 1)
                        case .night:
                            weatherView.weatherIconBackgroundColor = UIColor(red: 20/255, green: 24/255, blue: 82/255, alpha: 1)
                        }
                        
                        ///print("Current weather fetched and decoded successfully")
                        ///print("\(currentWeather.main) \(currentWeather.dt)")
                    case .failure(let apiError):
                        switch apiError{
                        case .error(let errorString):
                            print("Error: current weather could not be fetched and decoded")
                            print(errorString)
                        }
                    }
                }
            })
        }
    }
    
    /** Location Manager Delegate Methods*/
    /**Handle incoming location events*/
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations.last!
        
        /** Sort the locations again when the location updates*/
        if sortingByDistance == true{
            sortLocationsByDistance(highestToLowest: highestToLowestSortingByDistance)
        }
        
        /** Update the weather*/
        updateTheCurrentWeather(using: location.coordinate.latitude, longitude: location.coordinate.longitude)
        
        /** Update the distance of the user from various locations periodically when the user's location changes, updates only applied to the visible cells in this tableview*/
        if laundromatLocationsTableView != nil && mapView != nil{
            if let cells = laundromatLocationsTableView.visibleCells as? [LaundromatLocationTableViewCell]{
                for cell in cells{
                    
                    /** Make sure the cell actually has data stored before unwrapping something that's not there, and make sure the user has their location enabled*/
                    guard cell.laundromatData?.coordinates.latitude != nil && cell.laundromatData?.coordinates.longitude != nil && mapView.myLocation != nil else{
                        return
                    }
                    
                    /** Store the location of the laundromat as a coordinate point by unwrapping its Geopoint coordinate*/
                    let storeLocation = CLLocation(latitude: (cell.laundromatData?.coordinates.latitude)!, longitude: (cell.laundromatData?.coordinates.longitude)!)
                    
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
                    
                    cell.subview?.distanceLabel.text = abbreviateMiles(miles: distanceInMiles, feetAbbreviation: "ft", milesAbbreviation: "mi") + " \(distanceEmoji)"
                    cell.subview?.distanceLabel.sizeToFit()
                    
                    /** If the distance label is currently invisible then make it appear*/
                    if cell.subview?.distanceLabel.alpha == 0{
                        UIView.animate(withDuration: 0.5, delay: 0){
                            cell.subview?.distanceLabel.alpha = 1
                        }
                    }
                }
            }
        }
        
        /** Do the same for the collection view*/
        if laundromatLocationsCollectionView != nil && mapView != nil{
            if let cells = laundromatLocationsCollectionView.visibleCells as? [LaundromatLocationTableViewCell]{
                for cell in cells{
                    
                    /** Make sure the cell actually has data stored before unwrapping something that's not there, and make sure the user has their location enabled*/
                    guard cell.laundromatData?.coordinates.latitude != nil && cell.laundromatData?.coordinates.longitude != nil && mapView.myLocation != nil else{
                        return
                    }
                    
                    /** Store the location of the laundromat as a coordinate point by unwrapping its Geopoint coordinate*/
                    let storeLocation = CLLocation(latitude: (cell.laundromatData?.coordinates.latitude)!, longitude: (cell.laundromatData?.coordinates.longitude)!)
                    
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
                    
                    cell.subview?.distanceLabel.text = abbreviateMiles(miles: distanceInMiles, feetAbbreviation: "ft", milesAbbreviation: "mi") + " \(distanceEmoji)"
                    cell.subview?.distanceLabel.sizeToFit()
                    
                    /** If the distance label is currently invisible then make it appear*/
                    if cell.subview?.distanceLabel.alpha == 0{
                        UIView.animate(withDuration: 0.5, delay: 0){
                            cell.subview?.distanceLabel.alpha = 1
                        }
                    }
                }
            }
        }
        
        ///print("Location: \(location)")
        
        ///listLikelyPlaces()
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
            
            /** Move the user to their current location when authorization is granted*/
            if mapView != nil{
                if let location = manager.location{
                    /** Zoom in to the user's current location (if available) (Animated)*/
                    let position = GMSCameraPosition(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: preciseLocationZoomLevel)
                    
                    /** Specify the animation duration of the camera position update animation*/
                    CATransaction.begin()
                    CATransaction.setValue(0.5, forKey: kCATransactionAnimationDuration)
                    mapView.animate(to: position)
                    CATransaction.commit()
                }
            }
            
            /** Sort the locations by distance when the user's location data is authorized*/
            sortLocationsByDistance(highestToLowest: false)
            
            print("Location status is OK.")
        @unknown default:
            fatalError()
        }
    }
    
    /**Handle location manager errors*/
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        
        print("Error: \(error)")
    }
    
    /** Location Manager Delegate Methods*/
    
    /** Set the specifics of this view controller*/
    func configure(){
        self.view.backgroundColor = bgColor
        setCustomNavUI()
        createSearchBar()
    }
    
    /** Create a custom search bar and add it to the navigation bar*/
    func createSearchBar(){
        searchBarContainer.frame.size = CGSize(width: view.frame.width, height: 60)
        searchBarContainer.clipsToBounds = false
        searchBarContainer.backgroundColor = .clear
        
        searchBar.delegate = self
        searchBar.shouldResignOnTouchOutsideMode = .disabled
        searchBar.frame.size = CGSize(width: view.frame.width * 0.9, height: 60)
        searchBar.layer.cornerRadius = searchBar.frame.height/2
        /** Warning: Using .white.lighter causes a weird dimming glitch, do not use it*/
        searchBar.backgroundColor = bgColor
        searchBar.textColor = fontColor.darker
        searchBar.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: true)
        searchBar.adjustsFontSizeToFitWidth = true
        searchBar.adjustsFontForContentSizeCategory = true
        searchBar.tintColor = appThemeColor
        searchBar.autocorrectionType = .yes
        searchBar.keyboardType = .asciiCapable
        searchBar.textContentType = .location
        searchBar.returnKeyType = .search
        searchBar.toolbarPlaceholder = ""
        searchBar.attributedPlaceholder = NSAttributedString(string:"Search for a laundromat", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        switch darkMode{
        case true:
            searchBar.keyboardAppearance = .dark
        case false:
            searchBar.keyboardAppearance = .light
        }
        
        /** Set the clear button*/
        searchBar.clearButtonMode = .never
        
        /** Shadow properties*/
        searchBar.layer.shadowColor = UIColor.darkGray.cgColor
        searchBar.layer.shadowOpacity = 0.25
        searchBar.layer.shadowRadius = 1
        searchBar.layer.shadowOffset = CGSize(width: 0, height: 2)
        searchBar.layer.shadowPath = UIBezierPath(roundedRect: searchBar.bounds, cornerRadius: searchBar.layer.cornerRadius).cgPath
        
        /** Border properties*/
        searchBar.clipsToBounds = true
        searchBar.layer.masksToBounds = false
        /** Set to .none, else the shadow and the rect bounds aren't rendered properly*/
        searchBar.borderStyle = .none
        searchBar.layer.borderWidth = 0
        
        /** Leave some white space on the left of the textfield so nothing spills out*/
        let spacer = UIView(frame: CGRect(x: 0, y: 0, width: searchBar.frame.height/(1), height: searchBar.frame.height/(1)))
        
        searchBarLeftViewButton.setImage(UIImage(systemName: "magnifyingglass.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        searchBarLeftViewButton.frame.size = CGSize(width: searchBar.frame.height/(2), height: searchBar.frame.height/(2))
        searchBarLeftViewButton.frame.origin = CGPoint(x: spacer.frame.width/2 - searchBarLeftViewButton.frame.width/2, y: spacer.frame.height/2 - searchBarLeftViewButton.frame.height/2)
        searchBarLeftViewButton.backgroundColor = .clear
        searchBarLeftViewButton.tintColor = appThemeColor
        searchBarLeftViewButton.layer.cornerRadius = searchBarLeftViewButton.frame.height/2
        searchBarLeftViewButton.imageView?.contentMode = .scaleAspectFill
        searchBarLeftViewButton.contentHorizontalAlignment = .fill
        searchBarLeftViewButton.contentVerticalAlignment = .fill
        searchBarLeftViewButton.isUserInteractionEnabled = true
        searchBarLeftViewButton.clipsToBounds = true
        
        searchBarLeftViewButton.addTarget(self, action: #selector(leftButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: searchBarLeftViewButton)
        spacer.addSubview(searchBarLeftViewButton)
        searchBar.leftView = spacer
        searchBar.leftViewMode = .always
        
        /** Leave some white space on the left of the textfield so nothing spills out*/
        let spacer_2 = UIView(frame: CGRect(x: 0, y: 0, width: searchBar.frame.height/(1), height: searchBar.frame.height/(1)))
        
        searchBarRightViewButton.frame.size = CGSize(width: searchBar.frame.height/(1.5), height: searchBar.frame.height/(1.5))
        searchBarRightViewButton.frame.origin = CGPoint(x: spacer_2.frame.width/2 - searchBarRightViewButton.frame.width/2, y: spacer_2.frame.height/2 - searchBarRightViewButton.frame.height/2)
        searchBarRightViewButton.backgroundColor = .clear
        searchBarRightViewButton.tintColor = appThemeColor
        searchBarRightViewButton.layer.cornerRadius = searchBarRightViewButton.frame.height/2
        searchBarRightViewButton.contentMode = .scaleAspectFill
        searchBarRightViewButton.isUserInteractionEnabled = true
        searchBarRightViewButton.clipsToBounds = true
        searchBarRightViewButton.setImage(UIImage(named: "user"), for: .normal)
        searchBarRightViewButton.imageView?.contentMode = .scaleAspectFill
        searchBarRightViewButton.layer.borderColor = UIColor.clear.cgColor
        searchBarRightViewButton.layer.borderWidth = 2
        
        searchBarRightViewButton.addTarget(self, action: #selector(rightButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: searchBarRightViewButton)
        spacer_2.addSubview(searchBarRightViewButton)
        searchBar.rightView = spacer_2
        searchBar.rightViewMode = .always
        
        /** Layout and animate these subviews*/
        searchBar.alpha = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 1){ [self] in
            searchBar.frame.origin = CGPoint(x: searchBarContainer.frame.width/2 - searchBar.frame.width/2, y: searchBarContainer.frame.height/2 - searchBar.frame.height/2)
            
            searchBar.transform = CGAffineTransform(scaleX: 0, y: 0)
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
                searchBar.alpha = 1
                searchBar.transform = CGAffineTransform(scaleX: 1, y: 1)
            }
        }
        
        searchBarContainer.addSubview(searchBar)
        
        navigationController!.navigationBar.topItem?.titleView = searchBarContainer
        navigationController!.navigationBar.prefersLargeTitles = false
        navigationController?.navigationItem.largeTitleDisplayMode = .never
        navigationController!.navigationBar.sizeToFit()
        navigationController!.navigationBar.backgroundColor = .clear
    }
    
    /** Textfield delegate methods*/
    /** Triggered when the textfield is getting ready to begin editting*/
    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool{
        markTextFieldAsFocused(textField: textField)
        
        if textField == searchBar{
            UIView.transition(with: searchBarLeftViewButton, duration: 0.5, options: .transitionFlipFromLeft, animations: { [self] in
                searchBarLeftViewButton.setImage(UIImage(systemName: "chevron.backward.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
            })
        }
        
        return true
    }
    
    /** Triggered when the user starts editing the textfield's content*/
    public func textFieldDidBeginEditing(_ textField: UITextField){
        
        /** Turn the right view button into a cancel button*/
        if textField == searchBar{
            searchBarRightViewButton.layer.borderWidth = 0
            searchBarRightViewButton.contentMode = .scaleAspectFit
            
            UIView.transition(with: searchBarRightViewButton, duration: 0.5, options: .transitionCrossDissolve, animations: { [self] in
                searchBarRightViewButton.setImage(UIImage(systemName: "x.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
            })
        }
    }
    
    /** Triggered when the user stops editing the textfield's content*/
    public func textFieldDidEndEditing(_ textField: UITextField) {
        /** Turn the right view button into a cancel button*/
        if textField == searchBar{
            searchBarRightViewButton.contentMode = .scaleAspectFill
            
            UIView.transition(with: searchBarRightViewButton, duration: 0.5, options: .transitionCrossDissolve, animations: { [self] in
                searchBarRightViewButton.setImage(userProfilePicture ?? UIImage(named: "user"), for: .normal)
                
                searchBarRightViewButton.layer.borderColor = appThemeColor.cgColor
                searchBarRightViewButton.layer.borderWidth = 2
            })
        }
    }
    
    /** Triggered when the textfield is getting ready to end editing*/
    public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool{
        restoreOriginalTextFieldStyling(textField: textField)
        
        if textField == searchBar{
            UIView.transition(with: searchBarLeftViewButton, duration: 0.5, options: .transitionFlipFromRight, animations: { [self] in
                searchBarLeftViewButton.setImage(UIImage(systemName: "magnifyingglass.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
            })
        }
        
        return true
    }
    
    /**When a user presses the return or done etc key, then simply hide the keyboard*/
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        /** If internet isn't available don't even try to do anything*/
        guard internetAvailable == true else{
            textField.resignFirstResponder()
            return true
        }
        
        textField.resignFirstResponder()
        return true
    }
    
    /** Dynamic styling of textfields*/
    /** Create a blue border around the textfield to inform the user that it's now in focus aka they're able to type in it*/
    func markTextFieldAsFocused(textField: UITextField){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            textField.layer.borderWidth = 2
            textField.layer.borderColor = appThemeColor.cgColor
        }
    }
    
    func restoreOriginalTextFieldStyling(textField: UITextField){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            textField.layer.borderColor = UIColor.darkGray.withAlphaComponent(0.25).cgColor
            textField.layer.borderWidth = 0
        }
    }
    
    func markTextFieldEntryAsIncorrect(textField: UITextField){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            textField.layer.borderColor = UIColor.red.withAlphaComponent(0.25).cgColor
            textField.layer.borderWidth = 1
        }
    }
    
    func markTextFieldEntryAsCorrect(textField: UITextField){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            textField.layer.borderColor = UIColor.green.withAlphaComponent(0.25).cgColor
            textField.layer.borderWidth = 1
        }
    }
    /** Dynamic styling of textfields*/
    /** Textfield delegate methods*/
    
    /**Customize the nav and tab bars for this view*/
    func setCustomNavUI(){
        ///navigationController?.hidesBarsOnSwipe = true
        
        /**Prevent the scrollview from snapping into place when integrating with large title nav bar*/
        self.extendedLayoutIncludesOpaqueBars = true
        
        /**Tab bar and nav bar customization*/
        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.configureWithOpaqueBackground()
        standardAppearance.shadowColor = UIColor.clear
        
        let standardTabbarAppearance = UITabBarAppearance()
        standardTabbarAppearance.configureWithOpaqueBackground()
        tabBarController?.tabBar.layer.cornerRadius = 0
        tabBarController?.tabBar.layer.borderWidth = 0.5
        tabBarController?.tabBar.layer.borderColor = UIColor.lightGray.cgColor
        tabBarController?.tabBar.layer.shadowColor = UIColor.lightGray.cgColor
        tabBarController?.tabBar.layer.shadowOpacity = 0.5
        tabBarController?.tabBar.layer.shadowRadius = 3
        tabBarController?.tabBar.layer.shadowPath = UIBezierPath(roundedRect: (tabBarController?.tabBar.bounds)!, cornerRadius: (tabBarController?.tabBar.layer.cornerRadius)!).cgPath
        tabBarController?.tabBar.clipsToBounds = false
        
        
        navigationItem.leftItemsSupplementBackButton = true
        switch darkMode{
        case true:
            navigationController?.navigationBar.barTintColor = bgColor
            navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: fontColor]
            navigationController?.navigationBar.tintColor = fontColor
            
            tabBarController?.tabBar.barTintColor = UIColor.black
            tabBarController?.tabBar.tintColor = appThemeColor
            standardTabbarAppearance.backgroundColor = .black
            
            standardAppearance.backgroundColor = .clear
            standardAppearance.largeTitleTextAttributes = [.foregroundColor: fontColor, NSAttributedString.Key.font: getCustomFont(name: .Ubuntu_bold, size: 30, dynamicSize: true)]
            standardAppearance.titleTextAttributes = [.foregroundColor: fontColor, NSAttributedString.Key.font: getCustomFont(name: .Ubuntu_Light, size: 16, dynamicSize: true)]
            
            /**Customize the navigation items if any are present*/
            if(navigationItem.rightBarButtonItems?.count != nil){
                for index in 0..<self.navigationItem.rightBarButtonItems!.count{
                    navigationItem.rightBarButtonItems?[index].tintColor = fontColor
                }
            }
            if(navigationItem.leftBarButtonItems?.count != nil){
                for index in 0..<self.navigationItem.leftBarButtonItems!.count{
                    navigationItem.leftBarButtonItems?[index].tintColor = fontColor
                }
            }
            
        case false:
            navigationController?.navigationBar.barTintColor = bgColor
            navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
            navigationController?.navigationBar.tintColor = appThemeColor
            
            tabBarController?.tabBar.barTintColor = UIColor.white
            tabBarController?.tabBar.tintColor = appThemeColor
            standardTabbarAppearance.backgroundColor = .white
            
            standardAppearance.backgroundColor = .clear
            standardAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white, NSAttributedString.Key.font: getCustomFont(name: .Ubuntu_bold, size: 30, dynamicSize: true)]
            standardAppearance.titleTextAttributes = [.foregroundColor: UIColor.white, NSAttributedString.Key.font: getCustomFont(name: .Ubuntu_Light, size: 16, dynamicSize: true)]
            
            /**Customize the navigation items if any are present*/
            if(navigationItem.rightBarButtonItems?.count != nil){
                for index in 0..<self.navigationItem.rightBarButtonItems!.count{
                    navigationItem.rightBarButtonItems?[index].tintColor = UIColor.white
                }
            }
            if(navigationItem.leftBarButtonItems?.count != nil){
                for index in 0..<self.navigationItem.leftBarButtonItems!.count{
                    navigationItem.leftBarButtonItems?[index].tintColor = UIColor.white
                }
            }
        }
        navigationController?.navigationBar.standardAppearance = standardAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = standardAppearance
        
        tabBarController?.tabBar.standardAppearance = standardTabbarAppearance
        if #available(iOS 15.0, *) {
            tabBarController?.tabBar.scrollEdgeAppearance = standardTabbarAppearance
        } else {
            ///Fallback on earlier versions, no other solutions
        }
    }
    
    /** Scrollview delegate methods*/
    /** Animate the tabbar appearing and disappearing to give the user more space to view everything*/
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView){
        let actualPosition = scrollView.panGestureRecognizer.translation(in: scrollView)
        
        if scrollView == bottomSheet.scrollView{
            if actualPosition.y > 0{
                /** Scrolled down, scrollview moves up*/
                showTabbar()
            }
            else{
                /** Scrolled up, scrollview moves down*/
                hideTabbar()
            }
        }
    }
    
    /** Detect when a scroll view scrolls*/
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == ordersTableView{
            /** Trigger refresh animation*/
            ordersBottomSheetRefreshControl.updateProgress(with: scrollView.contentOffset.y)
        }
        
        if scrollView == laundromatLocationsCollectionView{
            let pageIndex = round(scrollView.contentOffset.x/self.view.frame.width)
            
            /** Trigger refresh animation*/
            bottomSheetRefreshControl.updateProgress(with: scrollView.contentOffset.y)
            
            for (marker, laundromat) in mapMarkers{
                let laundromatCell = laundromatLocationsCollectionView.cellForItem(at: IndexPath(row: Int(pageIndex), section: 0))
                
                guard laundromatCell != nil else {
                    continue
                }
                
                if let storedLaundromat = laundromatCell as? LaundromatLocationCollectionViewCell{
                    if laundromat == storedLaundromat.laundromatData{
                        /** Zoom in to the given location*/
                        let position = GMSCameraPosition(latitude: marker.position.latitude, longitude: marker.position.longitude, zoom: streetLevelZoomLevel)
                        
                        /** Specify the animation duration of the camera position update animation*/
                        CATransaction.begin()
                        CATransaction.setValue(1, forKey: kCATransactionAnimationDuration)
                        mapView.animate(to: position)
                        CATransaction.commit()
                    }
                }
            }
        }
    }
    
    /** Hide the tabbar in an animated fashion*/
    func hideTabbar(){
        guard customTabbar != nil else {
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now()){
            UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn){
                self.customTabbar.frame.origin = CGPoint(x: 0, y: self.view.frame.height * 1.1)
            }
        }
        
        /** Prevent the tabbar from being unhidden*/
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1){
            self.customTabbar.isHidden = true
        }
    }
    
    /** Show the tabbar in an animated fashion*/
    func showTabbar(){
        guard customTabbar != nil else {
            return
        }
        
        self.customTabbar.isHidden = false
        
        DispatchQueue.main.asyncAfter(deadline: .now()){
            UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn){
                self.customTabbar.frame.origin = CGPoint(x: 0, y: self.view.frame.height - (self.customTabbar.frame.height))
            }
        }
    }
    /** Scrollview delegate methods*/
    
    /** Collectionview delegate methods*/
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var count = 0
        
        if collectionView == laundromatLocationsCollectionView{
            count = laundromats.count
        }
        
        return count
    }
    
    /** Supplement data to the collection view*/
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell = UICollectionViewCell()
        
        /** Identify the collectionview in question*/
        if collectionView == laundromatLocationsCollectionView{
            let laundromatLocationCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: LaundromatLocationCollectionViewCell.identifier, for: indexPath) as! LaundromatLocationCollectionViewCell
            
            laundromatLocationCollectionViewCell.create(with: laundromats[indexPath.row], presentingVC: self)
            
            cell = laundromatLocationCollectionViewCell
            
            /** Wait 2 seconds to start updating the distance label*/
            DispatchQueue.main.asyncAfter(deadline: .now() + 2){[self] in
                /** Update the distance of the user from various laundromat locations when these tableview cells are intiailized*/
                if laundromatLocationsCollectionView != nil && mapView != nil{
                    if let cells = laundromatLocationsCollectionView.visibleCells as? [LaundromatLocationCollectionViewCell]{
                        for cell in cells{
                            
                            /** Make sure the cell actually has data stored before unwrapping something that's not there and make sure the user has their location enabled*/
                            guard cell.laundromatData?.coordinates.latitude != nil && cell.laundromatData?.coordinates.longitude != nil && mapView.myLocation != nil else{
                                break
                            }
                            
                            /** Store the location of the laundromat as a coordinate point by unwrapping its Geopoint coordinate*/
                            let storeLocation = CLLocation(latitude: (cell.laundromatData?.coordinates.latitude)!, longitude: (cell.laundromatData?.coordinates.longitude)!)
                            
                            /** Compute the distance between the two coordinates (in meters)*/
                            let distance = mapView.myLocation!.distance(from: storeLocation)
                            
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
                            
                            cell.subview?.distanceLabel.text = abbreviateMiles(miles: distanceInMiles, feetAbbreviation: "ft", milesAbbreviation: "mi") + " \(distanceEmoji)"
                            cell.subview?.distanceLabel.sizeToFit()
                            
                            /** If the distance label is currently invisible then make it appear*/
                            if cell.subview?.distanceLabel.alpha == 0{
                                UIView.animate(withDuration: 0.5, delay: 0){
                                    cell.subview?.distanceLabel.alpha = 1
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.view.frame.width, height: 350)
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        mediumHaptic()
        
        /** Present the detail views for the following cells*/
        if collectionView == laundromatLocationsCollectionView{
            let vc = LaundromatLocationDetailVC(laundromatData: laundromats[indexPath.row])
            
            vc.modalTransitionStyle = .coverVertical
            vc.modalPresentationStyle = .fullScreen
            self.tabBarController?.present(vc, animated: true)
        }
    }
    /** Collectionview delegate methods*/
    
    /** Tableview delegate methods*/
    /**Set the number of rows in the table view*/
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = 0
        
        if tableView == laundromatLocationsTableView{
            count = laundromats.count
        }
        
        if tableView == ordersTableView && section == 0{
            count = rowsForSection[section]
        }
        else if tableView == ordersTableView && section == 1{
            count = rowsForSection[section]
        }
        
        return count
    }
    
    /**Create a standard header that includes the returned text*/
    func tableView(_ tableView: UITableView, titleForHeaderInSection
                   section: Int) -> String?{
        var headerTitle: String? = nil
        
        if tableView == ordersTableView{
            switch section{
            case 0:
                headerTitle = "Current orders"
            case 1:
                headerTitle = "Past orders"
            default:
                break
            }
        }
        
        return headerTitle
    }
    
    /** Customize font color for header view of section for table view**/
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int){
        
        if tableView == ordersTableView{
            let header = view as! UITableViewHeaderFooterView
            header.tintColor = fontColor
            header.isUserInteractionEnabled = true
            header.tag = section
            header.isExclusiveTouch = true
            header.autoresizesSubviews = true
            
            var config = header.defaultContentConfiguration()
            var textProperties = config.textProperties
            textProperties.color = fontColor
            textProperties.font = getCustomFont(name: .Ubuntu_Medium, size: 18, dynamicSize: true)
            
            /** Titles for the section headers*/
            switch section{
            case 0:
                config.text = "Current orders"
            case 1:
                config.text = "Past orders"
            default:
                break
            }
            
            config.textProperties = textProperties
            header.contentConfiguration = config
            
            /** Clear imageview added to the header in order to prevent duplicate imageviews when the header's subviews are removed when this part of the tableview leaves the the viewport */
            for subview in header.subviews{
                if let view = subview as? UIImageView{
                    view.removeFromSuperview()
                }
            }
            
            /** Make all sections expandable and collapsible*/
            /** Image view with chevron added to header view*/
            imageViewsForSection[section].image = UIImage(systemName: "chevron.forward", withConfiguration: UIImage.SymbolConfiguration(weight: .regular))
            imageViewsForSection[section].contentMode = .scaleAspectFit
            imageViewsForSection[section].backgroundColor = UIColor.clear
            imageViewsForSection[section].tintColor = fontColor
            
            DispatchQueue.main.async{ [self] in
                imageViewsForSection[section].frame = CGRect(x: header.frame.maxX - 40, y: header.frame.height/2 - (20/2), width: 20, height: 20)
            }
            
            /** Rotate chevron if the section is open*/
            if rowsForSection[section] != 0{
                UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){ [self] in
                    imageViewsForSection[section].transform = CGAffineTransform(rotationAngle: .pi/2)
                }
            }
            
            header.addSubview(imageViewsForSection[section])
            
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(sectionPressed))
            header.addGestureRecognizer(tapGestureRecognizer)
        }
    }
    
    /** Handle a tap event on a section header view*/
    @objc func sectionPressed(sender: UITapGestureRecognizer){
        let header = sender.view as! UITableViewHeaderFooterView
        let section = header.tag
        
        guard ordersTableView != nil else {
            return
        }
        
        lightHaptic()
        switch section{
        case 0:
            if rowsForSection[section] == 0{
                /** Open the section if the section is already closed*/
                rowsForSection[section] = 5
                
                UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
                    imageViewsForSection[section].transform = CGAffineTransform(rotationAngle: .pi/2)
                }
            }
            else{
                /** Close the section if the section is open**/
                rowsForSection[section] = 0
                
                UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
                    imageViewsForSection[section].transform = CGAffineTransform(rotationAngle: 0)
                }
            }
            self.ordersTableView!.reloadSections([section], with: .automatic)
        case 1:
            if rowsForSection[section] == 0{
                /** Open the section if the section is already closed*/
                rowsForSection[section] = 20
                
                UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
                    imageViewsForSection[section].transform = CGAffineTransform(rotationAngle: .pi/2)
                }
            }
            else{
                /** Close the section if the section is open**/
                rowsForSection[section] = 0
                
                UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
                    imageViewsForSection[section].transform = CGAffineTransform(rotationAngle: 0)
                }
            }
            
            self.ordersTableView!.reloadSections([section], with: .automatic)
        default:
            break
        }
    }
    
    /** Specify the number of sections for the given table view*/
    func numberOfSections(in tableView: UITableView) -> Int {
        var numberOfSections = 1
        
        if tableView == ordersTableView{
            numberOfSections = 2
        }
        
        return numberOfSections
    }
    
    /** Set the height for the following section headers*/
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        var height:CGFloat  = 0
        
        if tableView == ordersTableView{
            height = 40
        }
        
        return height
    }
    
    /** Set the height for the following section footers*/
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        var height:CGFloat = 0
        
        if tableView == ordersTableView{
            height = 0
        }
        
        return height
    }
    
    /** Detect when a user selects a row in the tableview*/
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        mediumHaptic()
        
        /** Present the detail views for the following cells*/
        if tableView == laundromatLocationsTableView{
            let vc = LaundromatLocationDetailVC(laundromatData: laundromats[indexPath.row])
            
            vc.modalTransitionStyle = .coverVertical
            vc.modalPresentationStyle = .fullScreen
            self.tabBarController?.present(vc, animated: true)
        }
        
        if tableView == ordersTableView{
            if indexPath.section == 0{
                let vc = CurrentOrderDetailVC()
                vc.modalTransitionStyle = .coverVertical
                vc.modalPresentationStyle = .fullScreen
                self.tabBarController?.present(vc, animated: true)
            }
            else if indexPath.section == 1{
                let vc = PastOrderDetailVC()
                vc.modalTransitionStyle = .coverVertical
                vc.modalPresentationStyle = .fullScreen
                self.tabBarController?.present(vc, animated: true)
            }
        }
    }
    
    /**Here we pass the table view all of the data for the cells*/
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        var cell = UITableViewCell()
        
        /** Identify the tableview in question*/
        if tableView == laundromatLocationsTableView{
            let laundromatLocationTableViewCell = tableView.dequeueReusableCell(withIdentifier: LaundromatLocationTableViewCell.identifier, for: indexPath) as! LaundromatLocationTableViewCell
            
            laundromatLocationTableViewCell.create(with: laundromats[indexPath.row], presentingVC: self)
            
            cell = laundromatLocationTableViewCell
            
            /** Wait 2 seconds to start updating the distance label*/
            DispatchQueue.main.asyncAfter(deadline: .now() + 2){[self] in
                /** Update the distance of the user from various laundromat locations when these tableview cells are intiailized*/
                if laundromatLocationsTableView != nil && mapView != nil{
                    if let cells = laundromatLocationsTableView.visibleCells as? [LaundromatLocationTableViewCell]{
                        for cell in cells{
                            
                            /** Make sure the cell actually has data stored before unwrapping something that's not there and make sure the user has their location enabled*/
                            guard cell.laundromatData?.coordinates.latitude != nil && cell.laundromatData?.coordinates.longitude != nil && mapView.myLocation != nil else{
                                break
                            }
                            
                            /** Store the location of the laundromat as a coordinate point by unwrapping its Geopoint coordinate*/
                            let storeLocation = CLLocation(latitude: (cell.laundromatData?.coordinates.latitude)!, longitude: (cell.laundromatData?.coordinates.longitude)!)
                            
                            /** Compute the distance between the two coordinates (in meters)*/
                            let distance = mapView.myLocation!.distance(from: storeLocation)
                            
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
                            
                            cell.subview?.distanceLabel.text = abbreviateMiles(miles: distanceInMiles, feetAbbreviation: "ft", milesAbbreviation: "mi") + " \(distanceEmoji)"
                            cell.subview?.distanceLabel.sizeToFit()
                            
                            /** If the distance label is currently invisible then make it appear*/
                            if cell.subview?.distanceLabel.alpha == 0{
                                UIView.animate(withDuration: 0.5, delay: 0){
                                    cell.subview?.distanceLabel.alpha = 1
                                }
                            }
                        }
                    }
                }
            }
        }
        if tableView == ordersTableView{
            switch indexPath.section{
            case 0:
                break
            case 1:
                break
            default:
                break
            }
            
            let ordersTableViewCell = tableView.dequeueReusableCell(withIdentifier: ordersTableViewCell.identifier, for: indexPath) as! ordersTableViewCell
            
            ordersTableViewCell.create()
            
            cell = ordersTableViewCell
            
            /** If there's no orders available then add a simple subview that prompts the user to make an order, preferably a button that navigates back to the home tab and auto selects the nearest location and auto presses it*/
        }
        
        return cell
    }
    
    /** Specify the height of the rows for the tableviews*/
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var height: CGFloat = 0
        
        if tableView == laundromatLocationsTableView{
            height = 320
        }
        
        if tableView == ordersTableView{
            height = 100
        }
        
        return height
    }
    /** Tableview delegate methods*/
    
    /** Button pressed methods*/
    /** Navigate to the shopping cart view controller*/
    @objc func shoppingCartButtonPressed(sender: UIButton){
        let vc = ShoppingCartVC()
        
        vc.modalPresentationStyle = .formSheet
        vc.modalTransitionStyle = .coverVertical
        self.tabBarController?.present(vc, animated: true)
    }
    
    /** Navigate to the customer support vc*/
    @objc func customerSupportButtonPressed(sender: UIButton){
        let vc = CustomerSupportUserClient()
        
        hideTabbar()
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle = .crossDissolve
        self.tabBarController?.present(vc, animated: true)
    }
    
    /** Go to the user's current location when they press this button*/
    @objc func currentLocationButtonPressed(sender: UIButton){
        guard mapView != nil else {
            return
        }
        
        guard mapView.myLocation != nil else {
            globallyTransmit(this: "Please enable access to your current location", with: UIImage(systemName: "paperplane.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .none, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
            return
        }
        
        let location = mapView.myLocation!
        
        /** Zoom in to the user's current location (if available) (Animated)*/
        let position = GMSCameraPosition(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: preciseLocationZoomLevel)
        
        /** Specify the animation duration of the camera position update animation*/
        CATransaction.begin()
        CATransaction.setValue(0.5, forKey: kCATransactionAnimationDuration)
        mapView.animate(to: position)
        CATransaction.commit()
        
        bottomSheet.show(animated: true)
    }
    /** Button pressed methods*/
    @objc func rightButtonPressed(sender: UIButton){
        lightHaptic()
        
        /** If the user taps this button while the search bar is editing then the search bar will clear its content*/
        if searchBar.isEditing == true{
            searchBar.text = ""
        }
    }
    
    @objc func leftButtonPressed(sender: UIButton){
        lightHaptic()
        
        /** If the user taps this button while the search bar is editing then the search bar will stop editing*/
        if searchBar.isEditing == true{
            searchBar.endEditing(true)
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
    
    /** A little something extra to keep things flashy*/
    /** Add the gesture recognizer to this view*/
    func addVisualSingleTapGestureRecognizer(){
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(viewSingleTapped))
        singleTap.numberOfTapsRequired = 1
        singleTap.numberOfTouchesRequired = 1
        singleTap.cancelsTouchesInView = false
        view.addGestureRecognizer(singleTap)
    }
    
    /** Show where the user taps on the screen*/
    @objc func viewSingleTapped(sender: UITapGestureRecognizer){
        /** Snapchat esque circular fade in fade out animation signals where the user has tapped*/
        let circleView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width * 0.05, height: view.frame.width * 0.05))
        circleView.layer.cornerRadius = circleView.frame.height/2
        circleView.layer.borderWidth = 0.5
        circleView.layer.borderColor = appThemeColor.cgColor
        circleView.backgroundColor = UIColor.clear
        circleView.clipsToBounds = true
        circleView.center.x = sender.location(in: view).x
        circleView.center.y = sender.location(in: view).y
        circleView.transform = CGAffineTransform(scaleX: 0, y: 0)
        
        let inscribedCircleView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width * 0.05, height: view.frame.width * 0.05))
        inscribedCircleView.layer.cornerRadius = inscribedCircleView.frame.height/2
        switch darkMode {
        case true:
            inscribedCircleView.backgroundColor = UIColor.lightGray.lighter.withAlphaComponent(0.5)
        case false:
            inscribedCircleView.backgroundColor = UIColor.white.darker.withAlphaComponent(0.5)
        }
        inscribedCircleView.transform = CGAffineTransform(scaleX: 0, y: 0)
        circleView.addSubview(inscribedCircleView)
        
        view.addSubview(circleView)
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .allowUserInteraction]){
            circleView.transform = CGAffineTransform(scaleX: 2, y: 2)
        }
        UIView.animate(withDuration: 0.5, delay: 0.1, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .allowUserInteraction]){
            inscribedCircleView.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        UIView.animate(withDuration: 0.5, delay: 0.4, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .allowUserInteraction]){
            circleView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            inscribedCircleView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        }
        UIView.animate(withDuration: 0.5, delay: 0.6, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .allowUserInteraction]){
            inscribedCircleView.alpha = 0
        }
        UIView.animate(withDuration: 0.5, delay: 0.7, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .allowUserInteraction]){
            circleView.alpha = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1){
            circleView.removeFromSuperview()
        }
    }
    /** A little something extra to keep things flashy*/
}
