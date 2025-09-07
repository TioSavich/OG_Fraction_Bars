import Foundation
import CoreGraphics
import SwiftUI

struct Bar: Codable, Equatable, Identifiable {
    var id = UUID()
    var x: CGFloat
    var y: CGFloat
    var w: CGFloat
    var h: CGFloat
    var color: Color
    var label: String = ""
    var fraction: String = ""
    var isSelected: Bool = false
    var isUnitBar: Bool = false
    var splits: [Split] = []
    var selectedSplit: Split?

    // Custom coding for Color
    enum CodingKeys: String, CodingKey {
        case id, x, y, w, h, color, label, fraction, isSelected, isUnitBar, splits, selectedSplit
    }

    init(id: UUID = UUID(), x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, color: Color, label: String = "", fraction: String = "", isSelected: Bool = false, isUnitBar: Bool = false, splits: [Split] = [], selectedSplit: Split? = nil) {
        self.id = id
        self.x = x
        self.y = y
        self.w = w
        self.h = h
        self.color = color
        self.label = label
        self.fraction = fraction
        self.isSelected = isSelected
        self.isUnitBar = isUnitBar
        self.splits = splits
        self.selectedSplit = selectedSplit
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
        try container.encode(w, forKey: .w)
        try container.encode(h, forKey: .h)
        try container.encode(label, forKey: .label)
        try container.encode(fraction, forKey: .fraction)
        try container.encode(isSelected, forKey: .isSelected)
        try container.encode(isUnitBar, forKey: .isUnitBar)
        try container.encode(splits, forKey: .splits)
        try container.encode(selectedSplit, forKey: .selectedSplit)

        let colorComponents = color.cgColor?.components ?? [0,0,0,0]
        try container.encode(colorComponents, forKey: .color)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        x = try container.decode(CGFloat.self, forKey: .x)
        y = try container.decode(CGFloat.self, forKey: .y)
        w = try container.decode(CGFloat.self, forKey: .w)
        h = try container.decode(CGFloat.self, forKey: .h)
        label = try container.decode(String.self, forKey: .label)
        fraction = try container.decode(String.self, forKey: .fraction)
        isSelected = try container.decode(Bool.self, forKey: .isSelected)
        isUnitBar = try container.decode(Bool.self, forKey: .isUnitBar)
        splits = try container.decode([Split].self, forKey: .splits)
        selectedSplit = try container.decodeIfPresent(Split.self, forKey: .selectedSplit)

        let colorComponents = try container.decode([CGFloat].self, forKey: .color)
        color = Color(.sRGB, red: colorComponents[0], green: colorComponents[1], blue: colorComponents[2], opacity: colorComponents[3])
    }

    mutating func split(into count: Int) {
        guard count > 0 else { return }

        splits.removeAll()

        let splitWidth = w / CGFloat(count)
        for i in 0..<count {
            let splitX = CGFloat(i) * splitWidth
            let newSplit = Split(
                x: splitX,
                y: 0,
                w: splitWidth,
                h: h,
                color: self.color // Splits inherit bar's color initially
            )
            splits.append(newSplit)
        }
    }
}
