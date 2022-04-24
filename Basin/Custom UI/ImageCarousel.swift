//
//  ImageCarousel.swift
//  Inspec
//
//  Created by Justin Cook on 1/5/22.
//

import Nuke
import UIKit

/** Scrollable image view collections made simple*/

/**
 Scrollable image view collections made simple
 
 - Author: Justin Cook
 */
/** Image carousel without the image saving and sharing option context menu*/
class imageCarousel: UIView, UIScrollViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource{
    
    var images: [UIImage]?
    var urls: [URL]?
    private var useURLs: Bool
    var contentBackgroundColor: UIColor?
    private var animatedTransition: Bool
    var transitionDuration: CGFloat?
    let infiniteScroll: Bool
    var showDetailViewOnTap: Bool
    var showContextMenu: Bool
    private var presentingVC: UIViewController?
    var showPageControl: Bool
    var pageControlActiveDotColor: UIColor?
    var pageControlInactiveDotColor: UIColor?
    var pageControlPosition: fourSidesPosition?
    /** Specifies whether or not to play the fade in animation every time this object is loaded up into a data source base UI Object like a table view*/
    var loadOnce: Bool
    /** String that depicts the current page the scrollview of the collectionview is currently on*/
    var imageCountLabelText = ""
    var showImageTrackerLabel: Bool
    var imageTrackerLabel = PaddedLabel(withInsets: 0, 0, 5, 5)
    var imageTrackerLabelPosition: fourCornersPosition?
    /** Timer used to fade out the image tracker label when it's being displayed*/
    var imageTrackerLabelFadeOutTimer = Timer()
    /** Specify the content mode of the image views for this carousel*/
    var imageViewContentMode: UIImageView.ContentMode
    
    /** Publicly Inaccessible variables*/
    fileprivate var imageViews = [UIImageView]()
    fileprivate var imageViewContainers = [UIView]()
    fileprivate var collectionView: UICollectionView? = nil
    fileprivate var pageControl = UIPageControl()
    fileprivate var imageCount = 0
    fileprivate var autoMoveTimer = Timer()
    fileprivate var autoMoveTimerActive = false
    fileprivate var animationDuration: CGFloat = 0
    fileprivate var timeInterval: Double = 0
    fileprivate var timerRepeating = false
    fileprivate var timerAnimated = false
    fileprivate var timerPaused = false
    
    /**
     -  parameter frame: Specifies the size of the image carousel and its encased subviews
     -  parameter images: An array of UIImages that will be used to populate the scrollview embedded stackview filled with imageviews
     -  parameter userURLs: Indicates whether or not to use the provided urls to download the image resources instead of using any included UIimages
     -  parameter animatedTransition: Specifies whether or not to animate the UIView fading in.
     -  parameter transitionDuration: The duration of the fade in animation.
     -  parameter infiniteScroll: Enable or disable scrollview looping, looping switches around the imageViews in the stackView whenever the user scrolls
     
     - Author: Justin Cook
     
     Important: This custom UI object is dependent on Nuke to load images from provided URL resources
     */
    init(frame: CGRect, images: [UIImage]?, urls: [URL]?, useURLs: Bool, contentBackgroundColor: UIColor?, animatedTransition: Bool, transitionDuration: CGFloat?, infiniteScroll: Bool, showDetailViewOnTap: Bool, showContextMenu: Bool, presentingVC: UIViewController, showPageControl: Bool, pageControlActiveDotColor: UIColor?, pageControlInactiveDotColor: UIColor?, pageControlPosition: fourSidesPosition?, loadOnce: Bool, showImageTrackerLabel: Bool, imageTrackerLabelPosition: fourCornersPosition?, imageViewContentMode: UIImageView.ContentMode){
        
        self.images = images
        self.urls = urls
        self.useURLs = useURLs
        self.contentBackgroundColor = contentBackgroundColor
        self.animatedTransition = animatedTransition
        self.transitionDuration = transitionDuration
        self.infiniteScroll = infiniteScroll
        self.showDetailViewOnTap = showDetailViewOnTap
        self.showContextMenu = showContextMenu
        self.presentingVC = presentingVC
        self.showPageControl = showPageControl
        self.pageControlActiveDotColor = pageControlActiveDotColor
        self.pageControlInactiveDotColor = pageControlInactiveDotColor
        self.pageControlPosition = pageControlPosition
        self.loadOnce = loadOnce
        self.showImageTrackerLabel = showImageTrackerLabel
        self.imageTrackerLabelPosition = imageTrackerLabelPosition
        self.imageViewContentMode = imageViewContentMode
        
        super.init(frame: frame)
        
        /** Set default values for nil parameters*/
        if transitionDuration == nil{self.transitionDuration = 0}
        if pageControlActiveDotColor == nil{self.pageControlActiveDotColor = UIColor.darkGray}
        if pageControlInactiveDotColor == nil{self.pageControlInactiveDotColor = UIColor.lightGray}
        if pageControlPosition == nil{self.pageControlPosition = .bottom}
        /** Set default values for nil parameters*/
        
        /** Get the amount of images to be displayed by the carousel, if none are provided then the default value is 0 and the carousel will be blank*/
        if useURLs == false{
            if images != nil{
                imageCount =  images!.count
            }
            else{
                imageCount = 0
            }
        }
        else{
            if urls != nil{
                imageCount = urls!.count
            }
            else{
                imageCount = 0
            }
        }
        
        buildUI()
    }
    
