import PromptuCore
import SwiftUI

struct ComposerView: View {
    @ObservedObject var session: Session
    /// Closes the hosting popover; injected because the view is hosted
    /// in an NSPopover, outside any SwiftUI presentation context.
    let close: () -> Void
    @FocusState private var keysFocused: Bool
    @FocusState private var fieldFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

    private var theme: Theme { .matching(colorScheme) }
    private var fieldShown: Bool { session.pending != nil || session.editInput != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            preview
            if let error = session.loadError {
                Text(error).foregroundStyle(theme.error).font(.caption)
            } else if session.editInput != nil {
                editField
            } else if session.pending != nil {
                placeholderField
            } else {
                blockGrid
            }
            Divider().overlay(theme.dimmed.opacity(0.3))
            footer
        }
        .padding(12)
        .frame(width: 380)
        .background(theme.background)
        .focusable()
        .focusEffectDisabled()
        .focused($keysFocused)
        .onKeyPress(phases: [.down, .repeat]) { handleKey($0) }
        .onAppear { keysFocused = true }
        .onChange(of: fieldShown) { _, shown in
            if shown { fieldFocused = true } else { keysFocused = true }
        }
    }

    /// The preview split into lines, so the scroll view can target the
    /// point marker's line.
    private var previewLines: [String] {
        (session.isEmpty ? "empty prompt" : session.preview)
            .components(separatedBy: "\n")
    }

    private var preview: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(previewLines.enumerated()), id: \.offset) { idx, line in
                        Text(line)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(previewColor(line))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id(idx)
                    }
                }
            }
            .frame(minHeight: 40, maxHeight: 300)
            .onChange(of: session.preview) {
                // Follow the point: its marker's line when moved, the tail
                // otherwise. The nil anchor scrolls the minimum needed.
                let lines = previewLines
                let target = lines.firstIndex { $0.contains("▮") } ?? lines.count - 1
                proxy.scrollTo(target, anchor: nil)
            }
        }
        .padding(8)
        .background(theme.surface, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(theme.dimmed.opacity(0.15)))
    }

    private func previewColor(_ line: String) -> Color {
        if session.isEmpty { return theme.dimmed }
        return line == "▮" ? theme.key : theme.foreground
    }

    private var blockGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), alignment: .leading),
                      GridItem(.flexible(), alignment: .leading)],
            alignment: .leading, spacing: 3
        ) {
            ForEach(session.blocks) { block in
                Button {
                    session.add(block)
                } label: {
                    HStack(spacing: 8) {
                        Text(block.key)
                            .font(.system(.body, design: .monospaced).bold())
                            .foregroundStyle(theme.key)
                            .frame(width: 22, height: 22)
                            .background(
                                theme.key.opacity(0.12), in: RoundedRectangle(cornerRadius: 5))
                        blockLabel(block)
                            .foregroundStyle(theme.foreground)
                            .lineLimit(1)
                    }
                    // Fill the grid cell, so the hover highlight spans
                    // the whole column.
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(HoverButtonStyle(theme: theme))
            }
        }
    }

    /// The block's menu label: its desc plus colored <placeholder> hints,
    /// standing alone when the desc is empty — the same rules as Emacs
    /// promptu's `promptu--block-description`.
    private func blockLabel(_ block: Block) -> Text {
        guard let hints = Compose.placeholderHints(block) else { return Text(block.desc) }
        let hintText = Text(hints).foregroundStyle(theme.placeholder)
        return block.desc.isEmpty ? hintText : Text(block.desc + " ") + hintText
    }

    private var placeholderField: some View {
        TextField(
            session.pending?.currentName ?? "",
            text: Binding(
                get: { session.pending?.input ?? "" },
                set: { session.pending?.input = $0 }
            )
        )
        .textFieldStyle(.plain)
        .foregroundStyle(theme.foreground)
        .padding(6)
        .background(theme.surface, in: RoundedRectangle(cornerRadius: 6))
        .focused($fieldFocused)
        .onSubmit { session.submitPlaceholder() }
        .onExitCommand { session.cancelPending() }
    }

    private var editField: some View {
        TextField(
            "edit entry",
            text: Binding(
                get: { session.editInput ?? "" },
                set: { session.editInput = $0 }
            )
        )
        .textFieldStyle(.plain)
        .foregroundStyle(theme.foreground)
        .padding(6)
        .background(theme.surface, in: RoundedRectangle(cornerRadius: 6))
        .focused($fieldFocused)
        .onSubmit { session.submitEdit() }
        .onExitCommand { session.cancelEdit() }
    }

    /// The key hints as one two-tone text: keys in the foreground color,
    /// labels dimmed, so the line lays out exactly like a plain string.
    private var keyHints: Text {
        [("-", "negate"), ("⌫", "remove"), ("↑↓", "point"),
         ("⌘E", "edit"), ("⌘Z", "undo"), ("⏎", "copy")]
            .map { key, label in
                Text(key).font(.caption.monospaced().bold())
                    .foregroundStyle(theme.foreground.opacity(0.8))
                    + Text(" \(label)").font(.caption).foregroundStyle(theme.dimmed)
            }
            .enumerated()
            .reduce(Text("")) { $0 + ($1.offset == 0 ? $1.element : Text("  ") + $1.element) }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            if session.negateNext {
                Text("negating next")
                    .font(.caption.bold())
                    .foregroundStyle(theme.placeholder)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(theme.placeholder.opacity(0.15), in: Capsule())
            } else {
                keyHints
            }
            Spacer()
            Button("Quit") { NSApp.terminate(nil) }
                .buttonStyle(HoverButtonStyle(theme: theme))
                .font(.caption)
                .foregroundStyle(theme.dimmed)
                .keyboardShortcut("q", modifiers: .command)
        }
    }

    /// Plain button that highlights under the mouse and dims while pressed.
    private struct HoverButtonStyle: ButtonStyle {
        let theme: Theme

        func makeBody(configuration: Configuration) -> some View {
            Highlighted(configuration: configuration, theme: theme)
        }

        // ButtonStyle itself can't hold per-button @State; this inner
        // view carries the hover flag for each styled button.
        private struct Highlighted: View {
            let configuration: Configuration
            let theme: Theme
            @State private var hovering = false

            var body: some View {
                configuration.label
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        hovering ? theme.hover : .clear,
                        in: RoundedRectangle(cornerRadius: 4))
                    .contentShape(Rectangle())
                    .opacity(configuration.isPressed ? 0.6 : 1)
                    .onHover { hovering = $0 }
            }
        }
    }

    private func handleKey(_ press: KeyPress) -> KeyPress.Result {
        guard !fieldShown else { return .ignored }

        if press.modifiers.contains(.command) {
            switch press.key.character {
            case "e":
                session.beginEdit()
                return .handled
            case "z":
                press.modifiers.contains(.shift) ? session.redo() : session.undo()
                return .handled
            default:
                return .ignored
            }
        }

        if press.modifiers.contains(.control) {
            switch press.key.character {
            case "p": session.pointUp(); return .handled
            case "n": session.pointDown(); return .handled
            default: return .ignored
            }
        }

        switch press.key {
        case .return:
            if session.finish() { close() }
            return .handled
        case .upArrow:
            session.pointUp()
            return .handled
        case .downArrow:
            session.pointDown()
            return .handled
        // Backspace arrives as DEL (U+7F), not KeyEquivalent.delete (U+8).
        case .delete, KeyEquivalent("\u{7F}"):
            session.removeEntry()
            return .handled
        case .escape:
            close()
            return .handled
        default:
            break
        }

        // Everything above may auto-repeat while held; adding is
        // deliberate, so a held block key must not pile up entries or
        // flip negation.
        if press.phase == .repeat { return .handled }

        if press.characters == "-" {
            session.negateNext.toggle()
            return .handled
        }
        if let block = session.blocks.first(where: { $0.key == press.characters }) {
            session.add(block)
            return .handled
        }
        return .ignored
    }
}
