//
//  PhotoCell.swift
//  VirtualTourists
//
//  Created by xingxiaoxiong on 12/15/15.
//  Copyright © 2015 Udacity. All rights reserved.
//

import UIKit

class PhotoCell: UICollectionViewCell {
    
    @IBOutlet weak var photo: UIImageView!
    
    var photoImage: UIImage? {
        set {
            self.photo.image = newValue
        }
        
        get {
            return self.photo.image
        }
    }
}
