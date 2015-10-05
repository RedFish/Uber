//
//  ViewController.swift
//  Uber
//
//  Created by Richard Guerci on 05/10/2015.
//  Copyright © 2015 Richard Guerci. All rights reserved.
//

import UIKit
import Parse

class ViewController: UIViewController, UITextFieldDelegate {

	@IBOutlet weak var username: UITextField!
	@IBOutlet weak var password: UITextField!
	@IBOutlet weak var `switch`: UISwitch!
	@IBOutlet weak var riderLabel: UILabel!
	@IBOutlet weak var driverLabel: UILabel!
	@IBOutlet weak var submitButton: UIButton!
	@IBOutlet weak var toggleButton: UIButton!
	@IBOutlet weak var questionLabel: UILabel!
	
	var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
	var isSignUpMode = true
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		`switch`.hidden = false
		riderLabel.hidden = false
		driverLabel.hidden = false
		username.delegate = self
		password.delegate = self
	}

	@IBAction func submitButtonAction(sender: AnyObject) {
		
		if username.text == "" || password.text == "" {
			displayAlert("Missing Field(s)", message: "Username and password are required")
		}
		else {
			//start spinner
			activityIndicator = UIActivityIndicatorView(frame: CGRectMake(0, 0, 50, 50))
			activityIndicator.center = self.view.center
			activityIndicator.hidesWhenStopped = true
			activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
			view.addSubview(activityIndicator)
			//ignore interaction events
			activityIndicator.startAnimating()
			UIApplication.sharedApplication().beginIgnoringInteractionEvents()
			
			//set default error message
			var errorMessage = "Please try again"
			
			if isSignUpMode {
				//signup with parse
				let user = PFUser()
				user.username = username.text
				user.password = password.text
				user["isDriver"] = self.`switch`.on
				
				user.signUpInBackgroundWithBlock {
					(succeeded: Bool, error: NSError?) -> Void in
					//enable interaction events
					self.activityIndicator.stopAnimating()
					UIApplication.sharedApplication().endIgnoringInteractionEvents()
					
					if error != nil {
						if let errorString = error!.userInfo["error"] as? String {
							errorMessage = errorString
						}
						self.displayAlert("Failed to sign up", message: errorMessage)
					} else {
						self.displayAlert("Sign Up Succcess", message: "You can start using Uber")
						self.password.text = ""
						self.toggleButtonAction("")
					}
				}
			}
			else{
				//login with parse
				PFUser.logInWithUsernameInBackground(username.text!, password:password.text!) {
					(user: PFUser?, error: NSError?) -> Void in
					//enable interaction events
					self.activityIndicator.stopAnimating()
					UIApplication.sharedApplication().endIgnoringInteractionEvents()
					
					if error != nil {//login failed
						if let errorString = error!.userInfo["error"] as? String {
							errorMessage = errorString
						}
						self.displayAlert("Failed to login", message: errorMessage)
					}
					else {
						self.login()
					}
				}
			}
		}
	}
	
	func login(){
		if let isDriver = PFUser.currentUser()!["isDriver"] {
			if isDriver as! Bool {
				self.performSegueWithIdentifier("showDriverView", sender: self)
			}
			else {
				self.performSegueWithIdentifier("showRiderView", sender: self)
			}
		}
	}
	
	@IBAction func toggleButtonAction(sender: AnyObject) {
		isSignUpMode = !isSignUpMode
		if isSignUpMode {
			`switch`.hidden = false
			riderLabel.hidden = false
			driverLabel.hidden = false
			questionLabel.text = "Already registered ?"
			submitButton.setTitle("Sign Up", forState: UIControlState.Normal)
			toggleButton.setTitle("login", forState: UIControlState.Normal)
		}
		else {
			`switch`.hidden = true
			riderLabel.hidden = true
			driverLabel.hidden = true
			questionLabel.text = "Not registered yet ?"
			submitButton.setTitle("Login", forState: UIControlState.Normal)
			toggleButton.setTitle("sign up", forState: UIControlState.Normal)
		}
	}
	
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func displayAlert(title:String, message:String){
		let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
		alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
			self.dismissViewControllerAnimated(true, completion: nil)
		}))
		self.presentViewController(alert, animated: true, completion: nil)
	}

	//Remove keyboard when touch ouside the keyboard
	override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
		self.view.endEditing(true)
	}
	
	//Remove keyboard when clic 'return'
	func textFieldShouldReturn(textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}

	override func viewDidAppear(animated: Bool) {
		if let _ = PFUser.currentUser()?.username {
			login()
		}
	}
}

