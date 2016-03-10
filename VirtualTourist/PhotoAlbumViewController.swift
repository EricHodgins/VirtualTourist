//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Eric Hodgins on 2016-03-01.
//  Copyright © 2016 Eric Hodgins. All rights reserved.
//

import UIKit

private let cellSpacing: CGFloat = 1

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var urlStrings = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        print("number of photos: \(urlStrings.count)")
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
    
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return urlStrings.count
    }
    
    func configureCell(cell: CustomCollectionViewCell, imageURL: String) {
        
        VTClient.sharedInstance.taskForImageDataWithURL(imageURL) { (imageData, error) -> Void in
            if error != nil {
                return
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                cell.view.hidden = true
                cell.activityViewIndicator.stopAnimating()
                cell.imageView.contentMode = .ScaleAspectFill
                cell.imageView.image = UIImage(data: imageData!)
            }
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("photoCell", forIndexPath: indexPath) as! CustomCollectionViewCell
        
        configureCell(cell, imageURL: urlStrings[indexPath.row])
        
        return cell
    }

}
