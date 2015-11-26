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
    
    public func imageWithURL(url:NSURL){
        let options = SwiftImageDownloadOptions()
        self.imageWithURL(url, options: options, placeholderImage: nil, progressHandler: nil)
    }
    
    public func imageWithURL(url:NSURL, options: SwiftImageDownloadOptions?){
        self.imageWithURL(url, options: options, placeholderImage: nil, progressHandler: nil)
    }
    
    public func imageWithURL(url:NSURL, options: SwiftImageDownloadOptions?, placeholderImage:UIImage?){
        self.imageWithURL(url, options: options, placeholderImage: placeholderImage, progressHandler: nil)
    }
    
    public func imageWithURL(url:NSURL, options: SwiftImageDownloadOptions?, placeholderImage:UIImage?, progressHandler:ProgressHandler?){
        self.imageWithURL(url, options: options, placeholderImage: placeholderImage, progressHandler: progressHandler, completionHandler: nil)
    }
    
    public func imageWithURL(url:NSURL, options:SwiftImageDownloadOptions?, completionHandler:CompletionHandler?)
    {
        self.imageWithURL(url, options: options, placeholderImage: nil, progressHandler: nil, completionHandler: completionHandler)
    }
    
    public func imageWithURL(url:NSURL, options:SwiftImageDownloadOptions?, progressHandler:ProgressHandler?, completionHandler:CompletionHandler?)
    {
        self.imageWithURL(url, options: options, placeholderImage: nil, progressHandler: progressHandler, completionHandler: completionHandler)
    }
    
    public func imageWithURL(url:NSURL,
        options:SwiftImageDownloadOptions?,
        placeholderImage:UIImage?,
        progressHandler:ProgressHandler?,
        completionHandler:CompletionHandler?)
    {
        if let operation = SwiftImageDownloadManager.sharedInstance.retrieveImageFromUrl(url, options: options, completionHandler: { (image:UIImage?, data:NSData?, error:NSError?, finished:Bool) -> Void in
            dispatch_async(dispatch_get_main_queue(), {()->Void in
                self.image = image
            })
            if let handler = completionHandler{
                handler(image: image, data: data, error: error, finished: finished)
            }
            },
            progressHandler: {(receivedSize:Int64, expectedSize:Int64) in
                if let handler = progressHandler {
                    handler(receivedSize: receivedSize, expectedSize: expectedSize)
                }
        }) {
            self.setFetchOperation(operation)
        }
    }
    
    
    public func cancelImageFetch(){
        if let operation = self.getFetchOperation(){
            SwiftImageDownloadManager.sharedInstance.cancel(operation);
        }
    }
    
}
