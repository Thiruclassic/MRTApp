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

class MapViewController: UIViewController, CLLocationManagerDelegate {

   

    
    @IBOutlet var mapView: GMSMapView!
    
    
    
    var locationManager = CLLocationManager()
    
    var selectedStations = RouteModel()
    
    
    
    
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
        locateStations(self.selectedStations.fromStation)
        locateStations(self.selectedStations.toStation)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation = locations.last
        
        let camera = GMSCameraPosition.camera(withLatitude: userLocation!.coordinate.latitude, longitude: userLocation!.coordinate.longitude, zoom: 10.0)
        let coordinates = CLLocationCoordinate2DMake(userLocation!.coordinate.latitude, userLocation!.coordinate.longitude)
        mapView = GMSMapView.map(withFrame: CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height - 120), camera: camera)
    
        mapView.settings.myLocationButton = true
        mapView.isMyLocationEnabled = true
        
       
        let marker = GMSMarker(position: coordinates)
        marker.title = "I am here"
        marker.map = self.mapView
        self.view.addSubview(mapView)
        
        
        
        locationManager.stopUpdatingLocation()
    }
    
    func locateStations(_ address: String) {
        
        let geocoder = CLGeocoder()
        let searchAddress = address + " MRT"
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
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    
}

