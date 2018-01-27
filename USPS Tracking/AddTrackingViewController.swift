//
//  AddTrackingNumViewController.swift
//  USPS Tracking
//
//  Created by Ibrahim Surani on 1/26/18.
//  Copyright © 2018 Faiz Surani. All rights reserved.
//

import UIKit

class AddTrackingViewController: UIViewController {
    @IBOutlet weak var popupAddView: UIView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var trackingNumberTextField: UITextField!
    @IBOutlet weak var senderTextField: UITextField!
    
    @IBAction func cancelButton(_ sender: Any) {
        
    }
    
    @IBAction func addButton(_ sender: Any) {
        let storedTrackingData = StoredTrackingData(trackingNumber: trackingNumberTextField.text!, name: titleTextField.text!, sender: senderTextField.text!, recentUpdate: "", statusCategory: "")
        
    }
    
    @IBAction func scanButton(_ sender: Any) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
