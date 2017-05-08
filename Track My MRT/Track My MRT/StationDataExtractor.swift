//
//  StationDataExtractor.swift
//  Track My MRT
//
//  Created by Thirumal Dhanasekaran on 27/4/17.
//  Copyright © 2017 Team-FT03. All rights reserved.
//

import Foundation



func readAllStations() -> Array<String>
{
    var stationArray = Array<String>()
    
    
    let stations:[NSDictionary] = readJSONData(fileName:STATION_JSON_FILE,fileType:JSON_TYPE,rootElement:STATION_ROOT_ELEMENT)
    
    for station:NSDictionary in stations
    {
        let name = String(describing: station[STATION_NAME]!)
        stationArray.append(name)
    }
    stationArray.sort()
    return stationArray

}

func sortAllStations(stationArray:[String])
{
    
}

func readJSONData(fileName:String,fileType:String,rootElement:String) -> [NSDictionary]
{
    let path=Bundle.main.path(forResource: fileName, ofType: fileType)
    
    let  jsonData=try? NSData(contentsOfFile: path!, options: NSData.ReadingOptions.mappedIfSafe)
    
    
    let jsonResult:NSDictionary = try! JSONSerialization.jsonObject(with: jsonData as! Data , options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
    
    
    
    return jsonResult[rootElement] as! [NSDictionary]
}

func computeLocalArrivalTime(nextTrain:String,subTrain:String,time:String) -> [String]
{
    let calendar = Calendar.current
    
    var arrivalTimes:[String] = [nextTrain,subTrain]
    
    
    
    let components:[String]=time.components(separatedBy: "-")
    var dateComponents=DateComponents()
    dateComponents.year=Int(components[0])
    dateComponents.month=Int(components[1])
    dateComponents.day=Int(components[2])
    dateComponents.second=Int(components[5])
    dateComponents.timeZone=TimeZone(abbreviation: SINGAPORE_TIMEZONE)
    
    
    
    for arrivalTime in arrivalTimes
    {
        
        var hour:Int! = Int(components[3])
        var minute:Int! = Int(components[4])
        
        guard Int(arrivalTime) != nil
            else {
            print(ERROR_MESSAGE, "Error in Train Arrival Data")
            return arrivalTimes
        }
        minute = minute + Int(arrivalTime)!
        if(minute>=60)
        {
            minute = minute % 60
            hour = hour + 1
        }
        
        dateComponents.hour=hour
        dateComponents.minute=minute

        let localdateTime = calendar.date(from: dateComponents)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = DATE_FORMAT
        dateFormatter.timeZone = TimeZone(abbreviation: SINGAPORE_TIMEZONE)
        arrivalTimes[arrivalTimes.index(of: arrivalTime)!] = dateFormatter.string(from: localdateTime!)
    }
    print(calendar)
 
    
    return arrivalTimes
}
