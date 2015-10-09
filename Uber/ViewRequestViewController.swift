//
//  ViewRequestViewController.swift
//  Uber
//
//  Created by Richard Guerci on 09/10/2015.
//  Copyright © 2015 Richard Guerci. All rights reserved.
//

import UIKit
import Parse
import MapKit

class ViewRequestViewController: UIViewController, CLLocationManagerDelegate {
	
	var mapManager: CLLocationManager!
	@IBOutlet weak var map: MKMapView!
	var request = RiderRequest()
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		let userLocation = CLLocationCoordinate2D(latitude: request.location.latitude, longitude: request.location.longitude)
		let coordinate = CLLocationCoordinate2DMake(userLocation.latitude, userLocation.longitude)
		let span:MKCoordinateSpan = MKCoordinateSpanMake(0.01, 0.01)
		let region:MKCoordinateRegion = MKCoordinateRegionMake(coordinate, span)
		map.setRegion(region, animated: true)
		let riderAnnotation = MKPointAnnotation()
		riderAnnotation.coordinate = coordinate
		riderAnnotation.title = "\(request.username) is waiting here"
		map.addAnnotation(riderAnnotation)
    }

	@IBAction func pickUpRiderButtonAction(sender: AnyObject) {
		let query = PFQuery(className: "RiderRequest")
		query.whereKey("username", equalTo: request.username)
		query.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
			if error != nil {
				print("Error finding RiderRequest")
			}
			else {
				if let objects = objects {
					for object in objects {
						let queryUpdate = PFQuery(className: "RiderRequest")
						queryUpdate.getObjectInBackgroundWithId(object.objectId!, block: {(object:PFObject?, error:NSError?) -> Void in
							if error != nil {
								print("Error getting object RiderRequest")
							}
							else if let object = object{
								//upadate db
								object["driverResponded"] = PFUser.currentUser()?.username
								object.saveInBackground()
								
								//launch direction in maps
								CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: self.request.location.latitude, longitude: self.request.location.longitude), completionHandler: { (placemarks, error) -> Void in
									if (error == nil) {
										//if statement was changed
										if let p = placemarks?[0] {
											let mapItem = MKMapItem(placemark: MKPlacemark(placemark:p))
											mapItem.name = "Drive to this place to pick up \(self.request.username)"
											let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
											mapItem.openInMapsWithLaunchOptions(launchOptions)
										}
									}
								})

							}
						})

					}
				}
			}
		})
	}
	
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
