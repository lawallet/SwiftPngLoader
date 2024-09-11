//
//  PngInfo.swift
//
//
//  Created by Richard Perry on 9/8/24.
//

import Foundation

enum PngSavingError: LocalizedError {
    case failed
    
    var errorDescription: String? {
        switch self {
        case .failed:
            "PNG failed to save"
        }
    }
    
    var failureReason: String? {
        switch self {
        case.failed:
            "PNG could not be saved at wanted location"
        }
    }
}
class PngInfo {
    let ihdrChunk: PngSection
    let idatChunk: [PngSection]
    let iendChunk: PngSection
    let plteChunk: PngSection?
    let chrmChunk: PngSection?
    let gamaChunk: PngSection?
    let iccpChunk: PngSection?
    let sbitChunk: PngSection?
    let srgbChunk: PngSection?
    let bkgdChunk: PngSection?
    let histChunk: PngSection?
    let trnsChunk: PngSection?
    let physChunk: PngSection?
    let spltChunk: [PngSection]?
    let timeChunk: PngSection?
    let itxtChunk: [PngSection]?
    let textChunk: [PngSection]?
    let ztxtChunk: [PngSection]?
    let nonstandardChunks: [String: PngSection]?
    
    init?(pngPath: URL, validateCrc: Bool = true) {
        
        var ihdrChunk: PngSection?
        var idatChunk: [PngSection]?
        var iendChunk: PngSection?
        var plteChunk: PngSection?
        var chrmChunk: PngSection?
        var gamaChunk: PngSection?
        var iccpChunk: PngSection?
        var sbitChunk: PngSection?
        var srgbChunk: PngSection?
        var bkgdChunk: PngSection?
        var histChunk: PngSection?
        var trnsChunk: PngSection?
        var physChunk: PngSection?
        var spltChunk: [PngSection]?
        var timeChunk: PngSection?
        var itxtChunk: [PngSection]?
        var textChunk: [PngSection]?
        var ztxtChunk: [PngSection]?
        var nonstandardChunks: [String: PngSection]?
        
        do {
            let handle = try FileHandle(forReadingFrom: pngPath)
            defer {
                try? handle.close()
            }
            let endOfFile = try handle.seekToEnd()
            try handle.seek(toOffset: 0)
            let readBytes = try handle.read(upToCount: 8)
            if readBytes?.count ?? 0 < 8 {
                return nil
            }
            let pngHeader:[UInt8] = [137, 80, 78, 71, 13, 10, 26, 10]
            let headerData = Data(bytes: pngHeader, count: pngHeader.count)
            if headerData != readBytes {
                return nil
            }
            var currOffset = try handle.offset()
            while currOffset < endOfFile {
                guard let currentSection = PngSection(fileHandle: handle) else {
                    return nil
                }
                if validateCrc {
                    let calcCrc = currentSection .calculateCrc()
                    if calcCrc != currentSection.CRC {
                        return nil
                    }
                }
                
                switch currentSection.chunkType {
                
                case .IHDR:
                    ihdrChunk = currentSection
                case .PLTE:
                    plteChunk = currentSection
                case .IDAT:
                    if idatChunk == nil {
                        idatChunk = []
                    }
                    idatChunk?.append(currentSection)
                case .IEND:
                    iendChunk = currentSection
                case .cHRM:
                    chrmChunk = currentSection
                case .gAMA:
                    gamaChunk = currentSection
                case .iCCP:
                    iccpChunk = currentSection
                case .sBIT:
                    sbitChunk = currentSection
                case .sRGB:
                    srgbChunk = currentSection
                case .bKGD:
                    bkgdChunk = currentSection
                case .hIST:
                    histChunk = currentSection
                case .tRNS:
                    trnsChunk = currentSection
                case .pHYs:
                    physChunk = currentSection
                case .sPLT:
                    if (spltChunk == nil) {
                        spltChunk = []
                    }
                    spltChunk?.append(currentSection)
                case .tIME:
                    timeChunk = currentSection
                case .iTXt:
                    if itxtChunk == nil {
                        itxtChunk = []
                    }
                    itxtChunk?.append(currentSection)
                case .tEXt:
                    if textChunk == nil {
                        textChunk = []
                    }
                    textChunk?.append(currentSection)
                case .zTXt:
                    if ztxtChunk == nil {
                        ztxtChunk = []
                    }
                    ztxtChunk?.append(currentSection)
                case .unknown:
                    if nonstandardChunks == nil {
                        nonstandardChunks = [:]
                    }
                    nonstandardChunks?[currentSection.rawChunkType] = currentSection
                }

                currOffset = try handle.offset()
            }
        } catch {
            return nil
        }
        
        // IHDR, IDAT, and IEND chunks are required to be in a PNG
        guard let hdrChunk = ihdrChunk, let datChunk = idatChunk, let endChunk = iendChunk else {
            return nil
        }

        self.ihdrChunk = hdrChunk
        self.idatChunk = datChunk
        self.iendChunk = endChunk
        self.plteChunk = plteChunk
        self.chrmChunk = chrmChunk
        self.gamaChunk = gamaChunk
        self.iccpChunk = iccpChunk
        self.sbitChunk = sbitChunk
        self.srgbChunk = srgbChunk
        self.bkgdChunk = bkgdChunk
        self.histChunk = histChunk
        self.trnsChunk = trnsChunk
        self.physChunk = physChunk
        self.spltChunk = spltChunk
        self.timeChunk = timeChunk
        self.itxtChunk = itxtChunk
        self.textChunk = textChunk
        self.ztxtChunk = ztxtChunk
        self.nonstandardChunks = nonstandardChunks
    }
    
