//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Eric Hodgins on 2016-03-01.
//  Copyright © 2016 Eric Hodgins. All rights reserved.
//

import UIKit
import CoreData

private let cellSpacing: CGFloat = 1

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
    
    var selectedIndexes = [NSIndexPath]()
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    var pin: Pin!

    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var urlStrings = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        
        try! fetchedResultsController.performFetch()
        
        fetchedResultsController.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        adjustCellDimensions()
    }
    
    func adjustCellDimensions() {
        //TODO: Add check to find device orientation
        
        let dimension = floor(((collectionView.frame.width) - (2 * cellSpacing)) / 3)
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
        flowLayout.minimumLineSpacing = cellSpacing
        flowLayout.minimumInteritemSpacing = cellSpacing
        
    }

    @IBAction func newCollectionButtonPressed(sender: AnyObject) {
        
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
    
    func configureCell(cell: CustomCollectionViewCell, photo: Photo, indexPath: NSIndexPath) {
        //check if photo path already exists
        
        cell.imageView!.image = nil
        
        if photo.photoPath == nil || photo.photoPath == "" {

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
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("photoCell", forIndexPath: indexPath) as! CustomCollectionViewCell
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { () -> Void in
//            self.configureCell(cell, photo: photo)
//        }

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
        print("Controller did change object")
        
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
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        print("controller did change content")
        
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

}

















