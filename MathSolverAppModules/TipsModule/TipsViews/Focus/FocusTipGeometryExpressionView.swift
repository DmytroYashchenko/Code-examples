import SwiftUIPlus

struct FocusTipGeometryExpressionView: View {

    @Environment(\.i18n) var i18n

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            MathLabel(
                latex: "\\text{\(i18n.str(.whatIs)) } m \\angle 1\\text{?}",
                color: .black900,
                fontSize: 14
            )

            Image(.imgTriangleProblem)
                    .resizable()
                    .aspectRatio(contentMode: .fit)

            HStack(spacing: 8) {
                MathLabel(
                    latex: "m \\angle 1 =",
                    color: .black900,
                    fontSize: 14
                )

                RoundedRectangle(
                    cornerSize: .init(width: 2, height: 2),
                    style: .continuous
                )
                .stroke(.primary100, lineWidth: 1)
                .frame(width: 38, height: 20)

                Spacer()
            }
        }
    }
}
