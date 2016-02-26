//
//  SwiftImageViewExtension.swift
//  CJImageUtilsDemo
//
//  Created by Jie Cao on 6/14/15.
//  Copyright (c) 2015 JieCao. All rights reserved.
//

import Foundation
import UIKit
import ObjectiveC

// MARK: - Associated Key
private var lastURLKey: Void?

public extension UIImageView{
    
    /// Get the image URL binded to this image view.
    private func getFetchOperation()-> SwiftImageDownloadOperation?{
        return objc_getAssociatedObject(self, &lastURLKey) as? SwiftImageDownloadOperation
    }
    
    private func setFetchOperation(key: SwiftImageDownloadOperation) {
        objc_setAssociatedObject(self, &lastURLKey, key, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    private func removeFetchOperation(){
        return objc_removeAssociatedObjects(self)
    }
    
    public func imageWithURL(url:NSURL,
        options:SwiftImageDownloadOptions? = nil,
        placeholderImage:UIImage? = nil,
        progressHandler:ProgressHandler? = nil,
        transformHandler:TransformHandler? = nil,
        completionHandler:CompletionHandler? = nil)
    {
        // The operation is added to the UIImageView instance as an associated object. So the object will retain the operation object.
        // The closure in the operation queue will also retain self. This cause the strong reference cycle. Use capture list to resolve the strong reference cycle.
        if let operation = SwiftImageDownloadManager.sharedInstance.retrieveImageFromUrl(url, options: options,
            completionHandler: { [unowned self](image:UIImage?, data:NSData?, error:NSError?, finished:Bool) -> Void in
                if let handler = completionHandler{
                    handler(image: image, data: data, error: error, finished: finished)
                } else {
                    dispatch_async(dispatch_get_main_queue(), {()->Void in
                        self.image = image
                    })
                }
            },
            progressHandler: {(receivedSize:Int64, expectedSize:Int64) in
                if let handler = progressHandler {
                    handler(receivedSize: receivedSize, expectedSize: expectedSize)
                }
            },
            transformHandler: transformHandler
            )
        {
            self.setFetchOperation(operation)
        }
    }
    
    
    public func cancelImageDownload(){
        if let operation = self.getFetchOperation(){
            operation.cancel()
        }
    }
    
}
