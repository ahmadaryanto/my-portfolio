import AppKit
import Foundation
import Vision

guard CommandLine.arguments.count >= 2 else {
    fputs("usage: ocr_images.swift <image_dir>\n", stderr)
    exit(1)
}

let imageDir = CommandLine.arguments[1]
let fm = FileManager.default
let dirURL = URL(fileURLWithPath: imageDir)

guard let files = try? fm.contentsOfDirectory(at: dirURL, includingPropertiesForKeys: nil)
    .filter({ $0.pathExtension.lowercased() == "png" })
    .sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) else {
    fputs("failed to list directory: \(imageDir)\n", stderr)
    exit(1)
}

for fileURL in files {
    guard let image = NSImage(contentsOf: fileURL) else { continue }
    var rect = NSRect(origin: .zero, size: image.size)
    guard let cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil) else { continue }

    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true

    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    do {
        try handler.perform([request])
    } catch {
        fputs("ocr failed for \(fileURL.lastPathComponent): \(error)\n", stderr)
        continue
    }

    let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
    let lines = observations.compactMap { $0.topCandidates(1).first?.string }
    let outURL = dirURL.appendingPathComponent(fileURL.deletingPathExtension().lastPathComponent + ".txt")
    try? lines.joined(separator: "\n").write(to: outURL, atomically: true, encoding: .utf8)
    print("ocr \(fileURL.lastPathComponent)")
}
