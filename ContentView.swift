import SwiftUI

/// Startbildschirm: Liste aller Tagebuch-Einträge.
struct ContentView: View {
    @EnvironmentObject var store: JournalStore
    @State private var showingNewEntry = false

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }

    var body: some View {
        NavigationView {
            Group {
                if store.entries.isEmpty {
                    emptyState
                } else {
                    entryList
                }
            }
            .navigationBarTitle("Mein Tagebuch")
            .navigationBarItems(trailing: Button(action: {
                showingNewEntry = true
            }) {
                Image(systemName: "square.and.pencil")
                    .imageScale(.large)
            })
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingNewEntry) {
            EntryEditView(entry: JournalEntry(), isNew: true)
                .environmentObject(store)
        }
    }

    // MARK: - Leerer Zustand

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("Noch keine Einträge")
                .font(.title3)
                .foregroundColor(.secondary)
            Text("Tippe oben rechts, um deinen ersten Eintrag zu schreiben.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Liste

    private var entryList: some View {
        List {
            ForEach(store.entries) { entry in
                NavigationLink(destination:
                    EntryEditView(entry: entry, isNew: false)
                        .environmentObject(store)
                ) {
                    EntryRow(entry: entry, dateFormatter: dateFormatter)
                }
            }
            .onDelete(perform: store.delete)
        }
        .listStyle(PlainListStyle())
    }
}

/// Eine Zeile in der Eintragsliste.
struct EntryRow: View {
    @EnvironmentObject var store: JournalStore
    let entry: JournalEntry
    let dateFormatter: DateFormatter

    var body: some View {
        HStack(spacing: 12) {
            thumbnail
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title.isEmpty ? "Ohne Titel" : entry.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(dateFormatter.string(from: entry.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
                if !entry.text.isEmpty {
                    Text(entry.text)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let first = entry.imageFilenames.first,
           let image = store.loadImage(named: first) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 54, height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(width: 54, height: 54)
                .overlay(
                    Image(systemName: "doc.text")
                        .foregroundColor(.secondary)
                )
        }
    }
}
