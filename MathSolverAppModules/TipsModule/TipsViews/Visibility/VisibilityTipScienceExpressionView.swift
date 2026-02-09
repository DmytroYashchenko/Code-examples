import SwiftUIPlus

struct VisibilityTipScienceExpressionView: View {

    @Environment(\.i18n) var i18n

    var body: some View {
        VStack(spacing: .zero) {
            Spacer()
                .frame(height: 16)

            Text(i18n.str(.completeTheChangesInConcentrations))
                .font(.ds.customFont(
                    fontStyle: .sfProTextRegular,
                    size: 17
                ))
                .multilineTextAlignment(.center)

            Spacer()
                .frame(height: 32)

            MathLabel(
                latex: "BaSO_{4}\\left( s \\right)\\to BA^{2+}\\left( aq \\right)+\\mathrm{SO}_{4}^{2-}\\left( aq \\right)",
                color: .black900,
                fontSize: 19
            )

            Spacer()
                .frame(height: 32)

            Text(i18n.str(.completeTheChangesInConcentrations))
                .font(.ds.customFont(
                    fontStyle: .sfProTextRegular,
                    size: 17
                ))
                .multilineTextAlignment(.center)
                .hidden()

            Spacer()
                .frame(height: 16)
        }
    }
}
