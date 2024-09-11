//
//  PngSection.swift
//
//
//  Created by Richard Perry on 6/28/24.
//

import Foundation

class PngSection {
    var length: UInt32
    // A 4 byte value. Should read this a byte at a time since PNG specs state you shouldn't read this as a string
    var chunkType: PngHeaderTypes
    var rawChunkType: String
    var chunkData: Data
    var CRC: UInt32
    
    init(length: UInt32, chunkType: PngHeaderTypes, rawChunkType: String, chunkData: Data, CRC: UInt32) {
        self.length = length
        self.chunkType = chunkType
        self.rawChunkType = rawChunkType
        self.chunkData = chunkData
        self.CRC = CRC
    }
    
    convenience init?(fileHandle: FileHandle) {
        do {
            guard let chunkLength = try fileHandle.read(upToCount: 4) else {
                return nil
            }
            var endianCorrectedChunkLength: UInt32 = 0
            chunkLength.withUnsafeBytes { rawBytes in
                let needToConvert = rawBytes.load(as: UInt32.self)
                // PNG data is stored in big endian format
                endianCorrectedChunkLength = needToConvert.bigEndian
                
            }
            guard let chunkType = try fileHandle.read(upToCount: 4) else {
                return nil
            }
            guard let convertedChunkType = String(data: chunkType, encoding: .utf8) else {
                return nil
            }
            let chunk = PngHeaderTypes(rawValue: convertedChunkType) ?? .unknown
            var chunkData: Data
            if endianCorrectedChunkLength > 0 {
                guard let chunkDat = try fileHandle.read(upToCount: Int(endianCorrectedChunkLength)) else {
                    return nil
                }
                chunkData = chunkDat
            } else {
                chunkData = Data()
            }
            guard let crcDat = try fileHandle.read(upToCount: 4) else {
                return nil
            }
            var crcVal: UInt32 = 0
            crcDat.withUnsafeBytes { rawBytes in
                crcVal = rawBytes.load(as: UInt32.self)
            }
            
            self.init(length: endianCorrectedChunkLength, chunkType: chunk, rawChunkType: convertedChunkType, chunkData: chunkData, CRC: crcVal)
                    
        } catch {
            return nil
        }
    }
    func updateCrc() {
        CRC = calculateCrc()
    }
    
    func calculateCrc() -> UInt32 {
        let chunkTypeArr: [UInt8] = Array(rawChunkType.utf8)
        let chunkDataArr: [UInt8] = chunkData.map({ $0 })
        let newCrc = crc(buf: chunkTypeArr + chunkDataArr)
        return newCrc.bigEndian
    }
    
    static private var crcTable: [UInt32] = []
    
    static private func makeCrcTable() -> [UInt32] {
        if crcTable.count == 0 {
            var c: UInt32 = 0
            for num:UInt32 in 0..<256 {
                c = num
                for _ in 0..<8 {
                    if ((c & 1) != 0) {
                        c = 0xedb88320 ^ (c >> 1)
                    } else {
                        c = c >> 1
                    }
                }
                crcTable.append(c)
            }
        }
        
        return crcTable
    }
    
    private func makeCrc(crc: UInt32, buf: [UInt8]) -> UInt32 {
        var c = crc
        let crcTable = PngSection.makeCrcTable()
        
        for num in 0..<buf.count {
            let leftSide: UInt32 = c ^ UInt32(buf[num])
            let fullNum:UInt32 = leftSide & 0xff
            c = crcTable[Int(fullNum)] ^ (c >> 8)
        }
        return c
    }
    
    private func crc(buf: [UInt8]) -> UInt32 {
        return makeCrc(crc: 0xffffffff, buf: buf) ^ 0xffffffff
    }
    
    func createData() -> Data {
        var dataStart = Data()
        let lengthBytes: [UInt8] = withUnsafeBytes(of: length.bigEndian, Array.init)
        let chunkTypeBytes: [UInt8] = Array(rawChunkType.utf8)
        let crcBytes: [UInt8] = withUnsafeBytes(of: CRC, Array.init)
        dataStart.append(contentsOf: lengthBytes + chunkTypeBytes)
        dataStart.append(chunkData)
        dataStart.append(contentsOf: crcBytes)
        return dataStart
    }
}
