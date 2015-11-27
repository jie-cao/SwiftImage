//
//  SwiftImageDownloadManager.swift
//  CJImageUtilsDemo
//
//  Created by Jie Cao on 6/13/15.
//  Copyright (c) 2015 JieCao. All rights reserved.
//

import UIKit

public class SwiftImageDownloadManager: NSObject {
    
    static let sharedInstance = SwiftImageDownloadManager()
    
    var imageDownloadOperationQueue = [String:SwiftImageDownloadOperation]()
    private static let ioQueueName = "com.jiecao.SwiftImage.DownloadManager.ioQueue"
    private let ioQueue: dispatch_queue_t = dispatch_queue_create(ioQueueName, DISPATCH_QUEUE_CONCURRENT)
    
    public class func defaultKeyConverter(urlString:NSURL)->String?{
        return urlString.absoluteString
    }
    
    public func cancelAll(){
        dispatch_barrier_async(self.ioQueue, { () -> Void in
            for (_, downloadOperation) in self.imageDownloadOperationQueue {
                downloadOperation.cancel()
            }
            self.imageDownloadOperationQueue.removeAll(keepCapacity: false)
        })
    }
    
    public func cancel(operation:SwiftImageDownloadOperation){
        operation.cancel();
        self.removeOperation(operation)
    }
    
    public func fetchOperationForKey(key: String) -> SwiftImageDownloadOperation? {
        var downloadOperation: SwiftImageDownloadOperation?
        dispatch_sync(self.ioQueue, { () -> Void in
            downloadOperation = self.imageDownloadOperationQueue[key]
        })
        return downloadOperation
    }
    
    public func removeOperation(operation:SwiftImageDownloadOperation){
        dispatch_async(self.ioQueue) { () -> Void in
            self.imageDownloadOperationQueue.removeValueForKey(operation.key!)
        }
    }
    
    public func addOperationForKey(key: String, operation:SwiftImageDownloadOperation) {
        dispatch_barrier_async(self.ioQueue, { () -> Void in
            self.imageDownloadOperationQueue[key] = operation
        })
    }
    
    public func retrieveImageFromUrl(url:NSURL, options:SwiftImageDownloadOptions? = nil, completionHandler:((image:UIImage?, data:NSData?, error:NSError?, finished:Bool)->Void)?, progressHandler:((receivedSize:Int64, expectedSize:Int64)->Void)?) -> SwiftImageDownloadOperation? {
        
        if  let operationKey = SwiftImageDownloadManager.defaultKeyConverter(url),
            let imageDownloadOperation = self.fetchOperationForKey(operationKey){
            if progressHandler != nil {
                imageDownloadOperation.addProgressHandler(progressHandler!)
            }
            if completionHandler != nil {
                imageDownloadOperation.addCompletionHandler(completionHandler!)
            }
            return imageDownloadOperation;
        } else {
            
            let fetchOptios = options != nil ? options! : SwiftImageDownloadOptions()
            
            let imageFetchOperation = SwiftImageDownloadOperation(url: url, options: fetchOptios, progressHandler: progressHandler, completionHandler: completionHandler)
            
            self.addOperationForKey(imageFetchOperation.key!, operation: imageFetchOperation)
            
            var downloadPriority:Int = DISPATCH_QUEUE_PRIORITY_DEFAULT
            if fetchOptios.priority == .HighPriority {
                downloadPriority = DISPATCH_QUEUE_PRIORITY_HIGH
            } else if fetchOptios.priority == .LowPriority {
                downloadPriority = DISPATCH_QUEUE_PRIORITY_LOW
            }
            
            
            dispatch_async(dispatch_get_global_queue(downloadPriority, 0), { () -> Void in
                imageFetchOperation.start()
            })
            
            return imageFetchOperation;
        }
    }
}
