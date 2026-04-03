import SwiftUI

struct FilmStock: Identifiable {
    let id: String
    let name: String
    let tagline: String
    let frameCount: Int
    let canisterHex: String

    // Color grading
    let colorMultiply: Color
    let saturation: Double
    let contrast: Double
    let brightness: Double
    let grayscale: Double
    let grainOpacity: Double     // 1.0 = normal
    let vignetteOpacity: Double  // 0.0–1.0

    static let all: [FilmStock] = [
        .solaris, .argent, .ember, .glacier,
        .bloom, .kino, .fade, .aurora, .instant
    ]
}

// MARK: - Film Stock Definitions

extension FilmStock {

    /// 따뜻한 황금빛 오후를 담은 클래식 컬러 — 36장
    static let solaris = FilmStock(
        id: "solaris",
        name: "Solaris",
        tagline: "Warm gold tones, soft contrast",
        frameCount: 36,
        canisterHex: "#C8900A",
        colorMultiply: Color(red: 1.0, green: 0.93, blue: 0.70),
        saturation: 1.05, contrast: 1.05, brightness: 0.0,
        grayscale: 0.0, grainOpacity: 1.0, vignetteOpacity: 0.30
    )

    /// 빛과 그림자만 남긴 깊은 흑백 — 36장
    static let argent = FilmStock(
        id: "argent",
        name: "Argent",
        tagline: "Timeless black & white, deep grain",
        frameCount: 36,
        canisterHex: "#707070",
        colorMultiply: .white,
        saturation: 1.0, contrast: 1.12, brightness: 0.0,
        grayscale: 1.0, grainOpacity: 1.8, vignetteOpacity: 0.40
    )

    /// 텅스텐 조명 아래 붉게 타오르는 실내 온기 — 24장
    static let ember = FilmStock(
        id: "ember",
        name: "Ember",
        tagline: "Amber-red warmth, tungsten glow",
        frameCount: 24,
        canisterHex: "#B83A14",
        colorMultiply: Color(red: 1.0, green: 0.76, blue: 0.48),
        saturation: 1.1, contrast: 1.08, brightness: 0.0,
        grayscale: 0.0, grainOpacity: 0.8, vignetteOpacity: 0.40
    )

    /// 새벽 공기처럼 차갑고 투명한 블루 실버 — 24장
    static let glacier = FilmStock(
        id: "glacier",
        name: "Glacier",
        tagline: "Cool silver-blue, crisp shadows",
        frameCount: 24,
        canisterHex: "#3A7EA8",
        colorMultiply: Color(red: 0.78, green: 0.90, blue: 1.0),
        saturation: 0.88, contrast: 1.06, brightness: 0.0,
        grayscale: 0.0, grainOpacity: 0.7, vignetteOpacity: 0.25
    )

    /// 과노출된 봄 햇살, 꿈처럼 번지는 핑크 헤이즈 — 12장
    static let bloom = FilmStock(
        id: "bloom",
        name: "Bloom",
        tagline: "Overexposed pink haze, dreamy soft",
        frameCount: 12,
        canisterHex: "#B84878",
        colorMultiply: Color(red: 1.0, green: 0.84, blue: 0.90),
        saturation: 0.82, contrast: 0.92, brightness: 0.04,
        grayscale: 0.0, grainOpacity: 1.4, vignetteOpacity: 0.20
    )

    /// 영화 속 한 장면 같은 틸-오렌지 시네마틱 룩 — 36장
    static let kino = FilmStock(
        id: "kino",
        name: "Kino",
        tagline: "Cinematic teal-orange, filmic contrast",
        frameCount: 36,
        canisterHex: "#1E5C50",
        colorMultiply: Color(red: 0.86, green: 0.96, blue: 0.90),
        saturation: 1.12, contrast: 1.15, brightness: -0.02,
        grayscale: 0.0, grainOpacity: 0.9, vignetteOpacity: 0.45
    )

    /// 세월에 바랜 빈티지, 오래된 앨범의 온기 — 24장
    static let fade = FilmStock(
        id: "fade",
        name: "Fade",
        tagline: "Faded vintage, muted warm palette",
        frameCount: 24,
        canisterHex: "#7A6040",
        colorMultiply: Color(red: 1.0, green: 0.94, blue: 0.82),
        saturation: 0.62, contrast: 0.90, brightness: 0.04,
        grayscale: 0.0, grainOpacity: 1.2, vignetteOpacity: 0.30
    )

    /// 보라와 청록이 번지는 밤하늘, 빛의 할레이션 — 12장
    static let aurora = FilmStock(
        id: "aurora",
        name: "Aurora",
        tagline: "Purple-teal night glow, halation",
        frameCount: 12,
        canisterHex: "#4A2E8A",
        colorMultiply: Color(red: 0.80, green: 0.84, blue: 1.0),
        saturation: 1.08, contrast: 1.05, brightness: -0.02,
        grayscale: 0.0, grainOpacity: 1.5, vignetteOpacity: 0.50
    )

    /// 단 한 장, 즉석 필름 특유의 따뜻한 크림 세피아 — 1장
    static let instant = FilmStock(
        id: "instant",
        name: "Instant",
        tagline: "One frame only, warm cream sepia",
        frameCount: 1,
        canisterHex: "#C4A87A",
        colorMultiply: Color(red: 1.0, green: 0.90, blue: 0.74),
        saturation: 0.68, contrast: 0.94, brightness: 0.03,
        grayscale: 0.0, grainOpacity: 0.6, vignetteOpacity: 0.35
    )
}

// MARK: - View Extension

extension View {
    @ViewBuilder
    func applyFilmGrading(_ stock: FilmStock?) -> some View {
        if let stock {
            self
                .grayscale(stock.grayscale)
                .saturation(stock.saturation)
                .contrast(stock.contrast)
                .brightness(stock.brightness)
                .colorMultiply(stock.colorMultiply)
        } else {
            self
        }
    }
}
