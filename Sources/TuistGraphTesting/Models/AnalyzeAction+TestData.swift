import Foundation
import TSCBasic
@testable import TuistGraph

public extension AnalyzeAction {
    static func test(
        configurationName: String = "Beta Release",
        preActions: [ExecutionAction] = [],
        postActions: [ExecutionAction] = []
    ) -> AnalyzeAction {
        AnalyzeAction(
            configurationName: configurationName,
            preActions: preActions,
            postActions: postActions
        )
    }
}
