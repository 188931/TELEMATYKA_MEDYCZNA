import PhotosUI
import SwiftUI

struct PatientPhotoCaptureView: View {
    @ObservedObject var viewModel: AppViewModel
    let context: PhotoCaptureContext

    @State private var selectedItem: PhotosPickerItem?
    @State private var previewImage: UIImage?
    @State private var caption = ""
    @State private var isUploading = false
    @State private var showCamera = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if let previewImage {
                        Image(uiImage: previewImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 240)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .accessibilityLabel("Podgląd wybranego zdjęcia pacjenta")
                            .accessibilityAddTraits(.isImage)
                    } else {
                        ContentUnavailableView("Brak zdjęcia", systemImage: "camera")
                            .accessibilityLabel("Nie wybrano jeszcze zdjęcia")
                    }
                } header: {
                    Text("Podgląd")
                        .accessibleHeading()
                }

                Section {
                    PhotosPicker("Wybierz z galerii", selection: $selectedItem, matching: .images)
                        .minimumTapTarget()
                        .accessibilityHint("Otwiera galerię zdjęć urządzenia")
                    Button("Zrób zdjęcie aparatem") { showCamera = true }
                        .minimumTapTarget()
                        .accessibilityHint("Otwiera aparat do zrobienia zdjęcia")
                } header: {
                    Text("Źródło")
                        .accessibleHeading()
                }

                Section {
                    TextField("Podpis zdjęcia (opcjonalnie)", text: $caption)
                        .accessibleFormLabel("Podpis zdjęcia, opcjonalny")
                } header: {
                    Text("Opis")
                        .accessibleHeading()
                }

                Section {
                    Button("Zapisz w kartotece") {
                        Task { await upload() }
                    }
                    .disabled(previewImage == nil || isUploading)
                    .minimumTapTarget()
                    .accessibilityHint(
                        previewImage == nil
                            ? "Wybierz lub zrób zdjęcie przed zapisem"
                            : "Zapisuje zdjęcie w kartotece pacjenta"
                    )
                }
            }
            .navigationTitle("Zdjęcie pacjenta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") { viewModel.activePhotoCaptureContext = nil }
                        .accessibilityHint("Zamyka bez zapisywania zdjęcia")
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                Task { await loadImage(from: newItem) }
            }
            .sheet(isPresented: $showCamera) {
                CameraPicker(image: $previewImage)
            }
            .accessibleLoading(isUploading, label: "Zapisywanie zdjęcia")
        }
    }

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            previewImage = image
        }
    }

    private func upload() async {
        guard let previewImage,
              let data = previewImage.jpegData(compressionQuality: 0.85) else { return }
        isUploading = true
        defer { isUploading = false }
        do {
            _ = try await viewModel.uploadPatientPhoto(
                patientID: context.patientID,
                visitID: context.visitID,
                caption: caption.isEmpty ? nil : caption,
                imageData: data
            )
            viewModel.activePhotoCaptureContext = nil
        } catch {
            viewModel.showError(error.localizedDescription)
        }
    }
}

private struct CameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker

        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
