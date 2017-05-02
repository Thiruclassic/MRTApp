//
//  HomeViewController.swift
//  Track My MRT
//
//  Created by Moushumi Seal on 25/4/17.
//  Copyright © 2017 Team-FT03. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController,UIPickerViewDataSource,UIPickerViewDelegate, UISplitViewControllerDelegate,UIScrollViewDelegate{

    
    
    
   
    @IBOutlet weak var fromStation: UIPickerView!
    
    @IBOutlet weak var toStation: UIPickerView!
    
    let stations = ["Clementi","Dover","Haw par villa", "Kent ridge"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        self.splitViewController?.delegate = self
        self.scrollView.maximumZoomScale = 0.5
        self.scrollView.minimumZoomScale = 5.0
        self.scrollView.contentSize = self.img.frame.size;
        self.splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.allVisible
        
    }
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var img: UIImageView!
    
    
    @IBAction func showRoute(_ sender: UIButton) {
        
    }

    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return stations.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return stations[row]
    }
    
    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController!, ontoPrimaryViewController primaryViewController: UIViewController!) -> Bool{
        return true
    }
    func viewForZoomingInScrollView(scrollView : UIScrollView) -> UIView
    {
        
        return self.img
        
    }

}
    


    

