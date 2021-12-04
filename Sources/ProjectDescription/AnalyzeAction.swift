import Foundation

public struct AnalyzeAction: Equatable, Codable {
    /// Name of the configuration that should be used for the Analyze action
    public let configuration: ConfigurationName

    /// List of actions to be executed before running the Analyze action
    public let preActions: [ExecutionAction]

    /// List of actions to be executed after running the Analyze action
    public let postActions: [ExecutionAction]

    private init(
        configuration: ConfigurationName,
        preActions: [ExecutionAction],
        postActions: [ExecutionAction]
    ) {
        self.configuration = configuration
        self.preActions = preActions
        self.postActions = postActions
    }

    /// Returns an analyze action.
    /// - Parameters:
    ///   - configuration: Configuration used for analyzing.
    ///   - preActions: Actions to run before the Analyze action.
    ///   - postActions: Actions to run after the Analyze action.
    /// - Returns: Analyze action.
    public static func analyzeAction(
        configuration: ConfigurationName,
        preActions: [ExecutionAction] = [],
        postActions: [ExecutionAction] = []
    ) -> AnalyzeAction {
        return AnalyzeAction(
            configuration: configuration,
            preActions: preActions,
            postActions: postActions
        )
    }
}
