import SwiftUI

@Observable
final class ClockDragSession {
    private(set) var draggedID: UUID?
    private(set) var startIndex = 0
    private(set) var targetIndex = 0
    private(set) var translation: CGFloat = 0
    private(set) var rowStride: CGFloat = 47
    private(set) var isSettling = false

    func update(id: UUID, translation: CGFloat, rowStride: CGFloat, store: ClockStore) {
        guard !isSettling, rowStride > 0 else { return }
        if draggedID == nil {
            guard let index = store.clocks.firstIndex(where: { $0.id == id }) else { return }
            draggedID = id
            startIndex = index
            targetIndex = index
            self.rowStride = rowStride
        }
        guard draggedID == id else { return }
        self.translation = min(max(translation, -CGFloat(startIndex) * self.rowStride),
                               CGFloat(store.clocks.count - 1 - startIndex) * self.rowStride)
        targetIndex = startIndex + Int((self.translation / self.rowStride).rounded())
    }

    func offset(id: UUID, store: ClockStore) -> CGFloat {
        guard let draggedID else { return 0 }
        if id == draggedID { return translation }
        guard let index = store.clocks.firstIndex(where: { $0.id == id }) else { return 0 }
        if targetIndex > startIndex && index > startIndex && index <= targetIndex { return -rowStride }
        if targetIndex < startIndex && index >= targetIndex && index < startIndex { return rowStride }
        return 0
    }

    func settle() {
        guard draggedID != nil else { return }
        isSettling = true
        translation = CGFloat(targetIndex - startIndex) * rowStride
    }

    func commit(store: ClockStore) {
        if let id = draggedID, let index = store.clocks.firstIndex(where: { $0.id == id }) {
            store.moveClock(id: id, by: targetIndex - index)
        }
        finish()
    }

    func finish() {
        draggedID = nil
        translation = 0
        startIndex = 0
        targetIndex = 0
        isSettling = false
    }
}

/// The colored tile stays in place; only its symbol changes on hover.
struct ClockReorderTile: View {
    let clock: WorldClock
    let store: ClockStore
    let dragSession: ClockDragSession
    let symbol: String
    let color: Color
    let isHovering: Bool
    var rowStride: CGFloat = DS.Size.rowHeight + 1

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var showsHandle: Bool { (isHovering || dragSession.draggedID == clock.id) && store.clocks.count > 1 }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DS.Radius.tile, style: .continuous)
                .fill(color.gradient)
                .frame(width: DS.Size.tile, height: DS.Size.tile)

            Image(systemName: symbol)
                .opacity(showsHandle ? 0 : 1)

            Image(systemName: "line.3.horizontal")
                .frame(width: DS.Size.tile, height: DS.Size.tile)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 3, coordinateSpace: .global)
                        .onChanged { value in
                            dragSession.update(id: clock.id, translation: value.translation.height,
                                               rowStride: rowStride, store: store)
                        }
                        .onEnded { _ in
                            guard dragSession.draggedID == clock.id else { return }
                            if reduceMotion {
                                dragSession.settle()
                                dragSession.commit(store: store)
                            } else {
                                withAnimation(.snappy(duration: 0.2), completionCriteria: .logicallyComplete) {
                                    dragSession.settle()
                                } completion: {
                                    guard dragSession.draggedID == clock.id else { return }
                                    var transaction = Transaction()
                                    transaction.disablesAnimations = true
                                    withTransaction(transaction) { dragSession.commit(store: store) }
                                }
                            }
                        }
                )
                .help("Drag to reorder")
                .accessibilityLabel(Text("Drag to reorder"))
                .accessibilityAction(named: Text("Move clock up")) {
                    withAnimation(reduceMotion ? nil : .snappy(duration: 0.25)) {
                        store.moveClock(id: clock.id, by: -1)
                    }
                }
                .accessibilityAction(named: Text("Move clock down")) {
                    withAnimation(reduceMotion ? nil : .snappy(duration: 0.25)) {
                        store.moveClock(id: clock.id, by: 1)
                    }
                }
                .opacity(showsHandle ? 1 : 0)
                .allowsHitTesting(showsHandle)
                .accessibilityHidden(store.clocks.count < 2)
        }
        .font(.system(size: DS.Size.tile * 0.5, weight: .semibold))
        .foregroundStyle(.white)
        .shadow(color: color.opacity(0.25), radius: 1, y: 0.5)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.15), value: showsHandle)
    }
}

private struct ClockReordering: ViewModifier {
    let clock: WorldClock
    let store: ClockStore
    let dragSession: ClockDragSession
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isDragging: Bool { dragSession.draggedID == clock.id }

    func body(content: Content) -> some View {
        content
            .background {
                if isDragging {
                    RoundedRectangle(cornerRadius: DS.Radius.row)
                        .fill(.regularMaterial)
                        .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                }
            }
            .offset(y: dragSession.offset(id: clock.id, store: store))
            .animation(
                reduceMotion || (isDragging && !dragSession.isSettling) ? nil : .snappy(duration: 0.2),
                value: dragSession.offset(id: clock.id, store: store)
            )
            .zIndex(isDragging ? 1 : 0)
    }
}

extension View {
    func clockReordering(clock: WorldClock, store: ClockStore, dragSession: ClockDragSession) -> some View {
        modifier(ClockReordering(clock: clock, store: store, dragSession: dragSession))
    }
}
