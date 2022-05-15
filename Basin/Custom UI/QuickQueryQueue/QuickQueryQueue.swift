//
//  QuickQueryQueue.swift
//  Basin
//
//  Created by Justin Cook on 5/10/22.
//

import Foundation
import UIKit
import Combine

/** A handy custom class that allows fast injection of search queries based on previous unique queries
 This class uses local data persistence in the form of core data
 All queries are stored in a set, and this set of unique queries is then referenced by a unique ID, ex.) A laundromat ID, an (optional) secondary parity key can also be specified if multiple quick query queues are to be used for a single search bar ex.) Menu category, so laundromat or dry cleaning
 The usage of quick queries can be turned off in the settings menu, once this is turned off all queries are deleted from memory*/
public class QuickQueryQueue: NSObject{
    /** Set of strings that allows for unique queries to be stored and later injected into search bars (the strings inside are all lowercased to provide a single case for uniformity)*/
    var queries: Set<String> = []
    /** Secondary key for parity when multiple quick query queue objects use the same primary idenitifier*/
    var secondaryKey: String? = nil
    /** Primary storage key for this object*/
    var primaryKey: String
    /** When this object was first created*/
    var created: Date
    /** When the queries set was last updated*/
    var updated: Date!
    /** The limit on the amount of queries that can be added to the set, default is 0 for unlimited amount*/
    var queryLimit: Int = 0
    /** Optional delegate for sending important events*/
    var delegate: QQQDelegate?
    
    init(primaryKey: String, created: Date) {
        self.primaryKey = primaryKey
        self.created = created
        self.updated = created
        
        super.init()
        
        /** Insert this object into the global set for loaded QQQs if its not already in there*/
        if quickQueryQueues.contains(self) == false{
            quickQueryQueues.insert(self)
        }
    }
    
    /** - Returns: True if there are no queries & false if there are queries currently present*/
    func isEmpty()->Bool{
        return queries.isEmpty
    }
    
    /** - Returns: The amount of queries in the set*/
    func count()->Int{
        return queries.count
    }
    
    /** - Returns: The index (int) of the given query*/
    func getIndexOfThis(query: String)->Int?{
        for (index, thisQuery) in queries.enumerated(){
            if thisQuery.lowercased() == query.lowercased(){return index}
        }
        
        return nil
    }
    
    /** - Returns: The query at the provided index (int)*/
    func getQueryfor(this index: Int)->String?{
        for (thisIndex, query) in queries.enumerated(){
            if thisIndex == index{return query.lowercased()}
        }
        
        return nil
    }
    
    /** Query addition and removal methods*/
    /** Removes all elements except the given (if it exists in the set)*/
    func removeAllExcept(this query: String){
        /** Don't operate if there are no queries*/
        guard count() > 0 else {
            return
        }
        
        /** Update the date of when this model was updated*/
        self.updated = .now
        
        let removeQueries = queries.filter { String in
            return String.lowercased() != query.lowercased()
        }
        quickQueryQueue(self, didRemoveThese: removeQueries.toArray() as! [String])
        
        queries = queries.filter { string in
            return string.lowercased() == query.lowercased()
        }
        
        /** Save the edits made to this object*/
        saveThisQuickQueryQueue(from: self)
    }
    
    func remove(these queries: [String]){
        guard count() > 0 else {
            return
        }
        
        var removedQueries: [String] = []
        
        for query in queries{
            if self.queries.contains(query.lowercased()){
                self.queries.remove(query.lowercased())
                removedQueries.append(query.lowercased())
            }
        }
        
        if removedQueries.count != 0{
            self.updated = .now
            
            /** Save the edits made to this object*/
            saveThisQuickQueryQueue(from: self)
            
            quickQueryQueue(self, didRemoveThese: removedQueries)
            
            if count() == 0{
                quickQueryQueue(self, didRemoveAll: removedQueries)
            }
        }
    }
    
    func remove(this query: String){
        guard count() > 0 && queries.contains(query.lowercased()) == true else {
            return
        }
        
        self.updated = .now
        
        queries.remove(query.lowercased())
        quickQueryQueue(self, didRemove: query.lowercased())
        
        /** Save the edits made to this object*/
        saveThisQuickQueryQueue(from: self)
        
        /** All queries removed*/
        if count() == 0{
            quickQueryQueue(self, didRemoveAll: [query.lowercased()])
        }
    }
    
    func removeAll(){
        guard count() > 0 else {
            return
        }
        
        self.updated = .now
        
        let removedQueries = lowerCase(this: queries.toArray() as! [String])
        queries.removeAll()
        quickQueryQueue(self, didRemoveAll: removedQueries)
        
        /** Save the edits made to this object*/
        saveThisQuickQueryQueue(from: self)
    }
    
