//
//  DriverViewController.swift
//  Uber
//
//  Created by Richard Guerci on 05/10/2015.
//  Copyright © 2015 Richard Guerci. All rights reserved.
//

import UIKit
import Parse

class DriverViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
		print("logged in as Driver")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "logoutDriver" {
			PFUser.logOut()
		}
	}

}
