import PromptuCore
import SwiftUI
import UniformTypeIdentifiers

/// A hover-highlighted row/cell that runs an action on click and can
/// also start a drag — a real Button can't, it swallows the mouse-down
/// the drag needs.
struct DraggableButton<Label: View>: View {
    let theme: Theme
    let action: () -> Void
    let drag: () -> NSItemProvider
    @ViewBuilder let label: () -> Label
    @State private var hovering = false

    var body: some View {
        label()
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(hovering ? theme.hover : .clear, in: RoundedRectangle(cornerRadius: 4))
            .contentShape(Rectangle())
            .onHover { hovering = $0 }
            .accessibilityAddTraits(.isButton)
            .onDrag(drag)
            .onTapGesture(perform: action)
    }
}

/// The ≡ icon marking a draggable row.
struct Grip: View {
    let theme: Theme

    var body: some View {
        Image(systemName: "line.3.horizontal")
            .font(.caption)
            .foregroundStyle(theme.dimmed)
            .padding(.horizontal, 2)
    }
}

/// A grip a drag starts from, for preview entries: the lines
/// themselves stay selectable text, so they can't double as the drag
/// zone.
struct DragHandle: View {
    let theme: Theme
    let begin: () -> NSItemProvider

    var body: some View {
        Grip(theme: theme).onDrag(begin)
    }
}

/// Drop delegate for the preview: a block dragged from the grid is
/// inserted at the hovered line's gap, an entry dragged from another
/// preview line is moved there. A nil line is the preview container
/// itself, whose gap appends at the end.
struct PreviewDropDelegate: DropDelegate {
    let line: Int?
    let gap: Int
    @Binding var draggingKey: String?
    @Binding var draggingEntry: Int?
    @Binding var drop: (line: Int?, gap: Int)?
    let session: Session

    func validateDrop(info: DropInfo) -> Bool {
        draggingKey != nil || draggingEntry != nil
    }

    func dropEntered(info: DropInfo) {
        drop = (line: line, gap: gap)
    }

    func dropExited(info: DropInfo) {
        if drop?.line == line, drop?.gap == gap { drop = nil }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: draggingEntry != nil ? .move : .copy)
    }

    func performDrop(info: DropInfo) -> Bool {
        drop = nil
        defer {
            draggingKey = nil
            draggingEntry = nil
        }
        if let entry = draggingEntry {
            session.moveEntry(entry, to: gap)
            return true
        }
        guard let key = draggingKey,
            let block = session.blocks.first(where: { $0.key == key })
        else { return false }
        session.insert(block, at: gap)
        return true
    }
}
