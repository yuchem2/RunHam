import CoreGraphics

/// 메트릭스 바에 아무 항목도 켜지 않았을 때 보여 줄 자는 햄스터(28×18pt, 1프레임).
/// 기본 러너와 같은 실루엣이 다리를 접고 엎드려 고개를 숙이고, 감은 눈(흰 선)과 Z.
enum SleepingHamsterSprite {
    static let pointSize = CGSize(width: 28, height: 18)
    static let scale: CGFloat = 2

    static let image: CGImage = SpriteRenderer.render(
        width: Int(pointSize.width * scale),
        height: Int(pointSize.height * scale)
    ) { context in
        context.scaleBy(x: scale, y: scale)
        draw(in: context)
    }

    static func draw(in context: CGContext) {
        context.saveGState()
        context.translateBy(x: 9.4, y: 4.9)
        HamsterSilhouette.draw(.init(pitch: -3, stretch: 1.02, headTilt: -14, showsLegs: false, eyesClosed: true), in: context)
        context.restoreGState()

        // Z z
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.setLineWidth(1.0)
        drawZ(in: context, origin: CGPoint(x: 21.4, y: 10.6), size: 2.0)
        drawZ(in: context, origin: CGPoint(x: 23.8, y: 13.6), size: 3.0)
    }

    private static func drawZ(in context: CGContext, origin: CGPoint, size: CGFloat) {
        context.move(to: CGPoint(x: origin.x, y: origin.y + size))
        context.addLine(to: CGPoint(x: origin.x + size, y: origin.y + size))
        context.addLine(to: origin)
        context.addLine(to: CGPoint(x: origin.x + size, y: origin.y))
        context.strokePath()
    }
}
