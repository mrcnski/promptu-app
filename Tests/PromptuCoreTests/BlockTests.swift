import Testing

@testable import PromptuCore

// MARK: - moving(_:toGap:)

private let blocks = [
    Block(key: "a", desc: "", text: "A"),
    Block(key: "b", desc: "", text: "B"),
    Block(key: "c", desc: "", text: "C"),
]

@Test func movingToLaterGapLandsBeforeIt() {
    #expect(blocks.moving("a", toGap: 2).map(\.key) == ["b", "a", "c"])
    #expect(blocks.moving("a", toGap: 3).map(\.key) == ["b", "c", "a"])
}

@Test func movingToEarlierGapLandsAtIt() {
    #expect(blocks.moving("c", toGap: 0).map(\.key) == ["c", "a", "b"])
    #expect(blocks.moving("c", toGap: 1).map(\.key) == ["a", "c", "b"])
}

@Test func movingToItsOwnGapsChangesNothing() {
    #expect(blocks.moving("b", toGap: 1) == blocks)
    #expect(blocks.moving("b", toGap: 2) == blocks)
}

@Test func movingUnknownKeyChangesNothing() {
    #expect(blocks.moving("x", toGap: 0) == blocks)
}
