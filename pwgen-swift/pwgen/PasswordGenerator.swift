//
//  PasswordGenerator.swift
//  pwgen
//
//  Created by Max-Joseph on 01.07.23.
//  Originally ported from JavaScript code at https://developer.apple.com/password-rules/scripts/generator.js
//  but modified to be simpler, more robust and versatile.
//

import Foundation


struct PasswordGenerator {
	enum Style {
		case random
		case nice
	}
	
	private typealias CharacterCollection = Collection<Character>
	
	
	static let defaultGroupSeparator: Character = "-"
	static let defaultAllowedCharacters: CharacterSet = .unambiguous
	static let defaultRequiredCharacterSets: [CharacterSet] = [.lower, .upper, .digit]
	
	private let passwordFunction: () -> [Character]
	private let group: (size: Int, separator: Character)?
	private let requiredCharacterSets: [CharacterSet]?
	private let repeatedCharacterLimit: Int?
	private let consecutiveCharacterLimit: Int?
	
	init(
		style: Style,
		minLength: Int,
		grouped: Bool,
		groupSeparator: Character = Self.defaultGroupSeparator,
		allowedCharacters: CharacterSet = Self.defaultAllowedCharacters,
		requiredCharacterSets: [CharacterSet] = Self.defaultRequiredCharacterSets,
		repeatedCharacterLimit: Int? = nil,
		consecutiveCharacterLimit: Int? = nil
	) {
		// Calculate the number of characters and splits such that the resulting length satisfies the specified minimum length
		let groupSize = {
			switch style {
				case .random: return 3
				case .nice: return 6
			}
		}()
		var numberOfSplits = 0
		var numberOfCharacters = groupSize
		var split = false
		if grouped {
			let splitSize = groupSize + 1
			numberOfSplits = (minLength - numberOfCharacters + splitSize - 1) / splitSize
			numberOfCharacters += numberOfSplits * groupSize
			split = numberOfSplits > 0
		}
		else {
			numberOfCharacters = minLength
		}
		
		// For each separator inserted due to splitting, remove a character set that requires the separator character
		var requiredCharacterSets = requiredCharacterSets
		requiredCharacterSets.indices
			.filter { requiredCharacterSets[$0].contains(groupSeparator) }
			.prefix(numberOfSplits)
			.reversed()
			.forEach { requiredCharacterSets.remove(at: $0) }
		// Remove any required character not present in the allowed characters
		requiredCharacterSets = requiredCharacterSets
			.map { $0.intersection(allowedCharacters) }
			.filter { !$0.isEmpty }
		// Set up character sets for generator to randomly choose from
		let characterPool = CharacterSet(union: requiredCharacterSets)
		let lowerConsonants: CharacterSet = .lowerConsonants.intersection(allowedCharacters)
		let upperConsonants: CharacterSet = .upperConsonants.intersection(allowedCharacters)
		let lowerVowels: CharacterSet = .lowerVowels.intersection(allowedCharacters)
		let upperVowels: CharacterSet = .upperVowels.intersection(allowedCharacters)
		let digits: CharacterSet = .digit.intersection(allowedCharacters)
		
		switch style {
			case .random:
				// If we have more requirements of the type "need a character from set" than the length of the password we want to generate, then
				// we will never be able to meet these requirements, and we'll end up in an infinite loop generating passwords.
				precondition(requiredCharacterSets.count <= numberOfCharacters, "Unable to meet requirements: More required character sets (\(requiredCharacterSets.count)) specified than number of password characters (\(numberOfCharacters)) to generate")
				
				self.passwordFunction = {
					Self.classicPassword(numberOfRandomCharacters: numberOfCharacters, from: characterPool)
				}
			case .nice:
				// If the requirements don't allow at least one character of each of these types, we can't generate a moreTypeablePassword.
				[lowerConsonants, upperConsonants, lowerVowels, upperVowels, digits].forEach {
					precondition(!$0.isEmpty, "Unable to meet requirements: For a password of style \"nice\", allowed characters must contain a lowercase and uppercase consonant and vowel and a digit")
				}
				
				self.passwordFunction = {
					Self.moreTypeablePassword(
						numberOfMinimumCharacters: numberOfCharacters,
						lowerConsonants: lowerConsonants,
						upperConsonants: upperConsonants,
						lowerVowels: lowerVowels,
						upperVowels: upperVowels,
						digits: digits
					)
				}
		}
		
		self.group = split ? (groupSize, groupSeparator) : nil
		self.requiredCharacterSets = style == .random ? requiredCharacterSets : nil
		self.repeatedCharacterLimit = {
			if let repeatedCharacterLimit, repeatedCharacterLimit < 1 {
				return nil
			}
			if style == .nice && repeatedCharacterLimit != 1 {
				return nil
			}
			return repeatedCharacterLimit
		}()
		self.consecutiveCharacterLimit = {
			if let consecutiveCharacterLimit, consecutiveCharacterLimit < 1 {
				return nil
			}
			return consecutiveCharacterLimit
		}()
	}
	
	
	func newPassword() -> String {
		while true {
			var password = passwordFunction()
			if let group {
				password = Self.splitArray(password, separator: group.separator, groupSize: group.size)
			}
			
			if let requiredCharacterSets, !Self.passwordContainsRequiredCharacters(password: password, requiredCharacterSets: requiredCharacterSets) {
				continue
			}
			if let repeatedCharacterLimit, !Self.passwordHasNotExceededRepeatedCharacterLimit(password: password, limit: repeatedCharacterLimit) {
				continue
			}
			if let consecutiveCharacterLimit, !Self.passwordHasNotExceededConsecutiveCharacterLimit(password: password, limit: consecutiveCharacterLimit) {
				continue
			}
			
			return String(password)
		}
	}
	
	
	private static func randomInt(max: Int) -> Int {
		Int.random(in: 0..<max)
	}
	private static func randomInt(range: Range<Int>) -> Int {
		Int.random(in: range)
	}
	private static func randomInt(range: ClosedRange<Int>) -> Int {
		Int.random(in: range)
	}
	private static func randomCharacter<C: CharacterCollection>(in collection: C) -> Character {
		collection.randomElement()!
	}
	
	
	private static func moreTypeablePassword(
		numberOfMinimumCharacters: Int,
		lowerConsonants: CharacterSet,
		upperConsonants: CharacterSet,
		lowerVowels: CharacterSet,
		upperVowels: CharacterSet,
		digits: CharacterSet
	) -> [Character] {
		func randomConsonant() -> [Character] {
			[randomCharacter(in: lowerConsonants)]
		}
		func randomVowel() -> [Character] {
			[randomCharacter(in: lowerVowels)]
		}
		func randomDigit() -> [Character] {
			[randomCharacter(in: digits)]
		}
		func randomSyllable() -> [Character] {
			randomConsonant() + randomVowel() + randomConsonant()
		}
		func randomWord() -> [Character] {
			randomSyllable() + randomSyllable()
		}
		
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
		
		// Uppercase a random consonant or vowel
		var password = Array(components.joined())
		let length = password.count
		while true {
			let index = randomInt(max: length)
			let lowercaseChar = password[index]
			let uppercaseChar: Character
			if lowerConsonants.contains(lowercaseChar) {
				uppercaseChar = randomCharacter(in: upperConsonants)
			} else if lowerVowels.contains(lowercaseChar) {
				uppercaseChar = randomCharacter(in: upperVowels)
			} else {
				continue
			}
			password[index] = uppercaseChar
			
			return password
		}
	}
	
