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
		
		`switch`.isHidden = false
		riderLabel.isHidden = false
		driverLabel.isHidden = false
		username.delegate = self
		password.delegate = self
	}

	@IBAction func submitButtonAction(_ sender: AnyObject) {
		
		if username.text == "" || password.text == "" {
			displayAlert("Missing Field(s)", message: "Username and password are required")
		}
		else {
			//start spinner
			activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
			activityIndicator.center = self.view.center
			activityIndicator.hidesWhenStopped = true
			activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
			view.addSubview(activityIndicator)
			//ignore interaction events
			activityIndicator.startAnimating()
			UIApplication.shared.beginIgnoringInteractionEvents()
			
			//set default error message
			var errorMessage = "Please try again"
			
			if isSignUpMode {
				//signup with parse
				let user = PFUser()
				user.username = username.text
				user.password = password.text
				user["isDriver"] = self.`switch`.isOn

                user.signUpInBackground(block: {(succeeded, error) in
                    //enable interaction events
                    self.activityIndicator.stopAnimating()
                    UIApplication.shared.endIgnoringInteractionEvents()
                    
                    if error != nil {
                        if let errorString = (error as NSError?)?.userInfo["error"] as? String {
                            errorMessage = errorString
                        }
                        self.displayAlert("Failed to sign up", message: errorMessage)
                    } else {
                        self.displayAlert("Sign Up Succcess", message: "You can start using Uber")
                        self.password.text = ""
                        self.toggleButtonAction(nil)
                    }
                })
			}
			else{
				//login with parse
				PFUser.logInWithUsername(inBackground: username.text!, password:password.text!) {
					(user: PFUser?, error: Error?) -> Void in
					//enable interaction events
					self.activityIndicator.stopAnimating()
					UIApplication.shared.endIgnoringInteractionEvents()
					
					if error != nil {//login failed
						if let errorString = (error as NSError?)?.userInfo["error"] as? String {
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
		if let isDriver = PFUser.current()!["isDriver"] {
			if isDriver as! Bool {
				self.performSegue(withIdentifier: "showDriverView", sender: self)
			}
			else {
				self.performSegue(withIdentifier: "showRiderView", sender: self)
			}
		}
	}
	
	@IBAction func toggleButtonAction(_ sender: AnyObject?) {
		isSignUpMode = !isSignUpMode
		if isSignUpMode {
			`switch`.isHidden = false
			riderLabel.isHidden = false
			driverLabel.isHidden = false
			questionLabel.text = "Already registered ?"
			submitButton.setTitle("Sign Up", for: UIControlState())
			toggleButton.setTitle("login", for: UIControlState())
		}
		else {
			`switch`.isHidden = true
			riderLabel.isHidden = true
			driverLabel.isHidden = true
			questionLabel.text = "Not registered yet ?"
			submitButton.setTitle("Login", for: UIControlState())
			toggleButton.setTitle("sign up", for: UIControlState())
		}
	}
	
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func displayAlert(_ title:String, message:String){
		let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
			self.dismiss(animated: true, completion: nil)
		}))
		self.present(alert, animated: true, completion: nil)
	}

	//Remove keyboard when touch ouside the keyboard
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		self.view.endEditing(true)
	}
	
	//Remove keyboard when clic 'return'
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}

	override func viewDidAppear(_ animated: Bool) {
		if let _ = PFUser.current()?.username {
			login()
		}
	}
}

