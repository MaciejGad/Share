import UIKit

func drawBrightSpots(on image: UIImage, spots: [CGRect]) -> UIImage {
    guard let cgImage = image.cgImage else { return image }

    let renderer = UIGraphicsImageRenderer(size: image.size)
    var resultImage = renderer.image { context in
        // Draw original
        UIImage(cgImage: cgImage).draw(in: CGRect(origin: .zero, size: image.size))

        // Draw circles
        context.cgContext.setStrokeColor(UIColor.red.cgColor)
        context.cgContext.setLineWidth(2.0)

        for rect in spots {
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radius = max(rect.width, rect.height) / 2
            let circleRect = CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            )
            context.cgContext.addEllipse(in: circleRect)
            context.cgContext.strokePath()
        }
    }

    if image.imageOrientation == .right || image.imageOrientation == .left {
        if let cgImage = resultImage.cgImage {
            resultImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        }
    }
    
    return resultImage
}
