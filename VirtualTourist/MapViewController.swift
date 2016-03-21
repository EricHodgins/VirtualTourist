//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Eric Hodgins on 2016-03-20.
//  Copyright © 2016 Eric Hodgins. All rights reserved.
//

import Foundation
import MapKit

extension TravelLocationsViewController {
    //MARK: MapView Delegate and Helper Methods

    
    func addCoreDataSavedPinsToMapView() {
        for pin in fetchedResultsController.fetchedObjects as! [Pin] {
            mapView.addAnnotation(pin)
        }
    }
    
    
    func addAnnotation(gestureRecognizer : UIGestureRecognizer) {
        
        if gestureRecognizer.state == .Began && !mapViewIsEditable {
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
            
            //cancel any prefetching imageData (this will prevent an error occurring if reload collection is pressed and these network requests are not finished
            for task in tasksForImageDataDownloads {
                task.cancel()
            }
            
            let photoViewController = storyboard?.instantiateViewControllerWithIdentifier("PhotoAlbum") as! PhotoAlbumViewController
            photoViewController.pin  = view.annotation as! Pin
            photoViewController.pinHasFinishedDownloadingURLS = pinHasFinishedDownloadingURLS
            navigationController?.pushViewController(photoViewController, animated: true)
        }
    }
    
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        
        if newState == .Starting {
            finishedDraggingMapPin = false
        } else if newState == .Ending || newState == .Canceling {
            view.dragState = .None
            
            cancelAnyNetworkTasksWhenPinIsUpated()
            
            // Grab the reference to the Pin object
            let pin = view.annotation as! Pin
            
            // Delete all associated images with the Pin
            for photo in pin.photos as NSArray {
                sharedContext.deleteObject(photo as! Photo)
            }
            
            // Update the lat and lon values set page number to 1 start over again
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
    
    // If any network requests are still active and the pin is updated to a new location an error can occur.  I beleive the NSURLSession tries to unwrap a nil optional.
    func cancelAnyNetworkTasksWhenPinIsUpated() {
        taskForURLDownload?.cancel()
        
        for task in tasksForImageDataDownloads {
            task.cancel()
        }
    }
    
    
    //MARK: Saving Map Region
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }
    
    
    func saveMapRegion() {
        
        let savedMapRegion = MapRegion(lat: mapView.region.center.latitude, lon: mapView.region.center.longitude, latDelta: mapView.region.span.latitudeDelta, lonDelta: mapView.region.span.longitudeDelta)
        
        NSKeyedArchiver.archiveRootObject(savedMapRegion, toFile: MapRegion.filePath)
        
    }
    
    func loadInPreviousSavedMapRegion() {
        
        if let mapRegion = NSKeyedUnarchiver.unarchiveObjectWithFile(MapRegion.filePath) as? MapRegion {
            mapView.setRegion(mapRegion.region, animated: true)
            mapView.setCenterCoordinate(mapRegion.center, animated: true)
        }        
    }

}