import AppKit

/// 설정 화면 행 아이콘용 햄스터: SF Symbols 의 외곽선 아이콘처럼 속은 비우고 바깥 테두리만 남긴다.
/// 실루엣과 반대로 눈은 채운 점이다. 템플릿 이미지라 다른 아이콘처럼 강조색으로 칠해진다.
enum HamsterSymbol {
    /// 웅크린 첫 자세가 가장 동글동글하다
    static let pose = HamsterHopSprite.poses[0]
    /// 실루엣 좌표 단위의 선 두께. 툴바(17pt)에서 약 1.1pt 로 SF Symbol 보통 굵기와 비슷하다.
    static let lineWidth: CGFloat = 1.1
    static let pixelsPerUnit: CGFloat = 8

    static let image: CGImage = trimmed(render())

    /// 설정 창 툴바 탭 아이콘. 옆의 SF Symbol(톱니바퀴·계기판)과 높이를 맞춘 템플릿 이미지.
    @MainActor static let toolbarImage: NSImage = {
        let height: CGFloat = 17
        let size = NSSize(width: height * CGFloat(image.width) / CGFloat(image.height), height: height)
        let icon = NSImage(cgImage: image, size: size)
        icon.isTemplate = true
        return icon
    }()

    private static func render() -> CGImage {
        let units = CGSize(width: 28, height: 24)
        let context = CGContext(
            data: nil,
            width: Int(units.width * pixelsPerUnit),
            height: Int(units.height * pixelsPerUnit),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.scaleBy(x: pixelsPerUnit, y: pixelsPerUnit)
        context.translateBy(x: units.width / 2 - 1, y: units.height / 2 - 2)
        context.setFillColor(CGColor(gray: 0, alpha: 1))
        context.setStrokeColor(CGColor(gray: 0, alpha: 1))

        // 실루엣을 둘레로 여러 번 밀어 그려 두껍게 만든 뒤, 원래 실루엣 자리를 비우면 바깥 테두리만 남는다
        let directions = 16
        for index in 0..<directions {
            let angle = CGFloat(index) / CGFloat(directions) * 2 * .pi
            context.saveGState()
            context.translateBy(x: cos(angle) * lineWidth, y: sin(angle) * lineWidth)
            HamsterSilhouette.draw(pose, in: context)
            context.restoreGState()
        }
        context.saveGState()
        context.setBlendMode(.clear)
        HamsterSilhouette.draw(pose, in: context)
        context.restoreGState()

        // 채운 눈
        let eye = HamsterSilhouette.eyeCenter(pose)
        context.fillEllipse(in: CGRect(center: eye, size: CGSize(width: 1.9, height: 2.0)))
        return context.makeImage()!
    }

    /// 투명한 둘레를 잘라 아이콘 칸을 꽉 채우게 한다
    private static func trimmed(_ image: CGImage) -> CGImage {
        guard let data = image.dataProvider?.data, let bytes = CFDataGetBytePtr(data) else { return image }
        var minX = image.width, maxX = -1, minY = image.height, maxY = -1
        for y in 0..<image.height {
            for x in 0..<image.width where bytes[y * image.bytesPerRow + x * 4 + 3] > 8 {
                minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
            }
        }
        guard maxX >= minX, maxY >= minY else { return image }
        return image.cropping(to: CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)) ?? image
    }
}
