// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DMGCanvasApp",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "DMGCanvasApp", targets: ["DMGCanvasApp"])
    ],
    targets: [
        .executableTarget(
            name: "DMGCanvasApp",
            path: "Sources/DMGCanvasApp"
        )
    ]
)
