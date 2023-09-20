//
//  Command.swift
//  pwgen
//
//  Created by Max-Joseph on 30.06.23.
//

import Foundation
import CommandLineTool
import ArgumentParser
import PasswordGenerator

@main
struct Command: ParsableCommand {
	static var configuration: CommandConfiguration {
		CommandConfiguration(
			commandName: executableName,
			version: "1.2.2",
			helpMessageLabelColumnWidth: 36,
			alwaysCompactUsageOptions: true
		)
	}
	
	struct PasswordOptions: ParsableArguments {
		@Option(name: .customShort("l"), help: ArgumentHelp("The minimum number of characters the password should be long. Always matches actual length if \"--random\" and \"--no-group\" flags are both set.", valueName: "amount"))
		var minimumLength: Int = 18
		
		@Flag(name: .shortAndLong, help: ArgumentHelp("Uniformly choose a random character for each position instead of generating a \"more typeable\" password."))
		var random = false
		
		@Flag(name: [.customShort("g"), .long], help: ArgumentHelp("Don't split password into more readable groups of characters by inserting the separator character (dash by default) at equal intervals."))
		var noGroup = false
		
		@Option(name: .short, help: ArgumentHelp("The separator character used for splitting the password into groups. Ignored when \"--no-group\" flag is set.", valueName: "character"))
		var separator: String = String(PasswordGenerator.defaultGroupSeparator)
		
		@Option(name: .long, help: ArgumentHelp("The set of characters which are allowed to occur in the password. Specify any of (\(CharacterSetString.allCasesRegexString)) or a custom string of (ASCII-printable) characters surrounded by [ and ], e.g. \"[abc123]\".", valueName: "character set"))
		var allowed: String = CharacterSetString.string(from: PasswordGenerator.defaultAllowedCharacters)
		
		@Option(name: .long, parsing: .upToNextOption, help: ArgumentHelp("The required character sets. The generated password will contain at least one character of each specified required set. See help for the \"--allowed\" option on how to specify character sets. Characters not present in the allowed characters will be removed from each set.", valueName: "character set ..."))
		var required: [String] = PasswordGenerator.defaultRequiredCharacterSets.map(CharacterSetString.string(from:))
		
		@Option(name: .long, help: ArgumentHelp("The maximum allowed length for any sequence of repeated characters in the password. E.g. for \"aaba\" the longest sequence has a length of 2. Unlimited if not specified.", valueName: "amount"))
		var repeated: Int?
		
		@Option(name: .long, help: ArgumentHelp("The maximum allowed length for any sequence of consecutive characters in the password. E.g. both \"123\" or \"abc\" and \"321\" or \"cba\" are considered consecutive. Unlimited if not specified.", valueName: "amount"))
		var consecutive: Int?
		
		mutating func validate() throws {
			guard minimumLength > 0 else {
				throw ValidationError("Please specify a 'minimum length' greater than 0.")
			}
			guard separator.count == 1 else {
				throw ValidationError("Please specify exactly one 'separator' character.")
			}
			if let repeated {
				guard repeated > 0 else {
					throw ValidationError("Please specify a 'repeated character limit' greater than 0.")
				}
			}
			if let consecutive {
				guard consecutive > 0 else {
					throw ValidationError("Please specify a 'consecutive character limit' greater than 0.")
				}
			}
		}
	}
	
	struct GeneralOptions: ParsableArguments {
		@Option(name: .short, help: ArgumentHelp("The number of passwords to generate. Each password will be printed in a new line.", valueName: "amount"))
		var numberOfPasswords: UInt = 1
		
		mutating func validate() throws {
			guard numberOfPasswords > 0 else {
				throw ValidationError("Please specify a 'number of passwords' amount greater than 0.")
			}
		}
	}
	
	@OptionGroup(title: "Password Options")
	var passwordOptions: PasswordOptions
	
	@OptionGroup
	var generalOptions: GeneralOptions
	
	func run() throws {
		let allowedCharacters = try CharacterSetString.characterSet(from: passwordOptions.allowed)
		let requiredCharacterSets = try passwordOptions.required.map(CharacterSetString.characterSet(from:))
		
		let generator = try PasswordGenerator(
			style: passwordOptions.random ? .random : .nice,
			minimumLength: passwordOptions.minimumLength,
			grouped: !passwordOptions.noGroup,
			groupSeparator: passwordOptions.separator.first!,
			allowedCharacters: allowedCharacters,
			requiredCharacterSets: requiredCharacterSets,
			repeatedCharacterLimit: passwordOptions.repeated,
			consecutiveCharacterLimit: passwordOptions.consecutive
		)
		for _ in 0..<generalOptions.numberOfPasswords {
			stdout(generator.newPassword())
		}
	}
}
