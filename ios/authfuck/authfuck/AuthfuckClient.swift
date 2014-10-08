//
//  AuthfuckClient.swift
//  authfuck
//
//  Created by Nir Sadeh on 10/7/14.
//  Copyright (c) 2014 Citylifeapps. All rights reserved.
//

import UIKit

class AuthfuckClient: NSObject {
    private let errorDomain = "Authfuck"
    private let route: String
    private let persistence: NSURLCredentialPersistence
    private let protectionSpace: NSURLProtectionSpace
    private let session: NSURLSession!
    
    dynamic var isSignedIn: Bool
    
    init(host: String, port: Int = 80, route: String = "/auth", `protocol`: String = "http", persistence: NSURLCredentialPersistence = .Synchronizable, var session: NSURLSession? = nil) {
        self.route = route
        self.persistence = persistence
        self.protectionSpace = NSURLProtectionSpace(host: host, port: port, `protocol`: `protocol`, realm: "Users", authenticationMethod: NSURLAuthenticationMethodHTTPBasic)
        self.isSignedIn = NSURLCredentialStorage.sharedCredentialStorage().defaultCredentialForProtectionSpace(self.protectionSpace) != nil
        super.init()
        
        if session == nil {
            session = NSURLSession.sharedSession()
        }
        
        self.session = session!
    }
    
    func signIn(user: String, password: String, completion: ((NSError?) -> ())?) {
        self.signOut()
        
        let cred = NSURLCredential(user: user, password: password, persistence: self.persistence)
        NSURLCredentialStorage.sharedCredentialStorage().setDefaultCredential(cred, forProtectionSpace: protectionSpace)

        // sign in to server
        let prot = self.protectionSpace.`protocol` ?? "http"
        let hostport = "\(self.protectionSpace.host):\(self.protectionSpace.port)"
        let route = self.route
        let url = NSURL(string: "\(prot)://\(hostport)\(route)")
        println("\(prot) \(hostport) \(route) \(url)")
        self.session.dataTaskWithURL(url) { (data, response, error) in
            if let err = error {
                self.signOut()
                completion?(err)
                return
            }
            
            let httpResponse = response as NSHTTPURLResponse
            if httpResponse.statusCode != 200 {
                self.signOut()
                let body = NSString(data: data, encoding: NSUTF8StringEncoding)
                completion?(NSError(domain: self.errorDomain, code: 1, userInfo: [ NSLocalizedDescriptionKey: body ]))
                return
            }
            
            self.isSignedIn = true
            completion?(nil)
        }.resume()
    }
    
    func signOut() {
        let storage = NSURLCredentialStorage.sharedCredentialStorage()
        if let credential = storage.defaultCredentialForProtectionSpace(self.protectionSpace) {
            storage.removeCredential(credential, forProtectionSpace: self.protectionSpace, options: [ NSURLCredentialStorageRemoveSynchronizableCredentials: NSNumber(bool: true) ])
        }
        self.isSignedIn = false
    }
}