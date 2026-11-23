import Lottie
import SwiftUI

struct CleaningSummaryView: View {

    @ObservedObject var viewModel: CleaningSummaryViewModel

    var body: some View {
        ZStack {
            Color.bgPrimary
                .ignoresSafeArea()

            VStack(spacing: .zero) {
                LottieView.make(.congratulations)
                    .resizable()
                    .backgroundBehavior(.pauseAndRestore)
                    .playing(loopMode: .playOnce)
                    .scaledToFit()
                    .frame(height: 260)

                VStack(spacing: 8) {
                    Text("Awesome!")
                        .font(.title1Bold)
                        .foregroundStyle(.fgPrimary)

                    Text("Your storage is now optimized.")
                        .font(.body2Regular)
                        .foregroundStyle(.fgSecondary)
                }
                .multilineTextAlignment(.center)
                .padding(.bottom, 16)

                summaryView

                Spacer()

                Text("Clear the \"Recently Deleted\" album to free up \(viewModel.deletedStorageText), or restore items you want to keep.")
                    .font(.caption1Regular)
                    .foregroundStyle(.fgSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 16)
        }
        .safeAreaInset(edge: .bottom) {
            Button("Got it!") {
                viewModel.gotItTapped()
            }
            .buttonStyle(.primary)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .background(.bgPrimary)
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
}

// MARK: - Subviews

private extension CleaningSummaryView {

    var summaryView: some View {
        VStack(spacing: .zero) {
            summaryRow(
                icon: .icCircledTrashBin,
                title: "You've cleaned",
                subtitle: viewModel.deletedItemsText,
                value: viewModel.deletedStorageText
            )

            divider

            summaryRow(
                icon: .icCircledArrows,
                title: "Freed up",
                subtitle: String(localized: "of storage space"),
                value: viewModel.freedStorageText
            )

        }
        .background(.bgSecondary, in: .rect(cornerRadius: 20, style: .continuous))
    }

    var divider: some View {
        Rectangle()
            .fill(.bgStroke)
            .frame(height: 1)
    }

    func summaryRow(
        icon: ImageResource,
        title: LocalizedStringKey,
        subtitle: String,
        value: String,
    ) -> some View {
        HStack(spacing: 12) {
            Image(icon)
                .resizable()
                .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body1Medium)
                    .foregroundStyle(.fgPrimary)

                Text(subtitle)
                    .font(.caption1Regular)
                    .foregroundStyle(.fgSecondary)
            }

            Spacer()

            Text(value)
                .font(.body2Medium)
                .foregroundStyle(.accent500)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.accentBg, in: .capsule)
        }
        .padding(16)
    }
}
