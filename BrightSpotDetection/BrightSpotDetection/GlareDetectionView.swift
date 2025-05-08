import SwiftUI


struct GlareDetectionView: View {
    @State private var showingImagePicker = false
    @EnvironmentObject var viewModel: GlareDetectionViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let processed = viewModel.processedImage {
                    Image(uiImage: processed)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 600)
                        .overlay(
                            Text(viewModel.glareDetected ? "⚠️ Glare Detected" : "✅ No Glare")
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .padding(),
                            alignment: .topTrailing
                        )
                } else {
                    if viewModel.showLoader {
                        ProgressView("Processing...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .padding()
                    }
                    Text("Select or take a photo to detect glare")
                        .padding()
                }

                HStack {
                    Button("Take Photo") {
                        viewModel.sourceType = .camera
                        showingImagePicker = true
                    }
                    .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))

                    Button("Choose Photo") {
                        viewModel.sourceType = .photoLibrary
                        showingImagePicker = true
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Glare Detector")
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker()
            }
        }
    }
}


#Preview {
    GlareDetectionView()
//        .environmentObject(GlareDetectionViewModel().with(showLoader: true))
        .environmentObject(
            GlareDetectionViewModel()
                .with(glareDetected: false)
                .with(processedImage:
                        UIImage(systemName: "photo")?
                    .applyingSymbolConfiguration(.init(pointSize: 100)
                )))
}

