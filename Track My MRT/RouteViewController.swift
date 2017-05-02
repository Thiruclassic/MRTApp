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
        
        socialShare(sharingText: "Text to share #Hashtag", sharingImage: UIImage(named: "image"), sharingURL: NSURL(string: "http://itunes.apple.com/app/"))

   
        
        
    
}

    
    
    func socialShare(sharingText: String?, sharingImage: UIImage?, sharingURL: NSURL?) {
        var sharingItems = [AnyObject]()
       
       
        
        if let text = sharingText {
            sharingItems.append(text as AnyObject)
        }
        if let image = sharingImage {
            sharingItems.append(image)
        }
        if let url = sharingURL {
            sharingItems.append(url)
        }
        let bounds = UIScreen.main.bounds
        UIGraphicsBeginImageContextWithOptions(bounds.size, true, 0.0)
        let activityViewController = UIActivityViewController(activityItems: sharingItems, applicationActivities: nil)
        self.view.drawHierarchy(in: bounds, afterScreenUpdates: false)
       
        activityViewController.excludedActivityTypes = [UIActivityType.airDrop,UIActivityType.copyToPasteboard,UIActivityType.addToReadingList,UIActivityType.assignToContact,UIActivityType.postToTencentWeibo,UIActivityType.postToVimeo,UIActivityType.print,UIActivityType.saveToCameraRoll,UIActivityType.postToWeibo]
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    
   
    
}

    
