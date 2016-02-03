//
//  SwiftImageCache.swift
//  CJImageUtilsDemo
//
//  Created by Jie Cao on 6/12/15.
//  Copyright (c) 2015 JieCao. All rights reserved.
//

import UIKit
import CoreGraphics

public enum CacheType {
    case None, Memory, File
}

public class SwiftImageCache: NSObject {
    private static let ioQueueName = "com.jiecao.SwiftImage.ImageCache.ioQueue"
    private static let processQueueName = "com.jiecao.SwiftImage.ImageCache.processQueue"
    private static let cacheName = "com.jiecao.SwiftImage.ImageCache.CachePath"
    static let sharedInstance = SwiftImageCache()
    
    var maxCacheAge:NSTimeInterval = 60 * 60 * 24 * 7
    /// The largest disk size can be taken for the cache. It is the total allocated size of cached files in bytes. Default is 0, which means no limit.
    var maxDiskCacheSize: UInt = 0
    var memoryCache : NSCache = NSCache()
    var fileManager : NSFileManager = NSFileManager()
    var filesFolder : NSURL!
    private let ioQueue: dispatch_queue_t = dispatch_queue_create(ioQueueName, DISPATCH_QUEUE_SERIAL)
    private let processQueue: dispatch_queue_t = dispatch_queue_create(processQueueName, DISPATCH_QUEUE_CONCURRENT)
    
    override init(){
        super.init()
        let paths = NSSearchPathForDirectoriesInDomains(.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        filesFolder = NSURL(fileURLWithPath:paths.first!).URLByAppendingPathComponent(SwiftImageCache.cacheName)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("clearMemoryCache"), name: UIApplicationDidReceiveMemoryWarningNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("backgroundCleanExpiredDiskCache"), name: UIApplicationWillTerminateNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("backgroundCleanExpiredDiskCache"), name: UIApplicationDidEnterBackgroundNotification, object: nil)
    }
    
