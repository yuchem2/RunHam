import CoreGraphics

/// 메트릭스 바에 아무 항목도 켜지 않았을 때 보여 줄 자는 햄스터(28×18pt, 1프레임).
/// 러너와 같은 정면 얼굴에 눈만 감은 눈(‿)으로, 동그랗게 웅크린 몸과 턱 밑에 모은 앞발, Z.
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
        context.setLineCap(.round)
        context.setLineJoin(.round)
        let head = CGPoint(x: 15.6, y: 7.4)
        let headScale: CGFloat = 0.78

        // 웅크린 몸과 짧은 꼬리
        context.fillEllipse(in: CGRect(center: CGPoint(x: 3.4, y: 3.6), size: CGSize(width: 1.4, height: 1.2)))
        context.fillEllipse(in: CGRect(center: CGPoint(x: 10.2, y: 5.2), size: CGSize(width: 13.6, height: 9.6)))

        // 머리 둘레를 비워 몸과 구분한 뒤, 감은 눈 얼굴
        context.setBlendMode(.clear)
        HamsterShape.fillFrontHeadSilhouette(at: head, scale: headScale, inflate: 0.6, in: context)
        context.setBlendMode(.normal)
        HamsterShape.drawFrontHead(at: head, scale: headScale, eyesClosed: true, in: context)

        // 턱 밑에 모은 앞발
        for x: CGFloat in [14.2, 17.0] {
            context.fillEllipse(in: CGRect(center: CGPoint(x: x, y: 2.4), size: CGSize(width: 2.0, height: 1.5)))
        }

        // Z z
        context.setLineWidth(1.0)
        drawZ(in: context, origin: CGPoint(x: 21.8, y: 11.2), size: 2.0)
        drawZ(in: context, origin: CGPoint(x: 23.8, y: 14.0), size: 3.0)
    }

    private static func drawZ(in context: CGContext, origin: CGPoint, size: CGFloat) {
        context.move(to: CGPoint(x: origin.x, y: origin.y + size))
        context.addLine(to: CGPoint(x: origin.x + size, y: origin.y + size))
        context.addLine(to: origin)
        context.addLine(to: CGPoint(x: origin.x + size, y: origin.y))
        context.strokePath()
    }
}
