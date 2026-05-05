import AppKit
import Foundation

guard CommandLine.arguments.count == 7 else {
    fputs("usage: crop_image.swift <input> <output> <x> <y> <width> <height>\n", stderr)
    exit(1)
}

let inputPath = CommandLine.arguments[1]
let outputPath = CommandLine.arguments[2]
guard
    let x = Double(CommandLine.arguments[3]),
    let y = Double(CommandLine.arguments[4]),
    let width = Double(CommandLine.arguments[5]),
    let height = Double(CommandLine.arguments[6])
else {
    fputs("invalid crop values\n", stderr)
    exit(1)
}

let inputURL = URL(fileURLWithPath: inputPath)
guard let image = NSImage(contentsOf: inputURL) else {
    fputs("failed to open image\n", stderr)
    exit(1)
}

var proposedRect = NSRect(origin: .zero, size: image.size)
guard let cgImage = image.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil) else {
    fputs("failed to read cgImage\n", stderr)
    exit(1)
}

let pixelHeight = cgImage.height
let cropRect = CGRect(
    x: x,
    y: y,
    width: width,
    height: height
).integral

guard let cropped = cgImage.cropping(to: cropRect) else {
    fputs("failed to crop image\n", stderr)
    exit(1)
}

let rep = NSBitmapImageRep(cgImage: cropped)
guard let pngData = rep.representation(using: .png, properties: [:]) else {
    fputs("failed to encode png\n", stderr)
    exit(1)
}

try pngData.write(to: URL(fileURLWithPath: outputPath))
print(outputPath)
