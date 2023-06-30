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
			alwaysCompactUsageOptions: true
		)
	}
	
	func run() throws {
		
	}
}