    func add(this query: String){
        guard count() < queryLimit || queryLimit == 0 else {
            return
        }
        
        guard queries.contains(query) == false else{
            return
        }
        
        self.updated = .now
        
        queries.insert(query.lowercased())
        quickQueryQueue(self, didAppend: query.lowercased())
        
        /** Save the edits made to this object*/
        saveThisQuickQueryQueue(from: self)
    }
    
    func add(these queries: [String]){
        var appendedQueries: [String] = []
        
        for query in queries{
            if count() < queryLimit || queryLimit == 0{
                self.queries.insert(query.lowercased())
                appendedQueries.append(query.lowercased())
            }
        }
        
        if appendedQueries.count != 0{
            self.updated = .now
            
            /** Save the edits made to this object*/
            saveThisQuickQueryQueue(from: self)
            
            quickQueryQueue(self, didAppendThese: appendedQueries)
        }
    }
    /** Query addition and removal methods*/
    
    /** Implementing delegate methods*/
    fileprivate func quickQueryQueue(_ quickQueryQueue: QuickQueryQueue, didAppend query: String){
        delegate?.quickQueryQueue?(quickQueryQueue, didAppend: query)
    }
    
    fileprivate func quickQueryQueue(_ quickQueryQueue: QuickQueryQueue, didAppendThese queries: [String]){
        delegate?.quickQueryQueue?(quickQueryQueue, didAppendThese: queries)
    }
    
    fileprivate func quickQueryQueue(_ quickQueryQueue: QuickQueryQueue, didRemove query: String){
        delegate?.quickQueryQueue?(quickQueryQueue, didRemove: query)
    }
    
    fileprivate func quickQueryQueue(_ quickQueryQueue: QuickQueryQueue, didRemoveThese queries: [String]){
        delegate?.quickQueryQueue?(quickQueryQueue, didRemoveThese: queries)
    }
    
    fileprivate func quickQueryQueue(_ quickQueryQueue: QuickQueryQueue, didRemoveAll queries: [String]){
        delegate?.quickQueryQueue?(quickQueryQueue, didRemoveAll: queries)
    }
}

/** Useful delegate protocol for informing an optional receiver about important events such as additions and deletions to the QQQ in question*/
@objc protocol QQQDelegate{
    @objc optional func quickQueryQueue(_ quickQueryQueue: QuickQueryQueue, didAppend query: String)
    
    @objc optional func quickQueryQueue(_ quickQueryQueue: QuickQueryQueue, didAppendThese queries: [String])
    
    @objc optional func quickQueryQueue(_ quickQueryQueue: QuickQueryQueue, didRemove query: String)
    
    @objc optional func quickQueryQueue(_ quickQueryQueue: QuickQueryQueue, didRemoveThese queries: [String])
    
    /** Notify delegate that all queries were removed (can be used for an undo state restoration functionality)*/
    @objc optional func quickQueryQueue(_ quickQueryQueue: QuickQueryQueue, didRemoveAll queries: [String])
}

/** Used by the QQQView to inform the view controller of the search controller to inject a query into the search bar*/
@objc protocol QQQViewDelegate{
    @objc optional func quickQueryQueueView(_ quickQueryQueueView: QuickQueryQueueView, didSelect query: String)
    
    @objc optional func quickQueryQueueView(_ quickQueryQueueView: QuickQueryQueueView, didRemove query: String)
    
    /** All queries were removed*/
    @objc optional func quickQueryQueueViewDidRemoveAllQueries(_ quickQueryQueueView: QuickQueryQueueView)
    
    /** A query is currently focused with a context menu config*/
    @objc optional func quickQueryQueueView(_ quickQueryQueueView: QuickQueryQueueView, focusedQuery query: String)
}

/** UIView subclass that encapsulates a horizontal collection view with cells representing queries from the quick query queue object passed to it*/
public class QuickQueryQueueView: UIView, UICollectionViewDataSource, UICollectionViewDelegate, QQQDelegate{
    /** QQQ Data model that will fill this object*/
    var data: QuickQueryQueue
    
    /** Optional delegate to be passed to the parent view controller of this object*/
    var delegate: QQQViewDelegate?
    
    /** UI Components*/
    var collectionView: UICollectionView!
    /** Contains visible content*/
    var containerView: UIView!
    /** Determine whether to display a shadow from the parent view or not*/
    var useShadow: Bool = false{
        didSet{
            switch useShadow{
            case true:
                self.layer.shadowColor = UIColor.darkGray.cgColor
            case false:
                self.layer.shadowColor = UIColor.clear.cgColor
            }
        }
    }
    /** Determine whether or not to show or hide this view*/
    var viewHidden: Bool = false
    
