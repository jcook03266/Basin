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
public class QuickQueryQueue{
    /** Set of strings that allows for unique queries to be stored and later injected into search bars*/
    var queries: Set<String> = []
    /** Secondary key for parity when multiple quick query queue objects use the same primary idenitifier*/
    var secondaryKey: String? = nil
    /** Primary storage key for this object*/
    var primaryKey: String
    /** When this object was first created*/
    var created: Date
    /** When the queries set was last updated*/
    var updated: Date!
    
    init(primaryKey: String, created: Date) {
        self.primaryKey = primaryKey
        self.created = created
        self.updated = created
    }
}

/** UIView subclass that encapsulates a horizontal collection view with cells representing queries from the quick query queue object passed to it*/
public class QuickQueryQueueView: UIView{
    var data: QuickQueryQueue
    
    /** UI Components*/
    var collectionView: UICollectionView!
    
    init(data: QuickQueryQueue, frame: CGRect) {
        self.data = data
        
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

