//
//  TravelLocationsViewController.swift
//  VirtualTourist
//
//  Created by Eric Hodgins on 2016-03-01.
//  Copyright © 2016 Eric Hodgins. All rights reserved.
//

import UIKit
import MapKit
import CoreData


class TravelLocationsViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var deletePinsView: UIView!
    @IBOutlet weak var mapView: MKMapView!
    
    var finishedDraggingMapPin : Bool = true
    var originalFrame = CGRect()
    var mapViewIsEditable : Bool = false
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Get the orignal view frame to restore back to normal whent the view is moved to show the pins can be removed
        originalFrame = self.view.frame
        
        
        try! fetchedResultsController.performFetch()
        addCoreDataSavedPinsToMapView()
        
        
        mapView.delegate = self
        
        // Gesture to add Pin annotation to the mapView
        let longGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "addAnnotation:")
        longGestureRecognizer.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longGestureRecognizer)
        

        
    }
    
    
    //MARK: Download Flickr Photos
    func downloadFlickrPhotos(withLatitude latitude: Double, andLongitude longitude: Double, pin: Pin) {
        VTClient.sharedInstance.getPhotosFromFlick(latitude, lon: longitude, page: pin.currentPage) { (success, photoResults, pictureCount, errorString) -> Void in
            if success {
                pin.totalPictureCount = pictureCount
                for pic in photoResults! {
                    let photo = Photo(imagePath: pic["url_m"] as! String, context: self.sharedContext)
                    photo.pin = pin
                }
                
                self.sharedContext.performBlock({ () -> Void in
                    CoreDataStackManager.sharedInstance.saveContext()
                })

            }
        }
    }
    
    
    
    
    
    //MARK: Core Data
    var sharedContext : NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance.managedObjectContext
    }
    
    lazy var fetchedResultsController : NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
    }()
    
    
    //MARK: Edit Button Pressed
    @IBAction func editButtonPressed(sender: AnyObject) {

        if !mapViewIsEditable {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "editButtonPressed:")
            let editFrame = CGRectMake(view.frame.origin.x, view.frame.origin.y - deletePinsView.frame.height, view.frame.width, view.frame.height)
            UIView.animateWithDuration(0.3) { () -> Void in
                self.view.frame = editFrame
            }
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Edit, target: self, action: "editButtonPressed:")
            UIView.animateWithDuration(0.3) { () -> Void in
                //TODO: when device orientation changes may need to fix this here
                self.view.frame = self.originalFrame
            }
        }
        
        mapViewIsEditable = !mapViewIsEditable
    }

}



//MARK: MapView Delegate
extension TravelLocationsViewController {
    
    func addCoreDataSavedPinsToMapView() {
        for pin in fetchedResultsController.fetchedObjects as! [Pin] {
            mapView.addAnnotation(pin)
        }
    }
    
    
    func addAnnotation(gestureRecognizer : UIGestureRecognizer) {
        
        if gestureRecognizer.state == .Began {
            let touchLocation = gestureRecognizer.locationInView(mapView)
            let mapCoordinates = mapView.convertPoint(touchLocation, toCoordinateFromView: mapView)
            
            // Make a Pin entity
            let pin = Pin(lat: mapCoordinates.latitude, lon: mapCoordinates.longitude, context: self.sharedContext)
            
            // Begin downloading photo urls
            downloadFlickrPhotos(withLatitude: mapCoordinates.latitude, andLongitude: mapCoordinates.longitude, pin: pin)
            mapView.addAnnotation(pin)
            
            //Save Pin
            CoreDataStackManager.sharedInstance.saveContext()
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView!.animatesDrop = true
            pinView!.draggable = true
            pinView!.pinTintColor = UIColor.blueColor()
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }

    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        print("callout accessory tapped")
    }
    
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        if mapViewIsEditable {
            let pin = view.annotation as! Pin
            sharedContext.deleteObject(pin)
            CoreDataStackManager.sharedInstance.saveContext()
            mapView.removeAnnotation(view.annotation!)
        }
        
        // Make sure the pin is not being dragged & the mapView is not in Edit mode (deleting pins)
        if finishedDraggingMapPin && !mapViewIsEditable {
            let photoViewController = storyboard?.instantiateViewControllerWithIdentifier("PhotoAlbum") as! PhotoAlbumViewController
            photoViewController.pin  = view.annotation as! Pin
            navigationController?.pushViewController(photoViewController, animated: true)
        }
    }
    
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        
        if newState == .Starting {
            finishedDraggingMapPin = false
        } else if newState == .Ending || newState == .Canceling {
            view.dragState = .None
            
            // Grab the reference to the Pin object
            let pin = view.annotation as! Pin
            
            // Delete all associated images with the Pin
            for photo in pin.photos as NSArray {
                sharedContext.deleteObject(photo as! Photo)
            }
            
            // Update the lat and lon values
            pin.latitude = (view.annotation?.coordinate.latitude)!
            pin.longitude = (view.annotation?.coordinate.longitude)!
            pin.currentPage = 1
            
            
            // Now save the new Pin location with 0 photos
            CoreDataStackManager.sharedInstance.saveContext()
            
            // Set the flag
            finishedDraggingMapPin = true
            
            // Begin downloading the photo url's
            downloadFlickrPhotos(withLatitude: (view.annotation?.coordinate.latitude)!, andLongitude: (view.annotation?.coordinate.longitude)!, pin: pin)

        }
    }
    
    
    func deletePin(pin : Pin) {
        
    }
}