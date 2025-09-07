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
    @Published var showingSplitDialog = false
    @Published var isEditingLabel = false
    @Published var unitBarID: UUID?

    var selectedBar: Binding<Bar>? {
        guard selectedBarIDs.count == 1,
              let barId = selectedBarIDs.first,
              let index = bars.firstIndex(where: { $0.id == barId }) else {
            return nil
        }
        return .init(
            get: { self.bars[index] },
            set: { self.bars[index] = $0 }
        )
    }

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

    func copySelected() {
        addUndoState()

        var newBars: [Bar] = []
        let offset: CGFloat = 20

        for i in 0..<bars.count {
            if selectedBarIDs.contains(bars[i].id) {
                var newBar = bars[i]
                newBar.id = UUID()
                newBar.x += offset
                newBar.y += offset
                newBar.isSelected = true
                bars[i].isSelected = false
                newBars.append(newBar)
            }
        }

        selectedBarIDs.removeAll()
        for bar in newBars {
            bars.append(bar)
            selectedBarIDs.insert(bar.id)
        }
    }

    func joinSelectedBars() {
        guard selectedBarIDs.count == 2 else { return }

        let selected = bars.filter { selectedBarIDs.contains($0.id) }

        guard let firstBar = selected.first, let secondBar = selected.last else { return }

        addUndoState()

        let newBar = Bar(
            x: firstBar.x,
            y: firstBar.y,
            w: firstBar.w + secondBar.w,
            h: firstBar.h, // Assume same height
            color: firstBar.color
        )

        bars.removeAll { selectedBarIDs.contains($0.id) }
        selectedBarIDs.removeAll()

        bars.append(newBar)
    }

    func deleteSelected() {
        addUndoState()
        bars.removeAll { selectedBarIDs.contains($0.id) }
        mats.removeAll { selectedMatIDs.contains($0.id) }
        selectedBarIDs.removeAll()
        selectedMatIDs.removeAll()
    }

    func selectObject(at point: CGPoint) {
        if let index = bars.lastIndex(where: { bar in
            CGRect(x: bar.x, y: bar.y, width: bar.w, height: bar.h).contains(point)
        }) {
            bars[index].isSelected.toggle()
            if bars[index].isSelected {
                selectedBarIDs.insert(bars[index].id)
            } else {
                selectedBarIDs.remove(bars[index].id)
            }
            return
        }

        if let index = mats.lastIndex(where: { mat in
            CGRect(x: mat.x, y: mat.y, width: mat.w, height: mat.h).contains(point)
        }) {
            mats[index].isSelected.toggle()
            if mats[index].isSelected {
                selectedMatIDs.insert(mats[index].id)
            } else {
                selectedMatIDs.remove(mats[index].id)
            }
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
        for mat in mats {
            if mat.isSelected {
                initialDragPositions[mat.id] = CGPoint(x: mat.x, y: mat.y)
            }
        }
    }

    func setUnitBar() {
        guard selectedBarIDs.count == 1, let barId = selectedBarIDs.first else { return }
        addUndoState()
        unitBarID = barId
        for i in 0..<bars.count {
            bars[i].isUnitBar = (bars[i].id == barId)
        }
    }

    func measureSelectedBars() {
        guard let unitBarID = unitBarID,
              let unitBar = bars.first(where: { $0.id == unitBarID }) else { return }

        addUndoState()

        for i in 0..<bars.count {
            if selectedBarIDs.contains(bars[i].id) {
                let ratio = bars[i].w / unitBar.w
                // Simple formatting, can be improved to find common denominators
                bars[i].fraction = String(format: "%.2f", ratio)
            }
        }
    }

    func splitSelectedBars(into count: Int) {
        addUndoState()
        for i in 0..<bars.count {
            if selectedBarIDs.contains(bars[i].id) {
                bars[i].split(into: count)
            }
        }
    }

    func dragSelectedObjects(by offset: CGSize) {
        for i in 0..<bars.count {
            if let initialPosition = initialDragPositions[bars[i].id] {
                bars[i].x = initialPosition.x + offset.width
                bars[i].y = initialPosition.y + offset.height
            }
        }
        for i in 0..<mats.count {
            if let initialPosition = initialDragPositions[mats[i].id] {
                mats[i].x = initialPosition.x + offset.width
                mats[i].y = initialPosition.y + offset.height
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
