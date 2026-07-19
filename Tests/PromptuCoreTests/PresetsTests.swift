import Foundation
import Testing

@testable import PromptuCore

private func tempDir() throws -> URL {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("promptu-presets-tests-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir
}

@Test func pageURLsPutBlocksFirstThenOthersAlphabetically() throws {
    let dir = try tempDir()
    defer { try? FileManager.default.removeItem(at: dir) }
    for name in ["ship.json", "build.json", "blocks.json", "notes.txt"] {
        try Data("[]".utf8).write(to: dir.appendingPathComponent(name))
    }

    let names = Presets.pageURLs(in: dir).map(\.lastPathComponent)
    #expect(names == ["blocks.json", "build.json", "ship.json"])
}

@Test func pageURLsListBlocksEvenWhenMissing() throws {
    let dir = try tempDir()
    defer { try? FileManager.default.removeItem(at: dir) }

    #expect(Presets.pageURLs(in: dir).map(\.lastPathComponent) == ["blocks.json"])
}

@Test func bundledPresetsAreValidPages() throws {
    for (fileName, json) in Presets.defaults {
        let blocks = try JSONDecoder().decode([Block].self, from: Data(json.utf8))
        #expect(!blocks.isEmpty, "\(fileName)")
        #expect(Set(blocks.map(\.key)).count == blocks.count, "\(fileName)")
        // Each page is in the house style and its placeholders match
        // the {name}s in its texts, like the block editor would derive.
        #expect(BlocksConfig.serialize(blocks) == json, "\(fileName)")
        for block in blocks {
            #expect(
                block.placeholders
                    == Compose.derivePlaceholders(text: block.text, negative: block.negative),
                "\(fileName)/\(block.key)")
        }
    }
}

@Test func seedWritesOnlyTheMissingPresetFiles() throws {
    let dir = try tempDir()
    defer { try? FileManager.default.removeItem(at: dir) }
    let existing = dir.appendingPathComponent("build.json")
    try Data("[]".utf8).write(to: existing)

    try Presets.seed(into: dir)
    #expect(try String(contentsOf: existing, encoding: .utf8) == "[]")
    for (fileName, json) in Presets.defaults where fileName != "build.json" {
        let url = dir.appendingPathComponent(fileName)
        #expect(try String(contentsOf: url, encoding: .utf8) == json + "\n")
    }
}
