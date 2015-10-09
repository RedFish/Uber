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
	var date = NSDate()
}


extension Double {
	func format(f: String) -> String {
		return NSString(format: "%\(f)f", self) as String
	}
}

class DriverViewController: UITableViewController, CLLocationManagerDelegate {
	
	var mapManager: CLLocationManager!
	var location = PFGeoPoint()
	var riderRequests : [RiderRequest]!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		print("logged in as Driver")
		
		riderRequests = [RiderRequest()]
		riderRequests.removeAll()
		
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
	
	// MARK: - Table view data source
	
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		// #warning Incomplete implementation, return the number of sections
		return 1
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		// #warning Incomplete implementation, return the number of rows
		return riderRequests.count
	}
	
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! Cell
		
		cell.username.text = riderRequests[indexPath.row].username
		let distance:Double = location.distanceInKilometersTo(riderRequests[indexPath.row].location)
		let format = ".1"
		cell.distance.text = "\(distance.format(format)) km"
		let minutes = abs(Int(riderRequests[indexPath.row].date.timeIntervalSinceNow / 60))
		cell.time.text = "\(minutes) minutes ago"
	
		return cell
	}
	
	//Called every time the location is updated
	func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		//Get the location
		let userLocation:CLLocation = locations[0]
		//let coordinate = CLLocationCoordinate2DMake(userLocation.coordinate.latitude, userLocation.coordinate.longitude)
		location = PFGeoPoint(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
		
		
		let query = PFQuery(className: "RiderRequest")
		query.whereKey("location", nearGeoPoint: location, withinKilometers: 25)
		query.orderByAscending("createdAt")
		query.limit = 10
		query.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
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
					
					self.riderRequests = self.riderRequests.sort({ $0.location.distanceInKilometersTo(self.location) < $1.location.distanceInKilometersTo(self.location) })
					self.tableView.reloadData()
				}
			}
		})
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "logoutDriver" {
			PFUser.logOut()
			navigationController?.setNavigationBarHidden(navigationController?.navigationBarHidden == false, animated: false)
		}
		else if segue.identifier == "showViewRequest" {
			if let destination = segue.destinationViewController as? ViewRequestViewController {
				destination.request = riderRequests[(tableView.indexPathForSelectedRow?.row)!]
			}
		}
	}

}
