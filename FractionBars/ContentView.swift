import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CanvasViewModel()

    var body: some View {
        VStack {
            Text("Fraction Bars")
                .font(.largeTitle)
                .padding()

            // Canvas for drawing fraction bars
            Canvas { context, size in
                for bar in viewModel.bars {
                    drawBar(context: &context, bar: bar)
                }
                for mat in viewModel.mats {
                    drawMat(context: &context, mat: mat)
                }
                if let rect = viewModel.newObjectRect {
                    drawPreview(context: &context, rect: rect)
                }
            }
            .border(Color.gray)
            .padding()
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        switch viewModel.currentTool {
                        case .select:
                            if value.translation == .zero { // Drag started
                                viewModel.selectBar(at: value.startLocation)
                                viewModel.startDragging()
                            }
                            viewModel.dragSelectedBars(by: value.translation)
                        case .bar, .mat:
                            viewModel.newObjectRect = CGRect(origin: value.startLocation, size: value.translation)
                        }
                    }
                    .onEnded { value in
                        switch viewModel.currentTool {
                        case .select:
                            break // No action needed on end for this simple drag
                        case .bar:
                            if let rect = viewModel.newObjectRect {
                                viewModel.addBar(rect: rect.normalized)
                            }
                        case .mat:
                            if let rect = viewModel.newObjectRect {
                                viewModel.addMat(rect: rect.normalized)
                            }
                        }
                        viewModel.newObjectRect = nil
                        viewModel.currentTool = .select // Reset tool after creation
                    }
            )

            Spacer()

            ToolbarView(viewModel: viewModel)
        }
    }

    private func drawBar(context: inout GraphicsContext, bar: Bar) {
        let rect = CGRect(x: bar.x, y: bar.y, width: bar.w, height: bar.h)
        context.fill(Path(rect), with: .color(bar.color))
        context.stroke(Path(rect), with: .color(.black), lineWidth: bar.isSelected ? 2.5 : 1)

        for split in bar.splits {
            let splitRect = CGRect(x: bar.x + split.x, y: bar.y + split.y, width: split.w, height: split.h)
            context.fill(Path(splitRect), with: .color(split.color))
            context.stroke(Path(splitRect), with: .color(.black), lineWidth: 1)
        }
    }

    private func drawMat(context: inout GraphicsContext, mat: Mat) {
        let rect = CGRect(x: mat.x, y: mat.y, width: mat.w, height: mat.h)
        context.fill(Path(rect), with: .color(mat.color))
        context.stroke(Path(rect), with: .color(.black), lineWidth: mat.isSelected ? 2.5 : 1)
    }

    private func drawPreview(context: inout GraphicsContext, rect: CGRect) {
        let path = Path(rect.normalized)
        context.stroke(path, with: .color(.red), style: StrokeStyle(lineWidth: 2, dash: [5]))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
