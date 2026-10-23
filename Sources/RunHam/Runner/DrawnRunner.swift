import CoreGraphics

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
        draw: @escaping (_ frame: Int, _ context: CGContext) -> Void
    ) -> Runner {
        func render(_ frame: Int, _ scale: CGFloat) -> CGImage {
            SpriteRenderer.render(width: Int(width * scale), height: Int(height * scale)) { context in
                context.scaleBy(x: scale, y: scale)
                draw(frame, context)
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
