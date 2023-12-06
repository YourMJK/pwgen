//
//  PasswordGenerator.swift
//  pwgen
//
//  Created by Max-Joseph on 01.07.23.
//  Originally ported from JavaScript code at https://developer.apple.com/password-rules/scripts/generator.js
//  but modified to be simpler, more robust and versatile.
//

import Foundation


public struct PasswordGenerator {
	public enum Style {
		case random
		case nice
	}
	
	private typealias CharacterCollection = Collection<Character>
	
	
	public static let defaultGroupSeparator: Character = "-"
	public static let defaultAllowedCharacters: CharacterSet = .unambiguous
	public static let defaultRequiredCharacterSets: [CharacterSet] = [.lower, .upper, .digits]
	
	private let passwordFunction: () -> [Character]
	private let group: (size: Int, separator: Character)?
	private let requiredCharacterSets: [CharacterSet]?
	private let repeatedCharacterLimit: Int?
	private let consecutiveCharacterLimit: Int?
	
	public init(
		style: Style,
		minimumLength: Int,
		grouped: Bool,
		groupSeparator: Character = Self.defaultGroupSeparator,
		allowedCharacters: CharacterSet = Self.defaultAllowedCharacters,
		requiredCharacterSets: [CharacterSet] = Self.defaultRequiredCharacterSets,
		repeatedCharacterLimit: Int? = nil,
		consecutiveCharacterLimit: Int? = nil
	) throws {
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
			numberOfSplits = (minimumLength - numberOfCharacters + splitSize - 1) / splitSize
			numberOfCharacters += numberOfSplits * groupSize
			split = numberOfSplits > 0
		}
		else {
			numberOfCharacters = minimumLength
		}
		
		// Remove empty character sets
		var requiredCharacterSets = requiredCharacterSets.filter { !$0.isEmpty }
		// For each separator inserted due to splitting, remove a character set that requires the separator character
		requiredCharacterSets.indices
			.filter { requiredCharacterSets[$0].contains(groupSeparator) }
			.prefix(numberOfSplits)
			.reversed()
			.forEach { requiredCharacterSets.remove(at: $0) }
		// Remove any required character not present in the allowed characters
		requiredCharacterSets = requiredCharacterSets
			.map { $0.intersection(allowedCharacters) }
		// Set up character sets for generator to randomly choose from
		let characterPool = CharacterSet(union: requiredCharacterSets)
		let lowerConsonants: CharacterSet = .lowerConsonants.intersection(allowedCharacters)
		let upperConsonants: CharacterSet = .upperConsonants.intersection(allowedCharacters)
		let lowerVowels: CharacterSet = .lowerVowels.intersection(allowedCharacters)
		let upperVowels: CharacterSet = .upperVowels.intersection(allowedCharacters)
		let digits: CharacterSet = .digits.intersection(allowedCharacters)
		
		switch style {
			case .random:
				// If we have more requirements of the type "need a character from set" than the length of the password we want to generate, then
				// we will never be able to meet these requirements, and we'll end up in an infinite loop generating passwords.
				guard requiredCharacterSets.count <= numberOfCharacters else {
					throw RequirementsError.moreCharacterSetsThanCharacters(requiredCharacterSetsCount: requiredCharacterSets.count, numberOfCharacters: numberOfCharacters)
				}
				// If any required character set is empty due to intersection with the allowed characters, we cannot fulfill the requirements.
				guard requiredCharacterSets.allSatisfy({ !$0.isEmpty }) else {
					throw RequirementsError.invalidRequiredCharacterSet
				}
				// If the character pool is empty (because no required character sets were given), there are no characters to randomly choose from.
				guard !characterPool.isEmpty else {
					throw RequirementsError.emptyCharacterPool
				}
				
				self.passwordFunction = {
					Self.classicPassword(numberOfRandomCharacters: numberOfCharacters, from: characterPool)
				}
			case .nice:
				// If the requirements don't allow at least one character of each of these types, we can't generate a moreTypeablePassword.
				guard [lowerConsonants, upperConsonants, lowerVowels, upperVowels, digits].allSatisfy({ !$0.isEmpty }) else {
					throw RequirementsError.nicePasswordMissingAllowedCharacters
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
	
	
	public func newPassword() -> String {
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
		var isSequenceAscending: Bool?
		var consecutiveSequenceLength = 0
		// Both "123" or "abc" and "321" or "cba" are considered consecutive.
		for i in 1..<passwordUnicodeScalars.count {
			let currCharCode = passwordUnicodeScalars[i].value
			let prevCharCode = passwordUnicodeScalars[i-1].value
			let areCharCodesAscending: Bool
			if currCharCode == prevCharCode + 1 {
				areCharCodesAscending = true
			} else if currCharCode == prevCharCode - 1 {
				areCharCodesAscending = false
			} else {
				isSequenceAscending = nil
				continue
			}
			
			if areCharCodesAscending != isSequenceAscending {
				isSequenceAscending = areCharCodesAscending
				consecutiveSequenceLength = 1
			}
			consecutiveSequenceLength += 1
			if consecutiveSequenceLength > limit {
				return false
			}
		}
		
		return true
	}
	
	private static func passwordHasNotExceededRepeatedCharacterLimit(password: [Character], limit: Int) -> Bool {
		if limit < 1 {
			return true
		}
		
		var repeatedChar: Character?
		var repeatedSequenceLength = 0
		for char in password {
			if char != repeatedChar {
				repeatedChar = char
				repeatedSequenceLength = 1
				continue
			}
			repeatedSequenceLength += 1
			if repeatedSequenceLength > limit {
				return false
			}
		}
		
		return true
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
