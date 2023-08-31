// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "pwgen",
	products: [
		.executable(name: "pwgen", targets: ["pwgen"]),
		.library(name: "PasswordGenerator", targets: ["PasswordGenerator"]),
	],
	dependencies: [
		.package(url: "https://github.com/YourMJK/CommandLineTool", from: "1.1.0"),
		.package(url: "https://github.com/apple/swift-collections", .upToNextMajor(from: "1.0.0")),
	],
	targets: [
		.executableTarget(
			name: "pwgen",
			dependencies: [
				"CommandLineTool",
				"PasswordGenerator",
			],
			path: "pwgen"
		),
		.target(
			name: "PasswordGenerator",
			dependencies: [
				.product(name: "OrderedCollections", package: "swift-collections")
			],
			path: "PasswordGenerator"
		),
	]
)
