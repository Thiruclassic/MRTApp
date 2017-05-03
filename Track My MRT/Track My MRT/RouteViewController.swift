//
//  RouteViewController.swift
//  Track My MRT
//
//  Created by Moushumi Seal on 27/4/17.
//  Copyright © 2017 Team-FT03. All rights reserved.
//

import UIKit

class RouteViewController : UIViewController{
    
    
    var fromStationText:String!
    var toStationText:String!
    
    @IBOutlet weak var fromStationLabel: UILabel!
    
    @IBOutlet weak var fromStationScrollLabel: UILabel!
    
    @IBOutlet weak var arrivalTimeLabel: UILabel!

    @IBOutlet weak var nextArrivalTimeLabel: UILabel!

    @IBOutlet weak var fareLabel: UILabel!


    @IBOutlet weak var toStationLabel: UILabel!
    
    @IBAction func share(_ sender: UIButton) {
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        fromStationLabel.text=fromStationText
        fromStationScrollLabel.text=fromStationText
        toStationLabel.text=toStationText
        
       // readStationArrivalTime(stnCode: "asd")
    
    }
    
    
}
