import Foundation

struct TipStepViewState: Identifiable {

    let tipType: TipType
    let tipState: TipState
    let title: String

    var id: String {
        tipType.rawValue
    }
}
