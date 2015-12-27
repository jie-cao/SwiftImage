//
//  SwiftImageDownloadOperation.swift
//  CJImageUtilsDemo
//
//  Created by Jie Cao on 6/13/15.
//  Copyright (c) 2015 JieCao. All rights reserved.
//

import UIKit

public enum ImageDownloadOperationErrorCode: Int {
    case BadData = 10000
    case NotModified = 10001
    case InvalidURL = 20000
}

public typealias ProgressHandler = ((receivedSize:Int64, expectedSize:Int64)->Void)
public typealias CompletionHandler = ((image:UIImage?, data:NSData?, error:NSError?, finished:Bool)->Void)

public class SwiftImageDownloadOperation: NSObject, NSURLSessionTaskDelegate{
    
    private static let ioQueueName = "com.jiecao.SwiftImage.ImageDownloadOption.ioQueue"
    let ImageDownloadOperationErrorDomain = "com.jiecao.SwiftImageDownloadOperation.Error"
    
    var responseData:NSMutableData = NSMutableData()
    var isCancelled:Bool = false
    var sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
    var session:NSURLSession?
    var sessionDataTask:NSURLSessionDataTask?
    var progressHandlers = [ProgressHandler]()
    var completionHandlers = [CompletionHandler]()
    var shouldDecode:Bool = false
    var url:NSURL?
    var key:String?
    var options:SwiftImageDownloadOptions!
    
    private let ioQueue: dispatch_queue_t = dispatch_queue_create(ioQueueName, DISPATCH_QUEUE_SERIAL)
    
    public init(url:NSURL, options:SwiftImageDownloadOptions, progressHandler:((receivedSize:Int64, expectedSize:Int64)->Void)?, completionHandler:((image:UIImage?, data:NSData?, error:NSError?, finished:Bool)->Void)?)
    {
        self.url = url
        self.key = SwiftImageDownloadManager.defaultKeyConverter(url)
        
        if (progressHandler != nil){
            self.progressHandlers.append(progressHandler!)
        }
        if (completionHandler != nil){
            self.completionHandlers.append(completionHandler!)
        }
        
        self.options = options
        
        self.shouldDecode = self.options.shouldDecode
    }
    
    public func addProgressHandler(progressHandler:ProgressHandler){
        dispatch_barrier_async(self.ioQueue, { () -> Void in
            self.progressHandlers.append(progressHandler)
        })
    }
    
    public func addCompletionHandler(completionHandler:CompletionHandler){
        dispatch_barrier_async(self.ioQueue, { () -> Void in
            self.completionHandlers.append(completionHandler)
        })
    }
    
    public func start() {
        if let url = self.url,
            let key =  self.key{
                SwiftImageCache.sharedInstance.retrieveImageForKey(key, options:options, completionHandler:{(image:UIImage?, cacheType:CacheType!) -> Void in
                    if image == nil && self.isCancelled == false{
                        self.sessionConfiguration.requestCachePolicy = self.options.requestCachePolicy
                        self.session = NSURLSession(configuration: self.sessionConfiguration, delegate: self, delegateQueue: nil)
                        self.sessionDataTask = self.session?.dataTaskWithURL(url)
                        if let sessionTask = self.sessionDataTask {
                            sessionTask.resume()
                        }
                        
                    } else {
                        if self.isCancelled == false{
                            dispatch_async(self.ioQueue, { () -> Void in
                                for completionHandler in self.completionHandlers {
                                    completionHandler(image:image, data:self.responseData, error:nil, finished:true)
                                }
                                self.progressHandlers.removeAll()
                                self.completionHandlers.removeAll()
                                SwiftImageDownloadManager.sharedInstance.removeOperation(self)
                            })
                        }
                    }
                })
        }
    }
    
    public func cancel() {
        isCancelled = false
    }
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        
        completionHandler(NSURLSessionResponseDisposition.Allow)
    }
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        
            responseData.appendData(data)
            
            dispatch_async(self.ioQueue, { [unowned self]() -> Void in
                for progressHandler in self.progressHandlers {
                    progressHandler(receivedSize: Int64(self.responseData.length), expectedSize: dataTask.response!.expectedContentLength)
                }
            })
    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if self.isCancelled == false {
            if let error = error {
                dispatch_async(self.ioQueue, { [unowned self]() -> Void in
                    for completionHandler in self.completionHandlers {
                        completionHandler(image:nil, data:nil, error:error, finished:true)
                    }
                    self.clearOperation()
                    })
            } else {
                let key = self.key
                let imageType = SwiftImageUtils.getImageTypeFromData(self.responseData)
                var  imageFromData:UIImage? = nil
                if imageType == .GIF {
                    imageFromData = SwiftImageUtils.getAnimatedImageFromData(self.responseData)
                    
                } else if imageType == .JPG || imageType == .PNG {
                    imageFromData = UIImage(data: self.responseData)
                }
                
                if let image = imageFromData {
                    SwiftImageCache.sharedInstance.storeImage(image, key: key!, imageData: self.responseData, cachePolicy:self.options.cachePolicy, completionHandler: { [unowned self]()-> Void in
                        let imageResult = self.shouldDecode ? SwiftImageUtils.decodImage(image, scale: self.options.scale) :image
                        dispatch_async(self.ioQueue, { [unowned self]() -> Void in
                            for completionHandler in self.completionHandlers {
                                completionHandler(image:imageResult, data:self.responseData, error:nil, finished:true)
                            }
                            self.clearOperation()
                            })
                        })
                    
                } else {
                    // If server response is 304 (Not Modified), inform the callback handler with NotModified error.
                    // It should be handled to get an image from cache, which is response of a manager object.
                    var errorCode = ImageDownloadOperationErrorCode.BadData.rawValue;
                    
                    if let res = task.response as? NSHTTPURLResponse where res.statusCode == 304 {
                        errorCode = ImageDownloadOperationErrorCode.NotModified.rawValue;
                    }
                    
                    dispatch_async(self.ioQueue, { [unowned self]() -> Void in
                        let error =  NSError(domain: self.ImageDownloadOperationErrorDomain, code: errorCode, userInfo: nil)
                        for completionHandler in self.completionHandlers {
                            completionHandler(image: nil, data: nil, error: error, finished:true)
                        }
                        self.clearOperation()
                        })
                }
            }
        }
    }
    
    private func clearOperation() {
        self.progressHandlers.removeAll()
        self.completionHandlers.removeAll()
        self.session?.finishTasksAndInvalidate()
        SwiftImageDownloadManager.sharedInstance.removeOperation(self)
    }

}
