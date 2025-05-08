import UIKit
import CoreImage
import Vision


struct BrightSpots {
    let spots: [CGRect]
    let startImage: CIImage?
    let grayScaleImage: CIImage?
    let blurredImage: CIImage?
    let thresholdedImage: CIImage?
    
    init(spots: [CGRect] = [], startImage: CIImage? = nil, grayScaleImage: CIImage? = nil, blurredImage: CIImage? = nil, thresholdedImage: CIImage? = nil) {
        self.spots = spots
        self.startImage = startImage
        self.grayScaleImage = grayScaleImage
        self.blurredImage = blurredImage
        self.thresholdedImage = thresholdedImage
    }
}

func detectBrightSpots(in image: UIImage) -> BrightSpots {
    guard let ciImage = CIImage(image: image) else { return .init()}
    let context = CIContext()

    // Grayscale
    let grayscaleFilter = CIFilter(name: "CIPhotoEffectMono")
    grayscaleFilter?.setValue(ciImage, forKey: kCIInputImageKey)
    guard let grayImage = grayscaleFilter?.outputImage else { return .init(startImage: ciImage) }

    // Gaussian blur
    let blurFilter = CIFilter(name: "CIGaussianBlur")
    blurFilter?.setValue(grayImage, forKey: kCIInputImageKey)
    blurFilter?.setValue(2.0, forKey: kCIInputRadiusKey)
    guard let blurredImage = blurFilter?.outputImage else { return .init(startImage: ciImage, grayScaleImage: grayImage) }

    // Threshold
    let thresholdFilter = CIFilter(name: "CIColorClamp")!
    thresholdFilter.setValue(blurredImage, forKey: kCIInputImageKey)
    thresholdFilter.setValue(CIVector(x: 0.9, y: 0.9, z: 0.9, w: 1), forKey: "inputMinComponents")
    thresholdFilter.setValue(CIVector(x: 1, y: 1, z: 1, w: 1), forKey: "inputMaxComponents")
    guard let thresholdedImage = thresholdFilter.outputImage else { return .init(startImage: ciImage, grayScaleImage: grayImage, blurredImage: blurredImage) }

    // Create CGImage for Vision
    let croppedThresholdedImage = thresholdedImage.cropped(to: ciImage.extent)
    guard let cgThresholded = context.createCGImage(croppedThresholdedImage, from: croppedThresholdedImage.extent) else { return .init(startImage: ciImage, grayScaleImage: grayImage, blurredImage: blurredImage, thresholdedImage: thresholdedImage) }

    let imageSize = image.size
    var brightSpots: [CGRect] = []

    // Recursive helper
    func extractBoundingRects(from contours: [VNContour]) -> [CGRect] {
        var rects: [CGRect] = []
        for contour in contours {
            let bbox = contour.normalizedPath.boundingBox
            let rect = CGRect(
                x: bbox.origin.x * imageSize.width,
                y: (1 - bbox.origin.y - bbox.size.height) * imageSize.height,
                width: bbox.size.width * imageSize.width,
                height: bbox.size.height * imageSize.height
            )
            rects.append(rect)
            rects.append(contentsOf: extractBoundingRects(from: contour.childContours))
        }
        return rects
    }

    // Vision request
    let request = VNDetectContoursRequest { request, error in
        guard let results = request.results as? [VNContoursObservation], error == nil else { return }
        for contourObservation in results {
            let rects = extractBoundingRects(from: contourObservation.topLevelContours)
            brightSpots.append(contentsOf: rects)
        }
    }

    request.detectsDarkOnLight = false
    request.maximumImageDimension = 512

    let handler = VNImageRequestHandler(cgImage: cgThresholded, options: [:])
    try? handler.perform([request])

    return .init(spots: brightSpots, startImage: ciImage, grayScaleImage: grayImage, blurredImage: blurredImage, thresholdedImage: thresholdedImage)
}
