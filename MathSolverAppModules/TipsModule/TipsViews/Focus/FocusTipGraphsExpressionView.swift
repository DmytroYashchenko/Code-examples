import SwiftUIPlus

struct FocusTipGraphsExpressionView: View {

    @Environment(\.i18n) var i18n

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(i18n.str(.plotAnalyzeTheFunction))
                    .font(.ds.customFont(
                        fontStyle: .sfProTextRegular,
                        size: 12
                    ))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                MathLabel(
                    latex: "f(x)= -2x+4",
                    color: .black900,
                    fontSize: 14
                )
            }

            VStack(alignment: .leading, spacing: 2) {
                let titles = [
                    "a. \(i18n.str(.theYInterceptIsAt)) (0, 4)",
                    "b. \(i18n.str(.theXInterceptIsAt)) (2, 0)",
                    "c. \(i18n.str(.theSlopeOfThisLineIs)) -2"
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