    deinit{
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    public func clearMemoryCache(){
        memoryCache.removeAllObjects()
    }
    
    public func clearDiskCache(){
        dispatch_barrier_async(ioQueue, { () -> Void in
            do {
                try self.fileManager.removeItemAtPath(self.filesFolder.path!)
            } catch _ {
            }
            do {
                try self.fileManager.createDirectoryAtPath(self.filesFolder.path!, withIntermediateDirectories: true, attributes: nil)
            } catch _ {
            }
        })
    }
    
    func backgroundCleanExpiredDiskCache() {
        
        
        var backgroundTask: UIBackgroundTaskIdentifier!
        
        backgroundTask = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler { () -> Void in
            UIApplication.sharedApplication().endBackgroundTask(backgroundTask)
            backgroundTask = UIBackgroundTaskInvalid
        }
        
        self.cleanExpiredDiskCacheWithCompletionHander { () -> () in
            UIApplication.sharedApplication().endBackgroundTask(backgroundTask)
            backgroundTask = UIBackgroundTaskInvalid
        }
    }
    
    func cleanExpiredDiskCacheWithCompletionHander(completionHandler: (()->())?) {
        // Do things in cocurrent io queue
        dispatch_barrier_async(ioQueue, { () -> Void in
            let diskCacheURL = NSURL(fileURLWithPath: self.filesFolder.path!)
            
            let resourceKeys = [NSURLIsDirectoryKey, NSURLContentModificationDateKey, NSURLTotalFileAllocatedSizeKey]
            let expiredDate = NSDate(timeIntervalSinceNow: -self.maxCacheAge)
            var cachedFiles = [NSURL: [NSObject: AnyObject]]()
            var URLsToDelete = [NSURL]()
            
            var diskCacheSize: UInt = 0
            
            if let fileEnumerator = self.fileManager.enumeratorAtURL(diskCacheURL,
                includingPropertiesForKeys: resourceKeys,
                options: NSDirectoryEnumerationOptions.SkipsHiddenFiles,
                errorHandler: nil) {
                    
                    for fileURL in fileEnumerator.allObjects as! [NSURL] {
                        
                        do {
                            let resourceValues = try fileURL.resourceValuesForKeys(resourceKeys)
                            // If it is a Directory. Continue to next file URL.
                            if let isDirectory = resourceValues[NSURLIsDirectoryKey] as? NSNumber {
                                if isDirectory.boolValue {
                                    continue
                                }
                            }
                            
                            // If this file is expired, add it to URLsToDelete
                            if let modificationDate = resourceValues[NSURLContentModificationDateKey] as? NSDate {
                                if modificationDate.laterDate(expiredDate) == expiredDate {
                                    URLsToDelete.append(fileURL)
                                    continue
                                }
                            }
                            
                            if let fileSize = resourceValues[NSURLTotalFileAllocatedSizeKey] as? NSNumber {
                                diskCacheSize += fileSize.unsignedLongValue
                                cachedFiles[fileURL] = resourceValues
                            }
                        } catch _ {
                        }
                        
                    }
            }
            
            for fileURL in URLsToDelete {
                do {
                    try self.fileManager.removeItemAtURL(fileURL)
                } catch _ {
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if let completionHandler = completionHandler {
                    completionHandler()
                }
            })
        })
    }
    
    public func storeImage(image:UIImage, key:String, imageData:NSData? = nil, cachePolicy:SwiftImageCachePolicy, completionHandler:(()-> Void)?){
        if (cachePolicy.rawValue | SwiftImageCachePolicy.MemoryCache.rawValue) != 0 {
            self.memoryCache.setObject(image, forKey: key)
        }
        
        if (cachePolicy.rawValue | SwiftImageCachePolicy.FileCache.rawValue) != 0 {
            dispatch_async(ioQueue, {()-> Void in
                var data:NSData?
                let imageType = SwiftImageUtils.getImageTypeFromData(imageData)
                switch (imageType){
                case .JPG:
                    data = UIImageJPEGRepresentation(image, 1.0)
                case .PNG:
                    data = UIImagePNGRepresentation(image)
                default:
                    data = imageData
                }
                
                if data != nil {
                    if !self.fileManager.fileExistsAtPath(self.filesFolder!.path!){
                        do {
                            try self.fileManager.createDirectoryAtURL(self.filesFolder, withIntermediateDirectories: true, attributes: nil)
                        } catch _ {
                            print("Cannot create file at file URL: \(self.fileManager)")
                        }
                    }
                    self.fileManager.createFileAtPath(self.cachePathForKey(key), contents: data!, attributes: nil)
                    
                }
            })
            
        }
        
        if let handler = completionHandler {
            handler()
        }
    }
    
    public func retrieveImageForKey(key: String, options:SwiftImageDownloadOptions, completionHandler: ((UIImage?, CacheType!) -> Void)?) {
        
        if let image = self.retrieveImageFromMemoryCache(key) {
            
            //Found image in memory cache.
            if options.shouldDecode {
                dispatch_async(self.processQueue, { () -> Void in
                    let result = SwiftImageUtils.decodImage(image, scale: options.scale)
                    if let handler = completionHandler {
                        handler(result, .Memory)
                    }
                })
            } else {
                
                if let handler = completionHandler {
                    handler(image, .Memory)
                }
            }
        } else {
            
            dispatch_async(ioQueue, { () -> Void in
                
                if let image = self.retrieveImageForFile(key, scale: options.scale) {
                    
                    if options.shouldDecode {
                        dispatch_async(self.processQueue, { () -> Void in
                            let result = SwiftImageUtils.decodImage(image, scale: options.scale)
                            self.storeImage(result!, key: key, cachePolicy: options.cachePolicy, completionHandler: nil)
                            
                            if let handler = completionHandler {
                                handler(result, .File)
                                
                            }
                        })
                    } else {
                        self.storeImage(image, key: key, cachePolicy: options.cachePolicy, completionHandler: nil)
                        if let handler = completionHandler {
                            handler(image, .File)
                        }
                    }
                    
                } else {
                    
                    if let handler = completionHandler {
                        handler(nil, nil)
                    }
                }
            })
        }
    }
    
    public func retrieveImageFromMemoryCache(key: String) -> UIImage? {
        return memoryCache.objectForKey(key) as? UIImage
    }
    
    public func retrieveImageForFile(key: String, scale: CGFloat = 1.0) -> UIImage? {
        var  imageFromData:UIImage? = nil
        if let data = loadImageDataFromFile(key){
            let imageType = SwiftImageUtils.getImageTypeFromData(data)

            if imageType == .GIF {
                imageFromData = SwiftImageUtils.getAnimatedImageFromData(data)
                
            } else if imageType == .JPG || imageType == .PNG {
                imageFromData = UIImage(data: data, scale: scale)
            }
        }
        return imageFromData
    }
    
    public func loadImageDataFromFile(key: String) -> NSData? {
        let filePath = cachePathForKey(key)
        return NSData(contentsOfFile: filePath)
    }
    
    public func cachePathForKey(key: String) -> String {
        let fileName = cacheFileNameForKey(key)
        return self.filesFolder!.URLByAppendingPathComponent(fileName).path!
    }
    
    public func cacheFileNameForKey(key: String) -> String {
        return key.toMD5()
    }
}
