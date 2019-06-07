//
//  KissFrame.swift
//  KissTNC
//
//  Created by Jeremy Kitchen on 5/21/19.
//  Copyright © 2019 Jeremy Kitchen. All rights reserved.
//
import Foundation

public class KissFrame {
    // TODO: Equatable protocol
    // UInt8 is effectively a byte, and when you Data(...)![0] it returns a UInt8
    static let FEND: UInt8 = 0xC0
    static let FESC: UInt8 = 0xDB
    static let TFEND: UInt8 = 0xDC
    static let TFESC: UInt8 = 0xDD
    // If the FEND or FESC codes appear in the data to be transferred, they need to be escaped. The FEND code is then sent as FESC, TFEND and the FESC is then sent as FESC, TFESC.
    // I think this means after I pull the FENDs out I need to s/FESCTFEND/FEND/ and s/FESCTFESC/FESC/
    
    // convert to enum of frame types?
    public enum FrameType: UInt8 {
        case DataFrame = 0x00
        case TXDelay = 0x01
        case P = 0x02
        case SlotTime = 0x03
        case TXTail = 0x04
        case FullDuplex = 0x05
        case SetHardware = 0x06
        case Return = 0x0F

    }
    
    public var port: UInt8
    public var frameType: FrameType
    
    // payload contains unescaped data
    public var payload: Data!
    
    public init(ofType type: FrameType, port inputPort: UInt8, payload inputPayload: Data) {
        port = inputPort
        frameType = type
        payload = inputPayload
    }
    
    public convenience init?(_ data: Data) {
        var offset = 0
        if data[0] == KissFrame.FEND {
            offset = 1
        }
        
        let frameData = KissFrame.decode(data.suffix(from: offset).prefix(while: { $0 != KissFrame.FEND }))
        
        let port = (frameData[0] & 0xf0) >> 4
        guard let frameType = FrameType(rawValue: frameData[0] & 0x0f) else {
            return nil
        }
        
        let payload = KissFrame.decode(frameData.suffix(from: 1))
        self.init(ofType: frameType, port: port, payload: payload)
    }

    
    public func frame() -> Data {
        var outputFrame = Data([KissFrame.FEND])
        outputFrame.append(KissFrame.encode(Data([port << 4 | frameType.rawValue])))
        outputFrame.append(KissFrame.encode(payload))
        outputFrame.append(KissFrame.FEND)
        return outputFrame
    }

    private static func decode(_ payload: Data) -> Data {
        var newData = Data()
        var iterator = payload.makeIterator()
        while let byte = iterator.next() {
            if byte == KissFrame.FESC {
                let nextByte = iterator.next()
                if nextByte == KissFrame.TFEND {
                    newData.append(KissFrame.FEND)
                } else if nextByte == KissFrame.TFESC {
                    newData.append(KissFrame.FESC)
                } else {
                    // decoding error
                }
            } else {
                newData.append(byte)
            }
        }
        return newData
    }
    
    private static func encode(_ payload: Data) -> Data {
        var newData = Data()
        var iterator = payload.makeIterator()
        while let byte = iterator.next() {
            if byte == KissFrame.FEND {
                newData.append(contentsOf: [KissFrame.FESC, KissFrame.TFEND])
            } else if byte == KissFrame.FESC {
                newData.append(contentsOf: [KissFrame.FESC, KissFrame.TFESC])
            } else {
                newData.append(byte)
            }
        }
        return newData
    }
}
