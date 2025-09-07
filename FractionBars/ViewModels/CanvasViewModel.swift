import SwiftUI

@MainActor
class CanvasViewModel: ObservableObject {
    @Published var bars: [Bar] = []
    @Published var mats: [Mat] = []
    @Published var selectedBarIDs: Set<UUID> = []
    @Published var selectedMatIDs: Set<UUID> = []
    @Published var currentTool: Tool = .select
    @Published var newObjectRect: CGRect?
    @Published var currentColor: Color = .yellow

    private var initialDragPositions: [UUID: CGPoint] = [:]

    private var undoStack: [CanvasState] = []
    private var redoStack: [CanvasState] = []

    private var saveFileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("fractionbars.json")
    }

    enum Tool: Equatable {
        case select
        case bar
        case mat
    }

    func addBar(rect: CGRect) {
        addUndoState()
        let newBar = Bar(x: rect.minX, y: rect.minY, w: rect.width, h: rect.height, color: currentColor)
        bars.append(newBar)
    }

    func addMat(rect: CGRect) {
        addUndoState()
        let newMat = Mat(x: rect.minX, y: rect.minY, w: rect.width, h: rect.height, color: .gray) // Mats have a fixed color for now
        mats.append(newMat)
    }

    func deleteSelected() {
        addUndoState()
        bars.removeAll { selectedBarIDs.contains($0.id) }
        mats.removeAll { selectedMatIDs.contains($0.id) }
        selectedBarIDs.removeAll()
        selectedMatIDs.removeAll()
    }

    func selectBar(at point: CGPoint) {
        // This is a selection change, not an undoable action in this implementation
        bars = bars.map { var bar = $0; bar.isSelected = false; return bar }
        selectedBarIDs.removeAll()

        if let index = bars.lastIndex(where: { bar in
            CGRect(x: bar.x, y: bar.y, width: bar.w, height: bar.h).contains(point)
        }) {
            bars[index].isSelected = true
            selectedBarIDs.insert(bars[index].id)
        }
    }

    func startDragging() {
        addUndoState()
        initialDragPositions.removeAll()
        for bar in bars {
            if bar.isSelected {
                initialDragPositions[bar.id] = CGPoint(x: bar.x, y: bar.y)
            }
        }
    }

    func dragSelectedBars(by offset: CGSize) {
        for i in 0..<bars.count {
            if let initialPosition = initialDragPositions[bars[i].id] {
                bars[i].x = initialPosition.x + offset.width
                bars[i].y = initialPosition.y + offset.height
            }
        }
    }

    private func addUndoState() {
        let currentState = CanvasState(bars: bars, mats: mats)
        undoStack.append(currentState)
        redoStack.removeAll()
        // Limit undo stack size
        if undoStack.count > 100 {
            undoStack.removeFirst()
        }
    }

    func undo() {
        guard let previousState = undoStack.popLast() else { return }
        let currentState = CanvasState(bars: bars, mats: mats)
        redoStack.append(currentState)

        self.bars = previousState.bars
        self.mats = previousState.mats
    }

    func redo() {
        guard let nextState = redoStack.popLast() else { return }
        let currentState = CanvasState(bars: bars, mats: mats)
        undoStack.append(currentState)

        self.bars = nextState.bars
        self.mats = nextState.mats
    }

    func save() {
        let state = CanvasState(bars: bars, mats: mats)
        do {
            let data = try JSONEncoder().encode(state)
            try data.write(to: saveFileURL)
            print("Saved to \(saveFileURL)")
        } catch {
            print("Error saving state: \(error)")
        }
    }

    func load() {
        do {
            let data = try Data(contentsOf: saveFileURL)
            let state = try JSONDecoder().decode(CanvasState.self, from: data)
            self.bars = state.bars
            self.mats = state.mats
            undoStack.removeAll()
            redoStack.removeAll()
            print("Loaded from \(saveFileURL)")
        } catch {
            print("Error loading state: \(error)")
        }
    }
}
