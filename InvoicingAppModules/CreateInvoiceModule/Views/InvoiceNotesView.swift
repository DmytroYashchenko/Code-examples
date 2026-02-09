import SwiftUI

struct InvoiceNotesView: View {

    @Binding var text: String

    var body: some View {
        TextField(
            "",
            text: $text,
            prompt: Text("Additional information")
                .foregroundColor(.textSecondary),
            axis: .vertical
        )
        .font(.poppins(size: 14))
        .foregroundColor(.textPrimary)
        .padding(12)
        .frame(minHeight: 60, alignment: .top)
        .background(.backgroundSecondary, in: .rect(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(.border, lineWidth: 1)
        }
    }
}
