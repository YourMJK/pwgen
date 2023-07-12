// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "pwgen",
	products: [
		.executable(name: "pwgen", targets: ["pwgen"]),
	],
	dependencies: [
		.package(url: "https://github.com/YourMJK/CommandLineTool", from: "1.0.0"),
		.package(url: "https://github.com/apple/swift-collections", .upToNextMajor(from: "1.0.0")),
	],
	targets: [
		.executableTarget(
			name: "pwgen",
			dependencies: [
				"CommandLineTool",
				.product(name: "OrderedCollections", package: "swift-collections")
			],
			path: "pwgen"
		),
	]
)
