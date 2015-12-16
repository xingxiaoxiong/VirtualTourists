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
    var downloadingCount = 0

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setMapRegion(false)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if pin.photos.isEmpty {
            downloadPhotos()
        }
    }
    
    func downloadPhotos() {
        newCollectionButton.enabled = false
        
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
                                
                self.downloadingCount = photos.count
                
                if totalPhotosVal > 0 {
                    
                    _ = photos.map() { (dictionary: [String : AnyObject]) -> Photo in
                        let dic: [String : AnyObject] = [
                            "path": dictionary["url_m"]!,
                            "id": dictionary["id"]!
                        ]
                        let photo = Photo(dictionary: dic, context: self.sharedContext)
                        
                        photo.pin = self.pin
                        
                        return photo
                    }
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.collectionView.reloadData()
                    }
                    
                    self.saveContext()
                    
                } else {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.newCollectionButton.setTitle("No Images", forState: UIControlState.Normal)
                    }
                    
                }
                
            }
            
        })

    }
    
    // MARK: - Core Data Convenience
    
    lazy var sharedContext: NSManagedObjectContext =  {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }


    @IBAction func newCollectionButtonTapped(sender: UIButton) {
        for photo in pin.photos {
            photo.photo = nil
            sharedContext.deleteObject(photo)
        }
        CoreDataStackManager.sharedInstance().saveContext()
        downloadPhotos()
    }
    
    func alertViewForError(error: NSError) {
        let alert = UIAlertController(title: "Alert", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    var filePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
        return url.URLByAppendingPathComponent(MapRegionKey).path!
    }
    
    func setMapRegion(animated: Bool) {
        
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
            
            let longitude = regionDictionary["longitude"] as! CLLocationDegrees
            let latitude = regionDictionary["latitude"] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let longitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
            let latitudeDelta = regionDictionary["longitudeDelta"] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            let savedRegion = MKCoordinateRegion(center: center, span: span)
            
            mapView.setRegion(savedRegion, animated: animated)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = center
            mapView.addAnnotation(annotation)
        }
        
    }

}

extension PhotoViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.size.width/3 - 5, height: collectionView.frame.size.width/3 - 2.5)
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.pin.photos.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let photo = pin.photos[indexPath.row]
        var photoImage = UIImage(named: "photoPlaceHolder")
        
        if photoImage == nil {
            print("image nil")
        }
        
        let CellIdentifier = "PhotoCell"
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(CellIdentifier, forIndexPath: indexPath) as! PhotoCell
        cell.photo.image = nil
        
        if photo.photo != nil {
            photoImage = photo.photo
        } else {
            
            //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
                let task = Flickr.sharedInstance().taskForImage(photo.path) { data, error in
                    
                    if let error = error {
                        self.alertViewForError(error)
                    }
                    
                    if let data = data {
                        let image = UIImage(data: data)
                        
                        photo.photo = image
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            cell.photo.image = image
                            self.downloadingCount--
                            if self.downloadingCount == 0 {
                                self.newCollectionButton.enabled = true
                            }
                        }
                    }
                }
                cell.taskToCancelifCellIsReused = task
            //}
            
        }
        
        cell.photo.image = photoImage
        
        return cell

    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let photo = pin.photos[indexPath.row]
        photo.photo = nil
        sharedContext.deleteObject(photo)
        CoreDataStackManager.sharedInstance().saveContext()
        self.collectionView.reloadData()
    }

    
}