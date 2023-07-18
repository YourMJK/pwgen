//
//  PasswordGenerator.RequirementsError.swift
//  pwgen
//
//  Created by Max-Joseph on 18.07.23.
//

import Foundation

extension PasswordGenerator {
	enum RequirementsError: LocalizedError {
		case moreCharacterSetsThanCharacters(requiredCharacterSetsCount: Int, numberOfCharacters: Int)
		case nicePasswordMissingAllowedCharacters
		
		private static let prefix = "Unable to meet requirements:"
		
		var errorDescription: String? {
			switch self {
				case .moreCharacterSetsThanCharacters(let requiredCharacterSetsCount, let numberOfCharacters):
					return "\(Self.prefix) More required character sets (\(requiredCharacterSetsCount)) specified than number of password characters (\(numberOfCharacters)) to generate"
				case .nicePasswordMissingAllowedCharacters:
					return "\(Self.prefix) For a password of style \"nice\", allowed characters must contain a lowercase and uppercase consonant and vowel and a digit"
			}
		}
	}
}
