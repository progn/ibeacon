//
//  ViewController.swift
//  beacon
//
//  Created by Alexey Solovyov on 17.07.16.
//  Copyright © 2016 progn. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController {
    
    let locationManager = CLLocationManager()
    
    let kBeaconId = "estimote"
    let kBeaconUUID = NSUUID(UUIDString:"B9407F30-F5F8-466E-AFF9-25556B57FE6D")!

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    var detectedBeacons: [CLBeacon] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        
        // startMonitoringForRegion() requires AlwaysAuthorization (startRangingBeaconsInRegion can work with WhenInUseAuthorization)
        // don't forget add NSLocationAlwaysUsageDescription to Info.plist
        locationManager.requestAlwaysAuthorization()
    }

    func showRegionInfo(region: CLBeaconRegion, inside: Bool) {
        statusLabel.text = "\(region.proximityUUID.UUIDString)\n" + (inside ? "inside" : "outside")
    }

    func showBeaconsInfo(beacons: [CLBeacon]) {
        detectedBeacons = beacons
        tableView.reloadData()
    }
}

extension ViewController: UITableViewDataSource {

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return detectedBeacons.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let beacon = detectedBeacons[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        
        cell.textLabel?.text = "Major: \(beacon.major), Minor: \(beacon.minor)"
        
        cell.detailTextLabel?.text = "Proximity: \(proximityString(beacon.proximity)), Accuracy: \(beacon.accuracy)"
        
        return cell
    }
    
    func proximityString(proximity: CLProximity) -> String {
        switch proximity {
        case .Immediate:
            return "Immediate"
        case .Near:
            return "Near"
        case .Far:
            return "Far"
        case .Unknown:
            return "Unknown"
        }
    }
}

extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        printLog("didChangeAuthorizationStatus: \(status.rawValue)")
        
        if status == .AuthorizedWhenInUse || status == .AuthorizedAlways {
            let region = CLBeaconRegion(proximityUUID: kBeaconUUID, identifier: kBeaconId)
            
            manager.startMonitoringForRegion(region)
        }
    }
    
    func locationManager(manager: CLLocationManager, monitoringDidFailForRegion region: CLRegion?, withError error: NSError) {
        printLog("monitoringDidFailForRegion: \(region), \(error)")
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        printLog("Location manager failed: \(error.description)")
    }
    
    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        printLog("didEnterRegion: \(region)")
    }

    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        printLog("didExitRegion: \(region)")
    }
    
    func locationManager(manager: CLLocationManager, didDetermineState state: CLRegionState, forRegion region: CLRegion) {
        printLog("didDetermineState:\(state.rawValue) forRegion:\(region)")
        
        if region.identifier == kBeaconId, let region = region as? CLBeaconRegion {
            if state == .Inside {
                manager.startRangingBeaconsInRegion(region)
                showRegionInfo(region, inside: true)
            } else if state == .Outside {
                manager.stopRangingBeaconsInRegion(region)
                showRegionInfo(region, inside: false)
            }
        }
    }
    
    func locationManager(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
        printLog("didRangeBeacons: \(beacons)")
        
        showBeaconsInfo(beacons)
    }
}

// use "Swift Compiler – Custom Flags"  -DDEBUG or -DLOG
func printLog(text: String) {
    #if DEBUG
        print(text)
    #else
    #if LOG
        NSLog("\(text)")
    #endif
    #endif
}
