//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Eric Hodgins on 2016-03-01.
//  Copyright © 2016 Eric Hodgins. All rights reserved.
//

import UIKit

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var urlStrings = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        
        print(urlStrings)
    }
    
    override func viewDidLayoutSubviews() {
        adjustCellDimensions()
    }
    
    func adjustCellDimensions() {
        print(collectionView.frame.size.width)
        print(view.frame.size.width)

        
        let dimension = ((collectionView.frame.width) - 2) / 3
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
        flowLayout.minimumLineSpacing = 1
        flowLayout.minimumInteritemSpacing = 1
        
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
