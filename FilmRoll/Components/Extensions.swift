import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }

    /// 채도와 밝기를 낮춰 어둡게 만듭니다. amount: 0.0~1.0
    func darkened(by amount: Double) -> Color {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(
            hue: h,
            saturation: max(0, s - amount * 0.4),
            brightness: max(0, b - amount)
        )
    }
}

extension Date {
    var stampDate: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy.MM.dd"
        return f.string(from: self)
    }

    var stampTime: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: self)
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Shared CIContext (gamma 변환 없이 raw 픽셀 연산 — SwiftUI modifier와 동일)

private let sharedCIContext: CIContext = {
    CIContext(options: [
        .workingColorSpace: NSNull(),
        .outputColorSpace: NSNull(),
        .useSoftwareRenderer: false,
        .cacheIntermediates: false
    ])
}()

extension UIImage {
    /// FilmStock 그레이딩 + colorIntensity를 CIColorMatrix 체인으로 굽습니다.
    /// SwiftUI applyFilmGradingWithIntensity와 수학적으로 동일한 연산을 동일한 순서로 적용.
    /// workingColorSpace=nil로 sRGB gamma 변환 없이 raw 픽셀 값에서 직접 연산하여
    /// SwiftUI modifier(gamma space 연산)와 정확히 일치하는 결과를 생성합니다.
    func applyGrading(stock: FilmStock, colorIntensity: Float) -> UIImage {
        guard let cgImage = self.cgImage else { return self }
        var ciImage = CIImage(cgImage: cgImage)

        let t = Double(max(0, min(1, colorIntensity)))

        // --- 1. saturation (CIColorMatrix) ---
        // SwiftUI .saturation(s): outC = luma + (inC - luma) * s
        // = inC * s + (R*0.2126 + G*0.7152 + B*0.0722) * (1-s)
        let targetSat = stock.grayscale > 0.5 ? 0.0 : stock.saturation
        let sat = 1.0 + (targetSat - 1.0) * t
        let oneMinusS = 1.0 - sat

        let satMatrix = CIFilter.colorMatrix()
        satMatrix.inputImage = ciImage
        satMatrix.rVector = CIVector(x: sat + 0.2126 * oneMinusS, y: 0.7152 * oneMinusS, z: 0.0722 * oneMinusS, w: 0)
        satMatrix.gVector = CIVector(x: 0.2126 * oneMinusS, y: sat + 0.7152 * oneMinusS, z: 0.0722 * oneMinusS, w: 0)
        satMatrix.bVector = CIVector(x: 0.2126 * oneMinusS, y: 0.7152 * oneMinusS, z: sat + 0.0722 * oneMinusS, w: 0)
        satMatrix.aVector = CIVector(x: 0, y: 0, z: 0, w: 1)
        satMatrix.biasVector = CIVector(x: 0, y: 0, z: 0, w: 0)
        ciImage = satMatrix.outputImage ?? ciImage

        // --- 2. contrast (CIColorMatrix) ---
        // SwiftUI .contrast(c): out = (in - 0.5) * c + 0.5 = in * c + 0.5*(1-c)
        let con = 1.0 + (stock.contrast - 1.0) * t
        let conBias = 0.5 * (1.0 - con)

        let conMatrix = CIFilter.colorMatrix()
        conMatrix.inputImage = ciImage
        conMatrix.rVector = CIVector(x: con, y: 0, z: 0, w: 0)
        conMatrix.gVector = CIVector(x: 0, y: con, z: 0, w: 0)
        conMatrix.bVector = CIVector(x: 0, y: 0, z: con, w: 0)
        conMatrix.aVector = CIVector(x: 0, y: 0, z: 0, w: 1)
        conMatrix.biasVector = CIVector(x: conBias, y: conBias, z: conBias, w: 0)
        ciImage = conMatrix.outputImage ?? ciImage

        // --- 3. brightness (CIColorMatrix) ---
        // SwiftUI .brightness(b): out = in + b
        let bri = stock.brightness * t
        if abs(bri) > 0.0001 {
            let briMatrix = CIFilter.colorMatrix()
            briMatrix.inputImage = ciImage
            briMatrix.rVector = CIVector(x: 1, y: 0, z: 0, w: 0)
            briMatrix.gVector = CIVector(x: 0, y: 1, z: 0, w: 0)
            briMatrix.bVector = CIVector(x: 0, y: 0, z: 1, w: 0)
            briMatrix.aVector = CIVector(x: 0, y: 0, z: 0, w: 1)
            briMatrix.biasVector = CIVector(x: bri, y: bri, z: bri, w: 0)
            ciImage = briMatrix.outputImage ?? ciImage
        }

        // --- 4. grayscale (CIColorMatrix) ---
        // SwiftUI .grayscale(g): Rec.709 luminance 가중 평균으로 변환
        let grey = stock.grayscale > 0.5 ? t : 0.0
        if grey > 0.001 {
            let lr = 0.2126 * grey
            let lg = 0.7152 * grey
            let lb = 0.0722 * grey
            let inv = 1.0 - grey

            let greyMatrix = CIFilter.colorMatrix()
            greyMatrix.inputImage = ciImage
            greyMatrix.rVector = CIVector(x: inv + lr, y: lg, z: lb, w: 0)
            greyMatrix.gVector = CIVector(x: lr, y: inv + lg, z: lb, w: 0)
            greyMatrix.bVector = CIVector(x: lr, y: lg, z: inv + lb, w: 0)
            greyMatrix.aVector = CIVector(x: 0, y: 0, z: 0, w: 1)
            greyMatrix.biasVector = CIVector(x: 0, y: 0, z: 0, w: 0)
            ciImage = greyMatrix.outputImage ?? ciImage
        }

        // --- 5. colorMultiply (CIColorMatrix) ---
        // SwiftUI .colorMultiply(color): 각 채널에 색상값을 곱함
        var mulR: CGFloat = 1, mulG: CGFloat = 1, mulB: CGFloat = 1
        UIColor(stock.colorMultiply).getRed(&mulR, green: &mulG, blue: &mulB, alpha: nil)
        let mr = 1.0 + (Double(mulR) - 1.0) * t
        let mg = 1.0 + (Double(mulG) - 1.0) * t
        let mb = 1.0 + (Double(mulB) - 1.0) * t

        let mulMatrix = CIFilter.colorMatrix()
        mulMatrix.inputImage = ciImage
        mulMatrix.rVector = CIVector(x: mr, y: 0, z: 0, w: 0)
        mulMatrix.gVector = CIVector(x: 0, y: mg, z: 0, w: 0)
        mulMatrix.bVector = CIVector(x: 0, y: 0, z: mb, w: 0)
        mulMatrix.aVector = CIVector(x: 0, y: 0, z: 0, w: 1)
        mulMatrix.biasVector = CIVector(x: 0, y: 0, z: 0, w: 0)
        ciImage = mulMatrix.outputImage ?? ciImage

        // --- 렌더링 (gamma 변환 없이) ---
        guard let outputCG = sharedCIContext.createCGImage(ciImage, from: ciImage.extent) else { return self }
        return UIImage(cgImage: outputCG, scale: self.scale, orientation: .up)
    }

    /// orientation을 반영해 4:3 가로 비율로 중앙 크롭합니다.
    func croppedTo4x3() -> UIImage {
        let w = size.width
        let h = size.height
        let targetRatio: CGFloat = 4.0 / 3.0

        let cropW: CGFloat
        let cropH: CGFloat
        if w / h > targetRatio {
            cropW = h * targetRatio
            cropH = h
        } else {
            cropW = w
            cropH = w / targetRatio
        }
        let cropX = (w - cropW) / 2
        let cropY = (h - cropH) / 2

        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: cropW, height: cropH), format: format)
        return renderer.image { _ in
            self.draw(at: CGPoint(x: -cropX, y: -cropY))
        }
    }
}
