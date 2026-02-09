import SwiftUI

struct InvoiceDatesSelectionView: View {

    @Binding var issuedDate: Date
    @Binding var dueDate: DueDate
    @Binding var number: String

    @FocusState private var numberFocused

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                Text("Issued")
                    .font(.poppins(size: 12, weight: .regular))
                    .foregroundStyle(.textSecondary)
                    .frame(maxWidth: .infinity)

                Text("Due")
                    .font(.poppins(size: 12, weight: .regular))
                    .foregroundStyle(.textSecondary)
                    .frame(maxWidth: .infinity)

                Text(verbatim: "#")
                    .font(.poppins(size: 12, weight: .regular))
                    .foregroundStyle(.textSecondary)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 20)

            HStack(spacing: .zero) {
                issuedDatePicker
                separator

                dueDatePicker
                separator

                numberTextfield
            }
            .background(.backgroundSecondary, in: .rect(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.border, lineWidth: 1)
            }
            .frame(height: 44)
        }
    }

    private var issuedDatePicker: some View {
        Text(issuedDate.formatted(.dateTime.day().month(.abbreviated).year()))
            .font(.poppins(size: 14, weight: .regular))
            .foregroundStyle(.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 4)
            .overlay {
                DatePicker(
                    "",
                    selection: .init(
                        get: { issuedDate },
                        set: { issuedDate = $0.startOfDay }
                    ),
                    displayedComponents: [.date]
                )
                .tint(.textProminent)
                .labelsHidden()
                .colorMultiply(Color.clear)
                .onTapGesture(count: 99) { }
            }
    }

    @ViewBuilder
    private var dueDatePicker: some View {
        var dueData: (text: String, color: Color) {
            switch dueDate {
            case .noDueDate:
                return ("Date", .textSecondary)
            default:
                return (dueDate.dateTitle(from: issuedDate), .textPrimary)
            }
        }
        Menu {
            Picker(
                "",
                selection: Binding(
                    get: {
                        dueDate
                    },
                    set: {
                        dueDate = $0
                    }
                )
            ) {
                ForEach(DueDate.allCases) { variant in
                    Text(variant.selectionTitle)
                        .tag(variant)
                }
            }
            .labelsHidden()
        } label: {
            Text(dueData.text)
                .font(.poppins(size: 14, weight: .regular))
                .foregroundStyle(dueData.color)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 4)
        }
    }

    private var numberTextfield: some View {
        TextField(
            "",
            text: $number,
            prompt: Text("Number")
                .font(.poppins(size: 14, weight: .regular))
                .foregroundColor(.textSecondary)
        )
        .multilineTextAlignment(.center)
        .focused($numberFocused)
        .font(.poppins(size: 14, weight: .regular))
        .foregroundStyle(.textPrimary)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 4)
    }

    private var separator: some View {
        Rectangle()
            .fill(.border)
            .frame(width: 1)
    }
}
