//
//  LayerTableViewController.swift
//  koala-tea-video-editor
//
//  Created by Craig Holliday on 2/17/18.
//  Copyright © 2018 Koala Tea. All rights reserved.
//

import UIKit

let reuseIdentifier = "reuseIdentifier"

class LayerTableViewController: UITableViewController {

    var layers: [EditableLayer] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        let tlayer = EditableLayer()
//        tlayer.setText(to: "TESTING")
//        tlayer.setFont(to: .italicSystemFont(ofSize: 150))
//        tlayer.setTextColor(to: .red)
        tlayer.frame = CGRect(x: 0, y: 88, width: 200, height: 200)
        tlayer.setStartTime(to: 3)
        tlayer.setEndTime(to: 6)
        self.layers.append(tlayer)

        let tlayer2 = EditableLayer()
//        tlayer2.setText(to: "TESTING")
//        tlayer2.setFont(to: .italicSystemFont(ofSize: 150))
//        tlayer2.setTextColor(to: .red)
        tlayer2.frame = CGRect(x: 0, y: 88, width: 200, height: 200)
        tlayer2.setStartTime(to: 1)
        tlayer2.setEndTime(to: 8)
        self.layers.append(tlayer2)

        self.tableView.register(LayerTableViewCell.self, forCellReuseIdentifier: reuseIdentifier)

        self.tableView.tableFooterView = UIView()

        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 100
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return layers.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! LayerTableViewCell

        // Configure the cell...
        cell.duration = 10
        cell.editableLayer = layers[indexPath.row]

        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
