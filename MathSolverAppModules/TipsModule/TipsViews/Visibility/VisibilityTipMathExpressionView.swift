import SwiftUIPlus

struct VisibilityTipMathExpressionView: View {

    @Environment(\.i18n) var i18n

    var body: some View {
        VStack(spacing: 16) {
            Text(i18n.str(.solveTheSystemOfEquations))
                .font(.ds.customFont(
                    fontStyle: .sfProTextRegular,
                    size: 16
                ))
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            VStack(alignment: .leading, spacing: 16) {
                MathLabel(
                    latex: "1.\\ \\log_x \\left( 2x^2 - 3x - 4 \\right) = 2",
                    color: .black900,
                    fontSize: 18
                )

                MathLabel(
                    latex: "2.\\ x^2 - 3x - 4 = 0",
                    color: .black900,
                    fontSize: 18
                )
            }
        }
    }
}
