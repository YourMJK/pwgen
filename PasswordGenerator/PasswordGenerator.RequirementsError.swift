//
//  PasswordGenerator.RequirementsError.swift
//  pwgen
//
//  Created by Max-Joseph on 18.07.23.
//

import Foundation

extension PasswordGenerator {
	public enum RequirementsError: LocalizedError {
		case moreCharacterSetsThanCharacters(requiredCharacterSetsCount: Int, numberOfCharacters: Int)
		case nicePasswordMissingAllowedCharacters
		case invalidRequiredCharacterSet
		case emptyCharacterPool
		
		private static let prefix = "Unable to meet requirements:"
		
		public var errorDescription: String? {
			switch self {
				case .moreCharacterSetsThanCharacters(let requiredCharacterSetsCount, let numberOfCharacters):
					return "\(Self.prefix) More required character sets (\(requiredCharacterSetsCount)) specified than number of password characters (\(numberOfCharacters)) to generate"
				case .nicePasswordMissingAllowedCharacters:
					return "\(Self.prefix) For a password of style \"nice\", allowed characters must contain a lowercase and uppercase consonant and vowel and a digit"
				case .invalidRequiredCharacterSet:
					return "\(Self.prefix) Intersection of a required character set with the allowed characters is empty. Allowed characters must contain at least one character of each required set"
				case .emptyCharacterPool:
					return "\(Self.prefix) No characters available to randomly choose from. Required character sets must include at least one non-empty set"
			}
		}
	}
}
