import EventKit

enum SignatureEvent: Event {
    case screenShown
    case closeTapped
    case cleanTapped
    case createTapped
}

class SignatureEventProcessor: EventProcessor {
    func process(_ event: SignatureEvent) {
        switch event {
        case .screenShown:
            send("signature_screen_shown")
        case .closeTapped:
            send("signature_close_tapped")
        case .cleanTapped:
            send("signature_clean_tapped")
        case .createTapped:
            send("signature_create_tapped")
        }
    }
}
