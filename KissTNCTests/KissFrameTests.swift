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
        var frame = KissFrame(fromData: Data(base64Encoded: "wACEioKGnpxgrm6YqEBAdQPwUEFSQyBXSU5MSU5LIEdBVEVXQVkgT04gTVQgU0NPVFQsIENOODVSSywgUkVQRUFURVIgT04gMTQ2Ljg0IC02MDAsIElORk9AVzdMVC5PUkcNwA==")!)
        XCTAssertNotNil(frame)
        if let frame = frame {
            XCTAssertEqual(.DataFrame, frame.frameType, "the frameType is a data packet")
            XCTAssertEqual(0, frame.port, "the port is 0")
            XCTAssertEqual(97, frame.payload.count, "the length of the payload is 97")
            XCTAssertNotEqual(KissFrame.FEND, frame.payload.last, "we strip off the trailing FEND")
        }

        frame = KissFrame(fromData: Data([KissFrame.FEND, 0xff, KissFrame.FEND]))
        XCTAssertNotNil(frame)
        if let frame = frame {
            XCTAssertEqual(KissFrame.FrameType.Return, frame.frameType, "the frameType is end KISS")
            XCTAssertEqual(0x0f, frame.port, "the port is F")
            XCTAssertEqual(0, frame.payload.count, "there is no payload")
        }


        frame = KissFrame(fromData: Data([KissFrame.FEND, 0x00, KissFrame.FEND]))
        XCTAssertNotNil(frame)
        if let frame = frame {
            XCTAssertEqual(KissFrame.FrameType.DataFrame, frame.frameType)
            XCTAssertEqual(0, frame.payload.count)
        }

        frame = KissFrame(fromData: Data([KissFrame.FEND, 0x00, KissFrame.FESC, KissFrame.TFEND, KissFrame.FESC, KissFrame.TFESC, KissFrame.FEND]))
        XCTAssertNotNil(frame)
        if let frame = frame {
            XCTAssertEqual(Data([KissFrame.FEND, KissFrame.FESC]), frame.payload, "ensure we are properly unescaping")
        }

        frame = KissFrame(fromData: Data([KissFrame.FEND, 0x00, 0x01, 0x01, 0x01, KissFrame.FESC, KissFrame.TFEND, 0x01, 0x01, 0x01, KissFrame.FESC, KissFrame.TFESC, 0x01, 0x01, 0x01, 0x01, KissFrame.FEND]))
        XCTAssertNotNil(frame)
        if let frame = frame {
            XCTAssertEqual(Data([0x01, 0x01, 0x01, KissFrame.FEND, 0x01, 0x01, 0x01, KissFrame.FESC, 0x01, 0x01, 0x01, 0x01]), frame.payload)
        }

        // assume something already cut off the FENDs
        frame = KissFrame(fromData: Data([0x00, 0x01, 0x02, 0x03]))
        XCTAssertNotNil(frame)
        if let frame = frame {
            XCTAssertEqual(.DataFrame, frame.frameType)
            XCTAssertEqual(Data([0x01, 0x02, 0x03]), frame.payload)
        }
        
        // from: http://www.ax25.net/kiss.aspx
        // Receipt of any character other than TFESC or TFEND while in escaped mode is an error; no action is taken and frame assembly continues.
        // I'm interpreting this as "ignore the FESC, keep the non-TFESC/TFEND, exit escape mode, and move on with life
        // it's entirely possible that I should stay in escape mode and wait until a TFESC or TFEND comes along, but given that it says this "is an error", and the
        // spec says that FESC -> FESC, TFESC, and FEND -> FESC, TFEND, I think there's room for a lot of interpretation here and ... yea. It's fine.
        frame = KissFrame(fromData: Data([KissFrame.FEND, 0x00, 0x00, KissFrame.FESC, 0x00, 0x00, KissFrame.FEND]))
        XCTAssertNotNil(frame)
        if let frame = frame {
            XCTAssertEqual(Data([0x00,0x00,0x00]), frame.payload)
        }
        
        frame = KissFrame(fromData: Data([KissFrame.FEND, 0x00, KissFrame.FESC, KissFrame.FEND]))
        XCTAssertNotNil(frame)
    }


    func testGenerateFrames() {
        var frame = KissFrame(ofType: .DataFrame, port: 0x00, payload: Data([0x00,0x01,0x02,0x03]))
        XCTAssertNotNil(frame)
        if let frame = frame {
            XCTAssertEqual(Data([KissFrame.FEND, 0x00, 0x00, 0x01, 0x02, 0x03, KissFrame.FEND]), frame.frame())
        }

        frame = KissFrame(ofType: .DataFrame, port: 0x00, payload: Data([KissFrame.FEND, KissFrame.FESC]))
        XCTAssertNotNil(frame)
        if let frame = frame {
            XCTAssertEqual(Data([KissFrame.FEND, 0x00, KissFrame.FESC, KissFrame.TFEND, KissFrame.FESC, KissFrame.TFESC, KissFrame.FEND]), frame.frame(), "ensure we are properly escaping")
        }

        frame = KissFrame(ofType: .DataFrame, port: 0x0C, payload: Data([0x00, 0x00, 0x00]))
        XCTAssertNotNil(frame)
        if let frame = frame {
            XCTAssertEqual(Data([KissFrame.FEND, KissFrame.FESC, KissFrame.TFEND, 0x00, 0x00, 0x00, KissFrame.FEND]), frame.frame(), "port 12 frameType 0 is 0xC0 and needs encoding")
        }
        
        frame = KissFrame(ofType: .DataFrame, port: 4)
        XCTAssertNotNil(frame)
        
        frame = KissFrame(payload: Data([]))
        XCTAssertNotNil(frame)
        
        frame = KissFrame()
        XCTAssertNotNil(frame)
        if let frame = frame {
            XCTAssertEqual(0, frame.port)
            XCTAssertEqual(.DataFrame, frame.frameType)
            XCTAssertEqual(Data([]), frame.payload)
        }
        
        frame = KissFrame(port: 2, payload: Data([]))
        XCTAssertNotNil(frame)
    }

    func testRoundTrips() {
        // TODO: figure out a better way to loop over cases like this?
        let framesToRoundTrip: [KissFrame?] = [
            KissFrame(fromData: Data([KissFrame.FEND, 0x00, 0x00, 0x01, 0x02, 0x03, KissFrame.FEND])),
            KissFrame(fromData: Data([KissFrame.FEND, 0x00, KissFrame.FESC, KissFrame.TFEND, KissFrame.FEND])),
            KissFrame(ofType: .DataFrame, port: 0, payload: Data([KissFrame.FEND, KissFrame.FESC])),
        ]
        for frame in framesToRoundTrip {
            XCTAssertNotNil(frame)
            guard let frame = frame else {
                continue
            }
            guard let frame2 = KissFrame(ofType: frame.frameType, port: frame.port, payload: frame.payload) else {
                XCTFail()
                continue
            }
            
            guard let frame3 = KissFrame(fromData: frame2.frame()) else {
                XCTFail()
                continue
            }

            XCTAssertEqual(frame2.frame(), frame.frame(), "they're all the same")
            XCTAssertEqual(frame3.frame(), frame.frame(), "they're all the same")
        }
    }
    
    func testInvalidFrames() {
        // empty frame
        var frame = KissFrame(fromData: Data([KissFrame.FEND, KissFrame.FEND]))
        XCTAssertNil(frame)
        
        // emptier frame
        frame = KissFrame(fromData: Data([]))
        XCTAssertNil(frame)
        
        frame = KissFrame(ofType: .DataFrame, port: 122, payload: Data([]))
        XCTAssertNil(frame)
    }
    
    func testDataFrameInitializers() {
        let frame = KissFrame(data: Data([]))
        XCTAssertNotNil(frame)
        if let frame = frame {
            XCTAssertEqual(KissFrame.FrameType.DataFrame, frame.frameType)
        }
    }
    
    func testFullDuplexInitializers() {
        var frame = KissFrame(fullDuplex: true)
        XCTAssertNotNil(frame)
        if let frame = frame {
            XCTAssertEqual(KissFrame.FrameType.FullDuplex, frame.frameType)
            XCTAssertEqual(Data([0x01]), frame.payload)
        }
        
        frame = KissFrame(fullDuplex: false)
        XCTAssertNotNil(frame)
        if let frame = frame {
            XCTAssertEqual(KissFrame.FrameType.FullDuplex, frame.frameType)
            XCTAssertEqual(Data([0x00]), frame.payload)
        }
    }
    
    func testTxDelayInitializers() {
        let frame = KissFrame(txDelay: 42)
        XCTAssertNotNil(frame)
        if let frame = frame {
            XCTAssertEqual(KissFrame.FrameType.TXDelay, frame.frameType)
            XCTAssertEqual(Data([42]), frame.payload)
        }
    }
    
    func testPInitializers() {
        let frame = KissFrame(p: 42)
        XCTAssertNotNil(frame)
        if let frame = frame {
            XCTAssertEqual(KissFrame.FrameType.P, frame.frameType)
            XCTAssertEqual(Data([42]), frame.payload)
        }
    }
    
    func testSlotTimeInitializers() {
        let frame = KissFrame(slotTime: 42)
        XCTAssertNotNil(frame)
        if let frame = frame {
            XCTAssertEqual(KissFrame.FrameType.SlotTime, frame.frameType)
            XCTAssertEqual(Data([42]), frame.payload)
        }
    }
    
    func testSetHardwareInitializers() {
        let frame = KissFrame(setHardware: Data([0x01, 0x02]))
        XCTAssertNotNil(frame)
        if let frame = frame {
            XCTAssertEqual(KissFrame.FrameType.SetHardware, frame.frameType)
            XCTAssertEqual(Data([0x01, 0x02]), frame.payload)
        }
    }
    
    func setReturnInitializer() {
        let frame = KissFrame(return: 42)
        XCTAssertEqual(KissFrame.FrameType.Return, frame.frameType)
    }
}
