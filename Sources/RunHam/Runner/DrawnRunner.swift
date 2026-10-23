import CoreGraphics
import CoreImage

/// 코드로 그리는 기본 러너를 만드는 공통 도구.
///
/// 모든 기본 러너는 같은 규칙을 따른다: 높이 18pt 캔버스, 원점은 왼쪽 아래, 검은 실루엣에 하얀 눈(투명 구멍) 하나.
/// 메뉴바 프레임은 2배, 설정 미리보기는 6배로 그린다.
enum DrawnRunner {
    static let height: CGFloat = 18
    static let scale: CGFloat = 2
    static let previewScale: CGFloat = 6

    static func make(
        id: String,
        nameKey: String,
        width: CGFloat,
        frameCount: Int,
        baseFrameRate: Double,
        smoothing: CGFloat = 0,
        details: ((_ frame: Int, _ context: CGContext) -> Void)? = nil,
        draw: @escaping (_ frame: Int, _ context: CGContext) -> Void
    ) -> Runner {
        func render(_ frame: Int, _ scale: CGFloat) -> CGImage {
            let size = (width: Int(width * scale), height: Int(height * scale))
            let body = SpriteRenderer.render(width: size.width, height: size.height) { context in
                context.scaleBy(x: scale, y: scale)
                draw(frame, context)
            }
            guard smoothing > 0 || details != nil else { return body }
            let base = smoothing > 0 ? smooth(body, radius: smoothing * scale) : body
            // 눈처럼 또렷해야 하는 부분은 다듬은 뒤에 그린다
            return SpriteRenderer.render(width: size.width, height: size.height) { context in
                context.draw(base, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
                context.scaleBy(x: scale, y: scale)
                details?(frame, context)
            }
        }
        let frames = Array(0..<frameCount)
        return Runner(
            id: id,
            nameKey: nameKey,
            frames: frames.map { render($0, scale) },
            isPixelArt: false,
            previewFrames: frames.map { render($0, previewScale) },
            baseFrameRate: baseFrameRate
        )
    }

    /// 겹친 도형을 살짝 번지게 했다가 다시 또렷하게 깎아, 이음매 없이 말랑하게 이어진 실루엣으로 만든다.
    /// radius 는 픽셀 단위. 작은 틈은 메워지고 뾰족한 끝은 둥글어진다.
    static func smooth(_ image: CGImage, radius: CGFloat) -> CGImage {
        let input = CIImage(cgImage: image)
        let extent = input.extent
        let blurred = input.clampedToExtent().applyingGaussianBlur(sigma: radius).cropped(to: extent)
        // 알파를 0.5 근처에서 가파르게 올려 다시 또렷한 경계로(가장자리 1px 정도는 부드럽게 남긴다)
        let sharpness: CGFloat = 5
        let thresholded = blurred.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: sharpness),
            "inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: 0.5 - sharpness * 0.5),
        ]).applyingFilter("CIColorClamp")
        let context = CIContext(options: [.workingColorSpace: NSNull()])
        return context.createCGImage(thresholded, from: extent, format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB()) ?? image
    }

    // MARK: - 도형

    static func fill(_ center: CGPoint, _ size: CGSize, in context: CGContext) {
        context.fillEllipse(in: CGRect(center: center, size: size))
    }

    /// 중심을 축으로 angle(도)만큼 돌린 타원
    static func fill(_ center: CGPoint, _ size: CGSize, rotated angle: CGFloat, in context: CGContext) {
        context.saveGState()
        context.translateBy(x: center.x, y: center.y)
        context.rotate(by: angle * .pi / 180)
        context.fillEllipse(in: CGRect(center: .zero, size: size))
        context.restoreGState()
    }

    static func polygon(_ points: [CGPoint], in context: CGContext) {
        guard let first = points.first else { return }
        context.move(to: first)
        points.dropFirst().forEach { context.addLine(to: $0) }
        context.closePath()
        context.fillPath()
    }

    /// 끝이 둥근 선(다리, 꼬리 등)
    static func stroke(_ points: [CGPoint], width: CGFloat, in context: CGContext) {
        guard let first = points.first else { return }
        context.saveGState()
        context.setLineWidth(width)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.move(to: first)
        points.dropFirst().forEach { context.addLine(to: $0) }
        context.strokePath()
        context.restoreGState()
    }

    /// 굵기가 startWidth 에서 endWidth 로 점점 가늘어지는 곡선(꼬리·다리). 동그라미를 촘촘히 이어 몸과 자연스럽게 붙는다.
    static func taper(from start: CGPoint, control1: CGPoint, control2: CGPoint, to end: CGPoint,
                      startWidth: CGFloat, endWidth: CGFloat, in context: CGContext) {
        let steps = 24
        for index in 0...steps {
            let t = CGFloat(index) / CGFloat(steps), u = 1 - t
            let point = CGPoint(
                x: u * u * u * start.x + 3 * u * u * t * control1.x + 3 * u * t * t * control2.x + t * t * t * end.x,
                y: u * u * u * start.y + 3 * u * u * t * control1.y + 3 * u * t * t * control2.y + t * t * t * end.y
            )
            let width = startWidth + (endWidth - startWidth) * t
            context.fillEllipse(in: CGRect(center: point, size: CGSize(width: width, height: width)))
        }
    }

    /// 곧은 선 버전
    static func taper(from start: CGPoint, to end: CGPoint, startWidth: CGFloat, endWidth: CGFloat, in context: CGContext) {
        let a = CGPoint(x: start.x + (end.x - start.x) / 3, y: start.y + (end.y - start.y) / 3)
        let b = CGPoint(x: start.x + (end.x - start.x) * 2 / 3, y: start.y + (end.y - start.y) * 2 / 3)
        taper(from: start, control1: a, control2: b, to: end, startWidth: startWidth, endWidth: endWidth, in: context)
    }

    /// 실루엣에 하얀 눈(투명 구멍)을 뚫는다
    static func eye(_ center: CGPoint, size: CGSize = CGSize(width: 1.4, height: 1.5), in context: CGContext) {
        context.saveGState()
        context.setBlendMode(.clear)
        context.fillEllipse(in: CGRect(center: center, size: size))
        context.restoreGState()
    }

    /// 실루엣 안에 하얀 선(입 등)을 긋는다
    static func clearStroke(_ points: [CGPoint], width: CGFloat, in context: CGContext) {
        context.saveGState()
        context.setBlendMode(.clear)
        stroke(points, width: width, in: context)
        context.restoreGState()
    }

    /// 한 바퀴 위상(0..<1)
    static func phase(_ frame: Int, of count: Int) -> CGFloat {
        CGFloat(frame) / CGFloat(count)
    }
}
