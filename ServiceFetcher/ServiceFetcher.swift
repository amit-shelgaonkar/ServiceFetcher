//
//  ServiceFetcher.swift
//
//
//  Created by Amit on 26/11/16.
//  Copyright © 2016 Amit. All rights reserved.
//

import UIKit

typealias CompletionHandlerBlock = (_ responceObject:AnyObject,_ status:Bool) -> Void
typealias CancelBlock = () -> Void

var  completionHandler:CompletionHandlerBlock?
var CancelHandler:CancelBlock?

class ServiceFetcher: NSObject,NSURLSessionDelegate {
    
    var receivedData:NSMutableData = NSMutableData()
    var reachability: Reachability?
    
    func apiCallWithRequest(requestInfo:AnyObject?,forservice servicePath:String,httpType:String,onCompletion fetchBlock:CompletionHandlerBlock, onCancelation cancel:CancelBlock) {
        
        completionHandler = fetchBlock
        CancelHandler = cancel
        
        let configuration:NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session:NSURLSession = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        let url: NSURL = NSURL(string: servicePath)!
        let urlRequest: NSMutableURLRequest = NSMutableURLRequest()
        urlRequest.URL = url
        urlRequest.HTTPMethod = httpType

        urlRequest.timeoutInterval = 60.0
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("en", forHTTPHeaderField: "Accept-Language")
       // urlRequest.setValue("Basic Ymx1ZGVudGU6Ymx1ZGVudGUxMjM=", forHTTPHeaderField: "Authorization")

        urlRequest.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
       // urlRequest.setValue("authToken", forHTTPHeaderField: "authToken")
        urlRequest.setValue("iOS", forHTTPHeaderField: "os")
       
        if urlRequest.HTTPMethod == "POST" || urlRequest.HTTPMethod == "PUT"{
            if let requestInfo = requestInfo {
                var requestData: NSData!
                do {
                    requestData = try NSJSONSerialization.dataWithJSONObject(requestInfo, options: NSJSONWritingOptions.PrettyPrinted) as NSData!
                    let requestDataAsJSON = NSString(data: requestData!,
                                                     encoding: NSASCIIStringEncoding)
                    print("Request Body : \(requestDataAsJSON)")
                    urlRequest.HTTPBody = requestData
                } catch {
                    print("Request Body Fetch failed: \((error as NSError).localizedDescription)")
                }
            } else {
                print("Request Body Nil")
            }
        }
        
        do {
            reachability = try Reachability.reachabilityForInternetConnection()
        } catch {
            print("Unable to create Reachability")
        }
        
        if reachability!.isReachable() {
            let dataTask:NSURLSessionDataTask  = session.dataTaskWithRequest(urlRequest)
            dataTask.resume()
        } else  {
            CancelHandler!()
        }
    }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        receivedData.length = 0
        completionHandler(.Allow)
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
       
        if (error != nil) {
            let errorMessageInfo = ["error :\(error?.localizedDescription)"]
            completionHandler!(responceObject: errorMessageInfo,status: false)
        } else {
            let responce = try? NSJSONSerialization.JSONObjectWithData(receivedData, options: NSJSONReadingOptions.MutableContainers)
            print("responce:\(responce)")
            if responce != nil {
                completionHandler!(responceObject: responce!,status: true)
            } else {
                let errorMessageInfo = [kServiceResponseObjectError:"Something went wrong. Please try again."]
            completionHandler!(responceObject: errorMessageInfo,status: true)

            }
        }
    }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        receivedData.appendData(data)
        print("data:\(data)")
    }
    
    
}
