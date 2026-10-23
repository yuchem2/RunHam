import CoreGraphics

/// 햄스터 공 굴리기. 26×18pt, 8프레임.
///
/// 숨구멍 네 개가 난 공 테두리가 굴러가는 방향(시계 방향)으로 돌고, 공 뒤로 속도선이 날린다.
/// 안에서는 기본 러너와 같은 실루엣 햄스터가 공 바닥을 딛고 종종 달린다.
/// 좌표는 포인트 단위, 원점은 왼쪽 아래, 오른쪽으로 굴러간다.
enum HamsterBallSprite {
    static let canvas = CGSize(width: 26, height: 18)
    static let scale: CGFloat = 2
    static let previewScale: CGFloat = 6
    static let frameCount = 8

    static func makeRunner() -> Runner {
        let frames = Array(0..<frameCount)
        return Runner(
            id: "hamster-ball",
            nameKey: "runner.hamsterBall",
            frames: frames.map { render(frame: $0, scale: scale) },
            isPixelArt: false,
            previewFrames: frames.map { render(frame: $0, scale: previewScale) },
            // 8프레임 한 바퀴가 속도 1 에서 2초
            baseFrameRate: 4
        )
    }

    static let center = CGPoint(x: 16.6, y: 9)
    static let radius: CGFloat = 8.7
    static let ringWidth: CGFloat = 1.2
    static let holeCount = 4
    static let holeAngle: CGFloat = 0.2
    static let hamsterScale: CGFloat = 0.66

    static func render(frame: Int, scale: CGFloat) -> CGImage {
        SpriteRenderer.render(width: Int(canvas.width * scale), height: Int(canvas.height * scale)) { context in
            context.scaleBy(x: scale, y: scale)
            draw(frame: frame, in: context)
        }
    }

    static func draw(frame: Int, in context: CGContext) {
        let phase = CGFloat(frame) / CGFloat(frameCount)
        drawSpeedLines(frame: frame, in: context)
        // 한 바퀴(8프레임)에 숨구멍 한 칸만큼 돌아 끊김 없이 이어진다
        drawBall(rotation: -phase * 2 * .pi / CGFloat(holeCount), in: context)

        // 공 바닥 안쪽을 딛고 앞으로 살짝 기울어 달린다
        context.saveGState()
        context.translateBy(x: center.x - 0.2, y: center.y - radius + ringWidth + 2.0)
        context.rotate(by: -0.08)
        context.scaleBy(x: hamsterScale, y: hamsterScale)
        // 실루엣 원점(몸통 중심)을 발바닥 가운데로 옮긴다
        context.translateBy(x: -1.1, y: 6.4)
        let stride = 2 * .pi * phase
        HamsterSilhouette.draw(
            .init(lift: 0.35 * cos(2 * stride), front: 30 * cos(stride), hind: -30 * cos(stride)),
            in: context
        )
        context.restoreGState()
    }

    private static func drawBall(rotation: CGFloat, in context: CGContext) {
        context.saveGState()
        defer { context.restoreGState() }
        context.setLineWidth(ringWidth)
        context.setLineCap(.butt)
        let step = 2 * .pi / CGFloat(holeCount)
        for index in 0..<holeCount {
            let start = rotation + CGFloat(index) * step + holeAngle / 2
            context.addArc(center: center, radius: radius - ringWidth / 2, startAngle: start, endAngle: start + step - holeAngle, clockwise: false)
            context.strokePath()
        }
        // 투명한 공의 반짝임(돌지 않는다)
        context.setLineWidth(0.8)
        context.setLineCap(.round)
        context.addArc(center: center, radius: radius - 2.6, startAngle: .pi * 0.62, endAngle: .pi * 0.9, clockwise: false)
        context.strokePath()
    }

    /// 공 뒤(왼쪽)로 날리는 속도선. 프레임마다 길이가 바뀐다.
    private static func drawSpeedLines(frame: Int, in context: CGContext) {
        context.saveGState()
        defer { context.restoreGState() }
        context.setLineWidth(1.1)
        context.setLineCap(.round)
        for (index, y) in [CGFloat(12.5), 9.0, 5.5].enumerated() {
            let length: CGFloat = (index + frame) % 2 == 0 ? 4.2 : 2.6
            context.move(to: CGPoint(x: 6.2 - length, y: y))
            context.addLine(to: CGPoint(x: 6.2, y: y))
            context.strokePath()
        }
    }
}
