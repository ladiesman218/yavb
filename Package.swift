// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "yavb",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.89.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.8.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.7.2"),
        .package(url: "https://github.com/vapor/jwt.git", from: "5.0.0-beta.4"),
        .package(url: "https://github.com/vapor/leaf.git", from: "4.2.4"),
        .package(url: "https://github.com/vapor/redis.git", from: "4.0.0"),
        .package(url: "https://github.com/sushichop/Puppy.git", from: "0.7.0"),
        .package(url: "https://github.com/Joannis/VaporSMTPKit.git", from: "1.0.0"),
        // Generate fake db data for dev
        .package(url: "https://github.com/vadymmarkov/Fakery", from: "5.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "Leaf", package: "leaf"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "JWT", package: "JWT"),
                .product(name: "Redis", package: "redis"),
                .product(name: "Puppy", package: "Puppy"),
                .product(name: "VaporSMTPKit", package: "VaporSMTPKit"),
                .product(name: "Fakery", package: "Fakery"),
            ]
//            ,
//            swiftSettings: [
//                .enableUpcomingFeature("StrictConcurrency")
//            ]
        ),
        .testTarget(name: "AppTests",
            dependencies: [
                .target(name: "App"),
                .product(name: "XCTVapor", package: "vapor"),
                        
                // Workaround for https://github.com/apple/swift-package-manager/issues/6940
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "Fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "Leaf", package: "leaf"),
                .product(name: "Redis", package: "redis"),
                .product(name: "Puppy", package: "Puppy"),
            ]
        )
    ]
)
