//
//  Photo.swift
//  VirtualTourists
//
//  Created by xingxiaoxiong on 12/14/15.
//  Copyright © 2015 Udacity. All rights reserved.
//

import UIKit
import CoreData

class Photo : NSManagedObject {
    
    struct Keys {
        static let Path = "path"
        static let Id = "id"
    }
    
    @NSManaged var id: String
    @NSManaged var path: String
    @NSManaged var pin: Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        
        path = dictionary[Keys.Path] as! String
        print("id: \(dictionary[Keys.Id])")
        id = dictionary[Keys.Id]! as! String
    }
    
    var photo: UIImage? {
        
        get {
            return Flickr.Caches.imageCache.imageWithIdentifier(id)
        }
        
        set {
            Flickr.Caches.imageCache.storeImage(newValue, withIdentifier: id)
        }
    }
}
