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
    
        fromStationLabel.text=stationData.fromStation
        fromStationScrollLabel.text=stationData.fromStation
        toStationLabel.text=stationData.toStation
        fareLabel.text=stationData.fare!
        
        arrivalTimeLabel.text = stationData.arrivalTime
        nextArrivalTimeLabel.text = stationData.nxtTrainArrivalTime
        
        readStationArrivalTime(stnCode: stationData.stationCode,stnDirectionId: stationData.stationDirectionId)
    
    }
    
    func readStationArrivalTime(stnCode:String,stnDirectionId:Int)
    {
        let endpoint: String = MRT_ARRTIVAL_URL
        guard let mrtURL = URL(string: endpoint) else {
            print("Error: cannot create URL")
            return
        }
        var arrivalTimes:[String]!
        
        var mrtUrlRequest = URLRequest(url: mrtURL)
        
        
        let postString : String?
        postString=POST_KEY + stnCode
        
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
                
                guard let stnData = receivedMRTData[stnCode] as? AnyObject,let platformData=stnData[PLATFORM+String(stnDirectionId)] as? AnyObject, let nxtTrain=platformData[NXT_TRAIN] as? String,let subTrain=platformData[SUB_TRAIN] as? String,let time=receivedMRTData[TIME] as? String
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


