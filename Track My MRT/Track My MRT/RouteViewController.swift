//
//  RouteViewController.swift
//  Track My MRT
//
//  Created by Moushumi Seal on 27/4/17.
//  Copyright © 2017 Team-FT03. All rights reserved.
//

import UIKit

class RouteViewController : UIViewController{
    
    
    var stationData:StationData!
    
    @IBOutlet weak var activityIndicatorArrival: UIActivityIndicatorView!
    
    @IBOutlet weak var activityIndicatornxtArrival: UIActivityIndicatorView!
    
    @IBOutlet weak var fromStationLabel: UILabel!
    
    @IBOutlet weak var fromStationScrollLabel: UILabel!
    
    @IBOutlet weak var arrivalTimeLabel: UILabel!

    @IBOutlet weak var nextArrivalTimeLabel: UILabel!

    @IBOutlet weak var fareLabel: UILabel!
    

    @IBOutlet weak var intermediateStation1: UILabel!

    @IBOutlet weak var intermediateStation2: UILabel!

    @IBOutlet weak var intermediateStation3: UILabel!
    
    
    
    @IBOutlet weak var intermediateStationImage1: UIImageView!
    
    
    @IBOutlet weak var intermediateStationImage2: UIImageView!
    
    @IBOutlet weak var intermediateStationImage3: UIImageView!
    
    
    @IBOutlet weak var toStationLabel: UILabel!
    
    @IBOutlet weak var fromStationImage: UIImageView!
   
    @IBAction func share(_ sender: Any) {
        let bounds = UIScreen.main.bounds
        UIGraphicsBeginImageContextWithOptions(bounds.size, true, 0.0)
        self.view.drawHierarchy(in: bounds, afterScreenUpdates: false)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let activityViewController = UIActivityViewController(activityItems: [img!], applicationActivities: nil)
        self.present(activityViewController, animated: true, completion: nil)
        
        
        
    }

    func addBackGroundImage()
    {
        UIGraphicsBeginImageContext(self.view.frame.size)
        UIImage(named: "background.jpg")?.draw(in: self.view.bounds)
        
        let image: UIImage! = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        self.view.backgroundColor = UIColor(patternImage: image)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        fromStationLabel.text=stationData.fromStation
        fromStationScrollLabel.text=stationData.fromStation
        toStationLabel.text=stationData.toStation
        fareLabel.text=stationData.fare
        
        arrivalTimeLabel.text = stationData.arrivalTime
        nextArrivalTimeLabel.text = stationData.nxtTrainArrivalTime
        
       
        //intermediateStatusLabel.text = ""
        
        if(stationData.intermediateStations.count > 1)
        {
            fareLabel.isHidden = true
            intermediateStation2.text = stationData.intermediateStations[0]
            intermediateStation3.text = stationData.intermediateStations[1]
            intermediateStation2.isHidden = false
            intermediateStation3.isHidden = false
            intermediateStationImage2.isHidden = false
            intermediateStationImage3.isHidden = false
        }
        else if(stationData.intermediateStations.count == 1)
        {
            intermediateStation1.text = stationData.intermediateStations[0]
            intermediateStation1.isHidden = false
            intermediateStationImage1.isHidden = false
        }
        
        
        
        
        readStationArrivalTime(stnCode: stationData.stationCode,stnDirectionId: stationData.stationDirectionId)
        
        addBackGroundImage()
    
    }
    
    func readStationArrivalTime(stnCode:String?,stnDirectionId:Int)
    {
        
        if(stnCode != nil)
        {
        let endpoint: String = MRT_ARRTIVAL_URL
        guard let mrtURL = URL(string: endpoint) else {
            print("Error: cannot create URL")
            return
        }
        var arrivalTimes:[String]!
        
        var mrtUrlRequest = URLRequest(url: mrtURL)
        
        
        let postString : String?
        postString=POST_KEY + stnCode!
        
        mrtUrlRequest.httpBody=postString!.data(using: String.Encoding.utf8)
        
        mrtUrlRequest.httpMethod = "POST"
        
        
        
        
        let session = URLSession.shared
        
        let task = session.dataTask(with: mrtUrlRequest) {
            (data, response, error) in
            guard error == nil else {
                print("error calling POST on API")
                print(error)
                return
            }
            
            guard let responseData = data else {
                print("Error: did not receive data")
                return
            }
            
            
            let httpStatus = response as? HTTPURLResponse
            print("status: \(httpStatus?.statusCode)")
            // parse the result as JSON, since that's what the API provides
            do {
                guard let receivedMRTData = try JSONSerialization.jsonObject(with: responseData,
                                                                             options: []) as? [String: Any] else {
                                                                                print("Could not get JSON from responseData as dictionary")
                                                                                return
                }
                //print("Train Arrival Data: " + receivedMRTData.description)
                
                guard let stnData = receivedMRTData[stnCode!] as? AnyObject,let platformData=stnData[PLATFORM+String(describing: stnDirectionId)] as? AnyObject, let nxtTrain=platformData[NXT_TRAIN] as? String,let subTrain=platformData[SUB_TRAIN] as? String,let time=receivedMRTData[TIME] as? String
                    else {
                        print("Could not get MRTData from JSON")
                        return
                }
                
                let subTrainText = subTrain.replacingOccurrences(of: REDUNTANT_TEXT, with: "")
                let nextTrainText = nxtTrain.replacingOccurrences(of: REDUNTANT_TEXT, with: "")
                
                
                
                
                
                arrivalTimes = computeLocalArrivalTime(nextTrain: nextTrainText, subTrain: subTrainText, time: time)
                
                print(arrivalTimes[0])
                print(arrivalTimes[1])
                
                DispatchQueue.main.async {
                    self.activityIndicatorArrival.stopAnimating()
                    self.activityIndicatornxtArrival.stopAnimating()
                    self.arrivalTimeLabel.text=arrivalTimes[0]
                    self.nextArrivalTimeLabel.text=arrivalTimes[1]
                }
                
                
                
                
                
            } catch let err {
                print("error parsing response from POST on mrt api")
                print(err.localizedDescription)
                return
            }
        }
        task.resume()
        
    }
    }
    
    
}


