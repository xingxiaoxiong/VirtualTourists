//
//  MapViewController.swift
//  VirtualTourists
//
//  Created by xingxiaoxiong on 12/14/15.
//  Copyright © 2015 Udacity. All rights reserved.
//

import UIKit
import MapKit
import CoreData

let MapRegionKey = "mapRegionArchive"

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    var pins = [Pin]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        restoreMapRegion(false)
        
        let uilgr = UILongPressGestureRecognizer(target: self, action: "addAnnotation:")
        uilgr.minimumPressDuration = 2.0
        mapView.addGestureRecognizer (uilgr)
        
        pins = fetchAllPins()
        addAllPins()
    }
    
    var filePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
        return url.URLByAppendingPathComponent(MapRegionKey).path!
    }

    func saveMapRegion() {
        
        let dictionary = [
            "latitude" : mapView.region.center.latitude,
            "longitude" : mapView.region.center.longitude,
            "latitudeDelta" : mapView.region.span.latitudeDelta,
            "longitudeDelta" : mapView.region.span.longitudeDelta
        ]
        
        NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)
    }
    
    func restoreMapRegion(animated: Bool) {
        
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
            
            let longitude = regionDictionary["longitude"] as! CLLocationDegrees
            let latitude = regionDictionary["latitude"] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let longitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
            let latitudeDelta = regionDictionary["longitudeDelta"] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            let savedRegion = MKCoordinateRegion(center: center, span: span)
            
            mapView.setRegion(savedRegion, animated: animated)
        }
    }
    
    func addAnnotation(gestureRecognizer:UIGestureRecognizer){
        if gestureRecognizer.state == UIGestureRecognizerState.Began {
            let touchPoint = gestureRecognizer.locationInView(mapView)
            let newCoordinates = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinates
            mapView.addAnnotation(annotation)
            
            let dictionary: [String : AnyObject] = [
                Pin.Keys.Latitude : newCoordinates.latitude,
                Pin.Keys.Longitude : newCoordinates.longitude,
            ]
            let pinToBeAdded = Pin(dictionary: dictionary, context: sharedContext)
            self.pins.append(pinToBeAdded)
            
            CoreDataStackManager.sharedInstance().saveContext()
            
            //self.downloadPhotos(newCoordinates.latitude, longitude: newCoordinates.longitude, pin: pinToBeAdded)
            
        }
    }
    
    func downloadPhotos(latitude: Double, longitude: Double, pin: Pin) {
        
        Flickr.sharedInstance().getPhotoUrls(latitude, longitude: longitude, completionHandler: { [unowned self] (parsedResult, error) -> Void in
            
            if let error = error {
                dispatch_async(dispatch_get_main_queue()) {
                    self.alertViewForError(error)
                }
            } else {
                
                guard let stat = parsedResult["stat"] as? String where stat == "ok" else {
                    let error = NSError(domain: "Flickr API returned an error.", code: 0, userInfo: nil)
                    dispatch_async(dispatch_get_main_queue()) {
                        self.alertViewForError(error)
                    }
                    return
                }
                
                guard let photosDictionary = parsedResult["photos"] as? NSDictionary else {
                    let error = NSError(domain: "Cannot find keys 'photos'", code: 0, userInfo: nil)
                    dispatch_async(dispatch_get_main_queue()) {
                        self.alertViewForError(error)
                    }
                    return
                }
                
                guard let totalPhotosVal = (photosDictionary["total"] as? NSString)?.integerValue else {
                    let error = NSError(domain: "Cannot find key 'total'", code: 0, userInfo: nil)
                    dispatch_async(dispatch_get_main_queue()) {
                        self.alertViewForError(error)
                    }
                    return
                }
                
                guard let photos = photosDictionary["photo"] as? [[String: AnyObject]] else {
                    let error = NSError(domain: "Cannot find key 'photo'", code: 0, userInfo: nil)
                    dispatch_async(dispatch_get_main_queue()) {
                        self.alertViewForError(error)
                    }
                    return
                }
                
                if totalPhotosVal > 0 {
                    
                    dispatch_async(dispatch_get_main_queue()) {
                    _ = photos.map() { (dictionary: [String : AnyObject]) -> Photo in
                        let dic: [String : AnyObject] = [
                            "path": dictionary["url_m"]!,
                            "id": dictionary["id"]!
                        ]
                        let photo = Photo(dictionary: dic, context: self.sharedContext)
                        
                        Flickr.sharedInstance().taskForImage(photo.path) { data, error in
                            
                            if let error = error {
                                dispatch_async(dispatch_get_main_queue()) {
                                    self.alertViewForError(error)
                                }
                            }
                            
                            if let data = data {
                                let image = UIImage(data: data)
                                photo.photo = image
                            }
                        }
                        
                        photo.pin = pin
                        
                        return photo
                    }
                    }
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.saveContext()
                    }
                    
                }
                
            }
            
        })

    }
    
    func alertViewForError(error: NSError) {
        let alert = UIAlertController(title: "Alert", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    func fetchAllPins() -> [Pin] {
        
        // Create the Fetch Request
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        // Execute the Fetch Request
        do {
            return try sharedContext.executeFetchRequest(fetchRequest) as! [Pin]
        } catch  let error as NSError {
            print("Error in fetchAllPins(): \(error)")
            return [Pin]()
        }
    }
    
    func addAllPins() {
        var annotations = [MKPointAnnotation]()
        
        for pin in pins {
            
            let lat = CLLocationDegrees(pin.latitude)
            let long = CLLocationDegrees(pin.longitude)
            
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            
            annotations.append(annotation)
        }
        
        self.mapView.addAnnotations(annotations)
    }


}


extension MapViewController : MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        let controller =
        storyboard!.instantiateViewControllerWithIdentifier("PhotoViewController")
            as! PhotoViewController
        
        for pin in pins {
            if view.annotation?.coordinate.longitude == pin.longitude && view.annotation?.coordinate.latitude == pin.latitude {
                controller.pin = pin
                break
            }
        }
        
        self.navigationController!.pushViewController(controller, animated: true)
    }
}
