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
    var payload: Data
    
    init(_ data: Data) {
        if data[0] != KissFrame.FEND {
            // parse error
        }
        
        port = (data[1] & 0xf0) >> 4
        command = data[1] & 0x0f
        
        payload = data.suffix(from: 2).prefix(while: { $0 != KissFrame.FEND })
        // TODO: unescape FESC TFEND and FESC TFESC
    }
    
    init(port inputPort: UInt8, command inputCommand: UInt8, payload inputPayload: Data) {
        port = inputPort
        command = inputCommand
        payload = inputPayload
    }
    
    func frame() -> Data {
        var outputFrame = Data([KissFrame.FEND])
        outputFrame.append(port << 4 | command)
        outputFrame.append(payload) // TODO: escape FEND and FESC
        outputFrame.append(KissFrame.FEND)
        return outputFrame
    }
}
