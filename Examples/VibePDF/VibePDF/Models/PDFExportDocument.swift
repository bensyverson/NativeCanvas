//
//  PDFExportDocument.swift
//  VibePDF
//

import SwiftUI
import UniformTypeIdentifiers

struct PDFExportDocument: FileDocument {
    nonisolated static var readableContentTypes: [UTType] {
        [.pdf]
    }

    let data: Data

    init(data: Data) {
        self.data = data
    }

    nonisolated init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    nonisolated func fileWrapper(configuration _: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
