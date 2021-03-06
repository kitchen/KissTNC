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
        var frame: KissFrame?
        frame = try? KissFrame(fromData: Data(base64Encoded: "wACEioKGnpxgrm6YqEBAdQPwUEFSQyBXSU5MSU5LIEdBVEVXQVkgT04gTVQgU0NPVFQsIENOODVSSywgUkVQRUFURVIgT04gMTQ2Ljg0IC02MDAsIElORk9AVzdMVC5PUkcNwA==")!)
        XCTAssertNotNil(frame)
        if let frame = frame {
            XCTAssertEqual(.DataFrame, frame.frameType, "the frameType is a data packet")
            XCTAssertEqual(0, frame.port, "the port is 0")
            XCTAssertEqual(97, frame.payload.count, "the length of the payload is 97")
            XCTAssertNotEqual(KissFrame.FEND, frame.payload.last, "we strip off the trailing FEND")
        }

        frame = try? KissFrame(fromData: Data([KissFrame.FEND, 0xff, KissFrame.FEND]))
        XCTAssertNotNil(frame)
        if let frame = frame {
            XCTAssertEqual(KissFrame.FrameType.Return, frame.frameType, "the frameType is end KISS")
            XCTAssertEqual(0x0f, frame.port, "the port is F")
            XCTAssertEqual(0, frame.payload.count, "there is no payload")
        }


        frame = try? KissFrame(fromData: Data([KissFrame.FEND, 0x00, KissFrame.FEND]))
        XCTAssertNotNil(frame)
        if let frame = frame {
            XCTAssertEqual(KissFrame.FrameType.DataFrame, frame.frameType)
            XCTAssertEqual(0, frame.payload.count)
        }

        frame = try? KissFrame(fromData: Data([KissFrame.FEND, 0x00, KissFrame.FESC, KissFrame.TFEND, KissFrame.FESC, KissFrame.TFESC, KissFrame.FEND]))
        XCTAssertNotNil(frame)
        if let frame = frame {
            XCTAssertEqual(Data([KissFrame.FEND, KissFrame.FESC]), frame.payload, "ensure we are properly unescaping")
        }

        frame = try? KissFrame(fromData: Data([KissFrame.FEND, 0x00, 0x01, 0x01, 0x01, KissFrame.FESC, KissFrame.TFEND, 0x01, 0x01, 0x01, KissFrame.FESC, KissFrame.TFESC, 0x01, 0x01, 0x01, 0x01, KissFrame.FEND]))
        XCTAssertNotNil(frame)
        if let frame = frame {
            XCTAssertEqual(Data([0x01, 0x01, 0x01, KissFrame.FEND, 0x01, 0x01, 0x01, KissFrame.FESC, 0x01, 0x01, 0x01, 0x01]), frame.payload)
        }

        // assume something already cut off the FENDs
        frame = try? KissFrame(fromData: Data([0x00, 0x01, 0x02, 0x03]))
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
        frame = try? KissFrame(fromData: Data([KissFrame.FEND, 0x00, 0x00, KissFrame.FESC, 0x00, 0x00, KissFrame.FEND]))
        XCTAssertNotNil(frame)
        if let frame = frame {
            XCTAssertEqual(Data([0x00,0x00,0x00]), frame.payload)
        }
        
        frame = try? KissFrame(fromData: Data([KissFrame.FEND, 0x00, KissFrame.FESC, KissFrame.FEND]))
        XCTAssertNotNil(frame)
    }


    func testGenerateFrames() {
        var frame: KissFrame?
        frame = try? KissFrame(ofType: .DataFrame, port: 0x00, payload: Data([0x00,0x01,0x02,0x03]))
        XCTAssertNotNil(frame)
        if let frame = frame {
            XCTAssertEqual(Data([KissFrame.FEND, 0x00, 0x00, 0x01, 0x02, 0x03, KissFrame.FEND]), frame.frame())
        }

        frame = try? KissFrame(ofType: .DataFrame, port: 0x00, payload: Data([KissFrame.FEND, KissFrame.FESC]))
        XCTAssertNotNil(frame)
        if let frame = frame {
            XCTAssertEqual(Data([KissFrame.FEND, 0x00, KissFrame.FESC, KissFrame.TFEND, KissFrame.FESC, KissFrame.TFESC, KissFrame.FEND]), frame.frame(), "ensure we are properly escaping")
        }

        frame = try? KissFrame(ofType: .DataFrame, port: 0x0C, payload: Data([0x00, 0x00, 0x00]))
        XCTAssertNotNil(frame)
        if let frame = frame {
            XCTAssertEqual(Data([KissFrame.FEND, KissFrame.FESC, KissFrame.TFEND, 0x00, 0x00, 0x00, KissFrame.FEND]), frame.frame(), "port 12 frameType 0 is 0xC0 and needs encoding")
        }
        
        frame = try? KissFrame(ofType: .DataFrame, port: 4)
        XCTAssertNotNil(frame)
        
        frame = try? KissFrame(payload: Data([]))
        XCTAssertNotNil(frame)
        
        frame = try? KissFrame()
        XCTAssertNotNil(frame)
        if let frame = frame {
            XCTAssertEqual(0, frame.port)
            XCTAssertEqual(.DataFrame, frame.frameType)
            XCTAssertEqual(Data([]), frame.payload)
        }
        
        frame = try? KissFrame(port: 2, payload: Data([]))
        XCTAssertNotNil(frame)
    }

    func testRoundTrips() {
        // TODO: figure out a better way to loop over cases like this?
        let framesToRoundTrip: [KissFrame?] = [
            try? KissFrame(fromData: Data([KissFrame.FEND, 0x00, 0x00, 0x01, 0x02, 0x03, KissFrame.FEND])),
            try? KissFrame(fromData: Data([KissFrame.FEND, 0x00, KissFrame.FESC, KissFrame.TFEND, KissFrame.FEND])),
            try? KissFrame(ofType: .DataFrame, port: 0, payload: Data([KissFrame.FEND, KissFrame.FESC])),
        ]
        for frame in framesToRoundTrip {
            XCTAssertNotNil(frame)
            guard let frame = frame else {
                continue
            }
            guard let frame2 = try? KissFrame(ofType: frame.frameType, port: frame.port, payload: frame.payload) else {
                XCTFail()
                continue
            }
            
            guard let frame3 = try? KissFrame(fromData: frame2.frame()) else {
                XCTFail()
                continue
            }

            XCTAssertEqual(frame, frame2)
            XCTAssertEqual(frame2, frame3)
        }
    }
    
    func testInvalidFrames() {
        // empty frame
        XCTAssertThrowsError(try KissFrame(fromData: Data([KissFrame.FEND, KissFrame.FEND]))) { error in
            // FIXME: would like to figure out how to properly test that we're throwing the right error
            // XCTAssertEqual(error, KissFrame.Errors.EmptyFrame)
        }

        // emptier frame
        XCTAssertThrowsError(try KissFrame(fromData: Data([]))) { error in
            // XCTAssertEqual(KissFrame.Errors.EmptyFrame, error)
        }

        
        XCTAssertThrowsError(try KissFrame(ofType: .DataFrame, port: 122, payload: Data([]))) { error in
            // XCTAssertEqual(KissFrame.Errors.InvalidPortNumber(122), error)
        }
    }
    
    func testDataFrameInitializers() {
        let frame = try? KissFrame(data: Data([]))
        XCTAssertNotNil(frame)
        if let frame = frame {
            XCTAssertEqual(KissFrame.FrameType.DataFrame, frame.frameType)
        }
    }
    
    func testFullDuplexInitializers() {
        var frame = try? KissFrame(fullDuplex: true)
        XCTAssertNotNil(frame)
        if let frame = frame {
            XCTAssertEqual(KissFrame.FrameType.FullDuplex, frame.frameType)
            XCTAssertEqual(Data([0x01]), frame.payload)
        }
        
        frame = try? KissFrame(fullDuplex: false)
        XCTAssertNotNil(frame)
        if let frame = frame {
            XCTAssertEqual(KissFrame.FrameType.FullDuplex, frame.frameType)
            XCTAssertEqual(Data([0x00]), frame.payload)
        }
    }
    
    func testTxDelayInitializers() {
        let frame = try? KissFrame(txDelay: 42)
        XCTAssertNotNil(frame)
        if let frame = frame {
            XCTAssertEqual(KissFrame.FrameType.TXDelay, frame.frameType)
            XCTAssertEqual(Data([42]), frame.payload)
        }
    }
    
    func testPInitializers() {
        let frame = try? KissFrame(P: 42)
        XCTAssertNotNil(frame)
        if let frame = frame {
            XCTAssertEqual(KissFrame.FrameType.P, frame.frameType)
            XCTAssertEqual(Data([42]), frame.payload)
        }
    }
    
    func testSlotTimeInitializers() {
        let frame = try? KissFrame(slotTime: 42)
        XCTAssertNotNil(frame)
        if let frame = frame {
            XCTAssertEqual(KissFrame.FrameType.SlotTime, frame.frameType)
            XCTAssertEqual(Data([42]), frame.payload)
        }
    }
    
    func testSetHardwareInitializers() {
        let frame = try? KissFrame(setHardware: Data([0x01, 0x02]))
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
    
    func testNonZeroStartIndex() {
        let frameData = Data([0x00, 0x00, 0x00, KissFrame.FEND, 0x00, 0x00, 0x00, KissFrame.FEND])
        guard let firstFENDIndex = frameData.firstIndex(of: KissFrame.FEND) else {
            XCTFail()
            return
        }
        XCTAssertNotEqual(0, firstFENDIndex, "make sure we are setting the scenario properly")
        let frameDataSlice = frameData.suffix(from: firstFENDIndex)
        let frame = try? KissFrame(fromData: frameDataSlice)
        XCTAssertEqual(Data([KissFrame.FEND, 0x00, 0x00, 0x00, KissFrame.FEND]), frameDataSlice)
        XCTAssertNotNil(frame)
        if let frame = frame {
            XCTAssertEqual(KissFrame.FrameType.DataFrame, frame.frameType)
            XCTAssertEqual(Data([0x00, 0x00]), frame.payload)
        }
    }
    
    func testMiddleOfData() {
        let frameData = Data([0x00, 0x00, 0x00, KissFrame.FEND, 0x00, 0x00, 0x00, KissFrame.FEND, 0x42, 0x42])
        guard let firstFENDIndex = frameData.firstIndex(of: KissFrame.FEND) else {
            XCTFail()
            return
        }
        XCTAssertNotEqual(0, firstFENDIndex, "make sure we are setting the scenario properly")
        let frameDataSlice = frameData.suffix(from: firstFENDIndex + 1).prefix(while: { $0 != KissFrame.FEND })
        XCTAssertEqual(Data([0x00, 0x00, 0x00]), frameDataSlice)
        let frame = try? KissFrame(fromData: frameDataSlice)
        XCTAssertNotNil(frame)
        if let frame = frame {
            XCTAssertEqual(KissFrame.FrameType.DataFrame, frame.frameType)
            XCTAssertEqual(Data([0x00, 0x00]), frame.payload)
        }
    }
}
