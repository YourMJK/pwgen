//
//  CharacterSetString.swift
//  pwgen
//
//  Created by Max-Joseph on 26.07.23.
//

import Foundation
import ArgumentParser


enum CharacterSetString: String, CaseIterable {
	case lower
	case upper
	case digits
	case special
	case ascii
	case alphanum
	case unambiguous
	
	static func string(from characterSet: PasswordGenerator.CharacterSet) -> String {
		switch characterSet {
			case .lower: return Self.lower.rawValue
			case .upper: return Self.upper.rawValue
			case .digits: return Self.digits.rawValue
			case .special: return Self.special.rawValue
			case .ascii: return Self.ascii.rawValue
			case .alphanumeric: return Self.alphanum.rawValue
			case .unambiguous: return Self.unambiguous.rawValue
			default: return "[\(String(characterSet))]"
		}
	}
	
	var characterSet: PasswordGenerator.CharacterSet {
		try! Self.characterSet(from: rawValue)
	}
	
	static func characterSet(from string: String) throws -> PasswordGenerator.CharacterSet {
		switch string.lowercased() {
			case Self.lower.rawValue: return .lower
			case Self.upper.rawValue: return .upper
			case Self.digits.rawValue: return .digits
			case Self.special.rawValue: return .special
			case Self.ascii.rawValue: return .ascii
			case Self.alphanum.rawValue: return .alphanumeric
			case Self.unambiguous.rawValue: return .unambiguous
			default: break
		}
		
		guard string.hasPrefix("["), string.hasSuffix("]") else {
			throw ParsingError.unknownNamedCharacterSet(string: string)
		}
		let customCharacters = string.dropFirst().dropLast()
		return PasswordGenerator.CharacterSet(limitToASCII: customCharacters)
	}
	
	enum ParsingError: LocalizedError {
		case unknownNamedCharacterSet(string: String)
		
		var errorDescription: String? {
			switch self {
				case .unknownNamedCharacterSet(let string):
					return "No character set named \"\(string)\" found. To specify a custom set, surround a string of characters with [ and ]"
			}
		}
	}
}

