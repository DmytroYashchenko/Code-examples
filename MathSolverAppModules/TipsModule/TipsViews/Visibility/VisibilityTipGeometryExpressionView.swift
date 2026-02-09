import SwiftUIPlus

struct VisibilityTipGeometryExpressionView: View {

    @Environment(\.i18n) var i18n

    var body: some View {
        VStack(spacing: 16) {
            MathLabel(
                latex: "\\text{\(i18n.str(.whatIs)) } m \\angle 1\\text{?}",
                color: .black900,
                fontSize: 18
            )

            Image(.imgTriangleProblem)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
        }
        .padding(24)
    }
}
