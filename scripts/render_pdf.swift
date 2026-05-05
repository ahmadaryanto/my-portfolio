import AppKit
import Foundation
import PDFKit

guard CommandLine.arguments.count >= 3 else {
    fputs("usage: render_pdf.swift <input.pdf> <output_dir>\n", stderr)
    exit(1)
}

let inputPath = CommandLine.arguments[1]
let outputDir = CommandLine.arguments[2]
let fm = FileManager.default

let inputURL = URL(fileURLWithPath: inputPath)
guard let document = PDFDocument(url: inputURL) else {
    fputs("failed to open pdf: \(inputPath)\n", stderr)
    exit(1)
}

try fm.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

for pageIndex in 0..<document.pageCount {
    guard let page = document.page(at: pageIndex) else { continue }

    if let text = page.string {
        let textURL = URL(fileURLWithPath: outputDir).appendingPathComponent(String(format: "page-%02d.txt", pageIndex + 1))
        try text.write(to: textURL, atomically: true, encoding: .utf8)
    }

    let pageRect = page.bounds(for: .mediaBox)
    let scale: CGFloat = 2.0
    let width = max(Int(pageRect.width * scale), 1)
    let height = max(Int(pageRect.height * scale), 1)

    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: width,
        pixelsHigh: height,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        fputs("failed to create bitmap for page \(pageIndex + 1)\n", stderr)
        continue
    }

    NSGraphicsContext.saveGraphicsState()
    guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        NSGraphicsContext.restoreGraphicsState()
        fputs("failed to create graphics context for page \(pageIndex + 1)\n", stderr)
        continue
    }
    NSGraphicsContext.current = context

    NSColor.white.setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: width, height: height)).fill()

    let cgContext = context.cgContext
    cgContext.scaleBy(x: scale, y: scale)
    page.draw(with: .mediaBox, to: cgContext)

    NSGraphicsContext.restoreGraphicsState()

    if let pngData = bitmap.representation(using: .png, properties: [:]) {
      let imageURL = URL(fileURLWithPath: outputDir).appendingPathComponent(String(format: "page-%02d.png", pageIndex + 1))
      try pngData.write(to: imageURL)
    }
}

print("rendered \(document.pageCount) pages to \(outputDir)")
