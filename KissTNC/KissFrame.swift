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
    static let FEND: UInt8 = 0xC0
    static let FESC: UInt8 = 0xDB
    static let TFEND: UInt8 = 0xDC
    static let TFESC: UInt8 = 0xDD
    
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
    
    public let port: UInt8
    public let frameType: FrameType
    
    // payload contains unescaped data
    public let payload: Data
    
    public convenience init?(_ data: Data) {
        var frameData = data
        if frameData.first == KissFrame.FEND {
            frameData = frameData.suffix(from: frameData.startIndex + 1)
        }
        frameData = frameData.prefix(while: { $0 != KissFrame.FEND })
        
        guard let decodedFrameData = KissFrame.decode(frameData) else {
            return nil
        }
        
        guard let portFrameTypeField = decodedFrameData.first else {
            return nil
        }

        let port = (portFrameTypeField & 0xf0) >> 4
        guard let frameType = FrameType(rawValue: portFrameTypeField & 0x0f) else {
            return nil
        }
        
        let payload = decodedFrameData.suffix(from: decodedFrameData.startIndex + 1)
        self.init(port: port, frameType: frameType, payload: payload)
    }
    
    public convenience init(ofType frameType: FrameType, port: UInt8, payload: Data) {
        self.init(port: port, frameType: frameType, payload: payload)
    }
    
    public init(port: UInt8, frameType: FrameType, payload: Data) {
        self.port = port
        self.frameType = frameType
        self.payload = payload
    }
    
    public func frame() -> Data {
        var outputFrame = Data([KissFrame.FEND])
        outputFrame.append(KissFrame.encode(Data([port << 4 | frameType.rawValue])))
        outputFrame.append(KissFrame.encode(payload))
        outputFrame.append(KissFrame.FEND)
        return outputFrame
    }

    private static func decode(_ payload: Data) -> Data? {
        if payload.firstIndex(of: KissFrame.FESC) != nil { // short circuit if there's nothing to decode
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
                        return nil
                    }
                } else {
                    newData.append(byte)
                }
            }
            return newData
        } else {
            return payload
        }
    }
    
    private static func encode(_ payload: Data) -> Data {
        if payload.first(where: { $0 == KissFrame.FEND || $0 == KissFrame.FESC }) != nil { // short circuit if there's nothing to encode
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
        } else {
            return payload
        }
    }
}
