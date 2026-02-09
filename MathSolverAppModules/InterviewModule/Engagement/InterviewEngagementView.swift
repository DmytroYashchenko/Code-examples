import SwiftUIPlus

struct InterviewEngagementView: View {

    @Environment(\.i18n) var i18n
    @Environment(\.heightSize) var heightSize

    @ObservedObject var viewModel: InterviewEngagementViewModel

    var body: some View {
        VStack(spacing: .zero) {
            navigationBar
                .padding(.bottom, 24)

            VStack(spacing: .zero) {
                staffView

                Spacer()
                    .frame(height: heightSize == .small ? 32 : 44)

                textsView

                Spacer()

                Color.clear.overlay {
                    Image(.imgInterview)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                }

                Spacer()

                buttonsView
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Views

private extension InterviewEngagementView {

    var navigationBar: some View {
        Text(i18n.str(.heyThere))
            .font(.ds.title3Semibold)
            .foregroundStyle(.black900)
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .leading) {
                Button {
                    viewModel.close()
                } label: {
                    Image(.chevronLeft)
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(.black900)
                        .frame(width: 24, height: 24)
                }
                .frame(width: 48, height: 48)
            }
    }

    var staffView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                HStack(spacing: .zero) {
                    Image(.imgMarynaAvatar)
                        .resizable()
                        .frame(width: 62, height: 62)
                        .zIndex(1)

                    Image(.imgInaraAvatar)
                        .resizable()
                        .frame(width: 62, height: 62)
                        .padding(.leading, -8)
                }

                VStack(alignment: .leading, spacing: 4) {
                    let productManagerText = "• \(i18n.str(.productManager))"
                    let productDesignerText = "• \(i18n.str(.productDesigner))"

                    let productTitle = "\(i18n.str(.maryna)) \(productManagerText)"
                        .mutableAttributedString
                        .setFont(.ds.bodyBold)
                        .setTextColor(.black900)
                        .setFont(.ds.bodyRegular, to: productManagerText)
                        .setTextColor(.black600, to: productManagerText)
                        .attributedString

                    let designerTitle = "\(i18n.str(.inara)) \(productDesignerText)"
                        .mutableAttributedString
                        .setFont(.ds.bodyBold)
                        .setTextColor(.black900)
                        .setFont(.ds.bodyRegular, to: productDesignerText)
                        .setTextColor(.black600, to: productDesignerText)
                        .attributedString

                    Text(productTitle)
                    Text(designerTitle)
                }
            }

            Color.black200.frame(height: 1)
        }
    }

    var textsView: some View {
        VStack(spacing: 16) {
            Text(i18n.str(.readyToMakeDifference))
                .font(.ds.title2Bold)
                .foregroundStyle(.black900)

            Text(i18n.str(.joinOurUserInterviewAndSeeInput))
                .font(.ds.bodyRegular)
                .foregroundStyle(.black800)
                .multilineTextAlignment(.center)
                .layoutPriority(1)
        }
    }

    var buttonsView: some View {
        VStack(spacing: 12) {
            Button {
                viewModel.startTapped()
            } label: {
                Text(i18n.str(.yesSurely))
            }
            .frame(height: 48)
            .buttonStyle(.primary(isActive: true))

            Button {
                viewModel.skipTapped()
            } label: {
                Text(i18n.str(.notNow))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 48)
                    .contentShape(.rect)
            }
            .buttonStyle(.cta)
        }
    }
}
