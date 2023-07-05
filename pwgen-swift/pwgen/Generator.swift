//
//  Generator.swift
//  pwgen
//
//  Created by Max-Joseph on 01.07.23.
//  Ported from JavaScript code at https://developer.apple.com/password-rules/scripts/generator.js
//

import Foundation

struct Generator {
	static let defaultUnambiguousCharacters = [Character]("abcdefghijkmnopqrstuvwxyzABCDEFGHIJKLMNPQRSTUVWXYZ0123456789")
	
	static let defaultNumberOfCharactersForClassicPassword = 12
	static let defaultClassicPasswordLength = 15
	
	static let defaultNumberOfCharactersForMoreTypeablePassword = 18
	static let defaultMoreTypeablePasswordLength = 20
	static let defaultAllowedNumbers = [Character]("0123456789")
	static let defaultAllowedLowercaseConsonants = [Character]("bcdfghjkmnpqrstvwxz")
	static let defaultAllowedLowercaseVowels = [Character]("aeiouy")
	
	private static let lowercaseCharacterSet = Set<Character>("abcdefghijklmnopqrstuvwxyz")
	private static let uppercaseCharacterSet = Set<Character>("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
	private static let numberCharacterSet = Set<Character>("0123456789")
	static let defaultRequiredCharacterSets = [lowercaseCharacterSet, uppercaseCharacterSet, numberCharacterSet]
	
	
	private typealias CharacterCollection = Collection<Character>
	
	struct Requirements {
		let passwordMinLength: Int?
		let passwordMaxLength: Int?
		let passwordAllowedCharacters: [Character]?
		let passwordRequiredCharacters: [Set<Character>]?
		let passwordRepeatedCharacterLimit: Int?
		let passwordConsecutiveCharacterLimit: Int?
	}
	
	private enum PasswordGenerationStyle {
		case classic
		case classicWithoutDashes
		case moreTypeable
		case moreTypeableWithoutDashes
	}
	
	private struct PasswordGenerationParameters {
		let passwordGenerationStyle: PasswordGenerationStyle
		let numberOfRequiredRandomCharacters: Int?
		let passwordAllowedCharacters: [Character]?
		let requiredCharacterSets: [Set<Character>]?
	}
	
	func randomNumberWithUniformDistribution(range: Int) -> Int {
		// Based on the algorithn described in https://pthree.org/2018/06/13/why-the-multiply-and-floor-rng-method-is-biased/
		let range = UInt64(range)
		let max = (UInt64(1 << 32) / range) * range;
		var x: UInt64
		var srng = SystemRandomNumberGenerator()
		repeat {
			x = srng.next() & UInt64(UInt32.max)  // Get random 32 bit value
		} while (x >= max);
		
		return Int(x % range);
	}
	
	func randomCharacter(in array: [Character]) -> [Character] {
		let index = randomNumberWithUniformDistribution(range: array.count);
		return [array[index]];
	}
	
	func randomConsonant() -> [Character] {
		randomCharacter(in: Self.defaultAllowedLowercaseConsonants)
	}
	
	func randomVowel() -> [Character] {
		randomCharacter(in: Self.defaultAllowedLowercaseVowels)
	}
	
	func randomNumber() -> [Character] {
		randomCharacter(in: Self.defaultAllowedNumbers)
	}
	
	func randomSyllable() -> [Character] {
		randomConsonant() + randomVowel() + randomConsonant()
	}
	
	private func moreTypeablePassword() -> [Character] {
		var password = randomSyllable() + randomSyllable() + randomSyllable() + randomSyllable() + randomSyllable() + randomConsonant() + randomVowel()
		let length = password.count
		while true {
			let index = randomNumberWithUniformDistribution(range: length)
			let lowercaseChar = password[index]
			if lowercaseChar == "o" {
				continue
			}
			
			let uppercaseChars = lowercaseChar.uppercased()
			password.replaceSubrange(index...index, with: uppercaseChars)
			
			let numberPos = randomNumberWithUniformDistribution(range: 5)
			let passwordSegment1 = password[0..<6]
			let passwordSegment2 = password[6..<12]
			let passwordSegment3 = password[12...]
			switch numberPos {
				case 0: return passwordSegment3 + randomNumber() + passwordSegment1 + passwordSegment2
				case 1: return passwordSegment1 + randomNumber() + passwordSegment3 + passwordSegment2
				case 2: return passwordSegment1 + passwordSegment3 + randomNumber() + passwordSegment2
				case 3: return passwordSegment1 + passwordSegment2 + randomNumber() + passwordSegment3
				case 4: return passwordSegment1 + passwordSegment2 + passwordSegment3 + randomNumber()
				default: fatalError()
			}
		}
	}
	
	private func classicPassword(numberOfRequiredRandomCharacters: Int, allowedCharacters: [Character]) -> [Character] {
		let length = allowedCharacters.count
		var randomCharArray = [Character]()
		for _ in 0..<numberOfRequiredRandomCharacters {
			let index = randomNumberWithUniformDistribution(range: length)
			randomCharArray.append(allowedCharacters[index])
		}
		return randomCharArray
	}
	
	private func passwordHasNotExceededConsecutiveCharLimit(password: [Character], consecutiveCharLimit: Int) -> Bool {
		let passwordUnicodeScalars = password.flatMap(\.unicodeScalars).map(\.value)
		var longestConsecutiveCharLength = 1
		var firstConsecutiveCharIndex = 0
		// Both "123" or "abc" and "321" or "cba" are considered consecutive.
		var isSequenceAscending: Bool?
		for i in 1..<passwordUnicodeScalars.count {
			let currCharCode = passwordUnicodeScalars[i]
			let prevCharCode = passwordUnicodeScalars[i-1]
			if let _isSequenceAscending = isSequenceAscending {
				// If `isSequenceAscending` is not nil, then we know that we are in the middle of an existing
				// pattern. Check if the pattern continues based on whether the previous pattern was
				// ascending or descending.
				if (_isSequenceAscending && currCharCode == prevCharCode + 1) || (!_isSequenceAscending && currCharCode == prevCharCode - 1) {
					continue
				}
				
				// Take into account the case when the sequence transitions from descending
				// to ascending.
				if currCharCode == prevCharCode + 1 {
					firstConsecutiveCharIndex = i - 1
					isSequenceAscending = true
					continue
				}
				
				isSequenceAscending = nil
			} else if currCharCode == prevCharCode + 1 {
				isSequenceAscending = true
				continue
			} else if currCharCode == prevCharCode - 1 {
				isSequenceAscending = false
				continue
			}
			
			let currConsecutiveCharLength = i - firstConsecutiveCharIndex
			if currConsecutiveCharLength > longestConsecutiveCharLength {
				longestConsecutiveCharLength = currConsecutiveCharLength
			}
			
			firstConsecutiveCharIndex = i
		}
		
		if isSequenceAscending ?? false {
			let currConsecutiveCharLength = passwordUnicodeScalars.count - firstConsecutiveCharIndex
			if currConsecutiveCharLength > longestConsecutiveCharLength {
				longestConsecutiveCharLength = currConsecutiveCharLength
			}
		}
		
		return longestConsecutiveCharLength <= consecutiveCharLimit
	}
	
	private func passwordHasNotExceededRepeatedCharLimit(password: [Character], repeatedCharLimit: Int) -> Bool {
		var longestRepeatedCharLength = 1
		var lastRepeatedChar = password[0]
		var lastRepeatedCharIndex = 0
		for i in 1..<password.count {
			let currChar = password[i]
			if currChar == lastRepeatedChar {
				continue
			}
			
			let currRepeatedCharLength = i - lastRepeatedCharIndex
			if currRepeatedCharLength > longestRepeatedCharLength {
				longestRepeatedCharLength = currRepeatedCharLength
			}
			
			lastRepeatedChar = currChar
			lastRepeatedCharIndex = i
		}
		return longestRepeatedCharLength <= repeatedCharLimit
	}
	
	private func passwordContainsRequiredCharacters(password: [Character], requiredCharacterSets: [Set<Character>]) -> Bool {
		for requiredCharacterSet in requiredCharacterSets {
			var hasRequiredChar = false
			for char in password {
				if requiredCharacterSet.contains(char) {
					hasRequiredChar = true
					break
				}
			}
			if !hasRequiredChar {
				return false
			}
		}
		return true
	}
	
	private func stringContainsAllCharactersInString<C1: CharacterCollection, C2: CharacterCollection>(string1: C1, string2: C2) -> Bool {
		for char in string2 {
			if !string1.contains(char) {
				return false
			}
		}
		return true
	}
	
	private func stringsHaveAtLeastOneCommonCharacter<C1: CharacterCollection, C2: CharacterCollection>(string1: C1, string2: C2) -> Bool {
		for char in string2 {
			if string1.contains(char) {
				return true
			}
		}
		return false
	}
	
	private func canUseMoreTypeablePasswordFromRequirements(minPasswordLength: Int?, maxPasswordLength: Int?, allowedCharacters: [Character]?, requiredCharacterSets: [Set<Character>]) -> Bool {
		// MARK: Original code doesn't check for existance of minPasswordLength here but in JS the condition is false if minPasswordLength is undefined.
		if let minPasswordLength, minPasswordLength > Self.defaultMoreTypeablePasswordLength {
			return false
		}
		if let maxPasswordLength, maxPasswordLength < Self.defaultMoreTypeablePasswordLength {
			return false
		}
		
		if let allowedCharacters, !stringContainsAllCharactersInString(string1: allowedCharacters, string2: Self.defaultUnambiguousCharacters) {
			return false
		}
		
		if requiredCharacterSets.count > Self.defaultMoreTypeablePasswordLength {
			return false
		}
		
		// FIXME: This doesn't handle returning false to a password that requires two or more special characters.
		var numberOfDigitsThatAreRequired = 0
		var numberOfUpperThatAreRequired = 0
		for requiredCharacterSet in requiredCharacterSets {
			if requiredCharacterSet == Self.numberCharacterSet {
				numberOfDigitsThatAreRequired += 1
			}
			if requiredCharacterSet == Self.uppercaseCharacterSet {
				numberOfUpperThatAreRequired += 1
			}
		}
		
		if numberOfDigitsThatAreRequired > 1 {
			return false
		}
		if numberOfUpperThatAreRequired > 1 {
			return false
		}
		
		let defaultUnambiguousCharactersPlusDash = Self.defaultUnambiguousCharacters + "-";
		for requiredCharacterSet in requiredCharacterSets {
			if !stringsHaveAtLeastOneCommonCharacter(string1: requiredCharacterSet, string2: defaultUnambiguousCharactersPlusDash) {
				return false
			}
		}
		
		return true
	}
	
	private func passwordGenerationParameters(requirements: Requirements) -> PasswordGenerationParameters {
		var minPasswordLength = requirements.passwordMinLength
		let maxPasswordLength = requirements.passwordMaxLength
		
		// MARK: Original code doesn't check for existance of minPasswordLength and maxPasswordLength here but in JS the condition is false if either is undefined.
		if let min = minPasswordLength, let max = maxPasswordLength {
			if min > max {
				// Resetting invalid value of min length to zero means "ignore min length parameter in password generation".
				minPasswordLength = 0
			}
		}
		
		var allowedCharacters = requirements.passwordAllowedCharacters
		
		var requiredCharacterSets: [Set<Character>]? = Self.defaultRequiredCharacterSets
		if let requiredCharacterArray = requirements.passwordRequiredCharacters {
			var mutatedRequiredCharacterSets = [Set<Character>]()
			for requiredCharacters in requiredCharacterArray {
				// MARK: Original code doesn't check for existance of allowedCharacters here. But the requirements are usually generated to contain all required chars as allowed chars, so the solution below is equivalent to that case.
				if allowedCharacters == nil || stringsHaveAtLeastOneCommonCharacter(string1: requiredCharacters, string2: allowedCharacters!) {
					mutatedRequiredCharacterSets.append(requiredCharacters)
				}
			}
			requiredCharacterSets = mutatedRequiredCharacterSets
		}
		
		let canUseMoreTypeablePassword = canUseMoreTypeablePasswordFromRequirements(
			minPasswordLength: minPasswordLength,
			maxPasswordLength: maxPasswordLength,
			allowedCharacters: allowedCharacters,
			requiredCharacterSets: requiredCharacterSets!
		)
		if canUseMoreTypeablePassword {
			var style: PasswordGenerationStyle = .moreTypeable
			if let allowedCharacters, !allowedCharacters.contains("-") {
				style = .moreTypeableWithoutDashes
			}
			
			return PasswordGenerationParameters(
				passwordGenerationStyle: style,
				numberOfRequiredRandomCharacters: nil,
				passwordAllowedCharacters: nil,
				requiredCharacterSets: nil
			)
		}
		
		// If requirements allow, we will generate the password in default format: "xxx-xxx-xxx-xxx".
		var style: PasswordGenerationStyle = .classic
		var numberOfRequiredRandomCharacters = Self.defaultNumberOfCharactersForClassicPassword
		if let minPasswordLength, minPasswordLength > Self.defaultClassicPasswordLength {
			style = .classicWithoutDashes
			numberOfRequiredRandomCharacters = minPasswordLength
		}
		
		if let maxPasswordLength, maxPasswordLength < Self.defaultClassicPasswordLength {
			style = .classicWithoutDashes
			numberOfRequiredRandomCharacters = maxPasswordLength
		}
		
		if let allowedCharacters {
			// We cannot use default format if dash is not an allowed character in the password.
			if !allowedCharacters.contains("-") {
				style = .classicWithoutDashes
			}
		} else {
			allowedCharacters = Self.defaultUnambiguousCharacters
		}
		
		// In default password format, we use dashes only as separators, not as symbols you can encounter at a random position.
		if style == .classic {
			allowedCharacters?.removeAll { $0 == "-" }
		}
		
		// MARK: Original code is redundant, requiredCharacterSets is already set to Self.defaultRequiredCharacterSets if requirements.passwordRequiredCharacters was undefined.
//		if requiredCharacterSets == nil {
//			requiredCharacterSets = Self.defaultRequiredCharacterSets
//		}
		
		// If we have more requirements of the type "need a character from set" than the length of the password we want to generate, then
		// we will never be able to meet these requirements, and we'll end up in an infinite loop generating passwords. To avoid this,
		// reset required character sets if the requirements are impossible to meet.
		if let length = requiredCharacterSets?.count, length > numberOfRequiredRandomCharacters {
			requiredCharacterSets = nil
		}
		
		// MARK: Original code doesn't check for existance of requiredCharacterSets here and crashes if the above case is met (allowedCharacters is non-nil at this point).
		// Do not require any character sets that do not contain allowed characters.
		var mutatedRequiredCharacterSets = [Set<Character>]()
		for requiredCharacterSet in requiredCharacterSets ?? [] {
			var requiredCharacterSetContainsAllowedCharacters = false
			for character in allowedCharacters! {
				if requiredCharacterSet.contains(character) {
					requiredCharacterSetContainsAllowedCharacters = true
					break
				}
			}
			if requiredCharacterSetContainsAllowedCharacters {
				mutatedRequiredCharacterSets.append(requiredCharacterSet)
			}
		}
		requiredCharacterSets = mutatedRequiredCharacterSets
		
		return PasswordGenerationParameters(
			passwordGenerationStyle: style,
			numberOfRequiredRandomCharacters: numberOfRequiredRandomCharacters,
			passwordAllowedCharacters: allowedCharacters,
			requiredCharacterSets: requiredCharacterSets
		)
	}
	
	func generatedPasswordMatchingRequirements(requirements: Requirements?) -> String {
		let requirements = requirements ?? Requirements(
			passwordMinLength: nil,
			passwordMaxLength: nil,
			passwordAllowedCharacters: nil,
			passwordRequiredCharacters: nil,
			passwordRepeatedCharacterLimit: nil,
			passwordConsecutiveCharacterLimit: nil
		)
		
		let parameters = passwordGenerationParameters(requirements: requirements)
		let style = parameters.passwordGenerationStyle
		let numberOfRequiredRandomCharacters = parameters.numberOfRequiredRandomCharacters
		let repeatedCharLimit = requirements.passwordRepeatedCharacterLimit
		let allowedCharacters = parameters.passwordAllowedCharacters
		var shouldCheckRepeatedCharRequirement = repeatedCharLimit != nil
		
		while true {
			var password = [Character]()
			switch style {
				case .classic: fallthrough
				case .classicWithoutDashes:
					password = classicPassword(numberOfRequiredRandomCharacters: numberOfRequiredRandomCharacters!, allowedCharacters: allowedCharacters!)
					if style == .classic {
						password = Array([password[0..<3], password[3..<6], password[6..<9], password[9..<12]].joined(separator: "-"))
					}
					
					if !passwordContainsRequiredCharacters(password: password, requiredCharacterSets: parameters.requiredCharacterSets!) {
						continue
					}
					
				case .moreTypeable: fallthrough
				case .moreTypeableWithoutDashes:
					password = moreTypeablePassword()
					if style == .moreTypeable {
						password = Array([password[0..<6], password[6..<12], password[12..<18]].joined(separator: "-"))
					}
					
					if shouldCheckRepeatedCharRequirement && repeatedCharLimit != 1 {
						shouldCheckRepeatedCharRequirement = false
					}
			}
			
			if shouldCheckRepeatedCharRequirement, let repeatedCharLimit {
				if repeatedCharLimit >= 1 && passwordHasNotExceededRepeatedCharLimit(password: password, repeatedCharLimit: repeatedCharLimit) {
					continue
				}
			}
			
			if let consecutiveCharLimit = requirements.passwordConsecutiveCharacterLimit {
				if consecutiveCharLimit >= 1 && passwordHasNotExceededConsecutiveCharLimit(password: password, consecutiveCharLimit: consecutiveCharLimit) {
					continue
				}
			}
			
			return String(password)
		}
	}
}
