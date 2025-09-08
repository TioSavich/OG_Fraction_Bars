import SwiftUI

struct ToolbarView: View {
    @ObservedObject var viewModel: CanvasViewModel

    let colors: [Color] = [.red, .green, .blue, .yellow, .orange, .purple, .pink, .gray]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // Group 1: Create
                ToolButtonGroup {
                    Button(action: { viewModel.currentTool = .bar }) {
                        Image(systemName: "rectangle.stack.badge.plus")
                    }
                    .buttonStyle(ToolButtonStyle(isSelected: viewModel.currentTool == .bar))

                    Button(action: { viewModel.currentTool = .mat }) {
                        Image(systemName: "rectangle.grid.2x2")
                    }
                    .buttonStyle(ToolButtonStyle(isSelected: viewModel.currentTool == .mat))
                }

                // Group 2: Actions
                ToolButtonGroup {
                    Button(action: { viewModel.copySelected() }) {
                        Image(systemName: "doc.on.doc")
                    }
                    .disabled(viewModel.selectedBarIDs.isEmpty)

                    Button(action: { viewModel.joinSelectedBars() }) {
                        Image(systemName: "link")
                    }
                    .disabled(viewModel.selectedBarIDs.count != 2)

                    Button(action: { viewModel.deleteSelected() }) {
                        Image(systemName: "trash")
                    }
                }

                // Group 3: Splitting
                ToolButtonGroup {
                    Button(action: { viewModel.showingSplitDialog = true }) {
                        Image(systemName: "square.split.1x2")
                    }
                    .disabled(viewModel.selectedBarIDs.isEmpty)
                }

                // Group 4: Measurement
                ToolButtonGroup {
                    Button(action: { viewModel.setUnitBar() }) {
                        Image(systemName: "ruler")
                    }
                    .disabled(viewModel.selectedBarIDs.count != 1)

                    Button(action: { viewModel.measureSelectedBars() }) {
                        Image(systemName: "scalemass")
                    }
                    .disabled(viewModel.unitBarID == nil || viewModel.selectedBarIDs.isEmpty)

                    Button(action: { viewModel.isEditingLabel = true }) {
                        Image(systemName: "tag")
                    }
                    .disabled(viewModel.selectedBarIDs.count != 1)
                }

                // Group 5: File & History
                ToolButtonGroup {
                    Button(action: { viewModel.undo() }) {
                        Image(systemName: "arrow.uturn.backward")
                    }
                    Button(action: { viewModel.redo() }) {
                        Image(systemName: "arrow.uturn.forward")
                    }
                    Button(action: { viewModel.save() }) {
                        Image(systemName: "square.and.arrow.down")
                    }
                    Button(action: { viewModel.load() }) {
                        Image(systemName: "folder")
                    }
                }

                // Group 6: Colors
                ToolButtonGroup {
                    ForEach(colors, id: \.self) { color in
                        Button(action: { viewModel.currentColor = color }) {
                            Rectangle()
                                .fill(color)
                                .frame(width: 20, height: 20)
                                .border(viewModel.currentColor == color ? Color.black : Color.clear, width: 2)
                        }
                    }
                }
            }
            .padding()
        }
        .frame(height: 100)
    }
}

struct ToolButtonStyle: ButtonStyle {
    var isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(10)
            .background(isSelected ? Color.accentColor : Color.clear)
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(5)
    }
}

struct ToolButtonGroup<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 15) {
            content
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }
}


struct ToolbarView_Previews: PreviewProvider {
    static var previews: some View {
        ToolbarView(viewModel: CanvasViewModel())
            .previewLayout(.sizeThatFits)
    }
}
