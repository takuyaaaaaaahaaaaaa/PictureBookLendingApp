/// One camera presentation, including retries. No frames, identities or error text are retained.
struct CoverSearchTelemetry {
    private var searched = false
    private var hadCandidates = false
    private var finished = false
    private var failures: Set<String> = []

    mutating func didSearch() { searched = true }

    mutating func showCandidates(count: Int) -> AnalyticsEvent? {
        guard !finished, !hadCandidates, count > 0 else { return nil }
        hadCandidates = true
        return .coverCandidatesShown(count: count)
    }

    mutating func fail(_ reason: AnalyticsEvent.CoverFailure) -> AnalyticsEvent? {
        guard !finished, failures.insert(reason.rawValue).inserted else { return nil }
        return .coverSearchFailed(reason: reason)
    }

    mutating func finish(selected: Bool) -> AnalyticsEvent? {
        guard !finished else { return nil }
        finished = true
        return .coverSearchFinished(
            outcome: selected ? .selected : .abandoned,
            hadCandidates: hadCandidates,
            noCandidates: searched && !hadCandidates && failures.isEmpty)
    }
}
