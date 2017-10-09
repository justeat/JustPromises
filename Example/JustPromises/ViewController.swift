//
//  ViewController.swift
//  JustPromises
//
//  Created by albertodebortoli@gmail.com on 10/09/2017.
//  Copyright (c) 2017 albertodebortoli@gmail.com. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let demoExamples: ObjCExamples = ObjCExamples()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        demoExamples.runSucceedingExample()
        demoExamples.runFailingExample()
        demoExamples.runWhenAllExample()
    }

}

