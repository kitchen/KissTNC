//
//  KissFrame.swift
//  KissTNC
//
//  Created by Jeremy Kitchen on 5/21/19.
//  Copyright © 2019 Jeremy Kitchen. All rights reserved.
//
import Foundation

public class KissFrame {
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
    
    public convenience init?(fromData data: Data) {
        var frameData = data
        if frameData.first == KissFrame.FEND {
            frameData = frameData.suffix(from: frameData.startIndex + 1)
        }
        frameData = frameData.prefix(while: { $0 != KissFrame.FEND })
        
        let decodedFrameData = KissFrame.decode(frameData)
        guard let portFrameTypeField = decodedFrameData.first else {
            return nil
        }

        let port = (portFrameTypeField & 0xf0) >> 4
        guard let frameType = FrameType(rawValue: portFrameTypeField & 0x0f) else {
            return nil
        }
        
        let payload = decodedFrameData.suffix(from: decodedFrameData.startIndex + 1)
        self.init(ofType: frameType, port: port, payload: payload)
    }
    
    
    public convenience init?(data: Data, port: UInt8 = 0) {
        self.init(ofType: .DataFrame, port: port, payload: data)
    }
    
    public convenience init?(txDelay: UInt8, port: UInt8 = 0) {
        self.init(ofType: .TXDelay, port: port, payload: Data([txDelay]))
    }
    
    public convenience init?(P: UInt8, port: UInt8 = 0) {
        self.init(ofType: .P, port: port, payload: Data([P]))
    }
    
    public convenience init?(slotTime: UInt8, port: UInt8 = 0) {
        self.init(ofType: .SlotTime, port: port, payload: Data([slotTime]))
    }
    
    @available(*, deprecated, message: "obsolete according to spec, only here for compatibility")
    public convenience init?(txTail: UInt8, port: UInt8 = 0) {
        self.init(ofType: .TXTail, port: port, payload: Data([txTail]))
    }

    public convenience init?(fullDuplex: Bool, port: UInt8 = 0) {
        self.init(ofType: .FullDuplex, port: port, payload: Data([fullDuplex ? 1 : 0]))
    }

    public convenience init?(setHardware: Data, port: UInt8 = 0) {
        self.init(ofType: .SetHardware, port: port, payload: setHardware)
    }
    
    public convenience init(return: Any) {
        self.init(type: .Return, port: 0xf)
    }

    public convenience init?(ofType frameType: FrameType = .DataFrame, port: UInt8 = 0, payload: Data = Data([])) {
        guard port <= 15 else {
            print("guard condition failed")
            return nil
        }
        self.init(type: frameType, port: port, payload: payload)
    }

    private init(type frameType: FrameType, port: UInt8 = 0, payload: Data = Data([])) {
        self.frameType = frameType
        self.port = port
        self.payload = payload
    }

    public func frame() -> Data {
        var outputFrame = Data([KissFrame.FEND])
        outputFrame.append(KissFrame.encode(Data([port << 4 | frameType.rawValue])))
        outputFrame.append(KissFrame.encode(payload))
        outputFrame.append(KissFrame.FEND)
        return outputFrame
    }

    private static func decode(_ data: Data) -> Data {
        guard data.firstIndex(of: KissFrame.FESC) != nil else {
            return data
        }
        var newData = Data()
        var iterator = data.makeIterator()
        while let byte = iterator.next() {
            guard byte == KissFrame.FESC else {
                newData.append(byte)
                continue
            }
            
            guard let nextByte = iterator.next() else {
                continue
            }
            
            switch nextByte {
            case KissFrame.TFEND:
                newData.append(KissFrame.FEND)
            case KissFrame.TFESC:
                newData.append(KissFrame.FESC)
            default:
                newData.append(nextByte)
            }
        }
        return newData
    }

    private static func encode(_ data: Data) -> Data {
        guard data.first(where: { $0 == KissFrame.FEND || $0 == KissFrame.FESC }) != nil else {
            return data
        }
        var newData = Data()
        var iterator = data.makeIterator()
        while let byte = iterator.next() {
            switch byte {
            case KissFrame.FEND:
                newData.append(contentsOf: [KissFrame.FESC, KissFrame.TFEND])
            case KissFrame.FESC:
                newData.append(contentsOf: [KissFrame.FESC, KissFrame.TFESC])
            default:
                newData.append(byte)
            }
        }
        return newData
    }
}

extension KissFrame: Equatable {
    public static func == (lhs: KissFrame, rhs: KissFrame) -> Bool {
        return
            lhs.frameType == rhs.frameType &&
            lhs.port == rhs.port &&
            lhs.payload == rhs.payload
    }
}
