//
//  PNGChunkTypes.swift
//
//
//  Created by Richard Perry on 9/11/24.
//

import Foundation

enum PngHeaderTypes: String {
    case IHDR
    case PLTE
    case IDAT
    case IEND
    case cHRM
    case gAMA
    case iCCP
    case sBIT
    case sRGB
    case bKGD
    case hIST
    case tRNS
    case pHYs
    case sPLT
    case tIME
    case iTXt
    case tEXt
    case zTXt
    case unknown
}

enum PngParsingError: LocalizedError {
    case notPNG
    case general
    case noCharacterFound
    case malformedCharacter
    case emptyCharacter
    case copyError
    
    var errorDescription: String? {
        switch self {
        case .notPNG:
            return "Image is not a PNG"
        case .noCharacterFound:
            return "Image does not contain a character"
        case .malformedCharacter:
            return "Found character is invalid"
        case .emptyCharacter:
            return "Found character has no data"
        case .copyError:
            return "Unable to import PNG"
        default:
            return "There was a problem importing the character"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .notPNG:
            return "A PNG is required to import a character"
        case .noCharacterFound:
            return "PNG does not contain a character"
        case .malformedCharacter:
            return "Found character is not a valid v2 character"
        case .emptyCharacter:
            return "Found character has no information"
        case .copyError:
            return ""
        default:
            return ""
        }
    }
}
