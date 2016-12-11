//
//  ScriptsUITests.swift
//  ScriptsUITests
//
//  Created by Jon Andersen on 12/11/15.
//  Copyright © 2015 Andersen. All rights reserved.
//

import XCTest
import Photos

class ScriptsUITests: XCTestCase {
    
    fileprivate weak var done: XCTestExpectation?
    fileprivate var foundElement = false
    fileprivate var app: XCUIApplication!
    fileprivate var NUMBER_OF_VIDEOS = 37
    fileprivate var NUMBER_OF_NONLEAP_VIDEOS = 6


    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
//        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        app = XCUIApplication()
        
        addUIInterruptionMonitor(withDescription: "Alert Dialog") { (alert) -> Bool in
            alert.buttons["OK"].tap()
            self.foundElement = true
            return true
        }
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPopulate() {
        
        app.launch()
        done = self.expectation(description: "")

        self.app.tap();

        requestPermissions{
            self.populateLibrary()
        }
        
        let startTime = Date.timeIntervalSinceReferenceDate
        let status = PHPhotoLibrary.authorizationStatus()

        while (!foundElement && status != .authorized) {
            if (Date.timeIntervalSinceReferenceDate - startTime > 5.0) {
                break;
            }
            CFRunLoopRunInMode(CFRunLoopMode.defaultMode, 0.1, false);
        }

        
        self.waitForExpectations(timeout: 360, handler: nil)
        
    }
    
    
    
    //MARK : LOAD PHOTOS
    
    var assetCollectionPlaceholder: PHObjectPlaceholder!
    
    func createAlbum(_ completed: @escaping (PHAssetCollection) ->()) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", "Leap Second")
        let collection : PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        if let _ = collection.firstObject {
            completed(collection.firstObject!)
        } else {
            PHPhotoLibrary.shared().performChanges({
                let createAlbumRequest : PHAssetCollectionChangeRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: "Leap Second")
                self.assetCollectionPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection
                }, completionHandler: { success, error in
                    let collectionFetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [self.assetCollectionPlaceholder.localIdentifier], options: nil)
                    NSLog("\(collectionFetchResult)")
                    completed(collectionFetchResult.firstObject!)
            })
        }
    }

    
    
    func requestPermissions(_ completed : @escaping () -> ()){
        let status = PHPhotoLibrary.authorizationStatus()
        switch(status) {
        case .authorized: completed()
        case .notDetermined :
            PHPhotoLibrary.requestAuthorization({ (status) -> Void in
                completed()
            });
            self.app.tap();
        default:
            completed()
        }
    }
    
    func createAssetRequest(_ video: String) ->  PHObjectPlaceholder{
        let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(string: video)!)
        return assetRequest!.placeholderForCreatedAsset!
    }
    
    func populateLibrary() {
        createAlbum{collection in
            
            if collection.estimatedAssetCount > 0 {
                self.done?.fulfill()
                return
                
            }
            
            let leapSecondsRange = 1...self.NUMBER_OF_VIDEOS
            let nonLeapSecondsRange = 1...self.NUMBER_OF_NONLEAP_VIDEOS

            
            let bundle = Bundle(for: ScriptsUITests.classForCoder())
            PHPhotoLibrary.shared().performChanges({ () -> Void in
                
                let leapSeconds = leapSecondsRange.map{bundle.path(forResource: "\($0)", ofType: "m4v")!}
                    .map{self.createAssetRequest($0)}
                
                
                if let request = PHAssetCollectionChangeRequest(for: collection) {
                    request.addAssets(leapSeconds as NSFastEnumeration)
                }
                
                nonLeapSecondsRange.map{bundle.path(forResource: "nonleap\($0)", ofType: "m4v")!}
                    .forEach(createAssetRequest)
                
                
                
                }) { (success, error) -> Void in
                    self.done?.fulfill()
            }
        }
    }
    
    func video(_ videoPath: String, didFinishSavingWithError error: NSError, contextInfo info: UnsafeMutableRawPointer) {
        done?.fulfill()
    }
    
}
