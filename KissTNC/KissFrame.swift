//
//  KissFrame.swift
//  KissTNC
//
//  Created by Jeremy Kitchen on 5/21/19.
//  Copyright © 2019 Jeremy Kitchen. All rights reserved.
//
import Foundation

public struct KissFrame: Equatable {
    static let FEND: UInt8 = 0xC0
    static let FESC: UInt8 = 0xDB
    static let TFEND: UInt8 = 0xDC
    static let TFESC: UInt8 = 0xDD
    
    enum RawFrameType: UInt8 {
        case DataFrame = 0x00
        case TXDelay = 0x01
        case P = 0x02
        case SlotTime = 0x03
        case TXTail = 0x04
        case FullDuplex = 0x05
        case SetHardware = 0x06
        case Return = 0x0F
    }
    
    public enum FrameType: Equatable {
        case DataFrame(Data)
        case TXDelay(UInt8)
        case P(UInt8)
        case SlotTime(UInt8)
        case TXTail(UInt8)
        case FullDuplex(Bool)
        case SetHardware(Data)
        case Return
        
        init(_ type: UInt8, _ payload: Data) throws {
            guard let frameType = RawFrameType(rawValue: type) else {
                throw Error.InvalidFrameType(type)
            }
            
            self.init(frameType, payload)
        }

        init(_ type: RawFrameType, _ payload: Data) {
            switch type {
            case .DataFrame:
                self = .DataFrame(payload)
            case .TXDelay:
                self = .TXDelay(UInt8(payload[0]))
            case .P:
                self = .P(UInt8(payload[0]))
            case .SlotTime:
                self = .SlotTime(UInt8(payload[0]))
            case .TXTail:
                self = .TXTail(UInt8(payload[0]))
            case .FullDuplex:
                self = .FullDuplex(Bool(payload[0] == 0 ? false : true))
            case .SetHardware:
                self = .SetHardware(payload)
            case .Return:
                self = .Return
            }
        }
        
        var trueRawFrameType: RawFrameType {
            switch self {
            case .DataFrame:
                return .DataFrame
            case .TXDelay:
                return .TXDelay
            case .P:
                return .P
            case .SlotTime:
                return .SlotTime
            case .TXTail:
                return .TXTail
            case .FullDuplex:
                return .FullDuplex
            case .SetHardware:
                return .SetHardware
            case .Return:
                return .Return
            }
        }
            
        public var rawFrameType: UInt8 {
            return trueRawFrameType.rawValue
        }
        
    }
    
    public let port: UInt8
    public let type: FrameType
    
    public init(_ port: UInt8, _ type: FrameType) throws {
        guard port <= 15 else {
            throw Error.InvalidPortNumber(port)
        }
        self.port = port
        self.type = type
    }
    
    public init(_ type: FrameType, _ port: UInt8 = 0x00) throws {
        try self.init(port, type)
    }
    
    // TODO: change this to use Codable and write a Coder
    public init(fromData data: Data) throws {
        var frameData = data
        if frameData.first == KissFrame.FEND {
            frameData = frameData.suffix(from: frameData.startIndex + 1)
        }
        frameData = frameData.prefix(while: { $0 != KissFrame.FEND })
        
        let decodedFrameData = KissFrame.decode(frameData)
        guard let portFrameTypeField = decodedFrameData.first else {
            throw Error.EmptyFrame
        }

        let port = (portFrameTypeField & 0xf0) >> 4
        let frameTypeValue = portFrameTypeField & 0x0f
        
        let payload = decodedFrameData.suffix(from: decodedFrameData.startIndex + 1)
        let type = try FrameType(frameTypeValue, payload)
        
        try self.init(port, type)
    }
    
    public var payload: Data {
        switch self.type {
        case .DataFrame(let data), .SetHardware(let data):
            return data
        case .FullDuplex(let fullDuplex):
            return fullDuplex ? Data([0x01]) : Data([0x00])
        case let .P(num), let .SlotTime(num), let .TXTail(num), let .TXDelay(num):
            return Data([num])
        case .Return:
            return Data([])
        }
    }
    
    public var frame: Data {
        var outputFrame = Data([KissFrame.FEND])
        outputFrame.append(KissFrame.encode(Data([port << 4 | self.type.rawFrameType])))
        outputFrame.append(KissFrame.encode(payload))
        outputFrame.append(KissFrame.FEND)
        return outputFrame
    }


    // TODO: change to Codable
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

    // TODO: change to codable
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


public enum Error: Swift.Error {
    case EmptyFrame
    case InvalidFrameType(_ frameType: UInt8)
    case InvalidPortNumber(_ portNumber: UInt8)
}