    func writePngToDisk(location: URL) throws {
        
        let pngHeader:[UInt8] = [137, 80, 78, 71, 13, 10, 26, 10]
        // Write PNG header infor first (unless you're Apple somehow)
        
        var pngData = Data(bytes: pngHeader, count: pngHeader.count)
        // IHDR chunk must be first
        let iHdrData = ihdrChunk.createData()
        pngData.append(iHdrData)
        // If this PNG is Apple's compressed format add them in.
        // To modify the data chunks the hdr and idat chunks must be decompressed and these removed
        if let cgbiChunk = nonstandardChunks?["CgBI"] {
            pngData.append(cgbiChunk.createData())
        }
        if let idotChunk = nonstandardChunks?["iDOT"] {
            pngData.append(idotChunk.createData())
        }
        // cHRM, gAMA, iCCP, sBIT, sRGB chunks must come before PLTE and IDAT chunks
        if let chrChunk = chrmChunk {
            pngData.append(chrChunk.createData())
        }
        if let gamChunk = gamaChunk {
            pngData.append(gamChunk.createData())
        }
        if let iccChunk = iccpChunk {
            pngData.append(iccChunk.createData())
        }
        if let srgChunk = srgbChunk {
            pngData.append(srgChunk.createData())
        }
        if let sbiChunk = sbitChunk {
            pngData.append(sbiChunk.createData())
        }
        // PLTE chunk must come before IDAT if present
        if let pltChunk = plteChunk {
            pngData.append(pltChunk.createData())
        }
        // bKGD, hIST, tRNS chunks must come after PLTE and before IDAT chunks
        if let bkgChunk = bkgdChunk {
            pngData.append(bkgChunk.createData())
        }
        if let hisChunk = histChunk {
            pngData.append(hisChunk.createData())
        }
        if let trnChunk = trnsChunk {
            pngData.append(trnChunk.createData())
        }
        // pHYs and sPLT chunks must come before IDAT chunks
        if let phyChunk = physChunk {
            pngData.append(phyChunk.createData())
        }
        if let splChunk = spltChunk {
            for chunk in splChunk {
                pngData.append(chunk.createData())
            }
        }
        for chunk in idatChunk {
            pngData.append(chunk.createData())
        }
        if let timChunk = timeChunk {
            pngData.append(timChunk.createData())
        }
        if let itxChunk = itxtChunk {
            for chunk in itxChunk {
                pngData.append(chunk.createData())
            }
        }
        if let texChunk = textChunk {
            for chunk in texChunk {
                pngData.append(chunk.createData())
            }
        }
        if let ztxChunk = ztxtChunk {
            for chunk in ztxChunk {
                pngData.append(chunk.createData())
            }
        }
        // IEND chunk must be last
        pngData.append(iendChunk.createData())
        
        let writePath: String
        if #available(iOS 16.0, *) {
            writePath = location.path()
        } else {
            writePath = location.path
        }
        
        let created = FileManager.default.createFile(atPath: writePath, contents: pngData)
        if !created {
            throw PngSavingError.failed
        }
    }
    
    
    
    
}
