import SwiftUI

protocol GlareDetectionViewModelProtocol {
    var inputImage: UIImage? { get set }
    var processedImage: UIImage? { get set }
    var showLoader: Bool { get set }
    var glareDetected: Bool { get set }
    var sourceType: UIImagePickerController.SourceType { get set }
    func processImage(_ image: UIImage)
}

class GlareDetectionViewModel: ObservableObject {
    @Published var inputImage: UIImage?
    @Published var processedImage: UIImage?
    @Published var showLoader: Bool = false
    @Published var glareDetected: Bool = false
    @Published var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    func processImage(_ image: UIImage) {
        inputImage = image
        showLoader = true
        DispatchQueue.global(qos: .userInitiated).async {
            let spots = detectBrightSpots(in: image)
            print("Detected spots: \(spots.spots)")
            print("Images: \(spots.thresholdedImage), \(spots.blurredImage), \(spots.grayScaleImage)")
            let result = drawBrightSpots(on: image, spots: spots.spots)
            DispatchQueue.main.async {
                self.showLoader = false
                self.glareDetected = !spots.spots.isEmpty
                self.processedImage = result
            }
        }
    }
    
    func with(showLoader: Bool) -> Self {
        self.showLoader = showLoader
        return self
    }
    
    func with(glareDetected: Bool) -> Self {
        self.glareDetected = glareDetected
        return self
    }
    
    func with(processedImage: UIImage?) -> Self {
        self.processedImage = processedImage
        return self
    }
}
