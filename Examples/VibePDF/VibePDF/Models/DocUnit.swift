//
//  DocUnit.swift
//  VibePDF
//

import NativeCanvas

enum DocUnit: String, CaseIterable, Friendly {
    case px
    case mm
    case inches = "in"

    func toPixels(_ value: Double) -> Int {
        switch self {
        case .px: Int(value)
        case .mm: Int(value * 72.0 / 25.4)
        case .inches: Int(value * 72.0)
        }
    }

    var displayName: String {
        switch self {
        case .px: "px"
        case .mm: "mm"
        case .inches: "in"
        }
    }
}
