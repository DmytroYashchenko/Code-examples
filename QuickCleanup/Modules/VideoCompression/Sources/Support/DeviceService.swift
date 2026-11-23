import Foundation

class DeviceService {

    func deviceStorageCapacityGB() -> Int? {
        do {
            let values = try URL(fileURLWithPath: NSHomeDirectory())
                .resourceValues(forKeys: [.volumeTotalCapacityKey])

            guard let capacity = values.volumeTotalCapacity else {
                return nil
            }

            let gb = Double(capacity) / 1_000_000_000
            return Int(gb.rounded())
        } catch {
            return nil
        }
    }

    func normalizedStorageSizeGB() -> Int? {
        guard let size = deviceStorageCapacityGB() else { return nil }

        let knownSizes = [64, 128, 256, 512, 1024, 2048]
        return knownSizes.min(by: {
            abs($0 - size) < abs($1 - size)
        }) ?? size
    }
}
