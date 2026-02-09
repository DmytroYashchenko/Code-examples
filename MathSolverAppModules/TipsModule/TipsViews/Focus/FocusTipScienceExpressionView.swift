import SwiftUIPlus

struct FocusTipScienceExpressionView: View {

    @Environment(\.i18n) var i18n

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            let text = "\(i18n.str(.calculateHowMuchPercentOfSubstance)) \\(CaSO_{4}\\)"

            SwiftUILatexView(latex: text)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                let titles = [
                    "a. 36%",
                    "b. 47%",
                    "c. 58%",
                    "d. 99%"
                ]

                ForEach(titles) {
                    Text($0)
                        .font(.ds.customFont(
                            fontStyle: .sfProTextRegular,
                            size: 12
                        ))
                }
            }
        }
    }
}
