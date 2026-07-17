import Foundation

/// One building block, as read from blocks.json.
///
/// Mirrors the block plist schema of Emacs promptu's `promptu-blocks`.
public struct Block: Codable, Hashable, Identifiable, Sendable {
    public var key: String
    public var desc: String
    public var text: String
    public var negative: String?
    public var placeholders: [String]?

    public var id: String { key }

    public init(
        key: String, desc: String, text: String,
        negative: String? = nil, placeholders: [String]? = nil
    ) {
        self.key = key
        self.desc = desc
        self.text = text
        self.negative = negative
        self.placeholders = placeholders
    }
}

extension [Block] {
    /// The list with the block for `key` moved to `gap` (indices as
    /// they are before the move) — where a drag's insertion bar shows.
    /// Unchanged when the key is missing or the move changes nothing.
    public func moving(_ key: String, toGap gap: Int) -> [Block] {
        guard let from = firstIndex(where: { $0.key == key }) else { return self }
        let dest = gap > from ? gap - 1 : gap
        guard dest != from else { return self }
        var moved = self
        moved.insert(moved.remove(at: from), at: dest)
        return moved
    }
}
