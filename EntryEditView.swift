import SwiftUI

/// Ansicht zum Erstellen und Bearbeiten eines Eintrags.
struct EntryEditView: View {
    @EnvironmentObject var store: JournalStore
    @Environment(\.presentationMode) var presentationMode

    @State private var draft: JournalEntry
    private let isNew: Bool

    @State private var showingImageSourceDialog = false
    @State private var showingPhotoLibrary = false
    @State private var showingCamera = false

    init(entry: JournalEntry, isNew: Bool) {
        _draft = State(initialValue: entry)
        self.isNew = isNew
    }

    var body: some View {
        Form {
            Section(header: Text("Titel")) {
                TextField("Worum geht es?", text: $draft.title)
            }

            Section(header: Text("Datum")) {
                DatePicker("Datum",
                           selection: $draft.date,
                           displayedComponents: [.date, .hourAndMinute])
                    .environment(\.locale, Locale(identifier: "de_DE"))
            }

            Section(header: Text("Eintrag")) {
                ZStack(alignment: .topLeading) {
                    if draft.text.isEmpty {
                        Text("Schreib, was dir durch den Kopf geht …")
                            .foregroundColor(Color(.placeholderText))
                            .padding(.top, 8)
                            .padding(.leading, 4)
                    }
                    TextEditor(text: $draft.text)
                        .frame(minHeight: 160)
                }
            }

            Section(header: Text("Bilder")) {
                imagesGrid
                Button(action: { showingImageSourceDialog = true }) {
                    Label("Bild hinzufügen", systemImage: "photo.on.rectangle.angled")
                }
            }
        }
        .navigationBarTitle(isNew ? "Neuer Eintrag" : "Eintrag", displayMode: .inline)
        .navigationBarItems(
            leading: isNew ? AnyView(cancelButton) : AnyView(EmptyView()),
            trailing: saveButton
        )
        .actionSheet(isPresented: $showingImageSourceDialog) {
            ActionSheet(title: Text("Bild hinzufügen"), buttons: [
                .default(Text("Fotobibliothek")) { showingPhotoLibrary = true },
                .default(Text("Kamera")) { showingCamera = true },
                .cancel(Text("Abbrechen"))
            ])
        }
        .sheet(isPresented: $showingPhotoLibrary) {
            ImagePicker(source: .photoLibrary) { image in
                addImage(image)
            }
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(source: .camera) { image in
                addImage(image)
            }
        }
    }

    // MARK: - Buttons

    private var saveButton: some View {
        Button("Sichern") {
            store.addOrUpdate(draft)
            presentationMode.wrappedValue.dismiss()
        }
        .disabled(draft.title.isEmpty && draft.text.isEmpty && draft.imageFilenames.isEmpty)
    }

    private var cancelButton: some View {
        Button("Abbrechen") {
            presentationMode.wrappedValue.dismiss()
        }
    }

    // MARK: - Bilder

    private var imagesGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(draft.imageFilenames, id: \.self) { filename in
                    if let image = store.loadImage(named: filename) {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            Button(action: { removeImage(filename) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .background(Circle().fill(Color.black.opacity(0.5)))
                            }
                            .padding(4)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func addImage(_ image: UIImage) {
        if let filename = store.saveImage(image) {
            draft.imageFilenames.append(filename)
        }
    }

    private func removeImage(_ filename: String) {
        draft.imageFilenames.removeAll { $0 == filename }
    }
}
