SwiftImage [中文介绍](Readme_cn.md)
=========
SwiftImage is a framework for downloading and caching image in Swift. It makes it easy to deal with fetching and cachine image data from network.  It provides:

- A ImageView extension to allow UIImageView to download image data from network and cache the data into memory cache and file sytem
- A SwiftImageDownloadManager class to create and manage asynchronous image download tasks
- A SwiftImageDOwnloadOperation class to download image asynchronously
- A SwiftImageCache class to cache image data in memory cache and local file system
- A series of utilit methods to scale, crop and decode image


Installation
------------

### CocoaPods (iOS 8+)
You can use Cocoapods to install SwiftImage adding it to your Podfile:


#### Podfile
```
platform :ios, '8.0'
use_frameworks!
pod 'SwiftImage'
```
In the project, you can import the SwiftImage framework  

```swift
import SwiftImage
```  

### Manually
The source code from [here](https://github.com/jie-cao/SwiftImage). You can manually add the source code into your project.  

Usage
----------

### using ImageView Extension
After import, UIImageView now has a series of functions to download image data from a url.  
A simple example of the usage:   

```swift
let url = NSURL(string: "http://image.com/image.jpg")
var imageView = UIImageView()
imageView.imageWithURL(url!)
```
Use a closure as callback:  

```swift
let url = NSURL(string: "http://image.com/image.jpg")
var imageView = UIImageView()
imageView.imageWithURL(url!) { (image, data, error, finished) -> Void in
	// Your callback goes here
	dispatch_async(dispatch_get_main_queue(), { () -> Void in
		self.imageView.image = image;
		UIView.animateWithDuration(2.0, animations: { () -> Void in
			self.imageView.alpha = 1.0
       })
    })
}
```  
Remember to switch to main queue in the closure for UI updates. 

To cancel the download task for the UIImageView instance. You can call the `cancelImageDownload()` method:

```swift
imageView.cancelImageDownload()
```  

All the functions can be found at `SwiftImageExtension.swift`. They provides the capability to pass closures add the progress handler and completion handler. The parameter `options: SwiftImageDownloadOption?` is used config the downloading and caching behavior. It will be explained in the next section.

```swift
func imageWithURL(url:NSURL)
func imageWithURL(url:NSURL, placeholderImage: UIImage? = nil, completionHandler:CompletionHandler)
func imageWithURL(url:NSURL, placeholderImage:UIImage? = nil, progressHander:ProgressHandler, completionHandler:CompletionHandler)
func imageWithURL(url:NSURL, options:SwiftImagedDownloadOptions?)
func imageWithURL(url:NSURL, options:SwiftImagedDownloadOptions?, placeholderImage:UIImage?)
func imageWithURL(url:NSURL, options:SwiftImagedDownloadOptions?, placeholderImage:UIImage?, progressHandler:ProgressHandler?)
func imageWithURL(url:NSURL, options:SwiftImagedDownloadOptions?, completionHandler:CompletionHandler?)
func imageWithURL(url:NSURL, options:SwiftImagedDownloadOptions?, progressHandler:ProgressHandler?, completionHandler:CompletionHandler?)
func imageWithURL(url:NSURL, options:SwiftImagedDownloadOptions?, placeholderImage:UIImage?, progressHandler:ProgressHandler?, completionHandler:CompletionHandler?)
```

### Use SwiftImagedDownloadOptions object to set options for image downloading and caching
You can create a SwiftImagedDownloadOptions object and pass in the methods mentioned in the previous sections. It is used to specify the settings for image download and cache task.You can specify the following settings:  
  
1.priority  
The priority of the queue that is responsible for the downloading task. You can specify it as DefaultPriority， LowPriority or HighPriority. 
  
2.cachePolicy
The policy for caching. You can specify NoCache，MemoryCache，FileCache or MemoryAndFileCache.    
3.shouldDecode  
The flag to specify whether we should decode the image in the background thread before set it to the UIImageView in the UI thread. UIImageView will decode image on the UI thread if the image is not decoded in the global quue before. This will block the UI thread if there are too many images need to be decode in UI thread. The default option is true.  

4.requestCachePolicy  
The network download part of SwiftImage is implemented based on NSURLSession. The option is equal to the requestCachePolicy in the NSURLSessionConfiguration class. You can specify different cache policy to save the network bandwith and improve your app performance. 

### Usage in UITableViewCell
A simple example: 

```swift
func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		 // get the data ojbect for the indexPath
        let data = self.dataSource[indexPath.row] as! [String :String]        
        let cell = self.tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath) as! ImageTableViewCell
        cell.contentLabel?.text = data["text"]
        let placeholderImage = UIImage(named: "placeholder.jpg")
        // get image URL
        if let imageUrl = NSURL(string: data["url"]!){
            cell.photoView?.imageWithURL(imageUrl, options: nil, placeholderImage: placeholderImage)
            cell.photoView?.contentMode = .ScaleAspectFit
        }
        return cell
    }
    
```
Similar patterns can be applied to a UICollectionViewCell subclass that has UIImageView as a subview.  

### Use Closure
SwiftImage provides the following two types of closures:

```swift
public typealias ProgressHandler = ((receivedSize:Int64, expectedSize:Int64)->Void)
public typealias CompletionHandler = ((image:UIImage?, data:NSData?, error:NSError?, finished:Bool)->Void)
```
A ProgressHandler closure can be passed as callback to track the progress of the image download task.   
A CompletionHandler closue can be passed can be passed as the callback when the download operation complets.  

```swift
func imageWithURL(url:NSURL, options:SwiftImagedDownloadOptions?, placeholderImage:UIImage?, progressHandler:ProgressHandler?)
func imageWithURL(url:NSURL, options:SwiftImagedDownloadOptions?, completionHandler:CompletionHandler?)
func imageWithURL(url:NSURL, options:SwiftImagedDownloadOptions?, progressHandler:ProgressHandler?, completionHandler:CompletionHandler?)
func imageWithURL(url:NSURL, options:SwiftImagedDownloadOptions?, placeholderImage:UIImage?, progressHandler:ProgressHandler?, completionHandler:CompletionHandler?)
```

### Use SwiftImageDownloadManager
You can use a SwiftImageDownloadManager singleton instance to manage the image download operations. You can use it to create a image download operation. You can cancel a specific image download opation or cancel all the operations.  
To create an image download task:  
```swift
if let operation = SwiftImageDownloadManager.sharedInstance.retrieveImageFromUrl(url, options: options, completionHandler:{(image:UIImage?, data:NSData?, error:NSError?,finished:Bool) -> in
	// your completion handler
},
progressHandler: {(receivedSize:Int64, expectedSize:Int64) in
	// your progress handler
}) {
	// save the operation for future management
}
```

The function returns a `SwiftImageDownloadOperation` object. You can pass this object to `SwiftImageDownloadManager` singleton instance to cancel the download operation.  
To cancel an image download task:  

```swift
SwiftImageDownloadManager.sharedInstance.cancelOperation(operation)

```
To cancel all the existing image download tasks:  

```swift
SwiftImageDownloadManager.sharedInstance.cancelAll()
```

### Usre SwiftImageDownloadOperation to create an image download task
To create a image download task by creating a SwiftImageDownloadOperation instance:  

```swift
let operation = SwiftImageDownloadManager.sharedInstance.retrieveImageFromUrl(url, options: options, completionHandler: { [unowned self](image:UIImage?, data:NSData?, error:NSError?, finished:Bool) -> Void in
	// your closure goes here
	dispatch_async(dispatch_get_main_queue(), {()->Void in
		self.imageView.image = image
    })
}
```


After the instance is created, it will start the download immediately. You can call the `start()` method to start the download task.

To cancel the image download task for this SwiftImageDownloadOperation instance:  

```swift
operation.cancel()
```

### Use SwiftImageCache
SwiftImage implemented a SwiftImageCache singletong to cache image data asynchronously. It provides functions to store/fetch image data from memory cache or local file system.  

```swift
func storeImage(image:UIImage, key:String, imageData:NSData? = nil, cachePolicy:SwiftImageCachePolicy, completionHandler:(()-> Void)?)-> Void
func retrieveImageForKey(key: String, options: SwiftImageDownloadOptions, completionHandler: ((UIImage?, CacheType!) -> Void)?) -> Void    
func retrieveImageFromMemoryCache(key: String) -> UIImage?
func loadImageDataFromFile(key: String) -> NSData?    

```
The store and fetch operations are asynchronous. You can pass the closure as the completionHandler parameter as the callback when the tasks are completed.

The ```cachePolicy:SwiftImageCachePolicy``` paremeter is used to specify the cache policy. You can choose to cache the image data on memory cache, local file system or both. 

### Use SwiftImage utility functions
SwiftImage provides a series of functions for processing image data. The feature those functions provide are commonly asked. They include:

1. Scale Image

```swift
    class func resizeImage(image:UIImage, size:CGSize) -> UIImage   
```

2. Get the Image width or height according to the scaled height/width  

```swift
    class func scaleImage(image: UIImage, height: CGFloat) -> CGSize
    class func scaleImage(image: UIImage, width: CGFloat) -> CGSize
```  
3. Crop image to a round image

```swift
    class func roundImage(image:UIImage, radius:CGFloat) -> UIImage
```  
4.  Rotate a image 

```swift
    class func rotatedByDegrees(img: UIImage, degrees: CGFloat) -> UIImage
```  
5. Decode image at background thread

```swift
    class func decodImage(image:UIImage) -> UIImage?
    class func decodImage(image:UIImage, scale: CGFloat) -> UIImage? 
```  
These methods are class functions. They can be invoked from `SwiftImageUtils` class directly.
## Licenses

All source code is licensed under the [MIT License](https://raw.github.com/rs/SDWebImage/master/LICENSE).