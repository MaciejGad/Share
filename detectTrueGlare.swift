import UIKit
import CoreImage

func detectTrueGlare(in image: UIImage, valueThreshold: Float = 0.9, saturationLimit: Float = 0.2) -> UIImage? {
    guard let ciImage = CIImage(image: image),
          let hsvKernel = try? CIColorKernel(source: hsvGlareKernel),
          let sobelKernel = try? CIColorKernel(source: sobelKernel) else {
        return nil
    }

    let extent = ciImage.extent

    // Step 1: Run HSV Glare Kernel
    guard let hsvGlare = hsvKernel.apply(extent: extent, arguments: [ciImage, valueThreshold, saturationLimit]) else {
        return nil
    }

    // Step 2: Convert to grayscale before edge detection
    let grayFilter = CIFilter(name: "CIPhotoEffectMono")
    grayFilter?.setValue(ciImage, forKey: kCIInputImageKey)
    guard let grayImage = grayFilter?.outputImage else {
        return nil
    }

    // Step 3: Run Sobel Edge Detection
    guard let edges = sobelKernel.apply(extent: extent, arguments: [grayImage]) else {
        return nil
    }

    // Step 4: Multiply glare and edge maps
    let multiplyFilter = CIFilter(name: "CIMultiplyCompositing")
    multiplyFilter?.setValue(hsvGlare, forKey: kCIInputImageKey)
    multiplyFilter?.setValue(edges, forKey: kCIInputBackgroundImageKey)

    guard let combined = multiplyFilter?.outputImage else {
        return nil
    }

    // Step 5: Create final UIImage
    let context = CIContext()
    guard let cgImage = context.createCGImage(combined, from: extent) else {
        return nil
    }

    return UIImage(cgImage: cgImage)
}

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
        return vec4(1.0, 1.0, 1.0, 1.0); // White mask = potential glare
    } else {
        return vec4(0.0, 0.0, 0.0, 1.0);
    }
}
"""

let sobelKernel = """
kernel vec4 sobelEdge(__sample image) {
    vec2 dc = destCoord();

    vec2 size = samplerSize(image);
    float w = 1.0 / size.x;
    float h = 1.0 / size.y;

    float Gx = 0.0;
    float Gy = 0.0;

    // Sobel horizontal and vertical kernels
    Gx += -1.0 * sample(image, samplerTransform(image, dc + vec2(-w, -h))).r;
    Gx += -2.0 * sample(image, samplerTransform(image, dc + vec2(-w,  0))).r;
    Gx += -1.0 * sample(image, samplerTransform(image, dc + vec2(-w,  h))).r;
    Gx +=  1.0 * sample(image, samplerTransform(image, dc + vec2( w, -h))).r;
    Gx +=  2.0 * sample(image, samplerTransform(image, dc + vec2( w,  0))).r;
    Gx +=  1.0 * sample(image, samplerTransform(image, dc + vec2( w,  h))).r;

    Gy += -1.0 * sample(image, samplerTransform(image, dc + vec2(-w, -h))).r;
    Gy += -2.0 * sample(image, samplerTransform(image, dc + vec2( 0, -h))).r;
    Gy += -1.0 * sample(image, samplerTransform(image, dc + vec2( w, -h))).r;
    Gy +=  1.0 * sample(image, samplerTransform(image, dc + vec2(-w,  h))).r;
    Gy +=  2.0 * sample(image, samplerTransform(image, dc + vec2( 0,  h))).r;
    Gy +=  1.0 * sample(image, samplerTransform(image, dc + vec2( w,  h))).r;

    float edge = sqrt(Gx * Gx + Gy * Gy);
    return vec4(edge, edge, edge, 1.0);
}
"""