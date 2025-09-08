import Foundation
import CoreGraphics
import SwiftUI

struct Mat: Codable, Equatable, Identifiable {
    var id = UUID()
    var x: CGFloat
    var y: CGFloat
    var w: CGFloat
    var h: CGFloat
    var color: Color
    var isSelected: Bool = false

    // Custom coding for Color
    enum CodingKeys: String, CodingKey {
        case id, x, y, w, h, color, isSelected
    }

    init(id: UUID = UUID(), x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, color: Color, isSelected: Bool = false) {
        self.id = id
        self.x = x
        self.y = y
        self.w = w
        self.h = h
        self.color = color
        self.isSelected = isSelected
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
        try container.encode(w, forKey: .w)
        try container.encode(h, forKey: .h)
        try container.encode(isSelected, forKey: .isSelected)

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
        isSelected = try container.decode(Bool.self, forKey: .isSelected)

        let colorComponents = try container.decode([CGFloat].self, forKey: .color)
        color = Color(.sRGB, red: colorComponents[0], green: colorComponents[1], blue: colorComponents[2], opacity: colorComponents[3])
    }
}
