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
    
    static let DataFrame: UInt8 = 0x00
    static let TXDelay: UInt8 = 0x01
    static let P: UInt8 = 0x02
    static let SlotTime: UInt8 = 0x03
    static let TXTail: UInt8 = 0x04
    static let FullDuplex: UInt8 = 0x05
    static let SetHardware: UInt8 = 0x06
    static let Return: UInt8 = 0x0F
    
    public var port: UInt8
    public var command: UInt8
    
    // payload contains unescaped data
    public var payload: Data!
    
    public convenience init?(_ data: Data) {
        var frameData = data
        if frameData[0] == KissFrame.FEND {
            frameData = frameData[1...]
        }
        frameData = frameData.prefix(while: { $0 != KissFrame.FEND })
        
        guard let decodedFrameData = KissFrame.decode(frameData) else {
            return nil
        }
        
        let port = (decodedFrameData[decodedFrameData.startIndex] & 0xf0) >> 4
        let command = decodedFrameData[decodedFrameData.startIndex] & 0x0f
        
        let payload = decodedFrameData[(decodedFrameData.startIndex + 1)...]
        self.init(port: port, command: command, payload: payload)
    }
    
    public init(port: UInt8, command: UInt8, payload: Data) {
        self.port = port
        self.command = command
        self.payload = payload
    }
    
    public func frame() -> Data {
        var outputFrame = Data([KissFrame.FEND])
        outputFrame.append(KissFrame.encode(Data([port << 4 | command])))
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
