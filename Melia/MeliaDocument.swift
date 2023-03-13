//
//  MeliaDocument.swift
//  Melia
//
//  Created by Raphaël Calabro on 02/04/2022.
//

import SwiftUI
import MeliceFramework
import UniformTypeIdentifiers

class MeliaDocument: ReferenceFileDocument {
    static var readableContentTypes: [UTType] {
        [.mapMakerProject, .mapMakerProjectBundle]
    }

    @Published var project: MELProject
    var git: FileWrapper?

    var spriteDefinitions: Binding<MELSpriteDefinitionList> {
        Binding {
            self.project.root.sprites
        } set: { newValue in
            self.project.root.sprites = newValue
        }
    }

    init() {
        self.project = MELProjectMakeWithEmptyMap()
    }

    init(project: MELProject) {
        self.project = project
    }

    required init(configuration: ReadConfiguration) throws {
        if configuration.contentType == .mapMakerProject {
            self.project = try MeliaDocument.openMmk(configuration: configuration)
        } else if configuration.contentType == .mapMakerProjectBundle {
            self.project = try MeliaDocument.openMmkb(configuration: configuration)
            self.git = configuration.file.fileWrappers?[".git"]
        } else {
            throw CocoaError(.fileReadUnsupportedScheme)
        }
    }

    deinit {
        MELProjectDeinit(&project)
    }

    static func openMmk(configuration: ReadConfiguration) throws -> MELProject {
        guard let data = configuration.file.regularFileContents, data.count > 0
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        var project = MELProject()
        var format = MELMmkProjectFormat
        try format.open(project: &project, from: data)
        return project
    }

    static func openMmkb(configuration: ReadConfiguration) throws -> MELProject {
        return try MELMmkbProjectFormat.project(fileWrappers: configuration.file.fileWrappers ?? [:])
    }

    func snapshot(contentType: UTType) throws -> ProjectSnapshot {
        return ProjectSnapshot(project: self.project)
    }

    func fileWrapper(snapshot: ProjectSnapshot, configuration: WriteConfiguration) throws -> FileWrapper {
        if configuration.contentType == .mapMakerProject {
            var format = MELMmkProjectFormat
            return .init(regularFileWithContents: try format.save(project: snapshot.project))
        } else if configuration.contentType == .mapMakerProjectBundle {
            let fileWrapper = try MELMmkbProjectFormat.fileWrapper(project: snapshot.project)
            var fileWrappers = fileWrapper.fileWrappers!
            var scriptCount = 0
            for key in project.scripts.keys {
                if let key = String(utf8String: key),
                   let scriptData = project.scripts[key],
                   scriptData.count > 1 {
                    let tokens = Tokenizer().tokenize(code: scriptData)
                    let definition = project.root.sprites.first {
                        $0.motionName != nil && String(utf8String: $0.motionName!) == key
                    }
                    let generator = PlaydateCodeGenerator(tree: TokenTree(tokens: tokens), for: definition)

                    fileWrappers["script\(scriptCount).h"] = .init(regularFileWithContents: generator.headerFile.data(using: .utf8)!)
                    fileWrappers["script\(scriptCount).c"] = .init(regularFileWithContents: generator.codeFile.data(using: .utf8)!)
                    scriptCount += 1
                }
            }
            if let git {
                fileWrappers[".git"] = git
            }
            return .init(directoryWithFileWrappers: fileWrappers)
        } else {
            throw CocoaError(.fileWriteUnsupportedScheme)
        }
    }
}

class ProjectSnapshot {
    var project: MELProject

    init(project: MELProject) {
        self.project = MELProjectMakeWithProject(project)
    }

    deinit {
        MELProjectDeinit(&self.project)
    }
}
