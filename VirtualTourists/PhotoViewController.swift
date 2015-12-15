//
//  PhotoViewController.swift
//  VirtualTourists
//
//  Created by xingxiaoxiong on 12/14/15.
//  Copyright © 2015 Udacity. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoViewController: UIViewController {
    
    var pin: Pin!

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if pin.photos.isEmpty {
                        
            Flickr.sharedInstance().getPhotoUrls(pin.latitude as Double, longitude: pin.longitude as Double, completionHandler: { (parsedResult, error) -> Void in
                
                if let error = error {
                    self.alertViewForError(error)
                } else {
                    
                    guard let stat = parsedResult["stat"] as? String where stat == "ok" else {
                        let error = NSError(domain: "Flickr API returned an error. See error code and message in \(parsedResult)", code: 0, userInfo: nil)
                        self.alertViewForError(error)
                        return
                    }
                    
                    guard let photosDictionary = parsedResult["photos"] as? NSDictionary else {
                        let error = NSError(domain: "Cannot find keys 'photos' in \(parsedResult)", code: 0, userInfo: nil)
                        self.alertViewForError(error)
                        return
                    }
                    
                    guard let totalPhotosVal = (photosDictionary["total"] as? NSString)?.integerValue else {
                        let error = NSError(domain: "Cannot find key 'total' in \(photosDictionary)", code: 0, userInfo: nil)
                        self.alertViewForError(error)
                        return
                    }
                    
                    guard let photos = photosDictionary["photo"] as? [[String: AnyObject]] else {
                        let error = NSError(domain: "Cannot find key 'photo' in \(photosDictionary)", code: 0, userInfo: nil)
                        self.alertViewForError(error)
                        return
                    }
                    
                    if totalPhotosVal > 0 {
                        
                        _ = photos.map() { (dictionary: [String : AnyObject]) -> Photo in
                            let dic: [String : AnyObject] = ["path": dictionary["url_m"]!]
                            let photo = Photo(dictionary: dic, context: self.sharedContext)
                            
                            photo.pin = self.pin
                            //self.pin.photos.append(photo)
                            
                            return photo
                        }
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            self.collectionView.reloadData()
                        }
                        
                        self.saveContext()
                        
                    } else {
                        
                    }
                    
                }
                
            })
            
            
        }
    }
    
    // MARK: - Core Data Convenience
    
    lazy var sharedContext: NSManagedObjectContext =  {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }


    @IBAction func newCollectionButtonTapped(sender: UIButton) {
        
    }
    
    func alertViewForError(error: NSError) {
        let alert = UIAlertController(title: "Alert", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    
    func configureCell(cell: PhotoCell, atIndexPath indexPath: NSIndexPath) {
        
    }

}


extension PhotoViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.pin.photos.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let photo = pin.photos[indexPath.row]
        let CellIdentifier = "PhotoCell"
        var photoImage = UIImage(named: "photoPlaceHolder")
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(CellIdentifier, forIndexPath: indexPath) as! PhotoCell
        cell.photo.image = nil
        
        if photo.path == "" {
            photoImage = UIImage(named: "noPhoto")
        } else if photo.photo != nil {
            photoImage = photo.photo
        } else {
            
            let task = Flickr.sharedInstance().taskForImage(photo.path) { data, error in
                
                if let error = error {
                    self.alertViewForError(error)
                }
                
                if let data = data {
                    let image = UIImage(data: data)
                    
                    photo.photo = image
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        cell.photo.image = image
                    }
                }
            }
            
        }
        
        cell.photo.image = photoImage
        
        return cell

    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
    }

    
}