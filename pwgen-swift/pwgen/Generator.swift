//
//  Generator.swift
//  pwgen
//
//  Created by Max-Joseph on 01.07.23.
//  Originally ported from JavaScript code at https://developer.apple.com/password-rules/scripts/generator.js
//  but modified to be more robust and versatile.
//

import Foundation
import OrderedCollections


extension Generator {
	typealias CharacterSet = OrderedSet<Character>
}

extension Generator.CharacterSet {
	static let lower = Self("abcdefghijklmnopqrstuvwxyz")
	static let upper = Self("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
	static let digit = Self("0123456789")
	static let special = Self(#"-~!@#$%^&*_+=`|(){}[:;\"'<>,.?/ ]"#)
	
	static let ascii = Self(joined: .lower, .upper, .digit, .special)
	static let alphanumeric = Self(joined: .lower, .upper, .digit)
	
	private static let ambiguous = Self("lO")
	static let unambiguous = Self.alphanumeric.subtracting(ambiguous)
	static let unambiguousLowerConsonants = Self("bcdfghjklmnpqrstvwxz").subtracting(ambiguous)
	static let unambiguousUpperConsonants = Self("BCDFGHJKLMNPQRSTVWXZ").subtracting(ambiguous)
	static let unambiguousLowerVowels = Self("aeiouy").subtracting(ambiguous)
	static let unambiguousUpperVowels = Self("AEIOUY").subtracting(ambiguous)
	
	private init(joined elements: Self...) {
		self.init(uncheckedUniqueElements: elements.joined())
	}
}


struct Generator {
	static let defaultUnambiguousCharacters = CharacterSet.unambiguous
	
	static let defaultNumberOfCharactersForClassicPassword = 12
	static let defaultClassicPasswordLength = 15
	
	static let defaultNumberOfCharactersForMoreTypeablePassword = 18
	static let defaultMoreTypeablePasswordLength = 20
	static let defaultAllowedNumbers = CharacterSet.digit
	static let defaultAllowedLowercaseConsonants = CharacterSet.unambiguousLowerConsonants
	static let defaultAllowedLowercaseVowels = CharacterSet.unambiguousLowerVowels
	
	private static let lowercaseCharacterSet = CharacterSet.lower
	private static let uppercaseCharacterSet = CharacterSet.upper
	private static let numberCharacterSet = CharacterSet.digit
	static let defaultRequiredCharacterSets: [CharacterSet] = [.lower, .upper, .digit]
	
	
	struct Requirements {
		let minLength: Int?
		let maxLength: Int?
		let allowedCharacters: [Character]?
		let requiredCharacters: [CharacterSet]?
		let repeatedCharacterLimit: Int?
		let consecutiveCharacterLimit: Int?
	}
	
	private enum PasswordGenerationStyle {
		case classic(dashes: Bool, numberOfRequiredRandomCharacters: Int, allowedCharacters: [Character], requiredCharacterSets: [CharacterSet])
		case moreTypeable(dashes: Bool)
	}
	
	private typealias CharacterCollection = Collection<Character>
	
	
	private func randomInt(max: Int) -> Int {
		Int.random(in: 0..<max)
	}
	private func randomInt(range: Range<Int>) -> Int {
		Int.random(in: range)
	}
	private func randomInt(range: ClosedRange<Int>) -> Int {
		Int.random(in: range)
	}
	private func randomBool() -> Bool {
		Bool.random()
	}
	
	private func randomPermutation<T>(of collection: inout [T]) {
		collection.shuffle()
	}
	
	private func randomCharacter<C: CharacterCollection>(in collection: C) -> Character {
		collection.randomElement()!
	}
	
	private func randomConsonant() -> [Character] {
		[randomCharacter(in: Self.defaultAllowedLowercaseConsonants)]
	}
	
	private func randomVowel() -> [Character] {
		[randomCharacter(in: Self.defaultAllowedLowercaseVowels)]
	}
	
	private func randomDigit() -> [Character] {
		[randomCharacter(in: Self.defaultAllowedNumbers)]
	}
	
	private func randomSyllable() -> [Character] {
		randomConsonant() + randomVowel() + randomConsonant()
	}
	
	private func randomWord() -> [Character] {
		randomSyllable() + randomSyllable()
	}
	
	
	private func moreTypeablePassword(numberOfMinimumCharacters: Int = defaultNumberOfCharactersForMoreTypeablePassword) -> [Character] {
		var components = [[Character]]()
		
		// Generate enough words to satisfy minimum number of characters
		let wordLength = 6
		let numberOfNeededCharacters = max(numberOfMinimumCharacters - wordLength, 0)
		let numberOfAdditionalWords = (numberOfNeededCharacters + wordLength - 1) / wordLength
		for _ in 0..<numberOfAdditionalWords {
			components.append(randomWord())
		}
		
		// Password always includes one word starting or ending with a digit
		var digitWord = randomSyllable() + randomConsonant() + randomVowel()
		
		// Insert digit word while ensuring that password doesn't start with a digit
		let digitPosition = randomInt(range: 1...(numberOfAdditionalWords*2 + 1))
		let digitIndex = (digitPosition & 0b1 == 0) ? digitWord.startIndex : digitWord.endIndex
		let digitWordIndex = digitPosition / 2
		digitWord.insert(contentsOf: randomDigit(), at: digitIndex)
		components.insert(digitWord, at: digitWordIndex)
		
		// Uppercase a random character that is not an "o" or a digit
		var password = Array(components.joined())
		let length = password.count
		while true {
			let index = randomInt(max: length)
			let lowercaseChar = password[index]
			if lowercaseChar == "o" || CharacterSet.digit.contains(lowercaseChar) {
				continue
			}
			
			let uppercaseChars = lowercaseChar.uppercased()
			password.replaceSubrange(index...index, with: uppercaseChars)
			
			return password
		}
	}
	
	private func classicPassword(numberOfRequiredRandomCharacters: Int, allowedCharacters: [Character]) -> [Character] {
		var randomCharArray = [Character]()
		for _ in 0..<numberOfRequiredRandomCharacters {
			randomCharArray.append(randomCharacter(in: allowedCharacters))
		}
		return randomCharArray
	}
	
	private func splitPassword(password: [Character], separator: Character, groupSize: Int) -> [Character] {
		var components: [ArraySlice<Character>] = []
		var startIndex = password.startIndex
		while startIndex < password.endIndex {
			let endIndex = min(startIndex + groupSize, password.endIndex)
			components.append(password[startIndex..<endIndex])
			startIndex = endIndex
		}
		return Array(components.joined(separator: [separator]))
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
	
	private func passwordContainsRequiredCharacters(password: [Character], requiredCharacterSets: [CharacterSet]) -> Bool {
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
	
	private func canUseMoreTypeablePasswordFromRequirements(minPasswordLength: Int?, maxPasswordLength: Int?, allowedCharacters: [Character]?, requiredCharacterSets: [CharacterSet]) -> Bool {
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
		
		let defaultUnambiguousCharactersPlusDash = Self.defaultUnambiguousCharacters + "-"
		for requiredCharacterSet in requiredCharacterSets {
			if !stringsHaveAtLeastOneCommonCharacter(string1: requiredCharacterSet, string2: defaultUnambiguousCharactersPlusDash) {
				return false
			}
		}
		
		return true
	}
	
	private func passwordGenerationStyle(requirements: Requirements) -> PasswordGenerationStyle {
		var minPasswordLength = requirements.minLength
		let maxPasswordLength = requirements.maxLength
		
		// MARK: Original code doesn't check for existance of minPasswordLength and maxPasswordLength here but in JS the condition is false if either is undefined.
		if let min = minPasswordLength, let max = maxPasswordLength {
			if min > max {
				// Resetting invalid value of min length to zero means "ignore min length parameter in password generation".
				minPasswordLength = 0
			}
		}
		
		var allowedCharacters = requirements.allowedCharacters
		
		var requiredCharacterSets: [CharacterSet] = Self.defaultRequiredCharacterSets
		if let requiredCharacterArray = requirements.requiredCharacters {
			var mutatedRequiredCharacterSets = [CharacterSet]()
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
			requiredCharacterSets: requiredCharacterSets
		)
		if canUseMoreTypeablePassword {
			return .moreTypeable(dashes: allowedCharacters?.contains("-") ?? true)
		}
		
		// If requirements allow, we will generate the password in default format: "xxx-xxx-xxx-xxx".
		var dashes = true
		var numberOfRequiredRandomCharacters = Self.defaultNumberOfCharactersForClassicPassword
		if let minPasswordLength, minPasswordLength > Self.defaultClassicPasswordLength {
			dashes = false
			numberOfRequiredRandomCharacters = minPasswordLength
		}
		
		if let maxPasswordLength, maxPasswordLength < Self.defaultClassicPasswordLength {
			dashes = false
			numberOfRequiredRandomCharacters = maxPasswordLength
		}
		
		if let allowedCharacters {
			// We cannot use default format if dash is not an allowed character in the password.
			if !allowedCharacters.contains("-") {
				dashes = false
			}
		} else {
			allowedCharacters = Array(Self.defaultUnambiguousCharacters)
		}
		
		// In default password format, we use dashes only as separators, not as symbols you can encounter at a random position.
		if dashes {
			allowedCharacters?.removeAll { $0 == "-" }
		}
		
		// If we have more requirements of the type "need a character from set" than the length of the password we want to generate, then
		// we will never be able to meet these requirements, and we'll end up in an infinite loop generating passwords. To avoid this,
		// reset required character sets if the requirements are impossible to meet.
		if requiredCharacterSets.count > numberOfRequiredRandomCharacters {
			preconditionFailure("Unable to meet requirements: More required character sets specified than number of password characters to generate")
		}
		
		// MARK: Original code doesn't check for existance of requiredCharacterSets here and also crashes if the above case is met (allowedCharacters is non-nil at this point).
		// Do not require any character sets that do not contain allowed characters.
		var mutatedRequiredCharacterSets = [CharacterSet]()
		for requiredCharacterSet in requiredCharacterSets {
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
		
		return .classic(
			dashes: dashes,
			numberOfRequiredRandomCharacters: numberOfRequiredRandomCharacters,
			allowedCharacters: allowedCharacters!,
			requiredCharacterSets: requiredCharacterSets
		)
	}
	
	func generatedPasswordMatchingRequirements(requirements: Requirements?) -> String {
		let requirements = requirements ?? Requirements(
			minLength: nil,
			maxLength: nil,
			allowedCharacters: nil,
			requiredCharacters: nil,
			repeatedCharacterLimit: nil,
			consecutiveCharacterLimit: nil
		)
		
		let style = passwordGenerationStyle(requirements: requirements)
		let repeatedCharLimit = requirements.repeatedCharacterLimit
		var shouldCheckRepeatedCharRequirement = repeatedCharLimit != nil
		
		while true {
			var password = [Character]()
			switch style {
				case .classic(let dashes, let numberOfRequiredRandomCharacters, let allowedCharacters, let requiredCharacterSets):
					password = classicPassword(numberOfRequiredRandomCharacters: numberOfRequiredRandomCharacters, allowedCharacters: allowedCharacters)
					if dashes {
						password = splitPassword(password: password, separator: "-", groupSize: 3)
					}
					
					if !passwordContainsRequiredCharacters(password: password, requiredCharacterSets: requiredCharacterSets) {
						continue
					}
					
				case .moreTypeable(let dashes):
					password = moreTypeablePassword()
					if dashes {
						password = splitPassword(password: password, separator: "-", groupSize: 6)
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
			
			if let consecutiveCharLimit = requirements.consecutiveCharacterLimit {
				if consecutiveCharLimit >= 1 && passwordHasNotExceededConsecutiveCharLimit(password: password, consecutiveCharLimit: consecutiveCharLimit) {
					continue
				}
			}
			
			return String(password)
		}
	}
}
