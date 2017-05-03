//
//  RouteViewController.swift
//  Track My MRT
//
//  Created by Moushumi Seal on 27/4/17.
//  Copyright © 2017 Team-FT03. All rights reserved.
//

import UIKit

class RouteViewController : UIViewController{
    
    @IBOutlet weak var fromStationLabel: UILabel!
    
    @IBOutlet weak var arrivalTimeLabel: UILabel!

    @IBOutlet weak var nextArrivalTimeLabel: UILabel!

    @IBOutlet weak var fareLabel: UILabel!


    @IBOutlet weak var toStationLabel: UILabel!

    
    @IBAction func share(_ sender: Any) {
        
        let bounds = UIScreen.main.bounds
        UIGraphicsBeginImageContextWithOptions(bounds.size, true, 0.0)
        self.view.drawHierarchy(in: bounds, afterScreenUpdates: false)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let activityViewController = UIActivityViewController(activityItems: [img!], applicationActivities: nil)
        self.present(activityViewController, animated: true, completion: nil)
        
        
    
    }
    
    
    
   
    
}

    
