import SwiftUIPlus

struct InterviewBannerView: View {

    struct ViewState: Equatable {

        let title: String
        let subtitle: String
    }

    let viewState: ViewState

    var body: some View {
        HStack(spacing: .zero) {
            Image(.icHi)
                .renderingMode(.template)
                .resizable()
                .frame(width: 32, height: 32)
                .foregroundStyle(.success600)
                .padding(12)
                .background {
                    RoundedRectangle(
                        cornerRadius: 16,
                        style: .continuous
                    )
                    .foregroundStyle(.success50)
                }

            Spacer()
                .frame(width: 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(viewState.title)
                    .font(.ds.bodyBold)
                    .foregroundStyle(.black900)

                Text(viewState.subtitle)
                    .font(.ds.subheadMedium)
                    .foregroundStyle(.black600)
            }

            Spacer()

            Image(.chevronRight)
                .renderingMode(.template)
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundStyle(Color.black600)
        }
        .multipadding(
            .horizontal(16),
            .vertical(8)
        )
        .background {
            Color.backgroundSecondary
        }
        .contentShape(.rect)
    }
}
