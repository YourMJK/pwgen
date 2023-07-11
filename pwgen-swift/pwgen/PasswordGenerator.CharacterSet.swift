//
//  PasswordGenerator.CharacterSet.swift
//  pwgen
//
//  Created by Max-Joseph on 10.07.23.
//

import OrderedCollections


extension PasswordGenerator {
	typealias CharacterSet = OrderedSet<Character>
}

extension PasswordGenerator.CharacterSet {
	static let lower = Self("abcdefghijklmnopqrstuvwxyz")
	static let upper = Self("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
	static let digit = Self("0123456789")
	static let special = Self(#"-~!@#$%^&*_+=`|(){}[:;\"'<>,.?/ ]"#)
	
	static let ascii = Self(joined: .lower, .upper, .digit, .special)
	static let alphanumeric = Self(joined: .lower, .upper, .digit)
	static let unambiguous = Self.ascii.subtracting("lO")
	
	static let lowerVowels = Self("aeiouy")
	static let upperVowels = Self("AEIOUY")
	static let lowerConsonants = Self.lower.subtracting(lowerVowels)
	static let upperConsonants = Self.upper.subtracting(upperVowels)
	
	
	private init(joined elements: Self...) {
		self.init(uncheckedUniqueElements: elements.joined())
	}
	
	init<S: Sequence>(union sequence: S) where S.Element == Self {
		self = sequence.reduce(into: Self()) { result, other in
			result.formUnion(other)
		}
	}
	
	init<S: Sequence>(limitToASCII other: S) where S.Element == Self.Element {
		self = Self.ascii.intersection(other)
	}
}
