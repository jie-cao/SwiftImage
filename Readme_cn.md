SwiftImage
=========
SwiftImage是一个轻量级的从网络下载图像并进行缓存的库。整个库是基于Swift实现的并且受到了SDWebImage的很多启发。SwiftImage提供了对swift的原生的支持，不需要额外的配置来运行基于Objective-C的库。整个库包含了从网络获取图像并进行缓存的一系列功能和接口。具体包括：

- 一个UIImageView的extension来提供UIImageView从网络异步下载图像并缓存的接口
- SwiftImageDownloadManager来创建和管理图像异步下载的任务
- SwiftImageDownloadOpertion提供图像异步网络下载任务的接口
- SwiftImageCache提供缓存图片在内存和文件存储的接口
- 一系列图像处理的工具集来图像进行缩放，剪切和在Background thread解压图像

安装
------------

### 用CocoaPods安装

可以通过CocoaPods来安装SwiftImage

#### Podfile
```
platform :ios, '8.0'
use_frameworks!
pod 'SwiftImage'
```
然后在使用时，直接Import Framework就可以了  

```swift
import SwiftImage
```  

### 直接嵌入源代码
SwiftImage是一个开源库，可以从[这里](https://github.com/jie-cao/SwiftImage)直接找到源代码并加入项目

如何使用
----------

### 使用ImageView Extension
导入的SwiftImage库后，UIImageView提供了多个从NSURL异步下载图像并缓存的接口。一个简单的例子：

```swift
let url = NSURL(string: "http://image.com/image.jpg")
var imageView = UIImageView()
imageView.imageWithURL(url!)
```

所有的接口可以在`SwiftImageViewExtension.swift`文件中找到。

```swift
func imageWithURL(url:NSURL)
func imageWithURL(url:NSURL, options:SwiftImagedDownloadOptions?)
func imageWithURL(url:NSURL, options:SwiftImagedDownloadOptions?, placeholderImage:UIImage?)
func imageWithURL(url:NSURL, options:SwiftImagedDownloadOptions?, placeholderImage:UIImage?, progressHandler:ProgressHandler?)
func imageWithURL(url:NSURL, options:SwiftImagedDownloadOptions?, completionHandler:CompletionHandler?)
func imageWithURL(url:NSURL, options:SwiftImagedDownloadOptions?, progressHandler:ProgressHandler?, completionHandler:CompletionHandler?)
func imageWithURL(url:NSURL, options:SwiftImagedDownloadOptions?, placeholderImage:UIImage?, progressHandler:ProgressHandler?, completionHandler:CompletionHandler?)
```

### 通过SwiftImagedDownloadOptions来设置下载和缓存选项
在下载图像的时候，可以通过创建一个SwiftImagedDownloadOptions来对下载和缓存的各环节进行设置。可以设置的选项包括:  
1.priority  
负责图像下载队列的优先级。 可以设置为DefaultPriority， LowPriority和HighPriority。  
2.cachePolicy  
设置图像存储的策略。可以设置为NoCache，MemoryCache，FileCache和MemoryAndFileCache。对应不缓存，只在内存缓存和在内存和文件系统同时缓存。  
3.shouldDecode  
图像是否需要解压缩。在图像从网络下载后，UIImageView需要对图像进行解压缩才能显示。这个过程一般是隐式的。并且会发生在UI主线程。可以通过开启这个选项来是图像在后台队列解压从而不阻塞UI主线程。  
4.requestCachePolicy  
SwiftImage的图像下载是基于NSURLSession来实现的。这个选项对应的NSURLSessionConfiguration的requestCachePolicy选项。可以通过设置这个选项来设置下载时候session的缓存策略。


### UITableView使用的例子
UITableViewCell里面的ImageView可以直接用`SwiftImageViewExtension.swift`提供的函数。 

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
UICollectionViewCell也可以用类似的方法
### 使用 Closure
SwiftImage定义下面两个Closure来提供下载图像过程中和完成后的callback

```swift
public typealias ProgressHandler = ((receivedSize:Int64, expectedSize:Int64)->Void)
public typealias CompletionHandler = ((image:UIImage?, data:NSData?, error:NSError?, finished:Bool)->Void)
```
在`SwiftImageViewExtension.swift`提供的函数中，下面函数可以使用Closure 

```swift
func imageWithURL(url:NSURL, options:SwiftImagedDownloadOptions?, placeholderImage:UIImage?, progressHandler:ProgressHandler?)
func imageWithURL(url:NSURL, options:SwiftImagedDownloadOptions?, completionHandler:CompletionHandler?)
func imageWithURL(url:NSURL, options:SwiftImagedDownloadOptions?, progressHandler:ProgressHandler?, completionHandler:CompletionHandler?)
func imageWithURL(url:NSURL, options:SwiftImagedDownloadOptions?, placeholderImage:UIImage?, progressHandler:ProgressHandler?, completionHandler:CompletionHandler?)
```

### 使用 SwiftImageDownloadManager
有时候下载完图像后，不需要直接传递给UIImageView显示并且需要对下载图像的任务进行管理。SwiftImage提供了SwiftImageDownloadManager单例来创建并管理图像异步下载并缓存的任务。   
创建一个图像异步下载任务:  

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
该函数会返回一个`SwiftImageDownloadOperation`的实例。你可以保持一个实例，从而对一个下载任务进行管理，例如在某些情况下取消下载。取消一个图像下载任务  

```swift
SwiftImageDownloadManager.sharedInstance.cancelOperation(operation)
```
这里的Operation就是之前创建下载任务是得到的`SwiftImageDownloadOperation`的实例

### 使用 SwiftImageDownloadOperation创建图像下载缓存任务  
SwiftImage提供一个`SwiftImageDownloadOperation`的类来作为图像下载缓存任务的类。可以直接创建`SwiftImageDownloadOperation`的实例来创建图像下载和缓存的任务。

```swift
init(url:NSURL, options: SwiftImageDownloadOperation, progressHandler:((receivedSize:Int64, expectedSize:Int64)->Void)?, completionHandler:((image:UIImage?, data:NSData?, error:NSError?, finished:Bool)->Void)?)
```
任务创建后不会立即开始下载。需要调用`start()`来手动开始任务下载。

### 使用SwiftImageCache
SwiftImage实现了一个SwiftImageCache的单例来异步缓存图像。该实例提供一系列函数来实现在内存或者文件系统的存储和读取。

```swift
func storeImage(image:UIImage, key:String, imageData:NSData? = nil, cachePolicy:SwiftImageCachePolicy, completionHandler:(()-> Void)?)-> Void
func retrieveImageForKey(key: String, options: SwiftImageDownloadOptions, completionHandler: ((UIImage?, CacheType!) -> Void)?) -> Void    
func retrieveImageFromMemoryCache(key: String) -> UIImage?
func loadImageDataFromFile(key: String) -> NSData?
```

其中在文件系统存取图像信息是异步的，通过传递closure来实现callback

### 使用SwiftImage的工具集
SwiftImage提供了一些图像处理常用的函数。包括：  

1. 图像缩放

```swift
    class func resizeImage(image:UIImage, size:CGSize) -> UIImage   
```

2. 根据图像缩放到指定宽高后对应的高或者宽（保持宽高比)

```swift
    class func scaleImage(image: UIImage, height: CGFloat) -> CGSize
    class func scaleImage(image: UIImage, width: CGFloat) -> CGSize
```  
3. 剪切图像成圆形图像

```swift
    class func roundImage(image:UIImage, radius:CGFloat) -> UIImage
```  
4.  将图像旋转指定角度  

```swift
    class func rotatedByDegrees(img: UIImage, degrees: CGFloat) -> UIImage
```  
5. 图像解压缩
该函数的具体作用在前面已经介绍过。这里指列出函数的形式：

```swift
    class func decodImage(image:UIImage) -> UIImage?
    class func decodImage(image:UIImage, scale: CGFloat) -> UIImage? 
```  
这些函数都是class function， 可以直接用SwiftImage的class调用。  
## Licenses

All source code is licensed under the [MIT License](https://raw.github.com/rs/SDWebImage/master/LICENSE).