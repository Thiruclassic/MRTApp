//
//  MapViewController.swift
//  Track My MRT
//
//  Created by Moushumi Seal on 25/4/17.
//  Copyright © 2017 Team-FT03. All rights reserved.
//

import UIKit
import GoogleMaps
import CoreLocation
import MessageUI

class MapViewController: UIViewController, CLLocationManagerDelegate,MFMessageComposeViewControllerDelegate, GMSMapViewDelegate{

   

    
    @IBOutlet var mapView: GMSMapView!
    
    
    private var mapWidth: CGFloat = 0
    private var mapHeight: CGFloat = 0
    var locationManager = CLLocationManager()
    
    var selectedStations = RouteModel()
    
    var latitude = -1.0
    var longitude = -1.0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        selectedStations = (tabBarController as! MrtTabController).selectedStations
        // User Location
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("from: \(selectedStations.fromStation) :: to: \(selectedStations.toStation)")
        mapWidth = view.bounds.width
        mapHeight = view.bounds.height - 150
        locateStations(self.selectedStations.fromStation)
        locateStations(self.selectedStations.toStation)
        /*if(!(self.selectedStations.fromStation.isEmpty && self.selectedStations.toStation.isEmpty)) {
            let stationData = getStationlocationData(fromStation: self.selectedStations.fromStation,
                                                     toStation: self.selectedStations.toStation)
            locateStations(stationName: stationData.fromStation, latitude: stationData.coordinates[1], Longitude: stationData.coordinates[0])
            locateStations(stationName: stationData.toStation, latitude: stationData.coordinates[2], Longitude: stationData.coordinates[3])
        }*/
        
        locationManager.startUpdatingLocation()
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation = locations.last
        self.latitude = userLocation!.coordinate.latitude
        self.longitude = userLocation!.coordinate.longitude
        let camera = GMSCameraPosition.camera(withLatitude: userLocation!.coordinate.latitude, longitude: userLocation!.coordinate.longitude, zoom: 10.0)
        let coordinates = CLLocationCoordinate2DMake(userLocation!.coordinate.latitude, userLocation!.coordinate.longitude)
        mapView = GMSMapView.map(withFrame: CGRect(x: 0, y: 0, width: mapWidth, height: mapHeight), camera: camera)
    
        mapView.settings.myLocationButton = true
        mapView.isMyLocationEnabled = true
        
       
        let marker = GMSMarker(position: coordinates)
        marker.title = "I am here"
        marker.map = self.mapView
        self.view.addSubview(self.mapView)
        
        locationManager.stopUpdatingLocation()
    }
    
   /* private func locateStations(stationName: String, latitude: String, Longitude: String) {
            let lat = Double(latitude)
            let lon = Double(Longitude)
            let coordinates = CLLocationCoordinate2DMake(lat!, lon!)
            let marker = GMSMarker(position: coordinates)
            marker.title = stationName
            marker.map = self.mapView
    } */
    
    private func locateStations(_ address: String) {
        
        let geocoder = CLGeocoder()
        let searchAddress = address
        geocoder.geocodeAddressString(searchAddress, completionHandler:
            {(placemarks, error) -> Void in
                if let placemark = placemarks?[0] {
                    let marker = GMSMarker(position: placemark.location!.coordinate)
                    marker.title = address + " MRT"
                    marker.map = self.mapView
                }
                else {
                    print("Not found")
                }
        })

    } 
    
    @IBAction func sendLocation() {
        let message = "http://maps.google.com/maps?f=q&q=\(self.latitude),\(self.longitude)"
        if (MFMessageComposeViewController.canSendText()) {
            let controller = MFMessageComposeViewController()
            controller.body = message
            controller.recipients = []
            controller.messageComposeDelegate = self
            self.present(controller, animated: true, completion: nil)
        } else {
            print("Simulators")
            print("message::\(message)")
        }

    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        mapView.clear()
    }
    
}

