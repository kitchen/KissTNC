//
//  KissFrameTests.swift
//  KissTNCTests
//
//  Created by Jeremy Kitchen on 5/23/19.
//  Copyright © 2019 Jeremy Kitchen. All rights reserved.
//

import XCTest

class KissFrameTests: XCTestCase {
    func testParseFrames() {
        var frame = KissFrame(Data(base64Encoded: "wACEioKGnpxgrm6YqEBAdQPwUEFSQyBXSU5MSU5LIEdBVEVXQVkgT04gTVQgU0NPVFQsIENOODVSSywgUkVQRUFURVIgT04gMTQ2Ljg0IC02MDAsIElORk9AVzdMVC5PUkcNwA==")!)
        XCTAssertEqual(frame.command, 0x00, "the command is a data packet")
        XCTAssertEqual(frame.port, 0, "the port is 0")
        XCTAssertEqual(frame.payload.count, 97, "the length of the payload is 97")
        XCTAssertNotEqual(frame.payload.last, KissFrame.FEND, "we strip off the trailing FEND")
        
        frame = KissFrame(Data([KissFrame.FEND, 0xff, KissFrame.FEND]))
        XCTAssertEqual(frame.command, KissFrame.Return, "the command is end KISS")
        XCTAssertEqual(frame.port, 0x0F, "the port is F")
        XCTAssertEqual(frame.payload.count, 0, "there is no payload")
        
        frame = KissFrame(Data([KissFrame.FEND, 0x00, KissFrame.FESC, KissFrame.TFEND, KissFrame.FESC, KissFrame.TFESC, KissFrame.FEND]))
        XCTAssertEqual(frame.payload, Data([KissFrame.FEND, KissFrame.FESC]), "ensure we are properly unescaping")
    }
    
    func testGenerateFrames() {
        var frame = KissFrame(port: 0x00, command: 0x00, payload: Data([0x00,0x01,0x02,0x03]))
        XCTAssertEqual(frame.frame(), Data([KissFrame.FEND, 0x00, 0x00, 0x01, 0x02, 0x03, KissFrame.FEND]))
        
        frame = KissFrame(port: 0x00, command: 0x00, payload: Data([KissFrame.FEND, KissFrame.FESC]))
        XCTAssertEqual(frame.frame(), Data([KissFrame.FEND, 0x00, KissFrame.FESC, KissFrame.TFEND, KissFrame.FESC, KissFrame.TFESC, KissFrame.FEND]), "ensure we are properly escaping")
    }
    
    func testRoundTrips() {
        let framesToRoundTrip = [
            KissFrame(Data([KissFrame.FEND, 0x00, 0x00, 0x01, 0x02, 0x03, KissFrame.FEND])),
        ]
        for frame in framesToRoundTrip {
            let frame2 = KissFrame(port: frame.port, command: frame.command, payload: frame.payload)
            let frame3 = KissFrame(frame2.frame())
            
            XCTAssertEqual(frame.frame(), frame2.frame(), "they're all the same")
            XCTAssertEqual(frame.frame(), frame3.frame(), "they're all the same")
            // XCTAssertEqual(frame1, frame2, "the frames are identical") // TODO: need to implement Equatable for this
            // XCTAssertEqual(frame1, frame3, "the frames are identical") // TODO: need to implement Equatable for this
            
        }
        
        
    }

}
