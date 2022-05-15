//
//  CoreData.swift
//  Basin
//
//  Created by Justin Cook on 3/26/22.
//

import CoreData
import UIKit

/**NSManagedObject Arrays for storing fetched entity objects when loading core data from the entities*/
var favoriteLaundromatCoreDataArray: [NSManagedObject] = []
var quickQueryQueuesCoreDataArray: [NSManagedObject] = []

/** Enum for entity names to make things simpler to type*/
enum entities: String{
    /**Favorite Laundromats Model**/
    case FL = "FavoriteLaundromatsModel"
    case QQQ = "QuickQueryQueueModel"
}

final class CoreDataManager{
    // MARK: - Properties
    private let modelName: String
    
    // MARK: - Initialization
    init(modelName: String) {
        self.modelName = modelName
    }
    
    // MARK: - Core Data Stack
    private(set) lazy var managedObjectContext: NSManagedObjectContext = {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        
        managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        
        return managedObjectContext
    }()
    
    private lazy var managedObjectModel: NSManagedObjectModel = {
        guard let modelURL = Bundle.main.url(forResource: self.modelName, withExtension: "momd") else {
            fatalError("Unable to Find Data Model")
        }
        
        guard let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Unable to Load Data Model")
        }
        
        return managedObjectModel
    }()
    
    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        
        let fileManager = FileManager.default
        let storeName = "\(self.modelName).sqlite"
        
        let documentsDirectoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        let persistentStoreURL = documentsDirectoryURL.appendingPathComponent(storeName)
        
        /** Doesn't support light weight migration by inference
         do {
         try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType,
         configurationName: nil,
         at: persistentStoreURL,
         options: nil)
         } catch {
         fatalError("Unable to Load Persistent Store")
         }
         */
        
        /** Supports light weight migration by inference and a mapping model for old versions of the coreModel persistent container, NEVER EVER CHANGE AN ENTITY WITHOUT MAKING A NEW VERSION OF THE COREMODEL FILE AND CREATING A MAPPING MODEL, ESPECIALLY AFTER YOU RELEASE THE APP, YOU BETTER MAKE SURE IT'S FUCKING FLAWLESS*/
        do {
            let options = [ NSInferMappingModelAutomaticallyOption : true,
                      NSMigratePersistentStoresAutomaticallyOption : true]
            
            try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                                              configurationName: nil,
                                                              at: persistentStoreURL,
                                                              options: options)
        } catch {
            fatalError("Unable to Load Persistent Store")
        }
        
        return persistentStoreCoordinator
    }()
}

/**
 Reset all records inside of the entity defined by removing all objects and resaving the clean entity
 - Parameters:
 - entity: Specified entity being wiped of all objects
 */
func resetAllEntityRecords(in entity: String){
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else{return}
    let context = appDelegate.coreDataManager.managedObjectContext
    let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
    let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
    do{
        try context.execute(deleteRequest)
        try context.save()
    }catch
    {
        print ("There was an error")
    }
}

/**
 Load Core data objects from the entity to an NSManagedObject array, array is cleared first
 - Parameter entity: Specified entity from which all NSManagedObjects attached will be loaded up from and placed into an array
 - Parameter NSManagedObjectArray: Array that will store all NSManagedObjects loaded in from the specified entity
 */
func loadCoreData(in entity: entities, NSManagedObjectArray: inout [NSManagedObject]){
    NSManagedObjectArray.removeAll()
    
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else{return}
    let managedContext = appDelegate.coreDataManager.managedObjectContext
    
    let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entity.rawValue)
    
    do{
        let results = try managedContext.fetch(fetchRequest)
        for result in results{
            NSManagedObjectArray.append(result)
        }
    } catch let error as NSError{
        print("Could not fetch. \(error), \(error.userInfo)")
    }
}

///Start of QQQ Data methods//
/** Unique set of quick query queues since each one is unique*/
var quickQueryQueues: Set<QuickQueryQueue> = []

