//
//  ViewController.swift
//  authfuck
//
//  Created by Elad Ben-Israel on 10/7/14.
//  Copyright (c) 2014 Citylifeapps. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    var authClient = AuthfuckClient(host: "localhost", port: 5000)

    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        authClient.addObserver(self, forKeyPath: "isSignedIn", options: .Initial, context: nil)
    }
    
    deinit {
        authClient.removeObserver(self, forKeyPath: "isSignedIn")
    }
    
    override func observeValueForKeyPath(keyPath: String!, ofObject object: AnyObject!, change: [NSObject : AnyObject]!, context: UnsafeMutablePointer<Void>) {
        if keyPath == "isSignedIn" {
            dispatch_async(dispatch_get_main_queue()) {
                self.loginButton.enabled = !self.authClient.isSignedIn
                self.logoutButton.enabled = !self.loginButton.enabled
            }
        }
    }

    @IBAction func login() {
        let passwordInput = UIAlertController(title: "Login", message: "Password", preferredStyle: .Alert)
        passwordInput.addTextFieldWithConfigurationHandler { passwordTextField in
            passwordTextField.text = "12345"
        }
        passwordInput.addAction(UIAlertAction(title: "OK", style: .Default, handler: { _ in
            let passwordTextField = passwordInput.textFields?[0] as UITextField
            println("login with password \(passwordTextField.text)")
            self.authClient.signIn("eladb", password: passwordTextField.text) { error in
                if error != nil {
                    let alert = UIAlertController(title: error?.localizedDescription, message: nil, preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: "Dismiss", style: .Cancel, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            }
        }))
        passwordInput.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        self.presentViewController(passwordInput, animated: true, completion: nil)
    }
    
    @IBAction func logout() {
        self.authClient.signOut()
    }
    
    @IBAction func foo() {
        NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "http://localhost:5000/foo")) { (data, response, error) in
            if let err = error {
                println("error: \(err)")
                return
            }
            
            let body = NSString(data: data, encoding: NSUTF8StringEncoding)
            println("body: \(body)")
        }.resume()
    }
}

