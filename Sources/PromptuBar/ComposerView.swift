import PromptuCore
import SwiftUI

struct ComposerView: View {
    @ObservedObject var session: Session
    @Environment(\.dismiss) private var dismiss
    @FocusState private var keysFocused: Bool
    @FocusState private var fieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            preview
            Divider()
            if let error = session.loadError {
                Text(error).foregroundStyle(.red).font(.caption)
            } else if session.pending != nil {
                placeholderPrompt
            } else {
                blockGrid
            }
            Divider()
            footer
        }
        .padding(12)
        .frame(width: 380)
        .focusable()
        .focusEffectDisabled()
        .focused($keysFocused)
        .onKeyPress(phases: .down) { handleKey($0) }
        .onAppear { keysFocused = true }
        .onChange(of: session.pending == nil) { _, noPending in
            if noPending { keysFocused = true } else { fieldFocused = true }
        }
    }

    private var preview: some View {
        ScrollView {
            Text(session.entries.isEmpty ? "empty prompt" : session.composed)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(session.entries.isEmpty ? .secondary : .primary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: 40, maxHeight: 160)
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
                    HStack(spacing: 6) {
                        Text(block.key)
                            .font(.system(.body, design: .monospaced).bold())
                            .foregroundStyle(.orange)
                        Text(block.desc.isEmpty ? block.text : block.desc)
                            .lineLimit(1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var placeholderPrompt: some View {
        TextField(
            session.pending?.currentName ?? "",
            text: Binding(
                get: { session.pending?.input ?? "" },
                set: { session.pending?.input = $0 }
            )
        )
        .textFieldStyle(.roundedBorder)
        .focused($fieldFocused)
        .onSubmit { session.submitPlaceholder() }
        .onExitCommand { session.cancelPending() }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            if session.negateNext {
                Text("negating next")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
            } else {
                Text("- negate   ⌫ remove   ⏎ copy")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Quit") { NSApp.terminate(nil) }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.secondary)
                .keyboardShortcut("q", modifiers: .command)
        }
    }

    private func handleKey(_ press: KeyPress) -> KeyPress.Result {
        guard session.pending == nil else { return .ignored }
        switch press.key {
        case .return:
            if session.finish() { dismiss() }
            return .handled
        case .delete:
            session.removeLast()
            return .handled
        case .escape:
            dismiss()
            return .handled
        default:
            break
        }
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
