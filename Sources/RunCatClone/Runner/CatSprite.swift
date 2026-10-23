import CoreGraphics
import Foundation

/// 원본 에셋을 쓰지 않고 코드로 그리는 고양이 실루엣 (56×36px, 5프레임 갤럽).
enum CatSprite {
    static let width = 56
    static let frameCount = 5

    static func makeRunner() -> Runner {
        let frames = (0..<frameCount).map { index in
            SpriteRenderer.render(width: width) { draw(in: $0, phase: Double(index) / Double(frameCount)) }
        }
        return Runner(id: "cat", name: "Cat", frames: frames)
    }

    /// phase 0..<1 — 0 에서 다리가 가장 크게 벌어지고 0.5 에서 모인다.
    private static func draw(in ctx: CGContext, phase: Double) {
        let wave = cos(phase * 2 * .pi)
        let bob = CGFloat(sin(phase * 2 * .pi)) * 1.5
        let tilt = CGFloat(wave) * 0.08

        ctx.saveGState()
        ctx.translateBy(x: 28, y: 17 + bob)
        ctx.rotate(by: tilt)

        // 몸통
        ctx.addEllipse(in: CGRect(x: -13, y: -5.5, width: 26, height: 11))
        ctx.fillPath()

        // 머리
        ctx.addEllipse(in: CGRect(x: 10, y: -1, width: 13, height: 12))
        ctx.fillPath()

        // 귀
        ctx.move(to: CGPoint(x: 11.5, y: 8))
        ctx.addLine(to: CGPoint(x: 13, y: 15))
        ctx.addLine(to: CGPoint(x: 17, y: 10))
        ctx.move(to: CGPoint(x: 17, y: 10.5))
        ctx.addLine(to: CGPoint(x: 21, y: 15.5))
        ctx.addLine(to: CGPoint(x: 22, y: 8))
        ctx.fillPath()

        // 꼬리: 달리는 박자에 맞춰 위아래로 흔든다
        let tailLift = CGFloat(-wave) * 4
        ctx.setLineWidth(3)
        ctx.move(to: CGPoint(x: -11, y: 2))
        ctx.addQuadCurve(to: CGPoint(x: -25, y: 6 + tailLift), control: CGPoint(x: -19, y: 0))
        ctx.strokePath()

        // 다리: 앞다리는 앞으로, 뒷다리는 뒤로 뻗었다가 몸 아래로 모인다
        ctx.setLineWidth(3.4)
        // 모으는 구간은 덜 교차시키고 발끝만 바깥으로 꺾어 다리가 겹쳐 보이지 않게 한다
        let spread = wave >= 0 ? 0.9 * wave : 0.45 * wave
        let tuck = max(0, -wave)
        drawLeg(ctx, hip: CGPoint(x: 9, y: -2), angle: spread + 0.15, bend: 0.9 * tuck, length: 12)
        drawLeg(ctx, hip: CGPoint(x: 6, y: -2), angle: spread - 0.2, bend: 0.6 * tuck, length: 12)
        drawLeg(ctx, hip: CGPoint(x: -7, y: -2), angle: -spread - 0.1, bend: -0.9 * tuck, length: 12)
        drawLeg(ctx, hip: CGPoint(x: -10, y: -2), angle: -spread + 0.25, bend: -0.6 * tuck, length: 12)

        ctx.restoreGState()
    }

    /// angle 은 수직 아래 기준 라디안, 양수면 진행 방향(+x)으로 뻗는다. bend 는 무릎 아래를 추가로 꺾는 각도.
    private static func drawLeg(_ ctx: CGContext, hip: CGPoint, angle: Double, bend: Double, length: CGFloat) {
        let knee = CGPoint(
            x: hip.x + CGFloat(sin(angle)) * length * 0.55,
            y: hip.y - CGFloat(cos(angle)) * length * 0.55
        )
        let footAngle = angle * 0.6 + bend
        let foot = CGPoint(
            x: knee.x + CGFloat(sin(footAngle)) * length * 0.5,
            y: knee.y - CGFloat(cos(footAngle)) * length * 0.5
        )
        ctx.move(to: hip)
        ctx.addLine(to: knee)
        ctx.addLine(to: foot)
        ctx.strokePath()
    }
}
