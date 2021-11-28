import Foundation
import ProjectDescription
import TSCBasic
import TuistCore
import TuistGraph

extension TuistGraph.AnalyzeAction {
    static func from(manifest: ProjectDescription.AnalyzeAction,
                     generatorPaths: GeneratorPaths) throws -> TuistGraph.AnalyzeAction
    {
        let configurationName = manifest.configuration.rawValue

        let preActions = try manifest.preActions.map {
            try TuistGraph.ExecutionAction.from(
                manifest: $0,
                generatorPaths: generatorPaths
            )
        }

        let postActions = try manifest.postActions.map {
            try TuistGraph.ExecutionAction.from(
                manifest: $0,
                generatorPaths: generatorPaths
            )
        }

        return AnalyzeAction(
            configurationName: configurationName,
            preActions: preActions,
            postActions: postActions
        )
    }
}
