//
//  Generator.CharacterSet.swift
//  pwgen
//
//  Created by Max-Joseph on 10.07.23.
//

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
	static let unambiguous = Self.ascii.subtracting(ambiguous)
	static let unambiguousLowerConsonants = Self("bcdfghjklmnpqrstvwxz").subtracting(ambiguous)
	static let unambiguousUpperConsonants = Self("BCDFGHJKLMNPQRSTVWXZ").subtracting(ambiguous)
	static let unambiguousLowerVowels = Self("aeiouy").subtracting(ambiguous)
	static let unambiguousUpperVowels = Self("AEIOUY").subtracting(ambiguous)
	
	
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
