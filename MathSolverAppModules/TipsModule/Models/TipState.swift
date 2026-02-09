enum TipState {

    case incorrect
    case correct

    mutating func toggle() {
        switch self {
        case .incorrect:
            self = .correct
        case .correct:
            self = .incorrect
        }
    }
}
