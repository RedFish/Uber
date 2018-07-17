//
//  DriverViewController.swift
//  Uber
//
//  Created by Richard Guerci on 05/10/2015.
//  Copyright © 2015 Richard Guerci. All rights reserved.
//

import UIKit
import Parse
import MapKit

struct RiderRequest {
	var username = ""
	var location = PFGeoPoint()
	var date = Date()
}


extension Double {
	func format(_ f: String) -> String {
		return NSString(format: "%\(f)f" as NSString, self) as String
	}
}

class DriverViewController: UITableViewController, CLLocationManagerDelegate {
	
	var mapManager: CLLocationManager!
	var location = PFGeoPoint()
	var riderRequests : [RiderRequest]!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		riderRequests = [RiderRequest()]
		riderRequests.removeAll()
		
		//initialize LocationManager
		mapManager = CLLocationManager()
		mapManager.delegate = self
		mapManager.desiredAccuracy = kCLLocationAccuracyBest
		mapManager.requestAlwaysAuthorization()
		mapManager.startUpdatingLocation()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
	}
	
	// MARK: - Table view data source
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		// #warning Incomplete implementation, return the number of sections
		return 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		// #warning Incomplete implementation, return the number of rows
		return riderRequests.count
	}
	
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! Cell
		
		cell.username.text = riderRequests[indexPath.row].username
		let distance:Double = location.distanceInKilometers(to: riderRequests[indexPath.row].location)
		let format = ".1"
		cell.distance.text = "\(distance.format(format)) km"
		let minutes = abs(Int(riderRequests[indexPath.row].date.timeIntervalSinceNow / 60))
		cell.time.text = "\(minutes) minutes ago"
	
		return cell
	}
	
	//Called every time the location is updated
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		//Get the location
		let userLocation:CLLocation = locations[0]
		//let coordinate = CLLocationCoordinate2DMake(userLocation.coordinate.latitude, userLocation.coordinate.longitude)
		location = PFGeoPoint(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
		
		//update current location
		PFUser.current()?["driverLocation"] = self.location
		PFUser.current()!.saveInBackground()

		
		//refresh table
		let query = PFQuery(className: "RiderRequest")
		query.whereKey("location", nearGeoPoint: location, withinKilometers: 25)
		query.order(byAscending: "createdAt")
		query.limit = 10
		query.findObjectsInBackground(block: { (objects, error) -> Void in
			if error != nil {
				print("Error finding RiderRequest")
			}
			else {
				if let objects = objects {
					self.riderRequests.removeAll()
					for object in objects {
						if object["driverResponded"] == nil {
							let username = object["username"] as! String
							let location = object["location"] as! PFGeoPoint
							let date = object.createdAt
							self.riderRequests.append(RiderRequest(username: username, location: location, date: date!))
						}
					}
					
					self.riderRequests = self.riderRequests.sorted(by: { $0.location.distanceInKilometers(to: self.location) < $1.location.distanceInKilometers(to: self.location) })
					self.tableView.reloadData()
				}
			}
		})
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "logoutDriver" {
			PFUser.logOut()
			navigationController?.setNavigationBarHidden(navigationController?.isNavigationBarHidden == false, animated: false)
		}
		else if segue.identifier == "showViewRequest" {
			if let destination = segue.destination as? ViewRequestViewController {
				destination.request = riderRequests[(tableView.indexPathForSelectedRow?.row)!]
			}
		}
	}

}
