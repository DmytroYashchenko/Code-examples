import SwiftUIPlus

struct FocusTipMathExpressionView: View {

    @Environment(\.i18n) var i18n

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(i18n.str(.solveTheSystemOfEquations))
                .font(.ds.customFont(
                    fontStyle: .sfProTextRegular,
                    size: 12
                ))
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            VStack(alignment: .leading, spacing: 8) {
                MathLabel(
                    latex: "1.\\ \\log_x \\left( 2x^2 - 3x - 4 \\right) = 2",
                    color: .black900,
                    fontSize: 14
                )

                MathLabel(
                    latex: "2.\\ x^2 - 3x - 4 = 0",
                    color: .black900,
                    fontSize: 14
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                MathLabel(
                    latex: "a.\\ x = 0",
                    color: .black900,
                    fontSize: 14
                )

                MathLabel(
                    latex: "b.\\ x = 3",
                    color: .black900,
                    fontSize: 14
                )

                MathLabel(
                    latex: "c.\\ x = 1",
                    color: .black900,
                    fontSize: 14
                )

                MathLabel(
                    latex: "d.\\ x = 1",
                    color: .black900,
                    fontSize: 14
                )
            }
        }
    }
}
