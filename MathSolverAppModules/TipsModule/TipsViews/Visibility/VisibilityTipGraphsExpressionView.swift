import SwiftUIPlus

struct VisibilityTipGraphsExpressionView: View {

    @Environment(\.i18n) var i18n

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text(i18n.str(.plotAnalyzeTheFunction))
                    .font(.ds.customFont(
                        fontStyle: .sfProTextRegular,
                        size: 17
                    ))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                MathLabel(
                    latex: "f(x)= -2x+4",
                    color: .black900,
                    fontSize: 19
                )
            }

            VStack(alignment: .leading, spacing: 4) {
                let titles = [
                    "a. \(i18n.str(.theYInterceptIsAt)) (0, 4)",
                    "b. \(i18n.str(.theXInterceptIsAt)) (2, 0)",
                    "c. \(i18n.str(.theSlopeOfThisLineIs)) -2"
                ]

                ForEach(titles) {
                    Text($0)
                        .font(.ds.customFont(
                            fontStyle: .sfProTextRegular,
                            size: 17
                        ))
                }
            }
        }
    }
}
