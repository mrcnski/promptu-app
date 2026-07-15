import AppKit
import PromptuCore

/// Mutable composition state behind the menubar popover.
@MainActor
final class Session: ObservableObject {
    /// A block waiting for its placeholder values, filled in one at a time.
    struct Pending {
        var block: Block
        var negated: Bool
        var names: [String]
        var values: [String: String] = [:]
        var input = ""

        var currentName: String { names[values.count] }
    }

    let blocks: [Block]
    let loadError: String?

    @Published private(set) var entries: [String] = []
    @Published var negateNext = false
    @Published var pending: Pending?

    init() {
        do {
            blocks = try BlocksConfig.load()
            loadError = nil
        } catch {
            blocks = []
            loadError = "Can't read \(BlocksConfig.defaultURL.path): \(error.localizedDescription)"
        }
    }

    var composed: String { Compose.compose(entries) }

    func add(_ block: Block) {
        let negated = negateNext
        negateNext = false
        let names = Compose.activePlaceholders(block, negated: negated)
        if names.isEmpty {
            entries.append(Compose.resolve(block, negated: negated))
        } else {
            pending = Pending(block: block, negated: negated, names: names)
        }
    }

    func submitPlaceholder() {
        guard var p = pending else { return }
        p.values[p.currentName] = p.input
        p.input = ""
        if p.values.count == p.names.count {
            entries.append(
                Compose.substitute(
                    Compose.resolve(p.block, negated: p.negated), values: p.values))
            pending = nil
        } else {
            pending = p
        }
    }

    func cancelPending() {
        pending = nil
    }

    func removeLast() {
        if !entries.isEmpty { entries.removeLast() }
    }

    /// Copy the composed prompt to the clipboard and start over.
    /// Returns false (and does nothing) when the prompt is empty.
    func finish() -> Bool {
        guard !entries.isEmpty else { return false }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(composed, forType: .string)
        entries = []
        negateNext = false
        pending = nil
        return true
    }
}
