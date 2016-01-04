//
//  ImageTableViewController.swift
//  CJImageUtilsDemo
//
//  Created by Jie Cao on 11/20/15.
//  Copyright © 2015 JieCao. All rights reserved.
//

import UIKit

class ImageTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let reuseIdentifier = "ImageCell"
    @IBOutlet weak var tableView: UITableView!
    var dataSource = []
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.dataSource = [["text":"cat", "url":"http://www.fndvisions.org/img/cutecat.jpg"],
            ["text":"cat", "url":"http://www.mycatnames.com/wp-content/uploads/2015/09/Great-Ideas-for-cute-cat-names-2.jpg"],
            ["text":"cat", "url":"http://cdn.cutestpaw.com/wp-content/uploads/2011/11/cute-cat.jpg"],
            ["text":"cat", "url":"http://buzzneacom.c.presscdn.com/wp-content/uploads/2015/02/cute-cat-l.jpg"],
            ["text":"cat", "url":"http://images.fanpop.com/images/image_uploads/CUTE-CAT-cats-625629_689_700.jpg"],
            ["text":"cat", "url":"http://cl.jroo.me/z3/m/a/z/e/a.baa-Very-cute-cat-.jpg"],
            ["text":"cat", "url":"http://www.cancats.net/wp-content/uploads/2014/10/cute-cat-pictures-the-cutest-cat-ever.jpg"],
            ["text":"cat", "url":"https://catloves9.files.wordpress.com/2012/05/cute-cat-20.jpg"],
            ["text":"cat", "url":"https://s-media-cache-ak0.pinimg.com/736x/8c/99/e3/8c99e3483387df6395da674a6b5dee4c.jpg"],
            ["text":"cat", "url":"http://youne.com/wp-content/uploads/2013/09/cute-cat.jpg"],
            ["text":"cat", "url":"http://www.lovefotos.com/wp-content/uploads/2011/06/cute-cat1.jpg"],
            ["text":"cat", "url":"http://cutecatsrightmeow.com/wp-content/uploads/2015/10/heres-looking-at-you-kid.jpg"]]
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int{
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return self.dataSource.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let data = self.dataSource[indexPath.row] as! [String :String]
        
        let cell = self.tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath) as! ImageTableViewCell
        cell.contentLabel?.text = data["text"]
        let placeholderImage = UIImage(named: "placeholder.jpg")
        if let imageUrl = NSURL(string: data["url"]!){
            cell.photoView?.imageWithURL(imageUrl, placeholderImage: placeholderImage)
            cell.photoView?.contentMode = .ScaleAspectFit
        }
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 100.0
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
