//
//  Emby_PlayerTests.swift
//  Emby PlayerTests
//
//  Created by Mats Mollestad on 25/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import XCTest
@testable import Emby_Player

class Emby_PlayerTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    
    
    func testDecodingVTTSubtitleFormat() {
        let exampleFile = """
WEBVTT

00:00:12.679 --> 00:00:15.515
You give argyle meth, we give guns.

00:00:15.598 --> 00:00:18.643
Anybody ever tell you, you sound like
that motherfuckin' vampire

00:00:18.727 --> 00:00:21.771
that count shit on <i>Sesame Street?</i>
That purple son of a bitch.

00:00:21.855 --> 00:00:23.982
That's ridiculous.
Now let's get down to business.
"""
        let factory = SubtitleFactory()
        do {
            let subtitles = try factory.decodeVTTFormate(exampleFile)
            XCTAssert(subtitles.count == 4, "Expected 4 subtitles but decoded \(subtitles.count)")
        } catch let error {
            XCTFail("Decoding VTT file failed with error: \(error.localizedDescription)")
        }
    }
    
    func testHLSDecoding() {
        let exampleFile = """
#EXTM3U
#EXT-X-PLAYLIST-TYPE:VOD
#EXT-X-VERSION:3
#EXT-X-TARGETDURATION:3
#EXT-X-MEDIA-SEQUENCE:0
#EXTINF:3.0000, nodesc
hls1/main/0.ts?mediaSourceId=039a349e28196dace6e019611e8c3732&deviceId=xxxx
#EXTINF:3.0000, nodesc
hls1/main/1.ts?mediaSourceId=039a349e28196dace6e019611e8c3732&deviceId=xxxx
#EXTINF:3.0000, nodesc
hls1/main/2.ts?mediaSourceId=039a349e28196dace6e019611e8c3732&deviceId=xxxx
#EXTINF:3.0000, nodesc
hls1/main/3.ts?mediaSourceId=039a349e28196dace6e019611e8c3732&deviceId=xxxx
#EXTINF:3.0000, nodesc
hls1/main/4.ts?mediaSourceId=039a349e28196dace6e019611e8c3732&deviceId=xxxx
#EXTINF:3.0000, nodesc
hls1/main/5.ts?mediaSourceId=039a349e28196dace6e019611e8c3732&deviceId=xxxx
#EXTINF:3.0000, nodesc
hls1/main/6.ts?mediaSourceId=039a349e28196dace6e019611e8c3732&deviceId=xxxx
#EXTINF:3.0000, nodesc
hls1/main/7.ts?mediaSourceId=039a349e28196dace6e019611e8c3732&deviceId=xxxx
#EXTINF:3.0000, nodesc
hls1/main/8.ts?mediaSourceId=039a349e28196dace6e019611e8c3732&deviceId=xxxx
#EXT-X-ENDLIST
"""
        do {
            let decoder = HLSDecoder()
            let hlsFile = try decoder.decode(file: exampleFile)
            XCTAssert(hlsFile.items.count == 9, "The amount of hls items was inncorect: \(hlsFile.items.count)")
            XCTAssert(hlsFile.header.keys.count == 4, "The amount of hls headers was inncorect: \(hlsFile.header.keys.count)")
        } catch {
            XCTFail("Failed with error: \(error.localizedDescription)")
        }
    }
}
