import Foundation

public struct AnalyzeAction: Equatable, Codable {
    // MARK: - Attributes

    public let configurationName: String
    public let preActions: [ExecutionAction]
    public let postActions: [ExecutionAction]

    // MARK: - Init

    public init(
        configurationName: String,
        preActions: [ExecutionAction] = [],
        postActions: [ExecutionAction] = []
    ) {
        self.configurationName = configurationName
        self.preActions = preActions
        self.postActions = postActions
    }
}
