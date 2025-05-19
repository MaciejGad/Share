
let hsvGlareKernel = """
kernel vec4 glareHSV(__sample image, float valueThreshold, float saturationLimit) {
    float r = image.r;
    float g = image.g;
    float b = image.b;

    float maxVal = max(r, max(g, b));
    float minVal = min(r, min(g, b));
    float delta = maxVal - minVal;

    float v = maxVal;
    float s = (maxVal == 0.0) ? 0.0 : delta / maxVal;

    if (v > valueThreshold && s < saturationLimit) {
        return vec4(1.0, 0.0, 0.0, 1.0); // glare = red
    } else {
        return vec4(0.0, 0.0, 0.0, 1.0); // no glare = black
    }
}
"""
func detectGlareHSV(in image: UIImage, valueThreshold: Float = 0.9, saturationLimit: Float = 0.2) -> UIImage? {
    guard let ciImage = CIImage(image: image),
          let kernel = try? CIColorKernel(source: hsvGlareKernel) else {
        return nil
    }

    let arguments: [Any] = [ciImage, valueThreshold, saturationLimit]
    let extent = ciImage.extent

    guard let outputImage = kernel.apply(extent: extent, arguments: arguments) else {
        return nil
    }

    let context = CIContext()
    if let cgImage = context.createCGImage(outputImage, from: extent) {
        return UIImage(cgImage: cgImage)
    }

    return nil
}
