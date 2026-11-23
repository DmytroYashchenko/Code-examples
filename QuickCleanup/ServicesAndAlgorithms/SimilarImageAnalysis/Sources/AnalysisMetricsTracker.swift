import Foundation

final class AnalysisMetricsTracker {

    private let startDate = Date()
    private let analysisName: String
    private let totalAssetCount: Int
    private var eligibleAssetCount = 0
    private var peakFootprintBytes = UInt64.zero

    static func make(
        analysisName: String,
        totalAssetCount: Int
    ) -> AnalysisMetricsTracker? {
        #if DEBUG
        AnalysisMetricsTracker(
            analysisName: analysisName,
            totalAssetCount: totalAssetCount
        )
        #else
        nil
        #endif
    }

    private init(
        analysisName: String,
        totalAssetCount: Int
    ) {
        self.analysisName = analysisName
        self.totalAssetCount = totalAssetCount
        recordMemoryUsage()
    }

    func setEligibleAssetCount(_ count: Int) {
        eligibleAssetCount = count
    }

    func recordMemoryUsage() {
        let currentFootprintBytes = currentMemoryFootprintBytes()
        peakFootprintBytes = max(peakFootprintBytes, currentFootprintBytes)
    }

    func printCompletionSummary(groupCount: Int) {
        let elapsedTime = Date().timeIntervalSince(startDate)
        let currentFootprintBytes = currentMemoryFootprintBytes()
        let peakResidentBytes = peakResidentMemoryBytes()

        print(
            """
            \(analysisName) analysis finished.
            • Total assets: \(totalAssetCount)
            • Eligible assets: \(eligibleAssetCount)
            • Groups found: \(groupCount)
            • Elapsed: \(elapsedTime.formatted(.number.precision(.fractionLength(2)))) s
            • Current memory footprint: \(Self.memoryText(for: currentFootprintBytes))
            • Phase peak memory footprint: \(Self.memoryText(for: peakFootprintBytes))
            • Process peak resident memory: \(Self.memoryText(for: peakResidentBytes))
            """
        )
    }

    func printFailureSummary(error: Error) {
        let elapsedTime = Date().timeIntervalSince(startDate)
        let currentFootprintBytes = currentMemoryFootprintBytes()
        let peakResidentBytes = peakResidentMemoryBytes()

        print(
            """
            \(analysisName) analysis failed: \(error)
            • Total assets: \(totalAssetCount)
            • Eligible assets: \(eligibleAssetCount)
            • Elapsed: \(elapsedTime.formatted(.number.precision(.fractionLength(2)))) s
            • Current memory footprint: \(Self.memoryText(for: currentFootprintBytes))
            • Phase peak memory footprint: \(Self.memoryText(for: peakFootprintBytes))
            • Process peak resident memory: \(Self.memoryText(for: peakResidentBytes))
            """
        )
    }
}

// MARK: - Private methods

private extension AnalysisMetricsTracker {

    func currentMemoryFootprintBytes() -> UInt64 {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size
        )

        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(TASK_VM_INFO),
                    $0,
                    &count
                )
            }
        }

        guard result == KERN_SUCCESS else { return .zero }
        return info.phys_footprint
    }

    func peakResidentMemoryBytes() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(
            MemoryLayout<mach_task_basic_info>.size / MemoryLayout<natural_t>.size
        )

        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &count
                )
            }
        }

        guard result == KERN_SUCCESS else { return .zero }
        return UInt64(info.resident_size_max)
    }

    static func memoryText(for bytes: UInt64) -> String {
        ByteCountFormatter.string(
            fromByteCount: Int64(bytes),
            countStyle: .memory
        )
    }
}
