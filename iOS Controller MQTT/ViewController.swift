//
//  ViewController.swift
//  iOS Controller MQTT
//
//  Created by Ken Johnson on 2020-03-03.
//  Copyright © 2020 Ken Johnson. All rights reserved.
//

import UIKit
import CocoaMQTT
import SwiftSocket

//let serverAddress = "137.82.226.208"
//    let serverAddress = "10.43.135.243"        // Ken's at school
//let serverAddress = "192.168.50.158"            // Ken's at home
// let serverAddress = "192.168.50.158"         // Theirs at school
let serverAddress = "137.82.226.208"

let port = 8000

var client: TCPClient?

class ViewController: UIViewController {

    @IBOutlet weak var fBOutlet: UISlider!
    @IBOutlet weak var yawOutlet: UISlider!
    @IBOutlet weak var connectToggle: UISwitch!
    @IBOutlet weak var connectLabel: UILabel!
    
    let mqttClient = CocoaMQTT(clientID: "iOS Device", host: serverAddress, port: 1883)
    
    var throttle = Float(0)
    var yaw = Float(0)
    
    var isConnected = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.isConnected = false
        
//        client = TCPClient(address: serverAddress, port: Int32(port))
        
        // Do any additional setup after loading the view.
        fBOutlet.transform = CGAffineTransform(rotationAngle: CGFloat(-Double.pi / 2))
        
        fBOutlet.addTarget(self, action: #selector(ViewController.fBOnRelease(notification:)), for: ([.touchUpInside,.touchUpOutside]))
        yawOutlet.addTarget(self, action: #selector(ViewController.yawOnRelease(notification:)), for: ([.touchUpInside,.touchUpOutside]))
    }
    
    @IBAction func forwwardBackward(_ sender: UISlider) {
        if (sender.value != 0) {
            throttle = sender.value
            print(String(throttle) + " " + String(yaw))
            mqttClient.publish("rpi/gpio", withString: String(throttle) + " " + String(yaw))
        } else {
            throttle = sender.value
            mqttClient.publish("rpi/gpio", withString: String(throttle) + " " + String(yaw))
        }
    }
    
    @objc func fBOnRelease(notification: NSNotification) {
        fBOutlet.value = 0
        throttle = 0
        mqttClient.publish("rpi/gpio", withString: String(throttle) + " " + String(yaw))
    }
    
    @IBAction func yaw(_ sender: UISlider) {
        if (sender.value != 0) {
            yaw = sender.value
            print(String(throttle) + " " + String(yaw)) 
            mqttClient.publish("rpi/gpio", withString: String(throttle) + " " + String(yaw))
        } else {
            yaw = sender.value
            mqttClient.publish("rpi/gpio", withString: String(throttle) + " " + String(yaw))
        }
    }
    
    @objc func yawOnRelease(notification: NSNotification) {
        yawOutlet.value = 0
        yaw = 0
        mqttClient.publish("rpi/gpio", withString: String(throttle) + " " + String(yaw))
    }
    
    @IBAction func connectToggle(_ sender: UISwitch) {
        let isSwitchOn = sender.isOn
        connectControls(isSwitchOn: isSwitchOn)
//        connectVideo(isSwitchOn: isSwitchOn)
    }
    
    func connectControls(isSwitchOn: Bool) {
        if(isSwitchOn) {
            if(!isConnected) {
                mqttClient.connect()
                isConnected = true
            }
            
            connectLabel.text = "Connected"
            sleep(1)
            mqttClient.publish("rpi/gpio", withString: "connected")
        } else {
            mqttClient.publish("rpi/gpio", withString: "disconnected")
            connectLabel.text = "Disconnected"
        }
    }
    
    func connectVideo(isSwitchOn: Bool) {
        if(isSwitchOn) {
            switch client?.connect(timeout: 10) {
            case .success:
                print("Connected to server")
                let server = TCPServer(address: serverAddress, port: 8000)
                switch server.listen() {
                  case .success:
                    while true {
                        if let client = server.accept() {
                            echoService(client: client)
                        } else {
                            print("accept error")
                        }
                    }
                  case .failure(let error):
                    print(error)
                }
            case .failure(let error):
                print(error)
            case .none:
                print("error")
            }
            
        } else {
            client?.close();
        }
    }
    
    func echoService(client: TCPClient) {
        print("Newclient from:\(client.address)[\(client.port)]")
        let d = client.read(1024*10)
        client.send(data: d!)
        client.close()
    }
}