    /** Move the scrollview automatically by firing a timer for a specific amount of time*/
    func autoMove(timeInterval: Double, animationDuration: CGFloat, animated: Bool, repeating: Bool){
        guard imageCount > 1 else {
            return
        }
        
        self.timeInterval = timeInterval
        self.autoMoveTimerActive = true
        self.animationDuration = animationDuration
        self.timerRepeating = repeating
        self.timerAnimated = animated
        
        autoMoveTimer.invalidate()
        autoMoveTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: repeating){[self] _ in
            if animated{
                DispatchQueue.main.async{
                    UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
                        collectionView!.setContentOffset(CGPoint(x: collectionView!.contentOffset.x + collectionView!.frame.width, y: 0), animated: true)
                    }
                }
            }else{
                collectionView!.setContentOffset(CGPoint(x: collectionView!.contentOffset.x + collectionView!.frame.width, y: 0), animated: false)
            }
        }
    }
    
    /** Invalidate the auto move timer*/
    func stopAutoMove(){
        autoMoveTimer.invalidate()
    }
    
    /** Pause the auto move functionality*/
    func pauseAutoMove(){
        stopAutoMove()
        timerPaused = true
    }
    
    /** Resume auto move functionality*/
    func resumeAutoMove(){
        timerPaused = false
        autoMove(timeInterval: self.timeInterval, animationDuration: self.animationDuration, animated: self.timerAnimated, repeating: self.timerRepeating)
    }
    
    /**Construct the user interface using the specified parameters from the constructor*/
    private func buildUI(){
        /** Make the alpha of this view 0*/
        self.alpha = 0
        self.backgroundColor = contentBackgroundColor
        
        imageCountLabelText = "Image 1 of \(imageCount)"
        
        /** Infinite carousel scroll*/
        /** The infinite carousel works by having 3 sets of one set of imageviews arranged side by side, the first element of the middle set is the starting position of the carousel, and the leftmost set represents a backwards movement where the scrollview is then repositioned to the last element of the middle set. The rightmost set represents a forwards movement where the scrollview is repositioned to the first element of the middle set, and the cycle repeats from there*/
        if infiniteScroll == true && imageCount > 1{
            loadImages()
            loadImages()
            loadImages()
        }
        else{
            loadImages()
        }
        
        imageTrackerLabel.alpha = 0
        imageTrackerLabel.text = "1 / \(imageCount)"
        imageTrackerLabel.frame.size.height = 30
        imageTrackerLabel.textAlignment = .center
        imageTrackerLabel.backgroundColor = UIColor.darkGray.withAlphaComponent(0.9)
        imageTrackerLabel.frame.size.width = 60
        imageTrackerLabel.layer.cornerRadius = 16
        imageTrackerLabel.textColor = UIColor.white
        imageTrackerLabel.adjustsFontSizeToFitWidth = true
        imageTrackerLabel.font = getCustomFont(name: .Ubuntu_Light, size: 16, dynamicSize: false)
        imageTrackerLabel.clipsToBounds = true
        
        if imageTrackerLabelPosition != nil{
            switch imageTrackerLabelPosition!{
            case .lowerLeft:
                imageTrackerLabel.frame.origin = CGPoint(x: self.frame.minX + imageTrackerLabel.frame.width * 0.1, y: self.frame.maxY - imageTrackerLabel.frame.height * 1.25)
            case .lowerRight:
                imageTrackerLabel.frame.origin = CGPoint(x: self.frame.maxX - imageTrackerLabel.frame.width * 1.1, y: self.frame.maxY - imageTrackerLabel.frame.height * 1.25)
            case .upperLeft:
                imageTrackerLabel.frame.origin = CGPoint(x: self.frame.minX + imageTrackerLabel.frame.width * 0.1, y: self.frame.minY + imageTrackerLabel.frame.height * 0.25)
            case .upperRight:
                imageTrackerLabel.frame.origin = CGPoint(x: self.frame.maxX - imageTrackerLabel.frame.width * 1.1, y: self.frame.minY + imageTrackerLabel.frame.height * 0.25)
            }
        }else{/**Upper right corner**/
            imageTrackerLabel.frame.origin = CGPoint(x: self.frame.maxX - imageTrackerLabel.frame.width * 1.1, y: self.frame.minY + imageTrackerLabel.frame.height * 0.25)
        }
        
        if showImageTrackerLabel == false{
            imageTrackerLabel.alpha = 0
        }
        
        pageControl.currentPageIndicatorTintColor = pageControlActiveDotColor
        pageControl.numberOfPages = imageCount
        pageControl.backgroundStyle = .minimal
        pageControl.pageIndicatorTintColor = pageControlInactiveDotColor
        pageControl.frame.size.height = 30
        pageControl.frame.size.width = pageControl.intrinsicContentSize.width
        pageControl.layer.borderWidth = 0.5
        pageControl.layer.cornerRadius = 14
        pageControl.isExclusiveTouch = true
        pageControl.isUserInteractionEnabled = true
        pageControl.hidesForSinglePage = true
        pageControl.layer.borderColor = UIColor.clear.cgColor
        pageControl.backgroundColor = UIColor.clear
        pageControl.isEnabled = true
        pageControl.addTarget(self, action: #selector(pageControlTapped), for: .touchUpInside)
        pageControl.isExclusiveTouch = true
        
        if pageControlPosition != nil{
            switch pageControlPosition!{
            case .left:
                pageControl.transform = CGAffineTransform(rotationAngle: .pi/2)
                pageControl.frame.origin = CGPoint(x: self.frame.minX, y: self.frame.height/2 - pageControl.frame.height/2)
            case .right:
                pageControl.transform = CGAffineTransform(rotationAngle: .pi/2)
                pageControl.frame.origin = CGPoint(x: self.frame.maxX - pageControl.frame.width, y: self.frame.height/2 - pageControl.frame.height/2)
            case .top:
                pageControl.frame.origin = CGPoint(x: self.frame.width/2 - pageControl.frame.width/2, y: self.frame.minY)
            case .bottom:
                pageControl.frame.origin = CGPoint(x: self.frame.width/2 - pageControl.frame.width/2, y: self.frame.maxY - pageControl.frame.height)
            }
        }
        else{
            /** Default placement is at the bottom of the imageviews*/
            pageControl.frame.origin = CGPoint(x: self.frame.width/2 - pageControl.frame.width/2, y: imageViews[0].frame.maxY)
        }
        
        /** If there's only one image in the carousel then the page control isn't used, same with the image tracker label*/
        if imageCount == 1 || showPageControl == false || showImageTrackerLabel == false{
            pageControl.alpha = 0
            pageControl.isEnabled = false
            imageTrackerLabel.alpha = 0
        }
        
        /** Using a UI Collection View enables memory optimization by not rendering the images currently offscreen which is beneficial in this case because the given images must be replicated into 3 sets to give the user the illusion of an infinite scrollview*/
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        /** Specify item size in order to allow the collectionview to encompass all of them*/
        layout.itemSize = CGSize(width: self.frame.width, height: self.frame.height)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        collectionView = UICollectionView(frame: self.frame, collectionViewLayout: layout)
        collectionView!.register(ImageCarouselCollectionViewCell.self, forCellWithReuseIdentifier: ImageCarouselCollectionViewCell.identifier)
        collectionView!.delegate = self
        collectionView!.backgroundColor = UIColor.clear
        collectionView!.isPagingEnabled = true
        collectionView!.dataSource = self
        collectionView!.frame.origin = CGPoint(x: 0, y: 0)
        collectionView!.showsVerticalScrollIndicator = false
        collectionView!.showsHorizontalScrollIndicator = false
        collectionView!.isExclusiveTouch = true
        
        if infiniteScroll == true && imageCount > 1{
            /** Set the content offset to be equal to the middle most elements*/
            collectionView!.contentOffset = CGPoint(x: self.frame.width * CGFloat(imageCount), y: 0)
            collectionView!.contentSize = CGSize(width: self.frame.width * CGFloat(imageCount * 3), height: self.frame.height)
        }
        else{
            collectionView!.contentSize = CGSize(width: self.frame.width * CGFloat(imageCount), height: self.frame.height)
        }
        
        self.addSubview(collectionView!)
        self.addSubview(pageControl)
        self.addSubview(imageTrackerLabel)
    }
    
    func loadImages(){
        imageViews.removeAll()
        
        if useURLs == false{
            guard images != nil else {
                print("Error: No images provided!")
                return
            }
            /**Put includes images into imageviews*/
            for image in images!{
                /**Need a container in order to make the imageView padded **/
                let imageViewContainer = UIView()
                imageViewContainer.frame.size.height = self.frame.height
                imageViewContainer.frame.size.width = self.frame.width
                imageViewContainer.frame.origin = CGPoint(x: 0, y: 0)
                
                let imageView = UIImageView()
                imageView.frame.size.height = imageViewContainer.frame.height * 1
                imageView.frame.size.width = imageViewContainer.frame.width * 1
                imageView.frame.origin = CGPoint(x: imageViewContainer.frame.width/2 - imageView.frame.width/2, y: imageViewContainer.frame.height/2 - imageView.frame.height/2)
                imageView.contentMode = imageViewContentMode
                imageView.image = image
                
                imageViewContainer.addSubview(imageView)
                self.imageViews.append(imageView)
                self.imageViewContainers.append(imageViewContainer)
            }
            
            /** If this view was already loaded previously don't do the fade in animations any more*/
            if loadOnce == true{
                transitionDuration = 0
            }
            else{
                transitionDuration = 0.25
            }
            
            /**Fade the view in when the image is finished downloading*/
            func removePreloadAnimation(){
                UIView.animate(withDuration: transitionDuration!){
                    self.alpha = 1
                }
            }
            
            removePreloadAnimation()
        }
        else{
            guard urls != nil else {
                print("Error: No URLs provided!")
                return
            }
            
            /**Load images from urls into imageviews*/
            for _ in urls!{
                /**Need a container in order to make the imageView padded **/
                let imageViewContainer = UIView()
                imageViewContainer.frame.size.height = self.frame.height
                imageViewContainer.frame.size.width = self.frame.width
                imageViewContainer.frame.origin = CGPoint(x: 0, y: 0)
                
                let imageView = UIImageView()
                imageView.frame.size.height = imageViewContainer.frame.height * 1
                imageView.frame.size.width = imageViewContainer.frame.width * 1
                imageView.frame.origin = CGPoint(x: imageViewContainer.frame.width/2 - imageView.frame.width/2, y: imageViewContainer.frame.height/2 - imageView.frame.height/2)
                imageView.contentMode = imageViewContentMode
                
                imageViewContainer.addSubview(imageView)
                self.imageViews.append(imageView)
                self.imageViewContainers.append(imageViewContainer)
            }
            
            /** If this view was already loaded previously don't do the fade in animations any more*/
            if loadOnce == true{
                transitionDuration = 0
            }
            else{
                transitionDuration = 0.25
            }
            
            /**Fade the view in when the image is finished downloading*/
            func removePreloadAnimation(){
                UIView.animate(withDuration: transitionDuration!){
                    self.alpha = 1
                }
            }
            
            /**Loading options for the current image, placeholder, failure image, transition time etc*/
            let options = ImageLoadingOptions(
                transition: .fadeIn(duration: transitionDuration!))
            
            /**Load the images and handle its completion event*/
            for (index, imageView) in imageViews.enumerated(){
                let request = ImageRequest(url: urls![index])
                Nuke.loadImage(with: request, options: options, into: imageView, completion: {_ in removePreloadAnimation()})
                
                /** Add the images loaded up into the imageviews to the images array to be used for later*/
                images?.append(imageView.image!)
            }
        }
    }
    
    /** Override scrollview will begin decelerating to animate the tracker label appearing and disappearing (if enabled)*/
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView){
        if(scrollView.isPagingEnabled == true) && showImageTrackerLabel == true{
            let actualPosition = scrollView.panGestureRecognizer.translation(in: scrollView)
            
            if actualPosition.x > 0{
                /** Scrolled right, scrollview moves backwards*/
                DispatchQueue.main.asyncAfter(deadline: .now()){[self] in
                    UIView.animate(withDuration: 0.5, delay: 0){
                        self.imageTrackerLabel.alpha = 1
                    }
                }
            }
            else{
                /** Scrolled left, scrollview moves forwards*/
                DispatchQueue.main.asyncAfter(deadline: .now()){[self] in
                    UIView.animate(withDuration: 0.5, delay: 0){
                        self.imageTrackerLabel.alpha = 1
                    }
                }
            }
            
            /** Restart the timer's count down when this is repeated, this timer must be stored in memory in order to make invalidation possible or else new timers would continue to be instantiated*/
            imageTrackerLabelFadeOutTimer.invalidate()
            imageTrackerLabelFadeOutTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true){[self] _ in
                DispatchQueue.main.asyncAfter(deadline: .now()){[self] in
                    UIView.animate(withDuration: 0.5, delay: 0){
                        self.imageTrackerLabel.alpha = 0
                    }
                }
            }
        }
    }
    
    /**Page control and scrollView Listeners*/
    /**Default listener for UIScrollview to inform the instantiated page control of a page change*/
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        /** Make sure the scrollview has paging enabled*/
        if(scrollView.isPagingEnabled == true){
            
            if infiniteScroll == true{
                /** Note: Make sure the user is never at the beginning or the end of the 3 sets, this is bad and it ruins the illusion*/
                /** Failsafe: Beginning of the 3 sets, go forward to the middle!*/
                if scrollView.contentOffset.x == scrollView.frame.width * CGFloat(0){
                    scrollView.contentOffset.x = scrollView.frame.width * CGFloat((imageCount))
                }
                /** Failsafe: End of the 3 sets, go back to the middle!*/
                if scrollView.contentOffset.x == scrollView.frame.width * CGFloat((imageCount * 3) - 1){
                    scrollView.contentOffset.x = scrollView.frame.width * CGFloat((imageCount))
                }
                /** Note: Make sure the user is never at the beginning or the end of the 3 sets, this is bad and it ruins the illusion*/
                
                /** Sets the scrollview offset to be the middle most set when the user reaches outside of it*/
                /** If the user scrolls to the left then set the scrollview's offset to be the last element of the middle most set*/
                if scrollView.contentOffset.x <= scrollView.frame.width * CGFloat(imageCount - 1){
                    scrollView.contentOffset.x = scrollView.frame.width * CGFloat((imageCount * 2) - 1)
                }
                /** If the user scrolls to the first element of the last set then set the scrollview's offset to be the first element of the middle most set*/
                if scrollView.contentOffset.x >= scrollView.frame.width * CGFloat(imageCount * 2){
                    scrollView.contentOffset.x = scrollView.frame.width * CGFloat((imageCount))
                }
                /** Sets the scrollview offset to be the middle most set when the user reaches outside of it*/
                
                /** The offset of the scrollview's elements from the start of the scrollview*/
                let originalOffset = (scrollView.frame.width * CGFloat(imageCount * 3))/3
                let pageIndex = round((scrollView.contentOffset.x - originalOffset)/(scrollView.frame.width))
                
                pageControl.currentPage = Int(pageIndex)
            }
            else{
                let pageIndex = round(scrollView.contentOffset.x/self.frame.width)
                pageControl.currentPage = Int(pageIndex)
            }
            self.imageCountLabelText = "Image \(pageControl.currentPage + 1) of \(self.imageCount)"
            self.imageTrackerLabel.text = "\(pageControl.currentPage + 1) / \(self.imageCount)"
        }
    }
    
    /** Shift the scroll view to reflect the tap action on the page control*/
    @objc func pageControlTapped(_ sender: UIPageControl){
        /** Delay update in order to allow object to update as UI changes take effect*/
        DispatchQueue.main.asyncAfter(deadline: .now()){[self] in
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
                
                if infiniteScroll == false{
                    self.collectionView!.setContentOffset(CGPoint(x: self.frame.width * CGFloat(sender.currentPage), y: 0), animated: true)
                }
                else{
                    let originalOffset = (self.frame.width * CGFloat(imageCount * 3))/3
                    
                    self.collectionView!.setContentOffset(CGPoint(x: (self.frame.width * CGFloat(sender.currentPage)) + originalOffset, y: 0), animated: false)
                }
            }
        }
    }
    /** Page control and scrollView Listeners*/
    
    /** Various getter methods for private variables*/
    func getUseURLs()->Bool{
        return useURLs
    }
    func getPresentingVC()->UIViewController?{
        return presentingVC
    }
    func getAnimatedTransition()->Bool{
        return animatedTransition
    }
    func getPageControl()->UIPageControl{
        return pageControl
    }
    func getImageViews()->[UIImageView]{
        return imageViews
    }
    func getImages()->[UIImage]{
        var images = [UIImage]()
        
        for imageView in imageViews {
            images.append(imageView.image!)
        }
        
        return images
    }
    /** Various getter methods for private variables*/
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageViewContainers.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCarouselCollectionViewCell.identifier, for: indexPath) as! ImageCarouselCollectionViewCell
        
        var imageView = UIImageView()
        for view in imageViewContainers[indexPath.row].subviews{
            if let containedImageView = view as? UIImageView{
                imageView = containedImageView
            }
        }

        cell.contentView.backgroundColor = contentBackgroundColor
        cell.setUp(with: imageViewContainers[indexPath.row], containedImageView: imageView)
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.frame.width, height: self.frame.height)
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
    
    /** Context menu will disappear notif*/
    func collectionView(_ collectionView: UICollectionView, willEndContextMenuInteraction configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?){
        guard presentingVC != nil && showContextMenu == true else{
            return
        }
        if timerPaused == true{
            resumeAutoMove()
        }
    }
    
    /** Dismiss action view after peek animation finished then show the full view controller stored by the animator when the user taps on the cell*/
    func collectionView(_ collectionView: UICollectionView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        animator.addCompletion{ [self] in
            guard presentingVC != nil && showDetailViewOnTap == true else{
                if timerPaused == true{
                    resumeAutoMove()
                }
                return
            }
            
            if timerPaused == true{
                resumeAutoMove()
            }
            
            presentingVC!.modalPresentationStyle = .fullScreen
            presentingVC!.present(imageCarouselDetailView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height), imageCarousel: self, showImageTracker: true, backgroundColor: UIColor.clear), animated: true, completion: nil)
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard presentingVC != nil && showContextMenu == true else{
            return nil
        }
        
        ///let cell = collectionView.cellForItem(at: indexPath) as! ImageCarouselCollectionViewCell
        
        var children: [UIMenuElement] = []
        
        let expand = UIAction(title: "Expand", image: UIImage(systemName: "rectangle.expand.vertical")) { [self] action in
            lightHaptic()
            guard presentingVC != nil && showDetailViewOnTap == true else{
                if timerPaused == true{
                    resumeAutoMove()
                }
                return
            }
            
            if timerPaused == true{
                resumeAutoMove()
            }
            
            presentingVC!.modalPresentationStyle = .fullScreen
            presentingVC!.present(imageCarouselDetailView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height), imageCarousel: self, showImageTracker: true, backgroundColor: UIColor.clear), animated: true, completion: nil)
        }
        
        /** If the auto move timer is active then pause it and resume it after the context menu is done being displayed if the user doesn't tap to show further details */
        if autoMoveTimerActive == true{
            pauseAutoMove()
        }
        
        children.append(expand)
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil){ _ in
            UIMenu(title: "Interactions", children: children)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/** Display an imageCarousel in a 'focused' larger container*/
class imageCarouselDetailView: UIViewController{
    var imageCarousel: imageCarousel
    /**Blurred UIView that can overlayed ontop of another view as a subview*/
    private lazy var blurredView = getBlurredView()
    var imageTrackerLabel = PaddedLabel(withInsets: 0, 0, 5, 5)
    var showImageTracker: Bool
    /** Timer used to fade out the image tracker label when it's being displayed*/
    var imageTrackerLabelFadeOutTimer = Timer()
    /** Need a timer to change the text b/c this class needs to await the change in the imageCarousel view*/
    var imageTrackerTimer = Timer()
    var exitButton = UIButton()
    
    init(frame: CGRect, imageCarousel: imageCarousel, showImageTracker: Bool, backgroundColor: UIColor) {
        self.imageCarousel = imageCarousel
        self.showImageTracker = showImageTracker
        
        super.init(nibName: nil, bundle: nil)
        self.view.backgroundColor = backgroundColor
        self.view.frame = frame
    }
    
    override func viewDidLoad(){
        buildUI()
    }
    
    private func buildUI(){
        /** Prevent the context menu from presenting another detail view, this will create a loop of presenting this vc over and over again*/
        self.imageCarousel = Basin.imageCarousel(frame: CGRect(x: 0, y: view.frame.height/2 - view.frame.width/2, width: view.frame.width, height: view.frame.width), images: imageCarousel.images, urls: imageCarousel.urls, useURLs: imageCarousel.getUseURLs(), contentBackgroundColor: imageCarousel.contentBackgroundColor, animatedTransition: imageCarousel.getAnimatedTransition(), transitionDuration: imageCarousel.transitionDuration, infiniteScroll: imageCarousel.infiniteScroll, showDetailViewOnTap: false, showContextMenu: false, presentingVC: imageCarousel.getPresentingVC()!, showPageControl: imageCarousel.showPageControl, pageControlActiveDotColor: imageCarousel.pageControlActiveDotColor, pageControlInactiveDotColor: imageCarousel.pageControlInactiveDotColor, pageControlPosition: imageCarousel.pageControlPosition, loadOnce: imageCarousel.loadOnce, showImageTrackerLabel: false, imageTrackerLabelPosition: nil, imageViewContentMode: .scaleAspectFill)
        
        imageTrackerLabel.alpha = 0
        imageTrackerLabel.text = self.imageCarousel.imageCountLabelText
        imageTrackerLabel.frame.size.height = 30
        imageTrackerLabel.textAlignment = .center
        switch darkMode{
        case true:
            imageTrackerLabel.backgroundColor = UIColor.black
        case false:
            imageTrackerLabel.backgroundColor = bgColor
        }
        imageTrackerLabel.frame.size.width = view.frame.width/2.5
        imageTrackerLabel.layer.cornerRadius = 14
        imageTrackerLabel.textColor = fontColor
        imageTrackerLabel.adjustsFontSizeToFitWidth = true
        imageTrackerLabel.font = getCustomFont(name: .Ubuntu_Light, size: 16, dynamicSize: false)
        imageTrackerLabel.clipsToBounds = true
        imageTrackerLabel.frame.origin = CGPoint(x: view.frame.width/2 - imageTrackerLabel.frame.width/2, y: self.imageCarousel.frame.maxY + imageTrackerLabel.frame.height/2)
        
        let imageConfiguration = UIImage.SymbolConfiguration(weight: .regular)
        let image = UIImage(systemName: "xmark", withConfiguration: imageConfiguration)
        exitButton.imageEdgeInsets =  UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        exitButton.frame.size.height = 40
        exitButton.frame.size.width = exitButton.frame.size.height
        exitButton.backgroundColor = bgColor
        exitButton.tintColor = fontColor
        exitButton.setImage(image, for: .normal)
        exitButton.layer.cornerRadius = exitButton.frame.height/2
        exitButton.layer.shadowColor = UIColor.darkGray.cgColor
        exitButton.layer.shadowRadius = 1
        exitButton.layer.shadowOpacity = 1
        exitButton.clipsToBounds = true
        exitButton.layer.masksToBounds = false
        exitButton.isExclusiveTouch = true
        exitButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        exitButton.layer.shadowPath = UIBezierPath(roundedRect: exitButton.bounds, cornerRadius: exitButton.layer.cornerRadius).cgPath
        exitButton.frame.origin = CGPoint(x: view.frame.maxX - (exitButton.frame.width * 1.5), y: exitButton.frame.height/2)
        exitButton.addTarget(self, action: #selector(exitButtonPressed), for: .touchDown)
        
        let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(viewPanned))
        gestureRecognizer.delegate = self
        blurredView.addGestureRecognizer(gestureRecognizer)
        
        blurredView.contentView.addSubview(self.imageCarousel)
        blurredView.contentView.addSubview(exitButton)
        if showImageTracker == true{
            blurredView.contentView.addSubview(imageTrackerLabel)
        }
        view.addSubview(blurredView)
    }
    
    /** Allow the pan gesture recognizer to be recognized along with the scrollview*/
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
    
    /** Listen for changes in the embedded scrollview through this pan gesture recognizer*/
    @objc func viewPanned(sender: UIPanGestureRecognizer){
        /** Change the text to reflect the current page the scrollview is on*/
        imageTrackerTimer.invalidate()
        imageTrackerTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true){[self] _ in
            imageTrackerLabel.text = self.imageCarousel.imageCountLabelText
        }
        
        /** Animate the image tracker label appearing and disappearing*/
        DispatchQueue.main.asyncAfter(deadline: .now()){[self] in
            UIView.animate(withDuration: 0.5, delay: 0){
                self.imageTrackerLabel.alpha = 1
            }
        }
        
        /** Restart the timer's count down when this is repeated, this timer must be stored in memory in order to make invalidation possible or else new timers would continue to be instantiated*/
        imageTrackerLabelFadeOutTimer.invalidate()
        imageTrackerLabelFadeOutTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true){[self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now()){[self] in
                UIView.animate(withDuration: 0.5, delay: 0){
                    self.imageTrackerLabel.alpha = 0
                }
            }
        }
    }
    
    /** Manually dismiss the view controller with the press of this button*/
    @objc func exitButtonPressed(sender: UIButton){
        lightHaptic()
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.alpha = 0.8
            sender.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }
        UIView.animate(withDuration: 0.25, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.alpha = 1
            sender.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    /**Create a blurred UIView and return it back to a lazy variable to be used when it's needed*/
    func getBlurredView()->UIVisualEffectView{
        var effectView = UIVisualEffectView()
        
        switch darkMode{
        case true:
            effectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        case false:
            effectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialLight))
        }
        
        effectView.frame = UIScreen.main.bounds
        return effectView
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/** Convert strings into URLs*/
func stringToURL(stringArray: [String])->[URL]{
    var urls = [URL]()
    
    for string in stringArray{
        if URL(string: string) != nil{
            urls.append(URL(string: string)!)
        }
        else{
            print("Error: Cannot convert to URL, URL String invalid")
        }
    }
    return urls
}

/** Specifies four different sides of a square*/
public enum fourSidesPosition: Int{
    case left = 0
    case right = 1
    case top = 2
    case bottom = 3
}

/** Specifies four different corners of a square*/
public enum fourCornersPosition: Int{
    case lowerLeft = 0
    case lowerRight = 1
    case upperLeft = 2
    case upperRight = 3
}
