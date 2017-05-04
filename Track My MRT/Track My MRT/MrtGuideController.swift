//
//  MrtGuideController.swift
//  Track My MRT
//
//  Created by Varun Sam on 04/05/17.
//  Copyright © 2017 Team-FT03. All rights reserved.
//

import Foundation
import UIKit

class MrtGuideController:  UIViewController,UIScrollViewDelegate{
    
    
    @IBOutlet weak var img: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.scrollView.minimumZoomScale = 1.0
        self.scrollView.maximumZoomScale = 6.0
        
    }
    
    func  viewForZooming(in scrollView: UIScrollView) -> UIView? {
        
        return self.img
        
    }
    
    
}