/**Save Core data objects to entity*/
func saveThisQuickQueryQueue(from dataModel: QuickQueryQueue){
    if let appDelegate = UIApplication.shared.delegate as? AppDelegate{
        let managedContext = appDelegate.coreDataManager.managedObjectContext
        
        managedContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        guard let entity = NSEntityDescription.entity(forEntityName: entities.QQQ.rawValue, in: managedContext) else{return}
        
        let object = NSManagedObject(entity: entity, insertInto: managedContext)
        
        object.setValue(dataModel.primaryKey, forKey: #keyPath(QuickQueryQueueModel.primaryKey))
        
        object.setValue(dataModel.secondaryKey, forKey: #keyPath(QuickQueryQueueModel.secondaryKey))
        
        object.setValue(dataModel.queries, forKey: #keyPath(QuickQueryQueueModel.queries))
        
        object.setValue(dataModel.queryLimit, forKey: #keyPath(QuickQueryQueueModel.queryLimit))
        
        object.setValue(dataModel.created, forKey: #keyPath(QuickQueryQueueModel.created))
        
        object.setValue(dataModel.updated, forKey: #keyPath(QuickQueryQueueModel.updateDate))
        
        do{
            try managedContext.save()
            print("Saved Quick Query Queue: \(dataModel.primaryKey)")
        }catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
}

/** Form a fetch request for a single object from the entity*/
func fetchQuickQueryQueueCoreDataFor(this primaryKey: String)->QuickQueryQueue?{
    var quickQueryQueue: QuickQueryQueue? = nil
    
    if let appDelegate = UIApplication.shared.delegate as? AppDelegate{
        
        let fetchRequest: NSFetchRequest<QuickQueryQueueModel>
        fetchRequest = QuickQueryQueueModel.fetchRequest()
        
        fetchRequest.predicate = NSPredicate(format: "primaryKey = %@", primaryKey)
        
        let managedContext = appDelegate.coreDataManager.managedObjectContext
        
        do{
            let objects = try managedContext.fetch(fetchRequest)
            
            if objects.isEmpty == false{
                let NSManagedObject = objects[0]
                
                let item = QuickQueryQueue(primaryKey: NSManagedObject.value(forKey: #keyPath(QuickQueryQueueModel.primaryKey)) as! String, created: NSManagedObject.value(forKey: #keyPath(QuickQueryQueueModel.created)) as! Date)
                
                item.queries = NSManagedObject.value(forKey: #keyPath(QuickQueryQueueModel.queries)) as! Set<String>
                
                item.queryLimit = NSManagedObject.value(forKey: #keyPath(QuickQueryQueueModel.queryLimit)) as! Int
                
                item.created = NSManagedObject.value(forKey: #keyPath(QuickQueryQueueModel.created)) as! Date
                
                item.updated = NSManagedObject.value(forKey: #keyPath(QuickQueryQueueModel.updateDate)) as? Date
                
                quickQueryQueue = item
            }
            else{
                return quickQueryQueue
            }
        } catch {
            fatalError("Failed to fetch employees: \(error)")
        }
    }
    
    return quickQueryQueue
}

/** Load up the saved data from core data*/
func loadQuickQueryQueueCoreData(){
    quickQueryQueuesCoreDataArray.removeAll()
    /**Prevent duplicate information by removing any appended data*/
    quickQueryQueues.removeAll()
    
    loadCoreData(in: .QQQ, NSManagedObjectArray: &quickQueryQueuesCoreDataArray)
    
    for NSManagedObject in quickQueryQueuesCoreDataArray{
        
        let item = QuickQueryQueue(primaryKey: NSManagedObject.value(forKey: #keyPath(QuickQueryQueueModel.primaryKey)) as! String, created: NSManagedObject.value(forKey: #keyPath(QuickQueryQueueModel.created)) as! Date)
        
        item.queries = NSManagedObject.value(forKey: #keyPath(QuickQueryQueueModel.queries)) as! Set<String>
        
        item.queryLimit = NSManagedObject.value(forKey: #keyPath(QuickQueryQueueModel.queryLimit)) as! Int
        
        item.created = NSManagedObject.value(forKey: #keyPath(QuickQueryQueueModel.created)) as! Date
        
        item.updated = NSManagedObject.value(forKey: #keyPath(QuickQueryQueueModel.updateDate)) as! Date
        
        quickQueryQueues.insert(item)
    }
}

/** Use this when toggling the QQQ's to off in the settings menu*/
func eraseAllQuickQueryQueues(){
    resetAllEntityRecords(in: entities.QQQ.rawValue)
}
///End of QQQ Data methods//

///Start of Favorite Laundromats Core Data methods///
/** A simple list of favorited laundromats,*/
var favoriteLaundromats = LinkedList<FavoriteLaundromat>()

/** Simple object that stores a creation date and an id string*/
public class FavoriteLaundromat: Equatable{
    var creationDate: Date
    var laundromatID: String
    
    init(creationDate: Date, laundromatID: String) {
        self.creationDate = creationDate
        self.laundromatID = laundromatID
    }
    
    public static func == (lhs: FavoriteLaundromat, rhs: FavoriteLaundromat) -> Bool {
        let condition = lhs.creationDate == rhs.creationDate && lhs.laundromatID == rhs.laundromatID
        return condition
    }
    
    /** Remove this entry from the favorite laundromats list (if it hasn't already been removed)*/
    func removeFromFavoriteLaundromats(){
        /** Return if there's nothing in the list at all*/
        guard favoriteLaundromats.isEmpty == false else {
            return
        }
        
        /** Remove and resave the updated coreData*/
        for index in 0..<favoriteLaundromats.count(){
            if self == favoriteLaundromats.nodeAt(index: index)?.value{
                favoriteLaundromats.remove(this: favoriteLaundromats.nodeAt(index: index)!)
            }
        }
        
        updateFavoriteLaundromatCoreData()
    }
    
    /** Add this entry to the favorite laundromats list (if it hasn't already been added)*/
    func addToFavoriteLaundromats(){
        var contained = false
        for index in 0..<favoriteLaundromats.count(){
            if self.laundromatID == favoriteLaundromats.nodeAt(index: index)?.value.laundromatID{
                contained = true
            }
        }
        
        /** Return if this entry is already present in the list*/
        guard contained == false else{
            return
        }
        
        /** Add this unique element and then update core data*/
        favoriteLaundromats.appendUniqueElement(with: self)
        updateFavoriteLaundromatCoreData()
    }
    
    /** Update the favorite laundromats by saving the current version of the favorite laundromats list*/
    func updateFavoriteLaundromatCoreData(){
        /** Clear all previously saved favorite laundromat entities*/
        resetAllEntityRecords(in: entities.FL.rawValue)
        
        /** Save the edited favorite laundromats list to core data*/
        for laundromat in favoriteLaundromats.toArray(){
            FavoriteThisLaundromat(from: laundromat)
        }
    }
}

/**Save Core data objects to entity*/
func FavoriteThisLaundromat(from dataModel: FavoriteLaundromat){
    if let appDelegate = UIApplication.shared.delegate as? AppDelegate{
        let managedContext = appDelegate.coreDataManager.managedObjectContext
        
        managedContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        guard let entity = NSEntityDescription.entity(forEntityName: entities.FL.rawValue, in: managedContext) else{return}
        
        let object = NSManagedObject(entity: entity, insertInto: managedContext)
        object.setValue(dataModel.laundromatID, forKey: #keyPath(FavoriteLaundromatsModel.laundromatID))
        object.setValue(dataModel.creationDate, forKey: #keyPath(FavoriteLaundromatsModel.created))
        
        do{
            try managedContext.save()
            print("Saved Favorite Laundromat: \(dataModel.laundromatID)")
        }catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
}

/** Load up the saved favorited laundromats from core data*/
func loadFavoriteLaundromatsCoreData(){
    favoriteLaundromatCoreDataArray.removeAll()
    /**Prevent duplicate information by removing any appended data*/
    favoriteLaundromats.removeAll()
    
    loadCoreData(in: .FL, NSManagedObjectArray: &favoriteLaundromatCoreDataArray)
    
    for NSManagedObject in favoriteLaundromatCoreDataArray{
        let item = FavoriteLaundromat(creationDate: NSManagedObject.value(forKey: #keyPath(FavoriteLaundromatsModel.created)) as! Date, laundromatID: NSManagedObject.value(forKey: #keyPath(FavoriteLaundromatsModel.laundromatID)) as! String)
        
        /** Stores a list of favorited laundromat object IDs and the date when the laundromat was favorited*/
        item.addToFavoriteLaundromats()
    }
}
///End of Favorite Laundromats Data methods//
