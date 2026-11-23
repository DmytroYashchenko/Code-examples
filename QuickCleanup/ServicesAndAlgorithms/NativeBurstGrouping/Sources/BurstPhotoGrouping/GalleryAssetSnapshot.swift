import Foundation

struct GalleryAssetSnapshot: Sendable {
    let localIdentifier: String
    let mediaTypeRaw: Int16
    let mediaSubtypesRaw: Int64
    let creationDate: Date?
    let modificationDate: Date?
    let duration: Double
    let pixelWidth: Int32
    let pixelHeight: Int32
    let sizeBytes: Int64
    let isLivePhoto: Bool
    let isScreenshot: Bool
    let isBurstPhoto: Bool
    let burstIdentifier: String?
    let burstSelectionTypesRaw: Int16
    let representsBurst: Bool
    let isVideo: Bool
}
