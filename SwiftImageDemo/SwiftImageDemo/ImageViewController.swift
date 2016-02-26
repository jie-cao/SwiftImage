//
//  ImageViewController.swift
//  CJImageUtilsDemo
//
//  Created by Jie Cao on 11/20/15.
//  Copyright © 2015 JieCao. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        let url = NSURL(string: "http://www.catgifs.org/wp-content/uploads/2013/09/046_boxing_cat_gifs.gif")
        self.imageView.alpha = 0
        imageView.imageWithURL(url!) { (image, data, error, finished) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.imageView.image = image;
                UIView.animateWithDuration(2.0, animations: { () -> Void in
                  self.imageView.alpha = 1.0
                })
            })
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
}
