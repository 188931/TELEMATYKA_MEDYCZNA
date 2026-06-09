import SwiftUI

struct PatientPhotoGalleryView: View {
    @ObservedObject var viewModel: AppViewModel
    let patientID: Int
    let canAddPhoto: Bool
    let visitID: Int?

    @State private var photos: [PatientPhotoRecord] = []
    @State private var imageData: [String: Data] = [:]
    @State private var isLoading = false

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 8)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Zdjęcia pacjenta")
                    .font(.headline)
                    .accessibleHeading()
                Spacer()
                if canAddPhoto {
                    Button {
                        viewModel.openPhotoCapture(patientID: patientID, visitID: visitID)
                    } label: {
                        Label("Dodaj", systemImage: "camera.fill")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .minimumTapTarget()
                    .accessibilityHint("Otwiera formularz dodawania zdjęcia")
                }
            }

            if photos.isEmpty && !isLoading {
                Text("Brak zdjęć w kartotece")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Brak zdjęć w kartotece pacjenta")
            } else {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(photos) { photo in
                        VStack(spacing: 4) {
                            photoThumbnail(for: photo)
                                .frame(height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            if let caption = photo.caption, !caption.isEmpty {
                                Text(caption).font(.caption2).lineLimit(2)
                            }
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(photoAccessibilityLabel(photo))
                        .accessibilityAddTraits(.isImage)
                    }
                }
                .accessibilityLabel("Galeria zdjęć pacjenta, \(photos.count) zdjęć")
            }
        }
        .accessibleLoading(isLoading, label: "Ładowanie zdjęć")
        .task(id: patientID) { await loadPhotos() }
        .onChange(of: viewModel.activePhotoCaptureContext) { _, newValue in
            if newValue == nil { Task { await loadPhotos() } }
        }
    }

    private func photoAccessibilityLabel(_ photo: PatientPhotoRecord) -> String {
        if let caption = photo.caption, !caption.isEmpty {
            return "Zdjęcie pacjenta: \(caption), dodane \(photo.takenAt)"
        }
        return "Zdjęcie pacjenta z dnia \(photo.takenAt)"
    }

    @ViewBuilder
    private func photoThumbnail(for photo: PatientPhotoRecord) -> some View {
        if let data = imageData[photo.fileName], let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .accessibilityHidden(true)
        } else {
            Rectangle()
                .fill(Color(.secondarySystemBackground))
                .overlay { ProgressView() }
                .accessibilityLabel("Ładowanie miniatury zdjęcia")
                .task { await loadImage(for: photo) }
        }
    }

    private func loadPhotos() async {
        isLoading = true
        defer { isLoading = false }
        do {
            photos = try await viewModel.fetchPatientPhotos(patientID: patientID)
        } catch {
            viewModel.showError(error.localizedDescription)
        }
    }

    private func loadImage(for photo: PatientPhotoRecord) async {
        if let local = await viewModel.localPhotoData(fileName: photo.fileName) {
            imageData[photo.fileName] = local
            return
        }
        let url = viewModel.photoURL(fileName: photo.fileName)
        if let (data, _) = try? await URLSession.shared.data(from: url) {
            imageData[photo.fileName] = data
        }
    }
}
