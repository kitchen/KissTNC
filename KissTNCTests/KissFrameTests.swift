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
        XCTAssertNotNil(frame)
        if let frame = frame {
            XCTAssertEqual(0x00, frame.command, "the command is a data packet")
            XCTAssertEqual(0, frame.port, "the port is 0")
            XCTAssertEqual(97, frame.payload.count, "the length of the payload is 97")
            XCTAssertNotEqual(KissFrame.FEND, frame.payload.last, "we strip off the trailing FEND")
        }

        frame = KissFrame(Data([KissFrame.FEND, 0xff, KissFrame.FEND]))
        XCTAssertNotNil(frame)
        if let frame = frame {
            XCTAssertEqual(KissFrame.Return, frame.command, "the command is end KISS")
            XCTAssertEqual(0x0f, frame.port, "the port is F")
            XCTAssertEqual(0, frame.payload.count, "there is no payload")
        }

        frame = KissFrame(Data([KissFrame.FEND, 0x00, KissFrame.FESC, KissFrame.TFEND, KissFrame.FESC, KissFrame.TFESC, KissFrame.FEND]))
        XCTAssertNotNil(frame)
        if let frame = frame {
            XCTAssertEqual(Data([KissFrame.FEND, KissFrame.FESC]), frame.payload, "ensure we are properly unescaping")
        }

        frame = KissFrame(Data([KissFrame.FEND, 0x00, 0x01, 0x01, 0x01, KissFrame.FESC, KissFrame.TFEND, 0x01, 0x01, 0x01, KissFrame.FESC, KissFrame.TFESC, 0x01, 0x01, 0x01, 0x01, KissFrame.FEND]))
        XCTAssertNotNil(frame)
        if let frame = frame {
            XCTAssertEqual(Data([0x01, 0x01, 0x01, KissFrame.FEND, 0x01, 0x01, 0x01, KissFrame.FESC, 0x01, 0x01, 0x01, 0x01]), frame.payload)
        }

        // assume something already cut off the FENDs
        frame = KissFrame(Data([0x00, 0x01, 0x02, 0x03]))
        XCTAssertNotNil(frame)
        if let frame = frame {
            XCTAssertEqual(0x00, frame.command)
            XCTAssertEqual(Data([0x01, 0x02, 0x03]), frame.payload)
        }
    }

    func testGenerateFrames() {
        var frame = KissFrame(port: 0x00, command: 0x00, payload: Data([0x00,0x01,0x02,0x03]))
        XCTAssertEqual(Data([KissFrame.FEND, 0x00, 0x00, 0x01, 0x02, 0x03, KissFrame.FEND]), frame.frame())

        frame = KissFrame(port: 0x00, command: 0x00, payload: Data([KissFrame.FEND, KissFrame.FESC]))
        XCTAssertEqual(Data([KissFrame.FEND, 0x00, KissFrame.FESC, KissFrame.TFEND, KissFrame.FESC, KissFrame.TFESC, KissFrame.FEND]), frame.frame(), "ensure we are properly escaping")

        frame = KissFrame(port: 0x0C, command: 0x00, payload: Data([0x00, 0x00, 0x00]))
        XCTAssertEqual(Data([KissFrame.FEND, KissFrame.FESC, KissFrame.TFEND, 0x00, 0x00, 0x00, KissFrame.FEND]), frame.frame(), "port 12 command 0 is 0xC0 and needs encoding")
    }

    func testRoundTrips() {
        // TODO: figure out a better way to loop over cases like this?
        let framesToRoundTrip = [
            KissFrame(Data([KissFrame.FEND, 0x00, 0x00, 0x01, 0x02, 0x03, KissFrame.FEND])),
            KissFrame(Data([KissFrame.FEND, 0x00, KissFrame.FESC, KissFrame.TFEND, KissFrame.FEND])),
            KissFrame(port: 0, command: 0, payload: Data([KissFrame.FEND, KissFrame.FESC])),
        ]
        for frame in framesToRoundTrip {
            XCTAssertNotNil(frame)
            guard let frame = frame else {
                return
            }
            let frame2 = KissFrame(port: frame.port, command: frame.command, payload: frame.payload)
            let frame3 = KissFrame(frame2.frame())
            
            XCTAssertNotNil(frame3)
            guard let realFrame3 = frame3 else {
                return
            }

            XCTAssertEqual(frame2.frame(), frame.frame(), "they're all the same")
            XCTAssertEqual(realFrame3.frame(), frame.frame(), "they're all the same")
        }
    }
    
    func testInvalidFrames() {
        // FESC followed by the end of the frame. This should weed out errors with `iterator.next()` ... like the one this just triggered :)
        var frame = KissFrame(Data([KissFrame.FEND, 0x00, KissFrame.FESC, KissFrame.FEND]))
        XCTAssertNil(frame)
        
        // empty frame
        frame = KissFrame(Data([KissFrame.FEND, KissFrame.FEND]))
        XCTAssertNil(frame)
        
        // emptier frame
        frame = KissFrame(Data([]))
        XCTAssertNil(frame)
    }
}
