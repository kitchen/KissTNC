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
    
    static let DataFrame: UInt8 = 0x00
    static let TXDelay: UInt8 = 0x01
    static let P: UInt8 = 0x02
    static let SlotTime: UInt8 = 0x03
    static let TXTail: UInt8 = 0x04
    static let FullDuplex: UInt8 = 0x05
    static let SetHardware: UInt8 = 0x06
    static let Return: UInt8 = 0x0F
    
    var port: UInt8
    var command: UInt8
    
    // payload contains unescaped data
    var payload: Data!
    
    init(_ data: Data) {
        if data[0] != KissFrame.FEND {
            // parse error
        }
        
        port = (data[1] & 0xf0) >> 4
        command = data[1] & 0x0f
        
        payload = decode(data.suffix(from: 2).prefix(while: { $0 != KissFrame.FEND }))
    }
    
    init(port inputPort: UInt8, command inputCommand: UInt8, payload inputPayload: Data) {
        port = inputPort
        command = inputCommand
        payload = inputPayload
    }
    
    func frame() -> Data {
        var outputFrame = Data([KissFrame.FEND])
        outputFrame.append(port << 4 | command)
        outputFrame.append(encode(payload))
        outputFrame.append(KissFrame.FEND)
        return outputFrame
    }
    
    private func decode(_ payload: Data) -> Data {
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
    
    private func encode(_ payload: Data) -> Data {
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
