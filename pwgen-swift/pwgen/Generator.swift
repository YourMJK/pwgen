//
//  Generator.swift
//  pwgen
//
//  Created by Max-Joseph on 01.07.23.
//  Originally ported from JavaScript code at https://developer.apple.com/password-rules/scripts/generator.js
//  but modified to be more robust and versatile.
//

import Foundation


struct Generator {
	enum Style {
		case random
		case nice
	}
	
	private typealias CharacterCollection = Collection<Character>
	
	
	static let defaultGroupSeparator: Character = "-"
	static let defaultAllowedCharacters: CharacterSet = .unambiguous
	static let defaultRequiredCharacterSets: [CharacterSet] = [.lower, .upper, .digit]
	
	private let style: Style
	private let numberOfCharacters: Int
	private let group: (size: Int, separator: Character)?
	private let characterPool: CharacterSet
	private let requiredCharacterSets: [CharacterSet]
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
		self.style = style
		self.consecutiveCharacterLimit = consecutiveCharacterLimit
		self.repeatedCharacterLimit = {
			if style == .nice && repeatedCharacterLimit != 1 {
				return nil
			}
			return consecutiveCharacterLimit
		}()
		
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
		self.numberOfCharacters = numberOfCharacters
		self.group = split ? (groupSize, groupSeparator) : nil
		
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
		self.characterPool = CharacterSet(union: requiredCharacterSets)
		self.requiredCharacterSets = requiredCharacterSets
		
		// If we have more requirements of the type "need a character from set" than the length of the password we want to generate, then
		// we will never be able to meet these requirements, and we'll end up in an infinite loop generating passwords. To avoid this,
		// reset required character sets if the requirements are impossible to meet.
		precondition(requiredCharacterSets.count <= numberOfCharacters, "Unable to meet requirements: More required character sets (\(requiredCharacterSets.count)) specified than number of password characters (\(numberOfCharacters)) to generate")
	}
	
	
	private func randomInt(max: Int) -> Int {
		Int.random(in: 0..<max)
	}
	private func randomInt(range: Range<Int>) -> Int {
		Int.random(in: range)
	}
	private func randomInt(range: ClosedRange<Int>) -> Int {
		Int.random(in: range)
	}
	
	private func randomCharacter<C: CharacterCollection>(in collection: C) -> Character {
		collection.randomElement()!
	}
	
	private func randomConsonant() -> [Character] {
		[randomCharacter(in: CharacterSet.unambiguousLowerConsonants)]
	}
	
	private func randomVowel() -> [Character] {
		[randomCharacter(in: CharacterSet.unambiguousLowerVowels)]
	}
	
	private func randomDigit() -> [Character] {
		[randomCharacter(in: CharacterSet.digit)]
	}
	
	private func randomSyllable() -> [Character] {
		randomConsonant() + randomVowel() + randomConsonant()
	}
	
	private func randomWord() -> [Character] {
		randomSyllable() + randomSyllable()
	}
	
	
	private func moreTypeablePassword(numberOfMinimumCharacters: Int) -> [Character] {
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
	
	private func classicPassword(numberOfRandomCharacters: Int, from characterPool: CharacterSet) -> [Character] {
		var randomCharArray = [Character]()
		for _ in 0..<numberOfRandomCharacters {
			randomCharArray.append(randomCharacter(in: characterPool))
		}
		return randomCharArray
	}
	
	private func splitArray<T>(_ array: [T], separator: T, groupSize: Int) -> [T] {
		var components: [ArraySlice<T>] = []
		var startIndex = array.startIndex
		while startIndex < array.endIndex {
			let endIndex = min(startIndex + groupSize, array.endIndex)
			components.append(array[startIndex..<endIndex])
			startIndex = endIndex
		}
		return Array(components.joined(separator: [separator]))
	}
	
	
	private func passwordHasNotExceededConsecutiveCharLimit(password: [Character], consecutiveCharLimit: Int) -> Bool {
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
	
	
	func generatePassword() -> String {
		while true {
			var password = [Character]()
			
			switch style {
				case .random:
					password = classicPassword(numberOfRandomCharacters: numberOfCharacters, from: characterPool)
					if let group {
						password = splitArray(password, separator: group.separator, groupSize: group.size)
					}
					
					if !passwordContainsRequiredCharacters(password: password, requiredCharacterSets: requiredCharacterSets) {
						continue
					}
					
				case .nice:
					password = moreTypeablePassword(numberOfMinimumCharacters: numberOfCharacters)
					if let group {
						password = splitArray(password, separator: group.separator, groupSize: group.size)
					}
			}
			
			if let repeatedCharacterLimit, repeatedCharacterLimit >= 1, !passwordHasNotExceededRepeatedCharLimit(password: password, repeatedCharLimit: repeatedCharacterLimit) {
				continue
			}
			if let consecutiveCharacterLimit, consecutiveCharacterLimit >= 1, !passwordHasNotExceededConsecutiveCharLimit(password: password, consecutiveCharLimit: consecutiveCharacterLimit) {
				continue
			}
			
			return String(password)
		}
	}
}
