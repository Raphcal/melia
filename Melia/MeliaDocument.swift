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
            return try MELMmkbProjectFormat.fileWrapper(project: snapshot.project)
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
