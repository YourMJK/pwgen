//
//  PasswordGenerator.CharacterSet.swift
//  pwgen
//
//  Created by Max-Joseph on 10.07.23.
//

import OrderedCollections


extension PasswordGenerator {
	public typealias CharacterSet = OrderedSet<Character>
}

extension PasswordGenerator.CharacterSet {
	public static let lower = Self("abcdefghijklmnopqrstuvwxyz")
	public static let upper = Self("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
	public static let digits = Self("0123456789")
	public static let special = Self(#"-~!@#$%^&*_+=`|(){}[:;\"'<>,.?/ ]"#)
	
	public static let ascii = Self(joined: .lower, .upper, .digits, .special)
	public static let alphanumeric = Self(joined: .lower, .upper, .digits)
	public static let unambiguous = Self.ascii.subtracting("lO")
	
	public static let lowerVowels = Self("aeiouy")
	public static let upperVowels = Self("AEIOUY")
	public static let lowerConsonants = Self.lower.subtracting(lowerVowels)
	public static let upperConsonants = Self.upper.subtracting(upperVowels)
	
	
	private init(joined elements: Self...) {
		self.init(uncheckedUniqueElements: elements.joined())
	}
	
	public init<S: Sequence>(union sequence: S) where S.Element == Self {
		self = sequence.reduce(into: Self()) { result, other in
			result.formUnion(other)
		}
	}
	
	public init<S: Sequence>(limitToASCII other: S) where S.Element == Self.Element {
		self = Self.ascii.intersection(other)
	}
}
