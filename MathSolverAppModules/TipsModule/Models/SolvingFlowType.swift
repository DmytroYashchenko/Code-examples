enum SolvingFlowType: String, Equatable, CaseIterable {

    case math
    case geometry = "visual"
    case graph
    case science

    var id: String { rawValue }

    init?(aiFeature: AnyAIFeature) {
        switch aiFeature {
        case .math:
            self = .math
        case .geometry:
            self = .geometry
        case .graphs:
            self = .graph
        case .science:
            self = .science
        default:
            return nil
        }
    }
}
