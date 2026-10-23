import CoreGraphics

/// 메트릭스 바에 아무 항목도 켜지 않았을 때 보여 줄 자는 고양이(28×18pt, 1프레임).
/// 러너와 같은 곡선 스타일: 식빵 자세 몸통, 앞에 기댄 머리, 감은 눈(‿), 뒤로 말린 꼬리, Z.
enum SleepingCatSprite {
    static let pointSize = CGSize(width: 28, height: 18)
    static let scale: CGFloat = 2

    /// 러너 머리 위치에서 자는 머리 위치로 옮기는 양(귀 모양을 그대로 쓰기 위함)
    static let headOffset = CGPoint(x: -1.6, y: -4.2)

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

        // 뒤로 말린 꼬리
        context.setLineWidth(1.9)
        context.move(to: CGPoint(x: 4.6, y: 2.6))
        context.addCurve(to: CGPoint(x: 2.6, y: 7.2), control1: CGPoint(x: 1.2, y: 2.4), control2: CGPoint(x: 0.9, y: 6.2))
        context.strokePath()

        // 식빵 몸통
        context.fillEllipse(in: CGRect(center: CGPoint(x: 11.4, y: 4.4), size: CGSize(width: 15.6, height: 8.2)))

        // 머리와 귀
        let head = CGPoint(x: VectorCatSprite.headCenter.x + headOffset.x, y: VectorCatSprite.headCenter.y + headOffset.y)
        context.fillEllipse(in: CGRect(center: head, size: VectorCatSprite.headSize))
        context.saveGState()
        context.translateBy(x: headOffset.x, y: headOffset.y)
        VectorCatSprite.drawEars(in: context)
        context.restoreGState()

        // 감은 눈(‿)은 선으로 뚫는다
        context.setBlendMode(.clear)
        context.setLineWidth(0.75)
        for eye in [CGPoint(x: head.x - 1.7, y: head.y + 0.7), CGPoint(x: head.x + 1.7, y: head.y + 0.7)] {
            context.addArc(center: eye, radius: 0.85, startAngle: .pi * 1.15, endAngle: .pi * 1.85, clockwise: false)
            context.strokePath()
        }
        context.fillEllipse(in: CGRect(center: CGPoint(x: head.x, y: head.y - 1.0), size: CGSize(width: 0.9, height: 0.6)))
        context.setBlendMode(.normal)

        // Z z
        context.setLineWidth(1.0)
        // 귀 끝(약 22.8, 12.6)에 닿지 않도록 머리 오른쪽 위로 올라가게 둔다
        drawZ(in: context, origin: CGPoint(x: 25.2, y: 9.2), size: 2.0)
        drawZ(in: context, origin: CGPoint(x: 23.4, y: 13.4), size: 3.2)
    }

    private static func drawZ(in context: CGContext, origin: CGPoint, size: CGFloat) {
        context.move(to: CGPoint(x: origin.x, y: origin.y + size))
        context.addLine(to: CGPoint(x: origin.x + size, y: origin.y + size))
        context.addLine(to: origin)
        context.addLine(to: CGPoint(x: origin.x + size, y: origin.y))
        context.strokePath()
    }
}
