import SwiftUI

struct BackButton: View {

    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Circle()
                .fill(.bgSecondary)
                .frame(width: 40, height: 40)
                .overlay {
                    Icon(systemName: "chevron.left")
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundStyle(.fgPrimary)
                }
        }
    }
}
