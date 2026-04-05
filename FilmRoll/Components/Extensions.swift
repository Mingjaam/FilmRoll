import SwiftUI

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

extension UIImage {
    /// FilmStock 그레이딩 + colorIntensity를 실제 픽셀에 굽습니다.
    /// SwiftUI applyFilmGradingWithIntensity와 완전히 동일한 SwiftUI modifier를 ImageRenderer로 렌더링하여
    /// 카메라 프리뷰와 저장 이미지의 색감이 정확히 일치합니다.
    @MainActor
    func applyGrading(stock: FilmStock, colorIntensity: Float) -> UIImage {
        let w = self.size.width
        let h = self.size.height

        let renderer = ImageRenderer(
            content: Image(uiImage: self)
                .resizable()
                .frame(width: w, height: h)
                .applyFilmGradingWithIntensity(stock, intensity: Double(colorIntensity))
        )
        renderer.scale = self.scale
        renderer.proposedSize = ProposedViewSize(width: w, height: h)

        guard let cgImg = renderer.cgImage else { return self }
        return UIImage(cgImage: cgImg, scale: self.scale, orientation: .up)
    }

    /// orientation을 반영해 4:3 가로 비율로 중앙 크롭합니다.
    func croppedTo4x3() -> UIImage {
        // UIImage.size는 orientation이 적용된 논리적 크기 — 이걸 기준으로 계산
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

        // opaque 포맷 명시 — 알파 채널 불필요, 파일 크기 및 메모리 최적화
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: cropW, height: cropH), format: format)
        return renderer.image { _ in
            self.draw(at: CGPoint(x: -cropX, y: -cropY))
        }
    }
}
