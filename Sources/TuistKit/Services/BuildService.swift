import Foundation
import TSCBasic
import TuistAutomation
import TuistCache
import TuistCore
import TuistGraph
import TuistLoader
import TuistSupport

enum BuildServiceError: FatalError {
    case workspaceNotFound(path: String)
    case schemeWithoutBuildableTargets(scheme: String)
    case schemeNotFound(scheme: String, existing: [String])

    var description: String {
        switch self {
        case let .schemeWithoutBuildableTargets(scheme):
            return "The scheme \(scheme) cannot be built because it contains no buildable targets."
        case let .workspaceNotFound(path):
            return "Workspace not found expected xcworkspace at \(path)"
        case let .schemeNotFound(scheme, existing):
            return "Couldn't find scheme \(scheme). The available schemes are: \(existing.joined(separator: ", "))."
        }
    }

    var type: ErrorType {
        switch self {
        case .workspaceNotFound:
            return .bug
        case .schemeNotFound,
             .schemeWithoutBuildableTargets:
            return .abort
        }
    }
}

final class BuildService {
    private let generatorFactory: GeneratorFactorying
    private let buildGraphInspector: BuildGraphInspecting
    private let targetBuilder: TargetBuilding
    private let configLoader: ConfigLoading

    init(
        generatorFactory: GeneratorFactorying = GeneratorFactory(),
        buildGraphInspector: BuildGraphInspecting = BuildGraphInspector(),
        targetBuilder: TargetBuilding = TargetBuilder(),
        configLoader: ConfigLoading = ConfigLoader(manifestLoader: ManifestLoader())
    ) {
        self.generatorFactory = generatorFactory
        self.buildGraphInspector = buildGraphInspector
        self.targetBuilder = targetBuilder
        self.configLoader = configLoader
    }

    // swiftlint:disable:next function_body_length
    func run(
        schemeName: String?,
        generate: Bool,
        clean: Bool,
        listSchemes: Bool,
        configuration: String?,
        buildOutputPath: AbsolutePath?,
        path: AbsolutePath
    ) throws {
        let graph: Graph
        let config = try configLoader.loadConfig(path: path)
        let generator = generatorFactory.default(config: config)
        if try (generate || buildGraphInspector.workspacePath(directory: path) == nil) {
            graph = try generator.generateWithGraph(path: path, projectOnly: false).1
        } else {
            graph = try generator.load(path: path)
        }

        guard let workspacePath = try buildGraphInspector.workspacePath(directory: path) else {
            throw BuildServiceError.workspaceNotFound(path: path.pathString)
        }

        let graphTraverser = GraphTraverser(graph: graph)
        let buildableSchemes = buildGraphInspector.buildableSchemes(graphTraverser: graphTraverser)
        let buildableSchemesString = Set(buildableSchemes.map(\.name)).sorted(by: { $0 < $1 }).joined(separator: ", ")

        if listSchemes {
            logger.pretty("Found the following buildable schemes: \(.keystroke(.raw(buildableSchemesString)))")
            return
        } else {
            logger.log(level: .debug, "Found the following buildable schemes: \(buildableSchemesString)")
        }

        if let schemeName = schemeName {
            guard let scheme = buildableSchemes.first(where: { $0.name == schemeName }) else {
                throw BuildServiceError.schemeNotFound(scheme: schemeName, existing: buildableSchemes.map(\.name))
            }

            guard let graphTarget = buildGraphInspector.buildableTarget(scheme: scheme, graphTraverser: graphTraverser) else {
                throw TargetBuilderError.schemeWithoutBuildableTargets(scheme: scheme.name)
            }

            try targetBuilder.buildTarget(
                graphTarget,
                workspacePath: workspacePath,
                schemeName: scheme.name,
                clean: clean,
                configuration: configuration,
                buildOutputPath: buildOutputPath
            )
        } else {
            var cleaned: Bool = false
            // Build only buildable entry schemes when specific schemes has not been passed
            let buildableEntrySchemes = buildGraphInspector.buildableEntrySchemes(graphTraverser: graphTraverser)
            try buildableEntrySchemes.forEach { scheme in
                guard let graphTarget = buildGraphInspector.buildableTarget(scheme: scheme, graphTraverser: graphTraverser) else {
                    throw TargetBuilderError.schemeWithoutBuildableTargets(scheme: scheme.name)
                }

                try targetBuilder.buildTarget(
                    graphTarget,
                    workspacePath: workspacePath,
                    schemeName: scheme.name,
                    clean: !cleaned && clean,
                    configuration: configuration,
                    buildOutputPath: buildOutputPath
                )
                cleaned = true
            }
        }

        logger.log(level: .notice, "The project built successfully", metadata: .success)
    }
}
