//
//  StationDataExtractor.swift
//  Track My MRT
//
//  Created by Thirumal Dhanasekaran on 27/4/17.
//  Copyright © 2017 Team-FT03. All rights reserved.
//

import Foundation

let fileName:String! = "stations"
let fileType:String! = "json"

func readAllStations() -> Array<String>
{
    var stationArray = Array<String>()
    
    let path=Bundle.main.path(forResource: fileName, ofType: fileType)
    
    let  jsonData=try? NSData(contentsOfFile: path!, options: NSData.ReadingOptions.mappedIfSafe)
    
  
    let jsonResult:NSDictionary = try! JSONSerialization.jsonObject(with: jsonData as! Data , options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
    
    
    
    let stations:[NSDictionary] = jsonResult[JSON_ROOT_ELEMENT] as! [NSDictionary]
    
    for station:NSDictionary in stations
    {
        let name = String(describing: station[STATION_NAME]!)
        stationArray.append(name)

        print(name)
    }
    
    return stationArray

}


func readStationArrivalTime(stnCode:String) -> String
{
    let endpoint: String = MRT_ARRTIVAL_URL
    guard let mrtURL = URL(string: endpoint) else {
        print("Error: cannot create URL")
        return ""
    }
   
    
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
            print("Train Arrival Data: " + receivedMRTData.description)
            
            guard let todoID = receivedMRTData["platform1"] as? AnyObject,let one=todoID["direction"] as? String
                else {
                    print("Could not get MRTData from JSON")
                    return
            }
            
            print("The ID is: \(one)")
        } catch let err {
            print("error parsing response from POST on /todos")
            print(err.localizedDescription)
            return
        }
    }
    task.resume()
    
    return ""
}