	private static func classicPassword(numberOfRandomCharacters: Int, from characterPool: CharacterSet) -> [Character] {
		var randomCharArray = [Character]()
		for _ in 0..<numberOfRandomCharacters {
			randomCharArray.append(randomCharacter(in: characterPool))
		}
		return randomCharArray
	}
	
	private static func splitArray<T>(_ array: [T], separator: T, groupSize: Int) -> [T] {
		var components: [ArraySlice<T>] = []
		var startIndex = array.startIndex
		while startIndex < array.endIndex {
			let endIndex = min(startIndex + groupSize, array.endIndex)
			components.append(array[startIndex..<endIndex])
			startIndex = endIndex
		}
		return Array(components.joined(separator: [separator]))
	}
	
	
	private static func passwordHasNotExceededConsecutiveCharacterLimit(password: [Character], limit: Int) -> Bool {
		if limit < 1 {
			return true
		}
		
		let passwordUnicodeScalars = password.flatMap(\.unicodeScalars)
		var longestConsecutiveCharLength = 1
		var firstConsecutiveCharIndex = 0
		// Both "123" or "abc" and "321" or "cba" are considered consecutive.
		var isSequenceAscending: Bool?
		
		for i in 1..<passwordUnicodeScalars.count {
			let currCharCode = passwordUnicodeScalars[i].value
			let prevCharCode = passwordUnicodeScalars[i-1].value
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
		
		return longestConsecutiveCharLength <= limit
	}
	
	private static func passwordHasNotExceededRepeatedCharacterLimit(password: [Character], limit: Int) -> Bool {
		if limit < 1 {
			return true
		}
		
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
		
		return longestRepeatedCharLength <= limit
	}
	
	private static func passwordContainsRequiredCharacters(password: [Character], requiredCharacterSets: [CharacterSet]) -> Bool {
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
}
