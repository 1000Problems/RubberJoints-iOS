import Foundation
import SwiftData

@Model
final class Program {
    @Attribute(.unique) var id: Int
    var name: String
    var durationDays: Int
    var programDescription: String?

    init(id: Int, name: String, durationDays: Int, programDescription: String? = nil) {
        self.id = id
        self.name = name
        self.durationDays = durationDays
        self.programDescription = programDescription
    }
}
