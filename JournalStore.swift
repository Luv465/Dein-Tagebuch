import SwiftUI
import UIKit

/// Verwaltet alle Einträge und kümmert sich um das Speichern/Laden
/// auf der Festplatte. Einträge liegen als JSON, Bilder als JPGs
/// im Documents-Ordner der App.
final class JournalStore: ObservableObject {
    @Published private(set) var entries: [JournalEntry] = []

    private let fileManager = FileManager.default

    // MARK: - Pfade

    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var entriesFileURL: URL {
        documentsURL.appendingPathComponent("entries.json")
    }

    private var imagesDirectoryURL: URL {
        documentsURL.appendingPathComponent("Images", isDirectory: true)
    }

    // MARK: - Init

    init() {
        createImagesDirectoryIfNeeded()
        load()
    }

    private func createImagesDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: imagesDirectoryURL.path) {
            try? fileManager.createDirectory(at: imagesDirectoryURL,
                                             withIntermediateDirectories: true)
        }
    }

    // MARK: - Laden & Speichern

    private func load() {
        guard let data = try? Data(contentsOf: entriesFileURL) else {
            entries = []
            return
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([JournalEntry].self, from: data) {
            entries = decoded.sorted { $0.date > $1.date }
        }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(entries) {
            try? data.write(to: entriesFileURL, options: .atomic)
        }
    }

    // MARK: - Einträge bearbeiten

    func addOrUpdate(_ entry: JournalEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
        } else {
            entries.append(entry)
        }
        entries.sort { $0.date > $1.date }
        save()
    }

    func delete(at offsets: IndexSet) {
        // Zugehörige Bilder mitlöschen.
        for index in offsets {
            for filename in entries[index].imageFilenames {
                deleteImageFile(named: filename)
            }
        }
        entries.remove(atOffsets: offsets)
        save()
    }

    func delete(_ entry: JournalEntry) {
        for filename in entry.imageFilenames {
            deleteImageFile(named: filename)
        }
        entries.removeAll { $0.id == entry.id }
        save()
    }

    // MARK: - Bilder

    /// Speichert ein Bild und gibt den erzeugten Dateinamen zurück.
    func saveImage(_ image: UIImage) -> String? {
        let filename = UUID().uuidString + ".jpg"
        let url = imagesDirectoryURL.appendingPathComponent(filename)
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        do {
            try data.write(to: url, options: .atomic)
            return filename
        } catch {
            return nil
        }
    }

    /// Lädt ein Bild anhand seines Dateinamens.
    func loadImage(named filename: String) -> UIImage? {
        let url = imagesDirectoryURL.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    private func deleteImageFile(named filename: String) {
        let url = imagesDirectoryURL.appendingPathComponent(filename)
        try? fileManager.removeItem(at: url)
    }
}
