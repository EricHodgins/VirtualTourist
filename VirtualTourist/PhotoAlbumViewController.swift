//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Eric Hodgins on 2016-03-01.
//  Copyright © 2016 Eric Hodgins. All rights reserved.
//

import UIKit
import CoreData
import MapKit

private let cellSpacing: CGFloat = 1

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var indicatorLabel: UILabel!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    @IBOutlet weak var indicatorView: UIView!
    var pinHasFinishedDownloadingURLS: Bool = true
    var newCollectionNetworkTask: NSURLSessionTask?

    
    @IBOutlet weak var mapView: MKMapView!
    
    var selectedIndexes = [NSIndexPath]()
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    var pin: Pin!

    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("view did load albumVC")
        print("number of item in collectionview: \(collectionView.numberOfItemsInSection(0)), \(pinHasFinishedDownloadingURLS)")
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "hideDownloadIndicators", name: VTClient.NotificationKeys.finishedDownloadingURLsNotificationKey, object: nil)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        
        try! fetchedResultsController.performFetch()
        
        fetchedResultsController.delegate = self
        
        if pinHasFinishedDownloadingURLS {
            hideDownloadIndicators()
        } else {
            showDownloadIndicators()
        }
        
        updateBottomButton()
    }
    
    func setupMapRegion() {
        let lat = pin.latitude as CLLocationDegrees
        let lon = pin.longitude as CLLocationDegrees
        let latDelta = 0.5 as CLLocationDegrees
        let lonDelta = 0.5 as CLLocationDegrees
        let center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        let region = MKCoordinateRegion(center: center, span: span)
        mapView.setRegion(region, animated: true)
        mapView.addAnnotation(pin)
    }
    
    override func viewDidLayoutSubviews() {
        adjustCellDimensions()
    }
    
    override func viewWillDisappear(animated: Bool) {
        print("view did disappear")
        super.viewWillDisappear(animated)
        
        cancelAllCellNetworkTasks()
    }
    
    
    //Need to cancel any network task associated with this controller otherwise when the pin is updated in the map before the tasks have finished an error will occur. "session task will try to unwrap an optional but it is nil."
    func cancelAllCellNetworkTasks() {
        newCollectionNetworkTask?.cancel()
        
        for cell in collectionView.visibleCells() as! [CustomCollectionViewCell] {
            cell.taskToCancelifCellIsReused?.cancel()
        }
    }
    
    deinit {
        print("photo album has been deinitted.")
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func showDownloadIndicators() {
        indicatorView.hidden = false
        indicatorLabel.text = "Finding photos..."
        indicatorLabel.hidden = false
        activityView.startAnimating()
    }
    
    func hideDownloadIndicators() {
        print("photos urls have been downloaded: \(fetchedResultsController.fetchedObjects?.count), \(pin.photos.count)")
        
        if pin.photos.count != 0 {
            indicatorView.hidden = true
            indicatorLabel.hidden = true
            activityView.stopAnimating()
        } else {
            indicatorView.hidden = false
            indicatorLabel.text = "Bummer, there's no photos."
            activityView.stopAnimating()
        }
    }
    
    func adjustCellDimensions() {
        //TODO: Add check to find device orientation
        
        let dimension = floor(((collectionView.frame.width) - (2 * cellSpacing)) / 3)
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
        flowLayout.minimumLineSpacing = cellSpacing
        flowLayout.minimumInteritemSpacing = cellSpacing
        
    }
    
    
    //MARK - Core Data Convenience
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance.managedObjectContext
    }()
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        let sortDescriptors = NSSortDescriptor(key: "photoPath", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptors]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin)
        
        
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
    }()
    
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //return urlStrings.count
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    
    //MARK: Configure Cells
    func configureCell(cell: CustomCollectionViewCell, photo: Photo, indexPath: NSIndexPath) {
        //check if photo path already exists
        
        cell.imageView!.image = nil
        
        if photo.photoPath == nil || photo.photoPath == "" {
            print("no photo path ")
        } else if photo.flickrImage != nil {
            cell.view.hidden = true
            cell.activityViewIndicator.stopAnimating()
            cell.imageView.contentMode = .ScaleAspectFill
            cell.imageView!.image = photo.flickrImage!

        }
        else {
            let task = VTClient.sharedInstance.taskForImageDataWithURL(photo.photoPath!) { (imageData, error) -> Void in
                if error != nil {
                    return
                }
                
                photo.flickrImage = UIImage(data: imageData!)
                
                dispatch_sync(dispatch_get_main_queue()) {
                    //Make sure the cell is visible before loading the image. Otherwise whe it gets reused the image could be filled with the wrong photos
                    //and you'll get images that keep changing until all photos are finished downloading
                    
                    let visCell = self.collectionView.cellForItemAtIndexPath(indexPath) as? CustomCollectionViewCell
                    if visCell != nil {
                        visCell!.view.hidden = true
                        visCell!.activityViewIndicator.stopAnimating()
                        visCell!.imageView.contentMode = .ScaleAspectFill
                        visCell!.imageView.image = UIImage(data: imageData!)
                    }
                }
            }
            
            if cell.imageView.image == nil {
                cell.view.hidden = false
                cell.activityViewIndicator.startAnimating()
            }
            
            cell.taskToCancelifCellIsReused = task
        }
        
        //If the cell is selected or not change it's alpha value
        if let _ = selectedIndexes.indexOf(indexPath) {
            cell.imageView.alpha = 0.3
        } else {
            cell.imageView.alpha = 1.0
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("photoCell", forIndexPath: indexPath) as! CustomCollectionViewCell
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        configureCell(cell, photo: photo, indexPath: indexPath)
        
        return cell
    }
    
    
    //MARK: NSFetchedController Delegate
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        print("controller will change content")
        
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        print("Controller did change section")
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type {
        case .Insert:
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            updatedIndexPaths.append(indexPath!)
            break
        default:
            break
        }
        
        updateBottomButton()
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        collectionView.performBatchUpdates({ () -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            
            }, completion: nil)
    }
    
    
    
    
    //MARK: Selecting a cell to delete
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! CustomCollectionViewCell
        
        // Make sure the picture finishes downloading before it can be selected or unselected
        guard cell.imageView.image != nil else {
            return
        }
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        if let index = selectedIndexes.indexOf(indexPath) {
            // if the index is already selected unselect it
            selectedIndexes.removeAtIndex(index)
        } else {
            // else select it (add the indexPath)
            selectedIndexes.append(indexPath)
        }
        
        configureCell(cell, photo: photo, indexPath: indexPath)
        
        //update the New Collection button
        updateBottomButton()
    }
    
    
    func updateBottomButton() {

        if selectedIndexes.count > 0 {
            newCollectionButton.setTitle("Remove Selected Items", forState: .Normal)
            newCollectionButton.removeTarget(self, action: "loadNewPhotoPage", forControlEvents: .TouchUpInside)
            newCollectionButton.addTarget(self, action: "deleteSelectedPhotos", forControlEvents: .TouchUpInside)
        } else {
            newCollectionButton.setTitle("New Collection", forState: .Normal)
            newCollectionButton.removeTarget(self, action: "deleteSelectedPhotos", forControlEvents: .TouchUpInside)
            newCollectionButton.addTarget(self, action: "loadNewPhotoPage", forControlEvents: .TouchUpInside)
        }
    }
    
    func deleteSelectedPhotos() {
        print("delete selected photos")
        var photosToDelete = [Photo]()
        
        for indexPath in selectedIndexes {
            photosToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Photo)
        }
        
        for photo in photosToDelete {
            sharedContext.deleteObject(photo)
        }
        
        selectedIndexes = [NSIndexPath]()
        
        // Save current state
        CoreDataStackManager.sharedInstance.saveContext()
    }
    
    
    
    //MARK: Load a new Collection
    func loadNewPhotoPage() {
        
        newCollectionButton.enabled = false
        cancelAllCellNetworkTasks()
        
        showDownloadIndicators()

        deleteCollectionPhotos()
        
        //Make sure pages don't exceed the total amount of pictures available
        if pin.maxPage > pin.currentPage {
            pin.currentPage++
        } else {
            pin.currentPage = 1
        }
        
        
        newCollectionNetworkTask =  VTClient.sharedInstance.getPhotosFromFlick(Double(pin.latitude), lon: Double(pin.longitude), page: pin.currentPage) { (success, photoResults, pictureCount, errorString) -> Void in
            if success {
                self.pin.totalPictureCount = pictureCount
                for pic in photoResults! {
                    let photo = Photo(imagePath: pic["url_m"] as! String, context: self.sharedContext)
                    self.pin.totalPictureCount = pictureCount
                    photo.pin = self.pin
                }
                
                self.sharedContext.performBlock({ () -> Void in
                    CoreDataStackManager.sharedInstance.saveContext()
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.hideDownloadIndicators()
                        self.newCollectionButton.enabled = true
                    }
                })
                
            }
        }

    }
    
    
    //MARK: Delete the old previous collection photos
    func deleteCollectionPhotos() {
        for p in pin.photos as NSArray {
            let photo = p as! Photo
            sharedContext.deleteObject(photo)
        }
    }
    
}

















