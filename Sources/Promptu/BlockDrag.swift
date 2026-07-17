import PromptuCore
import SwiftUI
import UniformTypeIdentifiers

/// The ≡ grip a drag starts from. A dedicated handle, because block
/// rows and cells are Buttons — which swallow the mouse-down a drag
/// needs — and preview lines are selectable text; the grip also marks
/// them as draggable in the first place.
struct DragHandle: View {
    let theme: Theme
    let begin: () -> NSItemProvider

    var body: some View {
        Image(systemName: "line.3.horizontal")
            .font(.caption)
            .foregroundStyle(theme.dimmed)
            .padding(.horizontal, 2)
            .onDrag(begin)
    }
}

/// Drop delegate for dropping one block on another: the dragged block
/// takes the target's slot on drop. No live reordering on hover — a
/// drag headed for the preview crosses other cells, and must not
/// shuffle them in passing.
struct BlockReorderDelegate: DropDelegate {
    let targetKey: String
    @Binding var draggingKey: String?
    @Binding var dropTargetKey: String?
    let session: Session

    func validateDrop(info: DropInfo) -> Bool {
        draggingKey != nil && draggingKey != targetKey
    }

    func dropEntered(info: DropInfo) {
        dropTargetKey = targetKey
    }

    func dropExited(info: DropInfo) {
        if dropTargetKey == targetKey { dropTargetKey = nil }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        dropTargetKey = nil
        defer { draggingKey = nil }
        guard let key = draggingKey else { return false }
        session.moveBlock(key, over: targetKey)
        return true
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

extension View {
    /// Make this row/cell a reorder drop target, highlighted while a
    /// dragged block hovers over it.
    func blockDropTarget(
        _ block: Block, draggingKey: Binding<String?>, dropTargetKey: Binding<String?>,
        theme: Theme, session: Session
    ) -> some View {
        background(
            dropTargetKey.wrappedValue == block.key ? theme.hover : .clear,
            in: RoundedRectangle(cornerRadius: 4)
        )
        .onDrop(
            of: [.text],
            delegate: BlockReorderDelegate(
                targetKey: block.key, draggingKey: draggingKey,
                dropTargetKey: dropTargetKey, session: session))
    }
}
