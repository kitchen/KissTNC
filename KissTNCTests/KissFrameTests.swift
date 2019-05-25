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
        XCTAssertEqual(0x00, frame.command, "the command is a data packet")
        XCTAssertEqual(0, frame.port, "the port is 0")
        XCTAssertEqual(97, frame.payload.count, "the length of the payload is 97")
        XCTAssertNotEqual(KissFrame.FEND, frame.payload.last, "we strip off the trailing FEND")

        frame = KissFrame(Data([KissFrame.FEND, 0xff, KissFrame.FEND]))
        XCTAssertEqual(KissFrame.Return, frame.command, "the command is end KISS")
        XCTAssertEqual(0x0f, frame.port, "the port is F")
        XCTAssertEqual(0, frame.payload.count, "there is no payload")

        frame = KissFrame(Data([KissFrame.FEND, 0x00, KissFrame.FESC, KissFrame.TFEND, KissFrame.FESC, KissFrame.TFESC, KissFrame.FEND]))
        XCTAssertEqual(Data([KissFrame.FEND, KissFrame.FESC]), frame.payload, "ensure we are properly unescaping")

        frame = KissFrame(Data([KissFrame.FEND, 0x00, 0x01, 0x01, 0x01, KissFrame.FESC, KissFrame.TFEND, 0x01, 0x01, 0x01, KissFrame.FESC, KissFrame.TFESC, 0x01, 0x01, 0x01, 0x01, KissFrame.FEND]))
        XCTAssertEqual(Data([0x01, 0x01, 0x01, KissFrame.FEND, 0x01, 0x01, 0x01, KissFrame.FESC, 0x01, 0x01, 0x01, 0x01]), frame.payload)

        // assume something already cut off the FENDs
        frame = KissFrame(Data([0x00, 0x01, 0x02, 0x03]))
        XCTAssertEqual(0x00, frame.command)
        XCTAssertEqual(Data([0x01, 0x02, 0x03]), frame.payload)
    }

    func testGenerateFrames() {
        var frame = KissFrame(port: 0x00, command: 0x00, payload: Data([0x00,0x01,0x02,0x03]))
        XCTAssertEqual(Data([KissFrame.FEND, 0x00, 0x00, 0x01, 0x02, 0x03, KissFrame.FEND]), frame.frame())

        frame = KissFrame(port: 0x00, command: 0x00, payload: Data([KissFrame.FEND, KissFrame.FESC]))
        XCTAssertEqual(Data([KissFrame.FEND, 0x00, KissFrame.FESC, KissFrame.TFEND, KissFrame.FESC, KissFrame.TFESC, KissFrame.FEND]), frame.frame(), "ensure we are properly escaping")
    }

    func testRoundTrips() {
        let framesToRoundTrip = [
            KissFrame(Data([KissFrame.FEND, 0x00, 0x00, 0x01, 0x02, 0x03, KissFrame.FEND])),
            KissFrame(Data([KissFrame.FEND, 0x00, KissFrame.FESC, KissFrame.TFEND, KissFrame.FEND])),
            KissFrame(port: 0, command: 0, payload: Data([KissFrame.FEND, KissFrame.FESC])),
        ]
        for frame in framesToRoundTrip {
            let frame2 = KissFrame(port: frame.port, command: frame.command, payload: frame.payload)
            let frame3 = KissFrame(frame2.frame())

            XCTAssertEqual(frame2.frame(), frame.frame(), "they're all the same")
            XCTAssertEqual(frame3.frame(), frame.frame(), "they're all the same")
        }
    }
}
