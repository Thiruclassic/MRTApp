//
//  HomeViewController.swift
//  Track My MRT
//
//  Created by Moushumi Seal on 25/4/17.
//  Copyright © 2017 Team-FT03. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController, UISplitViewControllerDelegate,UITableViewDataSource,UITableViewDelegate{

    @IBOutlet weak var fromDropDown: UITableView!
    
    @IBOutlet weak var fromStationName:UITextField!
    
    @IBOutlet weak var toDropDown: UITableView!
    
    @IBOutlet weak var toStationName:UITextField!
    
    let backgroundQueue = DispatchQueue.global(qos: .background)
    
    
    
    
    var stations:Array = [""]
    var tempStations:Array = [""]
    
    var selectedStations = RouteModel()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fromDropDown.dataSource=self
        fromDropDown.delegate=self
        toDropDown.dataSource=self
        toDropDown.delegate=self
        
        fromStationName.inputView = UIView()
        toStationName.inputView = UIView()
        
        self.addBackGroundImage()
    
        self.splitViewController?.delegate = self
        self.splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.allVisible
        selectedStations = (tabBarController as! MrtTabController).selectedStations
        
        backgroundQueue.async {
            self.stations=readAllStations()
            createTables()
            //dropTables()
           
            
        }
        
    }
    
    

   
    
    func addBackGroundImage()
    {
        UIGraphicsBeginImageContext(self.view.frame.size)
        UIImage(named: "background.jpg")?.draw(in: self.view.bounds)
        
        let image: UIImage! = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        //self.view.backgroundColor = UIColor(patternImage: image)
    }
    
    @IBAction func showRoute(_ sender: UIButton) {
        
        if (fromStationName.text == "" && toStationName.text == "")
        {
            let alertPopUp:UIAlertController = UIAlertController(title: "Alert", message: "Source and Destination Stations cannot be empty", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "OK", style: .cancel) { action -> Void in
            }
            alertPopUp.addAction(cancelAction)
            self.present(alertPopUp, animated: true, completion: nil)
        }
        else if (fromStationName.text == "" && !(toStationName.text == ""))
        {
            let alertPopUp:UIAlertController = UIAlertController(title: "Alert", message: "Source Station cannot be empty", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "OK", style: .cancel) { action -> Void in
            }
            alertPopUp.addAction(cancelAction)
            self.present(alertPopUp, animated: true, completion: nil)
        }
        else if (!(fromStationName.text == "") && toStationName.text == "")
        {
            let alertPopUp:UIAlertController = UIAlertController(title: "Alert", message: "Destination Station cannot be empty", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "OK", style: .cancel) { action -> Void in
            }
            alertPopUp.addAction(cancelAction)
            self.present(alertPopUp, animated: true, completion: nil)
        }
        else if(fromStationName.text != toStationName.text)
        {
            let routeViewController=self.storyboard?.instantiateViewController(withIdentifier: ROUTEVIEW_CONTROLLER_ID) as! RouteViewController
            
            self.navigationController?.pushViewController(routeViewController, animated: true)
            
            let stationData:StationData = getRouteDetails(fromStation: fromStationName.text!, toStation: toStationName.text!,isIntermediate: false)
            
            routeViewController.stationData=stationData
        }
        else
        {
            let alertPopUp:UIAlertController = UIAlertController(title: "Alert", message: "Destination Station is same as Source", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "OK", style: .cancel) { action -> Void in
            }
            alertPopUp.addAction(cancelAction)
            self.present(alertPopUp, animated: true, completion: nil)
        }
        
      
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func showFromDropDown()
    {
        fromDropDown.cellForRow(at: IndexPath(row: 0, section: 0))?.removeFromSuperview()
        fromDropDown.isHidden=false
        fromDropDown.reloadData()
        
    }
    
    @IBAction func showToDropDown()
    {
        toDropDown.isHidden=false
        toDropDown.reloadData()
        
    }
    @IBAction func hideDropDown()
    {
        print("textfield hide func")
        fromDropDown.isHidden=true
        toDropDown.isHidden=true;
        
    }
    
    
    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController!, ontoPrimaryViewController primaryViewController: UIViewController!) -> Bool{
        return true
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell:CustomStationCell!
       
        if(tableView==self.fromDropDown)
        {
         cell=self.fromDropDown.dequeueReusableCell(withIdentifier: FROM_TABLE_CELL_ID) as! CustomStationCell
        }
        else
        {
        cell=self.toDropDown.dequeueReusableCell(withIdentifier: TO_TABLE_CELL_ID) as! CustomStationCell
        }
        
        
        //fromStationImage.image = UIImage(imageLiteralResourceName: "redTrain")
        let color = UIColor.white
        cell?.backgroundColor = color
        //print(tableView.restorationIdentifier!)
       
        
        let stationName=stations[indexPath.row] as String
        cell.stationLabel.text=stationName

        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stations.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! CustomStationCell!
        let title = cell?.stationLabel.text
        
        if(tableView==fromDropDown)
        {
            fromStationName.text=title
            self.selectedStations.fromStation = title!
        }
        else
        {
            toStationName.text=title
            self.selectedStations.toStation = title!
        }
        tableView.isHidden=true;
    }
}

