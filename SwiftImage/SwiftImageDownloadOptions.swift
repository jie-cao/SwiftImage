//
//  SwiftImageDownloadOptions.swift
//  CJImageUtilsDemo
//
//  Created by Jie Cao on 6/13/15.
//  Copyright (c) 2015 JieCao. All rights reserved.
//

import UIKit

public enum SwiftImageDownloadPriority {

    case DefaultPriority
    case LowPriority
    case HighPriority

}

public enum SwiftImageCachePolicy:Int {
    case NoCache = 0
    case MemoryCache = 1
    case FileCache = 2
    case MemoryAndFileCache = 3
}


public class SwiftImageDownloadOptions: NSObject {
    
    var priority:SwiftImageDownloadPriority = .DefaultPriority
    var cachePolicy:SwiftImageCachePolicy = .MemoryAndFileCache
    var shouldDecode: Bool = true
    var requestCachePolicy : NSURLRequestCachePolicy = .UseProtocolCachePolicy;
    var scale: CGFloat = UIScreen.mainScreen().scale
    
}
