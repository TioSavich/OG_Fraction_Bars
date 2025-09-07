import SwiftUI

struct SplitDialogView: View {
    @Binding var isPresented: Bool
    @Binding var splitCount: String
    var onCommit: () -> Void

    var body: some View {
        VStack {
            Text("Split Bar")
                .font(.headline)
            Text("Enter the number of parts to split the bar into:")
            TextField("Number of parts", text: $splitCount)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                Spacer()
                Button("OK") {
                    onCommit()
                    isPresented = false
                }
            }
            .padding()
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 10)
        .frame(width: 300)
    }
}

struct SplitDialogView_Previews: PreviewProvider {
    static var previews: some View {
        SplitDialogView(
            isPresented: .constant(true),
            splitCount: .constant("2"),
            onCommit: {}
        )
    }
}
