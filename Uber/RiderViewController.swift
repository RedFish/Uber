//
//  RiderViewController.swift
//  Uber
//
//  Created by Richard Guerci on 05/10/2015.
//  Copyright © 2015 Richard Guerci. All rights reserved.
//

import UIKit
import Parse
import MapKit

class RiderViewController: UIViewController, CLLocationManagerDelegate {
	
	var mapManager: CLLocationManager!
	@IBOutlet weak var map: MKMapView!
	@IBOutlet weak var uberButton: UIButton!
	let riderAnnotation = MKPointAnnotation()
	let driverAnnotation = MKPointAnnotation()
	var location = PFGeoPoint ()
	var driverLocation = CLLocationCoordinate2D ()
	var isCallingUber = false
	var isDriverOnTheWay = false
	
    override func viewDidLoad() {
		super.viewDidLoad()
		
		//initialize LocationManager
		mapManager = CLLocationManager()
		mapManager.delegate = self
		mapManager.desiredAccuracy = kCLLocationAccuracyBest
		mapManager.requestWhenInUseAuthorization()
		mapManager.startUpdatingLocation()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
		
    }
	@IBAction func callUberButtonAction(_ sender: AnyObject) {
		if !isCallingUber {
			let riderRequest = PFObject(className: "RiderRequest")
			riderRequest["username"] = PFUser.current()?.username
			riderRequest["location"] = location
			riderRequest.saveInBackground { (succsess, error) -> Void in
				if error == nil {
					//Success
					self.isCallingUber = true
					self.uberButton.setTitle("Cancel Uber", for: UIControlState())
				}
				else {
					self.displayAlert("Could not call Uber", message: "Try again later")
				}
			}
		}
		else {
			//check if already followed
			let query = PFQuery(className: "RiderRequest")
			query.whereKey("username", equalTo: (PFUser.current()?.username)!)
			query.findObjectsInBackground(block: { (objects, error) -> Void in
				if error != nil {
					print("Error finding RiderRequest")
				}
				else {
					if let objects = objects {
						for object in objects {
							object.deleteInBackground()
						}
					}
				}
			})
			self.uberButton.setTitle("Call an Uber", for: UIControlState())
			isCallingUber = false
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "logoutRider" {
			PFUser.logOut()
		}
	}

	//Called every time the location is updated
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		//Get the location
		let userLocation:CLLocation = locations[0]
		let coordinate = CLLocationCoordinate2DMake(userLocation.coordinate.latitude, userLocation.coordinate.longitude)
		var latDelta = 0.01
		var lonDelta = 0.01
		if isDriverOnTheWay {
			latDelta = abs(driverLocation.latitude - coordinate.latitude) * 2 + 0.005
			lonDelta = abs(driverLocation.longitude - coordinate.longitude) * 2 + 0.005
		}
		let span:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lonDelta)
		let region:MKCoordinateRegion = MKCoordinateRegionMake(coordinate, span)
		map.setRegion(region, animated: true)
		
		location = PFGeoPoint(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
		
		//get location of driver
		if isCallingUber {
			let query = PFQuery(className: "RiderRequest")
			query.whereKey("username", equalTo: (PFUser.current()?.username)!)
			query.findObjectsInBackground(block: { (objects, error) -> Void in
				if error != nil {
					print("Error finding RiderRequest")
				}
				else {
					if let objects = objects {
						for object in objects {
							if object["driverResponded"] != nil {
								if let driverResponded = object["driverResponded"] as? String {
									let queryUser = PFUser.query()
									queryUser?.whereKey("username", equalTo: driverResponded)
									queryUser?.findObjectsInBackground(block: { (drivers, error) -> Void in
										if error == nil {
											if let drivers = drivers {
												for driver in drivers {
													if let driverLocation = driver["driverLocation"] as? PFGeoPoint {
														let location = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
														self.driverLocation = CLLocationCoordinate2DMake(driverLocation.latitude, driverLocation.longitude)
														let distance = (location.distance(from: CLLocation(latitude: self.location.latitude, longitude: self.location.longitude))/1000).format(".1")
														self.uberButton.setTitle("Driver is \(distance)km away!", for: UIControlState())
														self.isDriverOnTheWay = true
													}
												}
											}
										}
										else { print("Cannot find driver") }
									})
								}
							}
						}
					}
				}
			})
		}
		
		
		map.removeAnnotation(riderAnnotation)
		riderAnnotation.coordinate = coordinate
		riderAnnotation.title = "You are here"
		map.addAnnotation(riderAnnotation)
		
		if isDriverOnTheWay {
			map.removeAnnotation(driverAnnotation)
			driverAnnotation.coordinate = driverLocation
			driverAnnotation.title = "Driver is here"
			map.addAnnotation(driverAnnotation)
		}
	}
	
	func displayAlert(_ title:String, message:String){
		let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
			self.dismiss(animated: true, completion: nil)
		}))
		self.present(alert, animated: true, completion: nil)
	}
}