    init(data: QuickQueryQueue, frame: CGRect) {
        self.data = data
        
        super.init(frame: frame)
        
        construct()
    }
    
    private func construct(){
        /** Listen for events from the quick query queue data*/
        data.delegate = self
        
        switch data.isEmpty(){
        case true:
            hide(animated: false)
        case false:
            show(animated: false)
        }
        
        self.backgroundColor = .clear
        self.clipsToBounds = false
        self.layer.shadowColor = UIColor.clear.cgColor
        self.layer.shadowOpacity = 0.25
        self.layer.shadowRadius = 2
        self.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: self.layer.cornerRadius).cgPath
        
        containerView = UIView(frame: self.frame)
        containerView.backgroundColor = bgColor
        containerView.clipsToBounds = true
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        /** Specify item size in order to allow the collectionview to encompass all of them*/
        layout.itemSize = CGSize(width: self.frame.width/4, height: self.frame.height)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height), collectionViewLayout: layout)
        collectionView.register(QueryCollectionViewCell.self, forCellWithReuseIdentifier: QueryCollectionViewCell.identifier)
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor.clear
        collectionView.isPagingEnabled = false
        collectionView.dataSource = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isExclusiveTouch = true
        collectionView.contentSize = CGSize(width: ((self.frame.width) * CGFloat(data.queries.count)), height: self.frame.height)
        
        /** Layout these subviews*/
        self.addSubview(containerView)
        containerView.addSubview(collectionView)
    }
    
    /** Swipe Action Methods*/
    func showActionButtons(animated: Bool){
        switch animated{
        case true:
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
                collectionView.frame.origin.x = -80
            }
        case false:
            collectionView.frame.origin.x = -80
        }
    }
    
    func hideActionButtons(animated: Bool){
        switch animated{
        case true:
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
                collectionView.frame.origin.x = 0
            }
        case false:
            collectionView.frame.origin.x = 0
        }
    }
    
    /** Collectionview delegate methods*/
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var count = 0
        
        if collectionView == collectionView{
            count = data.queries.count
        }
        
        return count
    }
    
    /** Supplement data to the collection view*/
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell = UICollectionViewCell()
        
        let queryQueueCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: QueryCollectionViewCell.identifier, for: indexPath) as! QueryCollectionViewCell
        
        /** Sort the queries to give them order, sets don't have order unless using NSOrderedSet*/
        let sortedQueries = data.queries.sorted()
        
        queryQueueCollectionViewCell.create(with: sortedQueries[indexPath.row])
        
        cell = queryQueueCollectionViewCell
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.frame.width/4, height: self.frame.height)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        mediumHaptic()
        
        let sortedQueries = data.queries.sorted()
        let query = sortedQueries[indexPath.row]
        quickQueryQueueView(self, didSelect: query)

        let queryQueueCollectionViewCell = collectionView.cellForItem(at: indexPath) as! QueryCollectionViewCell
        
        /** Shrink and resize animation*/
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            queryQueueCollectionViewCell.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
        UIView.animate(withDuration: 0.5, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            queryQueueCollectionViewCell.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
    }
    
    /** Provide context menu for the item at the given point*/
    public func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration?{
        
        let sortedQueries = data.queries.sorted()
        let query = sortedQueries[indexPath.row]
        
        quickQueryQueueView(self, focusedQuery: query)
        
        /** Inject the focused search query into the target search bar*/
        let search = UIAction(title: "Search", image: UIImage(systemName: "plus.magnifyingglass")){ [self] action in
            successfulActionShake()
            
            quickQueryQueueView(self, didSelect: query)
        }
        
        /** Copy and past the focused query to the user's clipboard*/
        let copy = UIAction(title: "Copy", image: UIImage(systemName: "doc.on.clipboard.fill")){ action in
            lightHaptic()
            
            UIPasteboard.general.string = query
            
            globallyTransmit(this: "Search query copied and pasted to clipboard", with: UIImage(systemName: "doc.on.clipboard.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: .clear, imageBorder: .none, blurEffect: true, accentColor: .lightGray.lighter, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 3, selfDismiss: true)
        }
        
        /** Removes the focused query*/
        let remove = UIAction(title: "Remove", image: UIImage(systemName: "minus.magnifyingglass"), attributes: .destructive){ [self] action in
            heavyHaptic()
            
            quickQueryQueueView(self, didRemove: query)
            data.remove(this: query)
            
            /** Inform the delegate that all queries have been removed*/
            if data.isEmpty() == true{
            quickQueryQueueViewDidRemoveAllQueries(self)
            }
        }
        
        /** Removes all queries and hides the query queue view*/
        let removeAll = UIAction(title: "Remove All", image: UIImage(systemName: "trash.fill"), attributes: .destructive){ [self] action in
            heavyHaptic()
            
            quickQueryQueueViewDidRemoveAllQueries(self)
            data.removeAll()
        }
        
        return UIContextMenuConfiguration(identifier: NSIndexPath(item: indexPath.item, section: indexPath.section), previewProvider:{return nil}){ _ in
            UIMenu(title: "Options", children: [search,copy,remove, removeAll])
        }
    }
    
    /** Provide custom previews for the context menu*/
    public func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview?{
        
        guard let indexPath = configuration.identifier as? IndexPath, let cell = collectionView.cellForItem(at: indexPath) else {
                return nil
            }
        
        let queryQueueCollectionViewCell = cell as! QueryCollectionViewCell
        
        let targetView = queryQueueCollectionViewCell.container!
        
        let targetedPreview = UITargetedPreview(view: targetView)
            targetedPreview.parameters.backgroundColor = .clear
            return targetedPreview
    }
    
    public func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview?{
        
        guard let indexPath = configuration.identifier as? IndexPath, let cell = collectionView.cellForItem(at: indexPath) else {
                return nil
            }
        
        let queryQueueCollectionViewCell = cell as! QueryCollectionViewCell
        
        let targetView = queryQueueCollectionViewCell.container!
        
        let targetedPreview = UITargetedPreview(view: targetView)
            targetedPreview.parameters.backgroundColor = .clear
            return targetedPreview
    }
    /** Provide custom previews for the context menu*/
    
    /** You can do something for newly displayed cells*/
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath){
        ///cell.alpha = 0
        
        /**
        /** Animate the cell appearing*/
        UIView.animate(withDuration: 1, delay: 0, options: .curveEaseIn){
            cell.alpha = 1
        }
        */
    }
    /** Collectionview delegate methods*/
    
    /** Perform updates in the given section (animated)*/
    func animatedReload(){
    self.collectionView.performBatchUpdates({
        let indexSet = IndexSet(integersIn: 0...0)
        self.collectionView.reloadSections(indexSet)
        }, completion: nil)
    }
    
    /** QQQ Delegate methods*/
    func quickQueryQueue(_ quickQueryQueue: QuickQueryQueue, didAppend query: String){
        /** Unhide this view if new data has been added while the view was hidden*/
        if viewHidden == true{
            show(animated: true)
        }
        
          animatedReload()
    }
    
    func quickQueryQueue(_ quickQueryQueue: QuickQueryQueue, didAppendThese queries: [String]) {
        /** Unhide this view if new data has been added while the view was hidden*/
        if viewHidden == true{
            show(animated: true)
        }
        
        animatedReload()
    }
    
    func quickQueryQueue(_ quickQueryQueue: QuickQueryQueue, didRemove query: String) {
        animatedReload()
    }
    
    func quickQueryQueue(_ quickQueryQueue: QuickQueryQueue, didRemoveThese queries: [String]) {
        animatedReload()
    }
    
    func quickQueryQueue(_ quickQueryQueue: QuickQueryQueue, didRemoveAll queries: [String]) {
        animatedReload()
        
        /** Nothing to see here, all data has been removed*/
        hide(animated: true)
    }
    /** QQQ Delegate methods*/
    
    /** Hide or show the QQQView in an animated or static fashion*/
    func hide(animated: Bool){
        viewHidden = true
        
        switch animated{
        case true:
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseIn){[self] in
                self.alpha = 0
            }
        case false:
            self.alpha = 0
        }
    }
    
    func show(animated: Bool){
        viewHidden =  false
        
        switch animated{
        case true:
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseIn){[self] in
                self.alpha = 1
            }
        case false:
            self.alpha = 1
        }
    }
    /** Hide or show the QQQView in an animated or static fashion*/
    
    /** Implementation of optional personal delegate methods*/
    fileprivate func quickQueryQueueView(_ quickQueryQueueView: QuickQueryQueueView, didSelect query: String){
        delegate?.quickQueryQueueView?(quickQueryQueueView, didSelect: query)
    }
    
    fileprivate func quickQueryQueueView(_ quickQueryQueueView: QuickQueryQueueView, didRemove query: String){
        delegate?.quickQueryQueueView?(quickQueryQueueView, didRemove: query)
    }
    
    fileprivate func quickQueryQueueViewDidRemoveAllQueries(_ quickQueryQueueView: QuickQueryQueueView){
        delegate?.quickQueryQueueViewDidRemoveAllQueries?(quickQueryQueueView)
    }
    
    fileprivate func quickQueryQueueView(_ quickQueryQueueView: QuickQueryQueueView, focusedQuery query: String){
        delegate?.quickQueryQueueView?(quickQueryQueueView, focusedQuery: query)
    }
    /** Implementation of optional personal delegate methods*/
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

