import PromptuCore
import SwiftUI
import UniformTypeIdentifiers

/// The grip a block drag starts from. A dedicated handle, because the
/// rows and cells are Buttons and a Button swallows the mouse-down a
/// drag needs; the grip also marks them as draggable in the first
/// place.
struct BlockDragHandle: View {
    let block: Block
    @Binding var draggingKey: String?
    let theme: Theme

    var body: some View {
        Image(systemName: "line.3.horizontal")
            .font(.caption)
            .foregroundStyle(theme.dimmed)
            .padding(.horizontal, 2)
            .onDrag {
                draggingKey = block.key
                return NSItemProvider(object: block.key as NSString)
            }
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

/// Drop delegate for dropping a dragged block onto the preview: insert
/// it at the hovered line's gap. A nil line is the preview container
/// itself, whose gap appends at the end.
struct PreviewDropDelegate: DropDelegate {
    let line: Int?
    let gap: Int
    @Binding var draggingKey: String?
    @Binding var drop: (line: Int?, gap: Int)?
    let session: Session

    func validateDrop(info: DropInfo) -> Bool {
        draggingKey != nil
    }

    func dropEntered(info: DropInfo) {
        drop = (line: line, gap: gap)
    }

    func dropExited(info: DropInfo) {
        if drop?.line == line, drop?.gap == gap { drop = nil }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .copy)
    }

    func performDrop(info: DropInfo) -> Bool {
        drop = nil
        defer { draggingKey = nil }
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
