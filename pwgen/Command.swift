//
//  Command.swift
//  pwgen
//
//  Created by Max-Joseph on 30.06.23.
//

import Foundation
import CommandLineTool
import ArgumentParser

@main
struct Command: ParsableCommand {
	static var configuration: CommandConfiguration {
		CommandConfiguration(
			commandName: executableName,
			version: "1.0.1",
			helpMessageLabelColumnWidth: 20,
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
		
		mutating func validate() throws {
			guard minimumLength > 0 else {
				throw ValidationError("Please specify a 'minimum length' greater than 0.")
			}
			guard separator.count == 1 else {
				throw ValidationError("Please specify exactly one 'separator' character.")
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
		let generator = try PasswordGenerator(
			style: passwordOptions.random ? .random : .nice,
			minimumLength: passwordOptions.minimumLength,
			grouped: !passwordOptions.noGroup,
			groupSeparator: passwordOptions.separator.first!
		)
		for _ in 0..<generalOptions.numberOfPasswords {
			stdout(generator.newPassword())
		}
	}
}
