import CoreGraphics

/// 앱 아이콘: 해바라기씨 색 그라데이션 위로 하얀 깡총 햄스터가 왼쪽 밖에서 뛰어든다.
/// RunCat Neo 아이콘과 같은 구도(큰 동물이 가장자리에서 잘린 채 뛰어오름)를 햄스터 색으로 다시 그렸다.
/// `scripts/make-icon.sh` 가 이 그림으로 .icns 를 만든다.
enum AppIconRenderer {
    /// 정점에서 몸을 살짝 든 자세
    static let pose = HamsterSilhouette.Pose(pitch: 8, stretch: 1.12, front: 55, hind: -55, hindReach: 1.2)

    static let top = CGColor(srgbRed: 0.99, green: 0.78, blue: 0.45, alpha: 1)
    static let bottom = CGColor(srgbRed: 0.56, green: 0.30, blue: 0.16, alpha: 1)
    static let eyeColor = CGColor(srgbRed: 0.27, green: 0.14, blue: 0.08, alpha: 1)

    static func render(pixels: Int) -> CGImage {
        let size = CGFloat(pixels)
        let context = CGContext(
            data: nil,
            width: pixels,
            height: pixels,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        // macOS 아이콘 격자: 1024 캔버스 안 824 크기의 둥근 사각형, 아래로 살짝 그림자
        context.scaleBy(x: size / 1024, y: size / 1024)
        let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
        let shape = CGPath(roundedRect: tile, cornerWidth: 185, cornerHeight: 185, transform: nil)

        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: -10), blur: 24, color: CGColor(gray: 0, alpha: 0.3))
        context.addPath(shape)
        context.setFillColor(bottom)
        context.fillPath()
        context.restoreGState()

        context.saveGState()
        context.addPath(shape)
        context.clip()
        let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: [top, bottom] as CFArray, locations: [0, 1])!
        context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: tile.maxY), end: CGPoint(x: 0, y: tile.minY), options: [])

        // 햄스터: 몸통 중심을 타일 왼쪽 가까이 두어 엉덩이가 잘리게 한다
        let scale: CGFloat = 44
        let origin = CGPoint(x: 372, y: 470)
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: -8), blur: 20, color: CGColor(gray: 0, alpha: 0.18))
        context.beginTransparencyLayer(auxiliaryInfo: nil)
        context.translateBy(x: origin.x, y: origin.y)
        context.scaleBy(x: scale, y: scale)
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.setStrokeColor(CGColor(gray: 1, alpha: 1))
        HamsterSilhouette.draw(pose, in: context)
        context.endTransparencyLayer()
        context.restoreGState()

        // 실루엣의 흰 눈 구멍 위에 짙은 눈동자와 반짝임
        let eye = HamsterSilhouette.eyeCenter(pose)
        let center = CGPoint(x: origin.x + eye.x * scale, y: origin.y + eye.y * scale)
        context.setFillColor(eyeColor)
        context.fillEllipse(in: CGRect(center: center, size: CGSize(width: 1.9 * scale, height: 2.0 * scale)))
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fillEllipse(in: CGRect(center: CGPoint(x: center.x + 0.35 * scale, y: center.y + 0.4 * scale), size: CGSize(width: 0.7 * scale, height: 0.7 * scale)))
        context.restoreGState()
        return context.makeImage()!
    }
}
