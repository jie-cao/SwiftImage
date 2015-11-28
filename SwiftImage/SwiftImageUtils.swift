//
//  SwiftImageUtils.swift
//  CJImageUtilsDemo
//
//  Created by Jie Cao on 6/13/15.
//  Copyright (c) 2015 JieCao. All rights reserved.
//

import UIKit

public class SwiftImageUtils: NSObject {
    private static let kPNGHeader: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
    private static let kPNGHeaderData:NSData = NSData(bytes: kPNGHeader, length: 8)
    public class func isPNG(image:UIImage, imageData:NSData? = nil) -> Bool {
        
        let alphaInfo = CGImageGetAlphaInfo(image.CGImage)
        let hasAlpha:Bool = !(alphaInfo == CGImageAlphaInfo.None ||
            alphaInfo == CGImageAlphaInfo.NoneSkipFirst ||
            alphaInfo == CGImageAlphaInfo.NoneSkipFirst)
        
        var imageIsPNG = hasAlpha
        
        if let data = imageData {
            if (data.length >= kPNGHeaderData.length) {
                if data.subdataWithRange(NSMakeRange(0, kPNGHeaderData.length)) == kPNGHeaderData {
                    imageIsPNG = true
                }
            }
            else {
                imageIsPNG = false
            }
        }
        
        return imageIsPNG
    }
    
    
    public class func decodImage(image:UIImage) -> UIImage? {
        return decodImage(image, scale: image.scale)
    }
    
    public class func blendImage(bottomImage:UIImage, topImage:UIImage, topImageOpacity:CGFloat = 1.0) ->UIImage{
            let width = bottomImage.size.width
            let height = bottomImage.size.height
            let newSize = CGSizeMake(width, height)
            UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
            bottomImage.drawInRect(CGRectMake(0, 0, newSize.width, newSize.height))
            topImage.drawInRect(CGRectMake(0, 0, newSize.width, newSize.height), blendMode: .Normal, alpha: topImageOpacity)
            let newImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            return newImage;
    }
    
    public class func degreesToRadians(degrees: CGFloat) -> CGFloat {
        return degrees * CGFloat(M_PI) / CGFloat(180)
    }
    
    public class func decodImage(image:UIImage, scale: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(image.size, true, 0)
        image.drawInRect(CGRectMake(0, 0, image.size.width, image.size.height))
        let decodedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return decodedImage
    }
    
    public class func rotatedByDegrees(img: UIImage, degrees: CGFloat) -> UIImage {
        
        let rotatedViewBox = UIView(frame: CGRectMake(0,0, img.size.width, img.size.height))
        let t = CGAffineTransformMakeRotation(SwiftImageUtils.degreesToRadians(degrees))
        rotatedViewBox.transform = t
        let rotatedSize = rotatedViewBox.frame.size
        
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap = UIGraphicsGetCurrentContext()
        
        CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2)
        
        CGContextRotateCTM(bitmap, SwiftImageUtils.degreesToRadians(degrees))
        
        CGContextScaleCTM(bitmap, 1.0, -1.0)
        CGContextDrawImage(bitmap, CGRectMake(-img.size.width / 2, -img.size.height / 2, img.size.width, img.size.height), img.CGImage)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage;
    }
    
    public class func getScaledImageSize(image: UIImage, height: CGFloat) -> CGSize {
        return CGSize(width: CGFloat(image.size.width) * (height / CGFloat(image.size.height != 0 ? image.size.height : 1)), height: height)
    }
    
    public class func getScaledImageSize(image: UIImage, width: CGFloat) -> CGSize {
        return CGSize(width: width, height: CGFloat(image.size.height) * (width / CGFloat(image.size.width != 0 ? image.size.width : 1)))
    }
    
    public class func scaleImage(image: UIImage, height: CGFloat) -> UIImage {
        let newSize = SwiftImageUtils.getScaledImageSize(image, height: height)
        return SwiftImageUtils.resizeImage(image, size: newSize)
    }
    
    public class func scaleImage(image: UIImage, width: CGFloat) -> UIImage {
        let newSize = SwiftImageUtils.getScaledImageSize(image, width:width)
        return SwiftImageUtils.resizeImage(image, size: newSize)
    }
    
    public class func getAspectRatio(image: UIImage) -> CGFloat {
        return image.size.height == 0 ? 0 : CGFloat(image.size.width) / CGFloat(image.size.height)
    }
    
    public class func roundImage(image:UIImage, radius:CGFloat) -> UIImage{
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(radius * 2, radius * 2), false, 0)
        let context = UIGraphicsGetCurrentContext()
        CGContextSaveGState(context)
        let clipPath = UIBezierPath(rect: CGRectMake(0, 0, radius * 2, radius * 2))
        clipPath.addClip()
        image.drawInRect(CGRectMake(0, 0, radius * 2, radius * 2))
        CGContextRestoreGState(context)
        let roundImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return  roundImage
    }
    
    public class func resizeImage(image:UIImage, size:CGSize) -> UIImage{
        if size.width != image.size.width || size.height != image.size.height {
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(size.width, size.height), false, 0)
            image.drawInRect(CGRectMake(0, 0, size.width, size.height))
            let roundImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return  roundImage
        } else {
            return image
        }
    }
}
