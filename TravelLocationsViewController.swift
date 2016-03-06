//
//  TravelLocationsViewController.swift
//  VirtualTourist
//
//  Created by Eric Hodgins on 2016-03-01.
//  Copyright © 2016 Eric Hodgins. All rights reserved.
//

import UIKit
import MapKit

class TravelLocationsViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    var finishedDraggingMapPin : Bool = true
    
    var urlStrings = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        let longGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "addAnnotation:")
        longGestureRecognizer.minimumPressDuration = 1.5
        mapView.addGestureRecognizer(longGestureRecognizer)
        
    }
    
    
    func downloadFlickrPhotos(withLatitude latitude: Double, andLongitude longitude: Double) {
        VTClient.sharedInstance.getPhotosFromFlick(latitude, lon: longitude, page: 1) { (success, photoResults, errorString) -> Void in
            if success {
                self.urlStrings = [String]()
                for photo in photoResults! {
                    self.urlStrings.append(photo["url_m"] as! String)
                }
            }
        }
    }

}


extension TravelLocationsViewController {
    func addAnnotation(gestureRecognizer : UIGestureRecognizer) {
        
        if gestureRecognizer.state == .Began {
            let touchLocation = gestureRecognizer.locationInView(mapView)
            let mapCoordinates = mapView.convertPoint(touchLocation, toCoordinateFromView: mapView)
            print(mapCoordinates.latitude)
            print(mapCoordinates.longitude)
            downloadFlickrPhotos(withLatitude: mapCoordinates.latitude, andLongitude: mapCoordinates.longitude)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = mapCoordinates
            annotation.title = "Maybe put number of photos or something here..."
            mapView.addAnnotation(annotation)
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        print("view for annotation")
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.animatesDrop = true
            pinView!.draggable = true
            pinView!.canShowCallout = true
            pinView!.pinTintColor = UIColor.blueColor()
            pinView!.rightCalloutAccessoryView = UIButton(type: .InfoLight)
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }

    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        print("pin tapped")
    }
    
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        if finishedDraggingMapPin {
            let photoViewController = storyboard?.instantiateViewControllerWithIdentifier("PhotoAlbum") as! PhotoAlbumViewController
            photoViewController.urlStrings = urlStrings
            navigationController?.pushViewController(photoViewController, animated: true)
        }
    }
    
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {

        if newState == .Starting {
            finishedDraggingMapPin = false
        } else if newState == .Ending || newState == .Canceling {
            view.dragState = .None
            finishedDraggingMapPin = true
        }
    }
}