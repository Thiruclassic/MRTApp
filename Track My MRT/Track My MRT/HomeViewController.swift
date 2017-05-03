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
    
    
    var stations:Array = [""]
    
    var selectedStations = RouteModel()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fromDropDown.dataSource=self
        fromDropDown.delegate=self
        toDropDown.dataSource=self
        toDropDown.delegate=self
        stations=readAllStations()
        self.splitViewController?.delegate = self
        self.splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.allVisible
        selectedStations = (tabBarController as! MrtTabController).selectedStations
       // createStationTable()
    }
    
    @IBAction func showRoute(_ sender: UIButton) {
        
        //readStationArrivalTime(stnCode: "LVR")
        
        let routeViewController=self.storyboard?.instantiateViewController(withIdentifier: ROUTEVIEW_CONTROLLER_ID) as! RouteViewController
        
        routeViewController.fromStationText=fromStationName.text
        routeViewController.toStationText=toStationName.text
        
       self.navigationController?.pushViewController(routeViewController, animated: true)
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func showFromDropDown()
    {
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
        let cell:CustomStationCell!
        if(tableView==self.fromDropDown)
        {
         cell=self.fromDropDown.dequeueReusableCell(withIdentifier: FROM_TABLE_CELL_ID) as! CustomStationCell
        }
        else
        {
        cell=self.toDropDown.dequeueReusableCell(withIdentifier: TO_TABLE_CELL_ID) as! CustomStationCell
        }
        
        cell?.backgroundColor=UIColor.green

        //print(tableView.restorationIdentifier!)
       
        
        let stationName=stations[indexPath.row] as String
                cell.stationLabel.text=stationName
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //print(stations.count)
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

