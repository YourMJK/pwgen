// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "pwgen",
	products: [
		.executable(name: "pwgen", targets: ["pwgen"]),
	],
	dependencies: [
		.package(url: "https://github.com/YourMJK/CommandLineTool", branch: "main"),
	],
	targets: [
		.executableTarget(
			name: "pwgen",
			dependencies: [
				"CommandLineTool"
			],
			path: "pwgen"
		),
	]
)
