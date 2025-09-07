import Foundation
import CoreGraphics

struct Point: Codable, Equatable {
    var x: CGFloat
    var y: CGFloat

    static func min(_ p1: Point, _ p2: Point) -> Point {
        return Point(x: Swift.min(p1.x, p2.x), y: Swift.min(p1.y, p2.y))
    }
}
