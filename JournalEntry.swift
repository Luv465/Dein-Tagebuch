import Foundation

/// Ein einzelner Tagebuch-Eintrag.
struct JournalEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var text: String
    var date: Date
    /// Dateinamen der zugehörigen Bilder (liegen im Images-Ordner).
    var imageFilenames: [String]

    init(id: UUID = UUID(),
         title: String = "",
         text: String = "",
         date: Date = Date(),
         imageFilenames: [String] = []) {
        self.id = id
        self.title = title
        self.text = text
        self.date = date
        self.imageFilenames = imageFilenames
    }
}
